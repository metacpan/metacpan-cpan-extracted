# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::SessionSettings;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::DBSerialize;
use Time::HiRes qw(time);
use Carp;
use Readonly;

Readonly::Scalar my $RETRY_COUNT  => 10;
Readonly::Scalar my $RETRY_WAIT   => 0.05;

our $VERSION = 0.995;


sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

    $self->{lastClean} = time;

    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we only use the template and database module
    return;
}

sub register {
    my $self = shift;
    $self->register_loginitem("on_login");
    $self->register_logoutitem("on_logout");
    $self->register_sessionrefresh("on_refresh");
    return;
}

# NOTE: We have TWO sets of data for each session:
# The first data set is the used keys within a session (a hash),
# the second set of data are the actual entries.
# We don't actually have to manage something like "last access"
# right now, we depend on beeing onLogout() called by the
# login module for timed-out sessions

sub get {
    my ($self, $settingname) = @_;
    
    my $settingref;
        
    my $loginh = $self->{server}->{modules}->{$self->{login}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};

    my $sessionid = $loginh->get_sessionid;
    return 0 if(!defined($sessionid));
    
    my $keyname = "SessionSettings::" . $sessionid . "::" . $settingname;
    
    $settingref = $memh->get($keyname);
    if(defined($settingref)) {
        return (1, Maplat::Helpers::DBSerialize::dbthaw($settingref));
    }

    # Ok, try DB
    my $sth = $dbh->prepare_cached("SELECT yamldata FROM session_settings WHERE sid = ? AND skey = ?")
          or croak($dbh->errstr);
    $sth->execute($sessionid, $settingname) or croak($dbh->errstr);
    while((my @line = $sth->fetchrow_array)) {
       $settingref = $line[0];
       last;
    }
    $sth->finish;
    $dbh->rollback;
 
    # Ok, now also store data in memcached
    if(defined($settingref)) {
       $memh->set($keyname, $settingref);
        return (1, Maplat::Helpers::DBSerialize::dbthaw($settingref));
    }
    
    return 0;
}

sub set { ## no critic (NamingConventions::ProhibitAmbiguousNames)
    my ($self, $settingname, $settingref) = @_;
    
    my $loginh = $self->{server}->{modules}->{$self->{login}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};

    my $sessionid = $loginh->get_sessionid;
    return 0 if(!defined($sessionid));
    
    my $keyname = "SessionSettings::" . $sessionid . "::" . $settingname;
    
    my $yamldata = Maplat::Helpers::DBSerialize::dbfreeze($settingref);
    my $olddata = $memh->get($keyname);
    if(defined($olddata) && $olddata eq $yamldata) {
        return 1;
    }
    
    $memh->set($keyname, $yamldata);

    my $sth = $dbh->prepare_cached("SELECT merge_sessionsettings(?, ?, ?)")
            or return;
            
    my $count = 0;
    my $ok = 0;
    while($count < $RETRY_COUNT) {
        # print STDERR "SESSION: ($count) Merge $sessionid / $settingname\n";
        if(!$sth->execute($sessionid, $settingname, $yamldata)) {
            $sth->finish;
            $dbh->rollback;
            $count++;
            if($count < $RETRY_COUNT) {
                sleep($RETRY_WAIT); # sleep for a short time and try again
            }
         } else {
            $sth->finish;
            $dbh->commit;
            $ok = 1;
            last;
         }
    }
    if(!$ok) {
        croak($dbh->errstr);
    }
    
    return 1;
}

sub delete {## no critic(BuiltinHomonyms)
    my ($self, $settingname, $forcedid) = @_;
    
    my $settingref;

    my $loginh = $self->{server}->{modules}->{$self->{login}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};

    my $sessionid = $loginh->get_sessionid;
    if(defined($forcedid)) {
        $sessionid = $forcedid;
    }
    return 0 if(!defined($sessionid));

    my $keyname = "SessionSettings::" . $sessionid . "::" . $settingname;
    

    $memh->delete($keyname);

    my $sth = $dbh->prepare_cached("DELETE FROM session_settings WHERE sid = ? AND skey = ?")
         or croak($dbh->errstr);
         
    my $count = 0;
    my $ok = 0;
    while($count < $RETRY_COUNT) {
        # print STDERR "SESSION: Delete ($count) $sessionid / $settingname\n";
        if(!$sth->execute($sessionid, $settingname)) {
            $sth->finish;
            $dbh->rollback;
            $count++;
            if($count < $RETRY_COUNT) {
                sleep($RETRY_WAIT);
            }
        } else {
            $sth->finish;
            $dbh->commit;
            $ok = 1;
            last;
        }
    }
    
    if(!$ok) {
        croak($dbh->errstr);
    }
    
    return 1;
}

sub list {
    my ($self, $forcedid) = @_;
    
    my @settingnames = ();
    
    my $loginh = $self->{server}->{modules}->{$self->{login}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};

    my $sessionid = $loginh->get_sessionid;

    if(defined($forcedid)) {
        $sessionid = $forcedid;
    }

    return 0 if(!defined($sessionid));

    my $sth = $dbh->prepare_cached("SELECT skey FROM session_settings WHERE sid = ?")
        or croak($dbh->errstr);
    $sth->execute($sessionid) or croak($dbh->errstr);
    while((my @line = $sth->fetchrow_array)) {
        push @settingnames, $line[0];
    }
    $sth->finish;
    $dbh->rollback;

    return (1, @settingnames);
}

sub on_login {
    my ($self, $username, $sessionid) = @_;
    
    $self->set('lastUpdate', time);
    $self->set('userName', $username);
    
    return;
}

sub on_logout {
    my ($self, $sessionid) = @_;
    
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    
    my ($status, @keys) = $self->list($sessionid);
    if($status != 0) {
        foreach my $key (@keys) {
            $self->delete($key, $sessionid);
        }
    }
    return;
}

sub on_refresh {
    my ($self, $sessionid) = @_;

    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    
    my $curTime = time;
    my ($oldOk, $oldTime) = $self->get('lastUpdate');
    if(!$oldOk || ($curTime - $oldTime) > 60) {
        $self->set('lastUpdate', $curTime);
    }

    
    # Clean up stale sessions - this is only needed if the user
    # closes his/her browser without logging out first. As long as the browser
    # is open, an automatic refresh (javascript) keeps the session "fresh"
    # Only run this once an hour, automatic logout is handled by the Login module
    # by way of expiring cookies/session information. We need this just in case the
    # Login module CAN'T handle the logout because the browser was forced closed.
    #
    # We only do the cleanup every 5 minutes or so
    my $now = time;
    
    return if(($now - $self->{lastClean}) < 300);
    $self->{lastClean} = $now;

    my $liststh = $dbh->prepare("SELECT sid, yamldata
                                FROM session_settings
                                WHERE skey = 'lastUpdate'")
        or croak($dbh->errstr);
    $liststh->execute or croak($dbh->errstr);

    my @stalesessions;
    my $currTime = time;
    while((my @line = $liststh->fetchrow_array)) {
        my $soldTime = Maplat::Helpers::DBSerialize::dbthaw($line[1]);
        my $age = ($currTime - $$soldTime) / 3600;
        if($age > 2) {
            push @stalesessions, $line[0];
        }
    }
    $liststh->finish;
    $dbh->rollback;

    foreach my $session (@stalesessions) {
        # "Manually" logout users
        $self->on_logout($session);
    }

    return;
}

1;
__END__

=head1 NAME

Maplat::Web::SessionSettings - save and load session/module specific data

=head1 SYNOPSIS

This module provides handling module-specific data handling on a per session basis

=head1 DESCRIPTION

This module provides a simple interface to memcached for saving and loading module
specific data on a per session basis. It can, for example, be used to save session specific filters
to memcache. It can handle complex data structures.

Data is not permanently stored, but rather it's deleted when a user logs out or the session times out (auto
user logout). Data is backed up by a DB with its own caching stragety.

=head1 Configuration

        <module>
                <modname>sessionsettings</modname>
                <pm>SessionSettings</pm>
                <options>
                        <memcache>memcache</memcache>
                        <db>maindb</db>
                        <login>authentification</login>
                </options>
        </module>

=head1 WARNING

This module implements its own memcached-based caching strategy. Use Maplat::Web::MemCache as the memcache module,
don't use Maplat::Web::MemCachePg. While both will work and data will be stored permanently, using MemCachePg will
generate some overhead, because the data will be saved redundatly in two places.

=head2 set

This function adds or updates a setting (data structure) in memcache.

It takes two arguments, $settingname is the key name of the setting, and
$settingref is a reference to the data structure you want to store, e.g.:

  $is_ok = $us->set($settingname, $settingref);

It returns a boolean to indicate success or failure.

=head2 get

This function reads a setting from memcached and returns a reference to the data structure.

It takes one arguments, $settingname is the key name of the setting.

  $settingref = $us->get($settingname);

=head2 delete

This function deletes a setting from database and returns a boolean to indicate success or failure.

It takes one arguments, $settingname is the key name of the setting.

  $is_ok = $us->delete($settingname);

=head2 list

This function lists all available settings for a session.

  @settingnames = $us->list();

=head2 on_login

Internal function.

=head2 on_logout

Internal function.

=head2 on_refresh

Internal function.

=head1 Dependencies

This module depends on the following modules beeing configured (the 'as "somename"'
means the key name in this modules configuration):

Maplat::Web::Memcache as "memcache"
Maplat::Web::Login as "login"

=head1 SEE ALSO

Maplat::Web
Maplat::Web::Memcache
Maplat::Web::Login

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
