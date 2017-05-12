# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::VNC;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;

our $VERSION = 0.995;
use 5.012;

use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
    
    my @themes;
    foreach my $key (sort keys %{$self->{view}}) {
        my %theme = %{$self->{view}->{$key}};
        $theme{name} = $key;
        
        push @themes, \%theme;
    }
    $self->{Themes} = \@themes;
    
    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we only use the template and database module
    return;
}

sub register {
    my $self = shift;
    $self->register_webpath($self->{select}->{webpath}, "get_select");
    $self->register_webpath($self->{displaywait}->{webpath}, "get_wait");
    $self->register_webpath($self->{displayshow}->{webpath}, "get_show");
    $self->register_webpath($self->{ajaxtunnel}->{webpath}, "get_tunnelstatus");
    $self->register_webpath($self->{ajaxrefresh}->{webpath}, "get_refresh");
    return;
}

sub get_select {
    my ($self, $cgi) = @_;
       
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    
    my %webdata =
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle       =>  $self->{pagetitle},
        webpath         =>  $self->{select}->{webpath},
        AvailThemes     =>  $self->{Themes},
        PostLink        =>  $self->{displaywait}->{webpath},
    );
    
    my @computers;
    my $selsth = $dbh->prepare_cached("SELECT * FROM computers NATURAL JOIN computers_vnccompany
                                      WHERE company_name = ?
                                      AND is_enabled = 't'
                                      ORDER BY line_id, computer_name")
            or croak($dbh->errstr);
    if(!$selsth->execute($webdata{userData}->{company})) {
        $dbh->rollback;
    } else {
        while((my $computer = $selsth->fetchrow_hashref)) {
            push @computers, $computer;
        }
        $selsth->finish;
    }
    $webdata{AvailComputers} = \@computers;
    
    my $template = $self->{server}->{modules}->{templates}->get("vncselect", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub get_wait {
    my ($self, $cgi) = @_;
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $client_ip = $cgi->remote_addr(); 
    
    my %webdata =
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle       =>  $self->{pagetitle},
        webpath         =>  $self->{select}->{webpath},
        AvailThemes     =>  $self->{Themes},
    );
    
    my $mode = $cgi->param('mode') || 'view';
    my $reason = $cgi->param('reason') || '';
    my $host = $cgi->param('computername') || '';
    my $hostok = 0;
    
    my $hostdata;
    my $selsth = $dbh->prepare_cached("SELECT * FROM computers NATURAL JOIN computers_vnccompany
                                      WHERE company_name = ?
                                      ORDER BY line_id, computer_name")
            or croak($dbh->errstr);
    if(!$selsth->execute($webdata{userData}->{company})) {
        $dbh->rollback;
    } else {
        while((my $computer = $selsth->fetchrow_hashref)) {
            if($computer->{computer_name} eq $host) {
                $hostok = 1;
                $hostdata = $computer;
            }
        }
        $selsth->finish;
    }
    if($reason eq '' || $host eq '') {
        $hostok = 0;
    }
    
    my $proxyport = 0;
    
    if($hostok) {
        # Find a random free port
        my @ports;
        my $selpsth = $dbh->prepare_cached("SELECT proxy_port FROM computers_vnc")
            or croak($dbh->errstr);
        if(!$selpsth->execute) {
            $dbh->rollback;
        } else {
            while((my ($port) = $selpsth->fetchrow_array)) {
                push @ports, $port;
            }
            $selpsth->finish;
            
            while($proxyport == 0) {
                my $newport = int(rand($self->{maxport} - $self->{minport} + 1) + $self->{minport});
                if(!($newport ~~ @ports)) {
                    $proxyport = $newport;
                }
            }
        }
    }
    
    my $isExisting = 0;
    {
        # Check if there already IS a tunnel for this connection
        my $csth = $dbh->prepare_cached("SELECT proxy_port FROM computers_vnc
                                        WHERE computer_name = ?
                                        AND client_ip = ?")
                or croak($dbh->errstr);
        if(!$csth->execute($hostdata->{computer_name}, $client_ip)) {
            $dbh->rollback;
        } else {
            while((my ($tmpport) = $csth->fetchrow_array)) {
                $isExisting = 1;
                $proxyport = $tmpport;
            }
            $csth->finish;
        }
    }

    if($proxyport > 0) {
        my $logsth = $dbh->prepare_cached("INSERT INTO computers_vnclog
                    (logtype, computer_name, client_ip, proxy_port, freelogtext, username)
                    VALUES ('REQUEST_SESSION', ?, ?, ?, ?, ?)")
                or croak($dbh->errstr);
        if($logsth->execute($hostdata->{computer_name}, $client_ip, $proxyport, $reason, $webdata{userData}->{user})) {
            $dbh->commit;
        } else {
            $dbh->rollback;
        }
    }

        
    if(!$isExisting && $proxyport > 0) {
        # Add proxy request for worker to database
        my $insth = $dbh->prepare_cached("INSERT INTO computers_vnc
                                         (computer_name, computer_ip, client_ip, proxy_port)
                                        VALUES (?,?,?,?)")
                or croak($dbh->errstr);
        if($insth->execute($hostdata->{computer_name}, $hostdata->{net_prod_ip},
                           $client_ip, $proxyport)) {
            $dbh->commit;
        } else {
            $dbh->rollback;
            $proxyport = 0;
        }
    }

    if($proxyport == 0) {
        # Something went wrong, let the user select again
        return $self->get_select($cgi);
    }
    
    $webdata{WaitLink} = $self->{ajaxtunnel}->{webpath};
    $webdata{ShowLink} = $self->{displayshow}->{webpath} . "/$host";
    $webdata{ProxyPort} = $proxyport;
    
    my $template = $self->{server}->{modules}->{templates}->get("vncwait", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub get_show {
    my ($self, $cgi) = @_;
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $client_ip = $cgi->remote_addr();
    
    my %webdata =
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle       =>  $self->{pagetitle},
        webpath         =>  $self->{select}->{webpath},
        AvailThemes     =>  $self->{Themes},
    );
    
    my $proxyport = $cgi->param('ID') || '';

    if($proxyport eq '') {
        # Something went wrong, let the user select again
        return $self->get_select($cgi);
    }
    
    my $vncpassword = "";
    my $selsth = $dbh->prepare_cached("SELECT * FROM computers_vnc NATURAL JOIN computers
                                      WHERE proxy_port = ?")
            or croak($dbh->errstr);
    if(!$selsth->execute($proxyport)) {
        $dbh->rollback;
    } else {
        while((my $line = $selsth->fetchrow_hashref)) {
            $webdata{ComputerData} = $line;
        }
        $selsth->finish;
    }
    
    $webdata{WaitLink} = $self->{ajaxrefresh}->{webpath};
    $webdata{ProxyPort} = $proxyport;
    $webdata{HideMenuBar} = "1";
    
    my $template = $self->{server}->{modules}->{templates}->get("vncdisplay", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}


sub get_tunnelstatus {
    my ($self, $cgi) = @_;
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $client_ip = $cgi->remote_addr();
    my $proxyport = $cgi->param('ID') || '';
    
    my $status = "WAIT";

    my $selsth = $dbh->prepare_cached("SELECT has_proxystarted FROM computers_vnc
                                      WHERE proxy_port = ?
                                      AND client_ip = ?")
            or croak($dbh->errstr);
    if(!$selsth->execute($proxyport, $client_ip)) {
        $dbh->rollback;
    } else {
        while((my ($started) = $selsth->fetchrow_array)) {
            if($started) {
                $status = "SHOWLINK";
            }
        }
        $selsth->finish;
    }
    
    return (status  =>  200,
            type    => "text/plain",
            data    => $status);
}

sub get_refresh {
    my ($self, $cgi) = @_;
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $client_ip = $cgi->remote_addr();
    my $proxyport = $cgi->param('ID') || '';
    
    my $status = "ERROR";

    my $upsth = $dbh->prepare_cached("UPDATE computers_vnc
                                      SET last_update = now()
                                      WHERE proxy_port = ?
                                      AND client_ip = ?")
            or croak($dbh->errstr);
    if(!$upsth->execute($proxyport, $client_ip)) {
        $dbh->rollback;
    } else {
        $dbh->commit;
        $status = "OK";
    }
    
    return (status  =>  200,
            type    => "text/plain",
            data    => $status);
}




1;
__END__

=head1 NAME

Maplat::Web::VNC - Support for remote maintenance

=head1 SYNOPSIS

Adds support for remote maintenance via VNC

=head1 DESCRIPTION

Provides remote maintenance. This is supposed to be used in conjunction with the computer database and FileMan.

=head1 Configuration

    <module>
        <modname>vnc</modname>
        <pm>VNC</pm>
        <options>
            <minport>40000</minport>
            <maxport>41000</maxport>
            <select>
                <pagetitle>VNC</pagetitle>
                <webpath>/vnc/select</webpath>
            </select>
            <displaywait>
                <pagetitle>VNC</pagetitle>
                <webpath>/vnc/display/wait</webpath>
            </displaywait>
            <displayshow>
                <pagetitle>VNC</pagetitle>
                <webpath>/vnc/display/show</webpath>
            </displayshow>
            <ajaxtunnel>
                <pagetitle>VNC Ajax Tunnel</pagetitle>
                <webpath>/vnc/ajax/tunnel</webpath>
            </ajaxtunnel>
            <ajaxrefresh>
                <pagetitle>VNC Ajax Refresh</pagetitle>
                <webpath>/vnc/ajax/refresh</webpath>
            </ajaxrefresh>
            <db>maindb</db>
            <memcache>memcache</memcache>
            <session>sessionsettings</session>
        </options>
    </module>



=head2 get_select

Select the computer to connect to.

=head2 get_show

Opens the VNCViewer Java applet page

=head2 get_wait

The wait page while the background worker opens the proxy tunnel.

=head2 get_refresh

AJAX callback to keep the tunnel status active.

=head2 get_tunnelstatus

AJAX callback to get the current tunnel status.

=head1 SEE ALSO

Maplat::Web

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
