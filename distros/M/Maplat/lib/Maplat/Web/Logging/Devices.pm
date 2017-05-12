# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::Logging::Devices;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);

use Maplat::Helpers::DateStrings;
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
    
    $self->register_webpath($self->{admin}->{webpath}, "get_admin");
    $self->register_webpath($self->{user}->{webpath}, "get_user");
    
    return;
}

sub get_user {
    my ($self, $cgi) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};

    my %webdata = 
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{user}->{pagetitle},
        webpath    =>  $self->{user}->{webpath},
    );
    
    my $mustupdate = $cgi->param("submitform") || "0";
    if($mustupdate eq "1") {
        my @hostnames = $cgi->param("hostname");
        my $upstmt = "UPDATE logging_devices SET description=?, is_active=?, scanspeed=? WHERE hostname=?";
        my $upsth = $dbh->prepare_cached($upstmt) or croak($dbh->errstr);
        foreach my $hostname (@hostnames) {
            my $description = $cgi->param("desc_" . $hostname) || "";
            my $scanspeed = $cgi->param("speed_" . $hostname) || "";
            my $active = $cgi->param("status_" . $hostname) || "";
            if($active eq "") {
                $active = "false";
            } else {
                $active = "true";
            }
            $upsth->execute($description, $active, $scanspeed, $hostname);
        }
        $upsth->finish;
        $dbh->commit;
    }

    my $stmt = "SELECT hostname, device_type, is_active, description, scanspeed " .
                "FROM logging_devices " .
                "ORDER BY hostname";

    my @devices;
    my $devicecnt = 0;
    my $sth = $dbh->prepare_cached($stmt) or croak($dbh->errstr);
    $sth->execute or croak($dbh->errstr);

    while((my $device = $sth->fetchrow_hashref)) {
        $devicecnt++;
        $device->{devicecnt} = $devicecnt;
        
        if($device->{description} eq "null") {
            $device->{description} = "";
        }
        push @devices, $device;
    }
    $sth->finish;
    $dbh->rollback;

    $webdata{devices} = \@devices;
    
    my $template = $self->{server}->{modules}->{templates}->get("logging/devices_user", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub get_admin {
    my ($self, $cgi) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};

    my %webdata = 
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{admin}->{pagetitle},
        webpath    =>  $self->{admin}->{webpath},
    );
    
    my $mustupdate = $cgi->param("submitform") || "0";
    if($mustupdate eq "1") {
        my @hostnames = $cgi->param("hostname");
        my $upstmt = "UPDATE logging_devices SET description=?, is_active=?, scanspeed=?, ip_addr=?, username=?, password=? WHERE hostname=?";
        my $upsth = $dbh->prepare_cached($upstmt) or croak($dbh->errstr);
        foreach my $hostname (@hostnames) {
            my $description = $cgi->param("desc_" . $hostname) || "";
            my $scanspeed = $cgi->param("speed_" . $hostname) || "";
            my $ip_addr = $cgi->param("ip_" . $hostname) || "";
            my $username = $cgi->param("user_" . $hostname) || "";
            my $password = $cgi->param("pass_" . $hostname) || "";
            my $active = $cgi->param("status_" . $hostname) || "";
            if($active eq "") {
                $active = "false";
            } else {
                $active = "true";
            }
            $upsth->execute($description, $active, $scanspeed, $ip_addr, $username, $password, $hostname);
        }
        $upsth->finish;
        $dbh->commit;
    }

    my $stmt = "SELECT hostname, device_type, is_active, description, scanspeed, ip_addr, username, password " .
                "FROM logging_devices " .
                "ORDER BY hostname";

    my @devices;
    my $devicecnt = 0;
    my $sth = $dbh->prepare_cached($stmt) or croak($dbh->errstr);
    $sth->execute or croak($dbh->errstr);

    while((my $device = $sth->fetchrow_hashref)) {
        $devicecnt++;
        $device->{devicecnt} = $devicecnt;
        
        if($device->{description} eq "null") {
            $device->{description} = "";
        }
        push @devices, $device;
    }
    $sth->finish;
    $dbh->rollback;

    $webdata{devices} = \@devices;
    
    my $template = $self->{server}->{modules}->{templates}->get("logging/devices_admin", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}
1;
__END__

=head1 NAME

Maplat::Web::Logging::Devices - manage Devices from which to log data

=head1 SYNOPSIS

  use Maplat::Web;
  use Maplat::Web::Logging;
  
Then configure() the module as you would normally.

=head1 DESCRIPTION

    <module>
        <modname>loggingdevices</modname>
        <pm>Logging::Devices</pm>
        <options>
            <linktitle>Devices</linktitle>
            <user>
                <webpath>/logging/devicesusr</webpath>
                <pagetitle>Devices</pagetitle>
            </user>
            <admin>
                <webpath>/logging/devicesadm</webpath>
                <pagetitle>Devices Admin</pagetitle>
            </admin>
            <db>maindb</db>
            <minurls>4</minurls>
        </options>
    </module>

This module provides the webmasks required to configure logging devices.

=head2 get_user

Internal function, renders the user view.

=head2 get_admin

Internal function, renders the admin view.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut



