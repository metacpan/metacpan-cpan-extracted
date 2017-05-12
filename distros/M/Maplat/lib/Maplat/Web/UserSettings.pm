# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::UserSettings;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::DBSerialize;

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
    #nothing to register
    return;
}

sub get {
    my ($self, $username, $settingname) = @_;
    
    if(!defined($username) || !defined($settingname)) {
        return 0;
    }
    
    my $settingref;
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $memhname = "UserSettings::" . $username . "::" . $settingname;
    
    $settingref = $memh->get($memhname);
    if(defined($settingref)) {
        return (1, $settingref);
    }
    
    my $sth = $dbh->prepare_cached("SELECT yamldata FROM users_settings " .
                            "WHERE username = ? AND name = ?")
                    or return 0;
    
    if(!$sth->execute($username, $settingname)) {
        return 0;
    }
    
    if((my @row = $sth->fetchrow_array)) {
        $settingref = Maplat::Helpers::DBSerialize::dbthaw($row[0]);
        $memh->set($memhname, $settingref);
    }
    $sth->finish;
    
    if(defined($settingref)) {
        return (1, $settingref);
    } else {
        return 0;
    }
}

sub set { ## no critic (NamingConventions::ProhibitAmbiguousNames)
    my ($self, $username, $settingname, $settingref) = @_;
    
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $memhname = "UserSettings::" . $username . "::" . $settingname;
    
    my $sth = $dbh->prepare_cached("SELECT merge_users_settings(?, ?, ?)")
            or return;
    if(!$sth->execute($username, $settingname, Maplat::Helpers::DBSerialize::dbfreeze($settingref))) {
        return;
    }
    $sth->finish;
    $memh->set($memhname, $settingref);
    
    return 1;
}

sub delete {## no critic(BuiltinHomonyms)
    my ($self, $username, $settingname) = @_;
    
    my $settingref;
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $memhname = "UserSettings::" . $username . "::" . $settingname;

    $memh->delete($memhname);
    
    my $sth = $dbh->prepare_cached("DELETE FROM users_settings " .
                            "WHERE username = ? AND name = ?")
            or return;
    if(!$sth->execute($username, $settingname)) {
        return;
    }
    
    $sth->finish;
    
    return 1;
}

sub list {
    my ($self, $username) = @_;
    
    my @settingnames;
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    
    my $sth = $dbh->prepare_cached("SELECT name FROM users_settings " .
                            "WHERE username = ? " .
                            "ORDER BY name")
                or return 0;
    if(!$sth->execute($username)) {
        return 0;
    }
    while((my @row = $sth->fetchrow_array)) {
        push @settingnames, $row[0]; 
    }
    $sth->finish;
    
    return (1, @settingnames);
}

1;
__END__

=head1 NAME

Maplat::Web::UserSettings - save and load user/module specific data

=head1 SYNOPSIS

This module provides handling module-specific data handling on a per user basis

=head1 DESCRIPTION

This module provides a simple interface to the PostgreSQL database for saving and loading module
specific data on a per user basis. It can, for example, be used to save user specific filters
to the database. It can handle complex data structures.

In the background, it uses Storable and Base64 to store complex data structures and text in a database
text field. This avoids having to play around with blobs.

=head1 Configuration

        <module>
                <modname>usersettings</modname>
                <pm>UserSettings</pm>
                <options>
                       <db>maindb</db>
                       <memcache>memcache</memcache>
                </options>
        </module>

=head1 WARNING

This module implements its own memcached-based caching strategy. Use Maplat::Web::MemCache as the memcache module,
don't use Maplat::Web::MemCachePg. While both will work and data will be stored permanently, using MemCachePg will
generate some overhead, because the data will be saved redundatly in two places.

=head2 set

This function adds or updates a setting (data structure) in the database.

It takes three arguments, $username is the username, $settingname is the key name of the setting, and
$settingref is a reference to the data structure you want to store, e.g.:

  $is_ok = $us->set($username, $settingname, $settingref);

It returns a boolean to indicate success or failure.

=head2 get

This function reads a setting from database and returns a reference to the data structure.

It takes two arguments, $username is the username and $settingname is the key name of the setting.

  $settingref = $us->get($username, $settingname);

=head2 delete

This function deletes a setting from database and returns a boolean to indicate success or failure.

It takes two arguments, $username is the username and $settingname is the key name of the setting.

  $is_ok = $us->delete($username, $settingname);

=head2 list

This function lists all available settings for a username.

It takes one arguments, $username is the username.

  @settingnames = $us->list($username);

=head1 Dependencies

This module is a basic web module and does not depend on other web modules.

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
