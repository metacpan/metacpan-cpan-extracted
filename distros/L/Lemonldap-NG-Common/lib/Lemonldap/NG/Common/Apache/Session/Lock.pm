
package Lemonldap::NG::Common::Apache::Session::Lock;

use strict;

our $VERSION = '2.0.0';

sub new {
    my $class   = shift;
    my $session = shift;

    my $self = {};
    $self->{args} = $session->{args};
    bless $self, $class;
    return $self;
}

sub module {
    my $self = shift;
    return $self->{args}->{lock_manager};
}

sub cache {
    my $self = shift;

    return $self->{cache} if $self->{cache};

    my $module = $self->{args}->{localStorage};
    eval "use $module;";
    $self->{cache} = $module->new( $self->{args}->{localStorageOptions} );

    return $self->{cache};
}

sub acquire_read_lock {
    my $self    = shift;
    my $session = shift;

    # Get session from cache
    my $id = $session->{data}->{_session_id};
    if ( $self->cache->get($id) ) {

        # got session from cache, no need to ask for locks
    }
    else {
        $self->module->acquire_read_lock($session);
    }
}

sub acquire_write_lock {
    my $self    = shift;
    my $session = shift;

    $self->module->acquire_write_lock($session);
}

sub release_write_lock {
    my $self    = shift;
    my $session = shift;

    $self->module->release_write_lock($session);
}

sub release_all_locks {
    my $self    = shift;
    my $session = shift;

    $self->module->release_all_locks($session);
}

1;

