# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::MemCacheSim;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::BuildNum;

our $VERSION = 0.995;

use Maplat::Helpers::Cache::Memcached;
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

    my %memd = ();
    $self->{memd} = \%memd;

    return $self;
}

sub reload {
    my ($self) = shift;
    return;
}

sub register {
    my $self = shift;
    $self->register_task("refresh_lifetick");
    return;
}

sub refresh_lifetick {
    my ($self) = @_;
    
    my $ticktime = time;
    
    if(($ticktime - $self->{oldtime}) > 10) {
        # only refresh every 10 seconds or so to keep
        # resource usage low - otherwise we'd be setting
        # the lifetick 1000 times a second or so
        my $tickkey = "LIFETICK::" . $$;
        $self->set($tickkey, $ticktime);
        $self->{oldtime} = $ticktime;
        return 1;
    }
    return 0;
}

sub get {
    my ($self, $key) = @_;
    
    $key = $self->sanitize_key($key);
    
    if(defined($self->{memd}->{$key})) {
        return $self->{memd}->{$key};
    } else {
        return;
    }
}

sub set { ## no critic (NamingConventions::ProhibitAmbiguousNames)
    my ($self, $key, $data) = @_;

    $key = $self->sanitize_key($key);
    
    return $self->{memd}->{$key} =  $data;
}

sub delete {## no critic(BuiltinHomonyms)
    my ($self, $key) = @_;
    
    $key = $self->sanitize_key($key);
    
    delete $self->{memd}->{$key};
    return 1;
}

sub sanitize_key {
    my ($self, $key) = @_;
    
    # Certain chars are not allowed in keys for whatever reason.
    # This *should* be handled by the Cache::Memcached module, but isn't
    # We handle this by substituting them with a tripple underline
    
    $key =~ s/\ /___/go;
    
    return $key;
}

# Helpers for "active commands"
sub set_activecommand {
    my ($self, $commandid) = @_;
    
    $self->set($main::APPNAME . "::activecommand", $commandid);
    return;
}

sub get_activecommands {
    my ($self) = @_;
    
    my %commands;
    
    foreach my $cmd (@{$self->{viewcommands}->{view}}) {
        my $value = $self->get($cmd . "::activecommand");
        if(defined($value) && $value ne "0") {
            $commands{$value} = $cmd;
        }
    }
    
    return %commands;
}

1;
__END__

=head1 NAME

Maplat::Web::MemCacheSim - Simulated Maplat::Web::MemCache

=head1 SYNOPSIS

This is a simulation of Maplat::Web::MemCache for testing on systems without running memcached.

=head1 DESCRIPTION

This module provides a web module that gives the caller an interface to the (simulated) memcached service.

The API is compatible to Maplat::Web::Memcache but it does not share data between processes and forks. At
least not in the way you might expect.

Do not use in production systems - this module exists for the sole purpose of running some tests without
having to have a running memcached daemon.

=head1 Configuration

        <module>
                <modname>memcache</modname>
                <pm>MemCache</pm>
                <options>
                        <service>127.0.0.1:11211</service>
                        <namespace>RBSMem</namespace>
                        <viewcommands>
                                <view>Adm Worker</view>
                                <view>Other Worker</view>
                        </viewcommands>
                </options>
        </module>

service is IP address and port of the memcached service - which is ignored and exists only because
the *real* module also needs it.

namespace if a single name assigned to all programs of the same project. Different projects
accessing the same memcached server must use different namespaces, while all programs working
on a common project must use the same namespace. this is so, because next to caching, memcached
in the Maplat framework is also used for interprocess communication.

maxage is the maximum age in days the files are allowed to reside in the directory

Further, the main script must declare the variables $VERSION and $APPNAME, because some functionality
of the wrapper needs those. This values are set in memcached and can be read out by the WebGUI as a central
point of determing which versions and build of which program are running on the server. So, the variables

  $main::APPNAME
  $main::VERSION

must be accesible and hold reasonable values.

viewcommands is a list of workers that can work on the commandqueue table. This helps checking every worker
for active commands and highlighting them in various other modules

=head2 refresh_lifetick

Refreshed the lifetick variable for this application in memcached.

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

=head2 afterfork

Internal function to reconnect to the memcache daemon after forking.

=head2 sanitize_key

Internal function to sanitize (clean up and re-encode) the memcached key string. Memcached has some limitations
how the keys can be named, this functions is used on every access to memcached to make sure the keys adhere
to this restrictions.

=head1 Dependencies

This module is a basic module which does not depend on other web modules.

=head1 AKA

Also Known As "memcached for CPAN testers".

If you are using MemCacheSim on a production system, now would be a good time to panic.

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
