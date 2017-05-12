# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Worker::Logging::EMCTime;
use strict;
use warnings;
use 5.010;

use base qw(Maplat::Worker::BaseModule);

use Net::SNMP;
use Carp;

our $VERSION = 0.995;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

    $self->loadMiniMIB();

    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we only use the template and database module
    return;
}

sub register {
    my $self = shift;
    
    $self->register_worker("work");
    return;
}

sub loadMiniMIB {
    my ($self) = @_;
    
    my @MIBS = $self->loadMIB();
    
    my %mibdef;
    foreach my $mib (@MIBS) {
        chomp $mib;
        my @parts = split/;/, $mib;
        next if($parts[0] eq 'ID');
        $mibdef{$parts[0]} = $parts[1];
    }
    
    $self->{mibdef} = \%mibdef;
    return;
}

sub loadMIB {
    my ($self) = @_;
    
    my $MIB =<<"MINIMIB";
ID;ColName;Description
1.3.6.1.4.1.28507.3.1.6.0;temperature;Temperature in 1/10 degree Celsius
1.3.6.1.4.1.28507.3.1.5.0;dcf_ok;Is DCF77 active or do we use the quarz
MINIMIB

    my @MIBS = split/\n/,$MIB;

    return @MIBS;
}

sub work {
    my ($self) = @_;
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $reph = $self->{server}->{modules}->{$self->{reporting}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    # Refresh Lifetick every now and then
    $memh->refresh_lifetick;
    
    my $workCount = 0;
    
    my @todo;
    my $selstmt = "SELECT * FROM logging_devices
                    WHERE device_type = 'EMCTIME'
                    AND is_active = 't'
                    AND scanspeed = '" . $self->{scanspeed} . "'
                    ORDER BY hostname";
    my $selsth = $dbh->prepare_cached($selstmt)
            or croak($dbh->errstr);
    $selsth->execute or croak($dbh->errstr);
    while((my $device = $selsth->fetchrow_hashref)) {
        push @todo, $device;
    }
    $selsth->finish;
    
    foreach my $device (@todo) {
        $workCount++;
        $reph->debuglog("Logging EMCTime for " . $device->{hostname} . " at " . $device->{ip_addr});
        # Refresh Lifetick every now and then
        $memh->refresh_lifetick;
        
        my ($ok, %vals) = $self->getValues($device->{ip_addr});
        if($ok) {
            
            my @dcols = qw[hostname device_type device_ok];
            my @dvals = ("'$device->{hostname}'", "'EMCTIME'", "'t'");
            
            foreach my $key (keys %vals) {
                my $colname = $self->{mibdef}->{$key};
                my $val = $vals{$key};
                
                if($colname eq "temperature") {
                    $val = $val / 10;
                } elsif($colname =~ /(?:is|has|active|ok)/) {
                    if($val == 1) {
                        $val = "'t'";
                    } else {
                        $val = "'f'";
                    }
                }
                push @dcols, $colname;
                push @dvals, $val;
            }
            
            my $columns = join(',', @dcols);
            my $values = join(',', @dvals);

            my $instmt = "INSERT INTO logging_log_emctime ($columns) VALUES ($values)";
            my $insth = $dbh->prepare($instmt) or croak($dbh->errstr);
            $insth->execute or croak($dbh->errstr);
            $insth->finish;
            $dbh->commit;
        } else {
            $reph->debuglog("Access failed to " . $device->{hostname} . "!");
            my $errorstmt = "INSERT INTO logging_log_emctime (hostname, device_type, device_ok)
                            VALUES (" . $dbh->quote($device->{hostname}) . ", 'EMCTIME', 'f')";
            my $errorsth = $dbh->prepare($errorstmt) or croak($dbh->errstr);
            $errorsth->execute or croak($dbh->errstr);
            $errorsth->finish;
            $dbh->commit;
        }
    }
    $dbh->rollback;
    return $workCount;
}

sub getValues {
    my ($self, $ip) = @_;
    
    my ($session,$error) = Net::SNMP->session(Hostname => $ip,
                                       Community => 'public');
    
    return 0 unless($session);
    
    my %vals;
    foreach my $id (keys %{$self->{mibdef}}) {
        my $result = $session->get_request($id);
        if(defined($result)) {
            $vals{$id} = $result->{$id};
        }
    }
    $session->close;
    return 1, %vals;
    
}


1;
__END__

=head1 NAME

Maplat::Worker::Logging::EMCTime - Log from EMC DCF77 Server

=head1 SYNOPSIS

  use Maplat::Worker;
  
Then configure() the module as you would normally.

This module is targeted to log from an industrial USV with a
"GE Consumer&Industrial Advanced SNMP WEB INTERFACE CARD"
via its web interface.

=head1 DESCRIPTION

    <module>
        <modname>usv</modname>
        <pm>Logging::EMCTime</pm>
        <options>
            <db>maindb</db>
            <memcache>memcache</memcache>
            <reporting>reporting</reporting>
            <scanspeed>fast</scanspeed>
        </options>
    </module>

This module provides the webmasks required to configure logging devices.

=head2 work

Internal function, logs for all USV devices.

=head2 loadMiniMIB

Internal function.

=head2 loadMIB

Internal function.

=head2 getValues

Internal function.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
