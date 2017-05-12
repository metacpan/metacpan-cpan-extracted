# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::MemCachePg;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::BuildNum;
use Maplat::Helpers::DBSerialize;
use Time::HiRes qw(sleep);
use Readonly;

our $VERSION = 0.995;

Readonly::Scalar my $RETRY_COUNT  => 10;
Readonly::Scalar my $RETRY_WAIT   => 0.05;

use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

    $self->{mctype} = "sim";
    
    # Add version information about our to the memcached storage
    # for the rare cases we need that for other programs to run
    # a compatibility API or something
    # APPNAME and VERSION in main needs to be declared "our ..."
    $self->set("VERSION::" . $main::APPNAME, $main::VERSION);
    $self->set("BUILD::" . $main::APPNAME, readBuildNum());

    $self->{oldtime} = 0;

    return $self;
}

sub reload {
    my ($self) = shift;
    return;
}

sub register {
    my $self = shift;

    # Nothing to be done
    return;
}

#sub refresh_lifetick {
#    my ($self) = @_;
#    
#    my $ticktime = time;
#    
#    if(($ticktime - $self->{oldtime}) > 10) {
#        # only refresh every 10 seconds or so to keep
#        # resource usage low - otherwise we'd be setting
#        # the lifetick 1000 times a second or so
#        my $tickkey = "LIFETICK::" . $$;
#        $self->set($tickkey, $ticktime);
#        $self->{oldtime} = $ticktime;
#        return 1;
#    }
#    return 0;
#}

sub get {
    my ($self, $key) = @_;
    
    $key = $self->sanitize_key($key);

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};

   # Try memcached first
    my $dataref = $memh->get($key);
    if(defined($dataref)) {
        return Maplat::Helpers::DBSerialize::dbthaw($dataref);
    }

   # Ok, try DB
   my $sth = $dbh->prepare_cached("SELECT yamldata FROM memcachedb WHERE mckey = ?")
         or croak($dbh->errstr);
   $sth->execute($key) or croak($dbh->errstr);
   while((my @line = $sth->fetchrow_array)) {
      $dataref = $line[0];
      last;
   }
   $sth->finish;
   $dbh->rollback;

   # Ok, now also store data in memcached
   if(defined($dataref)) {
      $memh->set($key, $dataref);
      return Maplat::Helpers::DBSerialize::dbthaw($dataref);
   }

   return;
}

sub set { ## no critic (NamingConventions::ProhibitAmbiguousNames)
    my ($self, $key, $data) = @_;

    $key = $self->sanitize_key($key);
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};

    my $yamldata = Maplat::Helpers::DBSerialize::dbfreeze($data);

    # Check if it already matches the key we have
    my $olddata = $memh->get($key);
    if(defined($olddata) && $olddata eq $yamldata) {
        return 1;
    }
 
    $memh->set($key, $yamldata);   
    
    # Always store as reference
#    if((ref $data) ne 'SCALAR') {
#        $memh->set($key, \$data);
#    } else {
#        $memh->set($key, $data);
#    }
   
    my $sth = $dbh->prepare_cached("SELECT merge_memcachedb(?, ?)")
            or return;
    my $count = 0;
    my $ok = 0;
    while($count < $RETRY_COUNT) {
        # print STDERR "WEB: Merge ($count) $key\n";
        if($sth->execute($key, $yamldata)) {
            $ok = 1;
            $sth->finish;
            $dbh->commit;
            last;
        } else {
            $count++;
            $sth->finish;
            $dbh->rollback;
            if($count < $RETRY_COUNT) {
                sleep($RETRY_WAIT); # try again in a short time
            }
        }
    }
    if(!$ok) {
        croak($dbh->errstr);
    }
    
    return 1;
}

sub delete {## no critic(BuiltinHomonyms)
    my ($self, $key) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};

   $memh->delete($key);
   
   my $sth = $dbh->prepare_cached("DELETE FROM memcachedb WHERE mckey = ?")
         or croak($dbh->errstr);
         
         
    my $count = 0;
    my $ok = 0;
    while($count < $RETRY_COUNT) {
        #print STDERR "WEB: Delete ($count) $key\n";
        if($sth->execute($key)) {
            $sth->finish;
            $dbh->commit;
            $ok = 1;
            last;
        } else {
            $sth->finish;
            $dbh->rollback;
            $count++;
            if($count < $RETRY_COUNT) {
                sleep($RETRY_WAIT); # try again in a short time
            }
        }
    }

    if(!$ok) {
        croak($dbh->errstr);
    }
    
    return 1;
}

sub sanitize_key {
    my ($self, $key) = @_;
    
   # Call the real memcache module for this, cause our db doesn't have the problem ;-)
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    return $memh->sanitize_key($key);
}

# Helpers for "active commands"
sub set_activecommand {
    my ($self, $commandid) = @_;
    
   # I dont see that as critical, this is only a convinience view without
   # any real problem in the production system if this fails or is plain wrong...
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
   return $memh->set_activecommand($commandid);
}

sub get_activecommands {
    my ($self) = @_;

   # I dont see that as critical, this is only a convinience view without
   # any real problem in the production system if this fails or is plain wrong...
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
   return $memh->get_activecommands();
}


sub refresh_lifetick {
    my ($self) = @_;

    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    return $memh->refresh_lifetick();
}

sub disable_lifetick {
    my ($self) = @_;

    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    return $memh->refresh_lifetick();
}

1;
__END__

=head1 NAME

Maplat::Web::MemCachePg - PostgreSQL-backed memcache module

=head1 SYNOPSIS

This is an API compatible implementation of Maplat::Web::MemCache. Internally, it uses that
module in combination with the PostgreSQL webmodule.

=head1 DESCRIPTION

You can use this module as a drop-in replacement of Maplat::Web::MemCache (that module still needs to be
configured, though, because we used it here to speed up data retrieval). In addition of using the real memcache
daemon, we also save the data to the configured database, e.g. implement a permanent storage engine on top of
memcached.

And, yes, i know that there is a general Berkeley DB backed memcached available. This means you need still another
database and it might not be available on all operating systems. If you choose to use the real db backed memcached,
just use Maplat::Web::MemCache. This one uses the configured PostgreSQL module to do its stuff, so it should work
everywhere where Maplat and PostgreSQL are available.

=head1 Configuration

        <module>
                <modname>memcachepg</modname>
                <pm>MemCachePg</pm>
                <options>
                  <memcache>memcache</memcache>
                  <db>maindb</db>
                </options>
        </module>

=head1 WARNING

If you want to store data permanent (even within a single program run), you should use Maplat::Web::MemCachePg,
which is using Maplat::Web::MemCache, but also uses the PostgreSQL module as a permanent backing store.

The memcache daemon itself is very fast, but is basically a cache; e.g. if more data comes in that it can hold,
the oldest data is silently discarded. Therefore, using a backing store for things like Login-data, shopping cart
contents and other things you want to permanently store, use a real backing store. You dont want to loose some
session information because more users logged on than memcached was set to handle.

A few Maplat::Web:: modules implement their own caching strategy, like the UserSettings module. For these, you should
*not* use Maplat::Web::MemCachePg but Maplat::Web::MemCache, otherwise you negate some of the performance due to
overhead (double store).

=head2 refresh_lifetick

Refresh the lifetick variable for this application in (real) memcached.

=head2 disable_lifetick

Disable the lifetick variable for this application in (real) memcached.

=head2 set

Save data in memcached.

Takes two arguments, a key name and a reference to the data to be stored in memcached. Returns a boolean
to indicate success or failure.

=head2 get

Read data from memcached. Takes one argument, the key name, returns a reference to the data from memcached
or undef.

=head2 delete

Delete a key from memcached. Takes one argument, the key name, returns a boolean indicating success or failure.

=head2 set_activecommand

Sets the command currently processed by this application (or 0 to indicate no active command). Takes one argument,
the id of the currently active command. Returns a boolean indicating success or failure.

=head2 get_activecommands

Returns a hash with all currently active commands in all (configured) workers, webguis and other apps.

=head2 sanitize_key

Internal function to sanitize (clean up and re-encode) the memcached key string. Memcached has some limitations
how the keys can be named, this functions is used on every access to memcached to make sure the keys adhere
to this restrictions.

=head1 Dependencies

This module depends on Maplat::Web::MemCache and Maplat::Web::PostgresDB

=head1 AKA

Also Known As "database backed storage engine for general data junk".

If you are using MemCache on a production system for data you *must* be able to retrieve again,
you really should be thinking of using THIS module instead of Maplat::Web::MemCache, unless you
implement your own permanent storage solution.

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
