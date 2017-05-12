# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Worker::Logging::USV;
use strict;
use warnings;
use 5.010;

use base qw(Maplat::Worker::BaseModule);

use WWW::Mechanize;
use HTML::TableExtract;
use Carp;

our $VERSION = 0.995;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

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
                    WHERE device_type = 'USV'
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
        $reph->debuglog("Logging USV for " . $device->{hostname} . " at " . $device->{ip_addr});
        # Refresh Lifetick every now and then
        $memh->refresh_lifetick;
        
        my $mech = WWW::Mechanize->new();
        $mech->credentials($device->{username}, $device->{password});
        
        my $url = 'http://' . $device->{ip_addr} . '/status.htm?UpsIndex=0';
        my $result = $mech->get($url);
        if($result->is_success) {
            my $content = $result->content;
            my %data = $self->parseContent($content);
            $data{hostname} = $device->{hostname};
            $data{device_type} = 'USV';
            my ($keys, $vals) = ("", "");
            foreach my $key (sort keys %data) {
                $keys .= ",$key";
                if($key eq "hostname" || $key eq "bat_status" || $key eq "device_type") {
                    $vals .= "," . $dbh->quote($data{$key});
                } else {
                    $vals .= "," . $data{$key};
                }
            }
            $keys =~ s/^\,//o;
            $vals =~ s/^\,//o;
            my $instmt = "INSERT INTO logging_log_usv ($keys) VALUES ($vals)";
            my $insth = $dbh->prepare($instmt) or croak($dbh->errstr);
            $insth->execute or croak($dbh->errstr);
            $insth->finish;
            $dbh->commit;
        } else {
            $reph->debuglog("Access failed to " . $device->{hostname} . "!");
            my $errorstmt = "INSERT INTO logging_log_usv (hostname, device_type, device_ok)
                            VALUES (" . $dbh->quote($device->{hostname}) . ", 'USV', 'f')";
            my $errorsth = $dbh->prepare($errorstmt) or croak($dbh->errstr);
            $errorsth->execute or croak($dbh->errstr);
            $errorsth->finish;
            $dbh->commit;
        }
    }
    $dbh->rollback;
    return $workCount;
}

sub tableToText {
    my ($self, $content) = @_;

    my $te = HTML::TableExtract->new;
    $te->parse($content);
    
    my @rows;
    foreach my $ts ($te->tables) {
        #print "Table (", join(',', $ts->coords), "):\n";
        foreach my $row ($ts->rows) {
            push @rows, join(',', @$row);
        }
    }
    
    return @rows;
}

sub parseContent {
    my ($self, $content) = @_;
    
    my @rows = $self->tableToText($content);
    
    my %values;
    
    my @ignore = ("Battery Group", "BatteryRipple, not available", "Input Group",
                  "Output Group", "Bypass Group");
    
    while((scalar @rows)) {
        my $line = shift @rows;
        
        given($line) {
            when(@ignore) {
                next;
            }
            when(/BatteryStatus,(.*)/o) {
                $values{bat_status} = $1;
            }
            when(/SecondsOnBattery,(.*)\ sec/o) {
                $values{bat_used} = $1;
            }
            when(/EstimatedMinuteRemain,(.*)\ min/o) {
                $values{bat_timeremain} = $1;
            }
            when(/EstimatedChargeRemain,(.*)\%/o) {
                $values{bat_chargeremain} = $1;
            }
            when(/BatteryVoltage,(.*)\ Volt/o) {
                $values{bat_voltage} = $1;
            }
            when(/BatteryCurrent,(.*)\ AMP/o) {
                $values{bat_current} = $1;
            }
            when(/BatteryTemperature,(.*)\ Celsius/o) {
                $values{bat_temp} = $1;
            }
            when('Phase,Frequency,Voltage,Current,TruePower') {
                for(1..3) {
                    my ($key, undef, $voltage) = split /\,/, shift @rows;
                    $key = "in_voltage$key";
                    $voltage =~ s/\ V//go;
                    $values{$key} = $voltage;
                }
            }
            when('Phase,Voltage,Current,Power,Load,Power Factor,Peak Current,Share Current') {
                for(1..3) {
                    my ($key, $voltage, $current, $power, $load) = split /\,/, shift @rows;
                    
                    $voltage =~ s/\ V//go;
                    $values{"out_voltage$key"} = $voltage;
                    $current =~ s/\ A//go;
                    $values{"out_current$key"} = $current;
                    $power =~ s/\ Watt.*//go;
                    $values{"out_power$key"} = $power;
                    $load =~ s/\%//go;
                    $values{"out_load$key"} = $load;
                }
            }
        }
    }
    
    return %values;
}

1;
__END__

=head1 NAME

Maplat::Worker::Logging::USV - Log from USV with Web Interface card

=head1 SYNOPSIS

  use Maplat::Worker;
  use Maplat::Worker::Logging;
  
Then configure() the module as you would normally.

This module is targeted to log from an industrial USV with a
"GE Consumer&Industrial Advanced SNMP WEB INTERFACE CARD"
via its web interface.

=head1 DESCRIPTION

    <module>
        <modname>usv</modname>
        <pm>Logging::USV</pm>
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

=head2 parseContent

Internal function.

=head2 tableToText

Internal function.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
