# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz

package Maplat::Web::ComputerDB::GlobalCostunits;
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

    my %webdata = 
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{pagetitle},
        webpath    =>  $self->{webpath},
    );


    my $mode = $cgi->param("mode") || "view";
    if($mode eq "create") {
        my $name = $cgi->param("costunit") || "";
        my $description = $cgi->param("description") || "";
        
        if($name ne "") {
            my $sth = $dbh->prepare_cached("INSERT INTO global_costunits (costunit, description)
                                           VALUES (?, ?)")
                        or croak($dbh->errstr);
            my $ok = 1;
            
            if(!$sth->execute($name, $description)) {
                $ok = 0;
            }
            
            if($ok) {
                $sth->finish;
                $dbh->commit;
                $webdata{statustext} = "Cost unit created";
                $webdata{statuscolor} = "oktext";
            } else {
                $webdata{statustext} = "Sorry, didn't work";
                $webdata{statuscolor} = "errortext";
                $dbh->rollback;
            }
        }
    } elsif($mode eq "change") {
        my $name = $cgi->param("costunit") || "";
        my $newname = $cgi->param("newcostunit") || "";
        my $description = $cgi->param("description") || "";
        if($name ne "") {
            my $sth = $dbh->prepare_cached("UPDATE global_costunits
                                           SET costunit = ?,
                                           description = ?
                                           WHERE costunit = ?")
                        or croak($dbh->errstr);
            if($sth->execute($newname, $description, $name)) {
                $sth->finish;
                $dbh->commit;
                $webdata{statustext} = "Cost unit updated";
                $webdata{statuscolor} = "oktext";
            } else {
                $webdata{statustext} = "Sorry, didn't work";
                $webdata{statuscolor} = "errortext";
                $dbh->rollback;
            }
        }
    } elsif($mode eq "delete") {
        my $name = $cgi->param("costunit") || "";
        if($name ne "") {
            my $sth = $dbh->prepare_cached("DELETE FROM global_costunits
                                           WHERE costunit = ?")
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
                "FROM global_costunits " .
                "ORDER BY costunit";

    my @units;
    my $sth = $dbh->prepare_cached($stmt) or croak($dbh->errstr);
                
    $sth->execute or croak($dbh->errstr);
    while((my $unit = $sth->fetchrow_hashref)) {
        push @units, $unit;
    }
    $sth->finish;

    $webdata{costunits} = \@units;
    
    my $template = $self->{server}->{modules}->{templates}->get("computerdb/globalcostunits", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}


1;
__END__

=head1 NAME

Maplat::Web::ComputerDB::GlobalCostunits - manage a list of cost units

=head1 SYNOPSIS

  use Maplat::Web;
  use Maplat::Web::ComputerDB;
  
Then configure() the module as you would normally.

=head1 DESCRIPTION

    <module>
        <modname>globalcostunits</modname>
        <pm>ComputerDB::GlobalCostunits</pm>
        <options>
            <pagetitle>GlobalCostunits</pagetitle>
            <webpath>/computers/costunits</webpath>
            <db>maindb</db>
            <memcache>memcache</memcache>
        </options>
    </module>

This module provides the webmasks required to edit and list cost units in the database.

=head2 get

Internal function, renders cost units mask.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
