# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz

package Maplat::Web::ComputerDB::GlobalOperatingSystem;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;

our $VERSION = 0.995;

use Carp;

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
    $self->register_webpath($self->{webpath}, "get");
    return;
}


sub get {
    my ($self, $cgi) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};

    my @domains;
    
    my $dsth = $dbh->prepare_cached("SELECT enumvalue FROM enum_computers_domains
                                    ORDER BY enumvalue")
            or croak($dbh->errstr);
    $dsth->execute or croak($dbh->errstr);
    while((my $domain = $dsth->fetchrow_array)) {
        push @domains, $domain;
    }
    $dsth->finish;

    my %webdata = 
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{pagetitle},
        webpath    =>  $self->{webpath},
        domains => \@domains,
    );

    

    my $mode = $cgi->param("mode") || "view";
    if($mode eq "create") {
        my $name = $cgi->param("operating_system") || "";
        my $domain = $cgi->param("default_domain") || "";
        my $servicepack = $cgi->param("default_servicepack") || "0";
        
        if($name ne "") {
            my $sth = $dbh->prepare_cached("INSERT INTO computers_os (operating_system, default_servicepack, default_domain)
                                           VALUES (?, ?, ?)")
                        or croak($dbh->errstr);
            my $ok = 1;
            
            if(!$sth->execute($name, $servicepack, $domain)) {
                $ok = 0;
            }
            
            if($ok) {
                $sth->finish;
                $dbh->commit;
                $webdata{statustext} = "OS created";
                $webdata{statuscolor} = "oktext";
            } else {
                $webdata{statustext} = "Sorry, didn't work";
                $webdata{statuscolor} = "errortext";
                $dbh->rollback;
            }
        }
    } elsif($mode eq "change") {
        my $name = $cgi->param("operating_system") || "";
        my $newname = $cgi->param("newoperating_system") || "";
        my $domain = $cgi->param("default_domain") || "";
        my $servicepack = $cgi->param("default_servicepack") || "0";
        
        if($name ne "") {
            my $sth = $dbh->prepare_cached("UPDATE computers_os
                                           SET operating_system = ?,
                                           default_domain = ?,
                                           default_servicepack = ?
                                           WHERE operating_system = ?")
                        or croak($dbh->errstr);
            if($sth->execute($newname, $domain, $servicepack, $name)) {
                $sth->finish;
                $dbh->commit;
                $webdata{statustext} = "OS updated";
                $webdata{statuscolor} = "oktext";
            } else {
                $webdata{statustext} = "Sorry, didn't work";
                $webdata{statuscolor} = "errortext";
                $dbh->rollback;
            }
        }
    } elsif($mode eq "delete") {
        my $name = $cgi->param("operating_system") || "";
        if($name ne "") {
            my $sth = $dbh->prepare_cached("DELETE FROM computers_os
                                           WHERE operating_system = ?")
                        or croak($dbh->errstr);
            if($sth->execute($name)) {
                $sth->finish;
                $dbh->commit;
                $webdata{statustext} = "Cost unit deleted";
                $webdata{statuscolor} = "oktext";
            } else {
                $webdata{statustext} = "Sorry, didn't work";
                $webdata{statuscolor} = "errortext";
                $dbh->rollback;
            }
        }
    }
    
    my $stmt = "SELECT * " .
                "FROM computers_os " .
                "ORDER BY operating_system, default_servicepack";

    my @oss;
    my $sth = $dbh->prepare_cached($stmt) or croak($dbh->errstr);
                
    $sth->execute or croak($dbh->errstr);
    while((my $os = $sth->fetchrow_hashref)) {
        push @oss, $os;
    }
    $sth->finish;

    $webdata{oss} = \@oss;
    
    my $template = $self->{server}->{modules}->{templates}->get("computerdb/globaloperatingsystem", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}


1;
__END__

=head1 NAME

Maplat::Web::ComputerDB::GlobalOperatingSystem - manage a list of operating systems

=head1 SYNOPSIS

  use Maplat::Web;
  use Maplat::Web::ComputerDB;
  
Then configure() the module as you would normally.

=head1 DESCRIPTION

    <module>
        <modname>globaloperatingsystem</modname>
        <pm>ComputerDB::GlobalOperatingSystem</pm>
        <options>
            <pagetitle>GlobalOperatingSystem</pagetitle>
            <webpath>/computers/os</webpath>
            <db>maindb</db>
            <memcache>memcache</memcache>
        </options>
    </module>

This module provides the webmasks required to edit and list operating systems in the database.

=head2 get

Internal function, renders OS mask.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
