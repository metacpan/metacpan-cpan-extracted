
package Lemonldap::NG::Common::Apache::Session::Store;

use strict;

our $VERSION = '2.0.15';

sub new {
    my $class = shift;
    return bless {}, $class;
}

sub insert {
    my $self    = shift;
    my $session = shift;
    $self->{args} = $session->{args};

    # Store session in cache
    my $id = $session->{data}->{_session_id};
    $self->cache->set( $id, $session->{serialized} );

    # Store in session backend
    return $self->module->insert($session);
}

sub update {
    my $self    = shift;
    my $session = shift;
    $self->{args} = $session->{args};

    #TODO: remove cache on all LL::NG instances if updateCache == 1

    unless ( defined( $session->{args}->{updateCache} )
        and $session->{args}->{updateCache} == -1 )
    {

        # Update session in cache
        my $id = $session->{data}->{_session_id};
        $self->cache->remove($id) if ( $self->cache->get($id) );
        $self->cache->set( $id, $session->{serialized} );
    }

    unless ( defined( $session->{args}->{updateCache} )
        and $session->{args}->{updateCache} == 2 )
    {

        # Update session in backend
        return $self->module->update($session);
    }
}

sub materialize {
    my $self    = shift;
    my $session = shift;
    $self->{args} = $session->{args};

    # Get session from cache
    my $id = $session->{data}->{_session_id};
    if ( !$self->{args}->{noCache} and $self->cache->get($id) ) {
        $session->{serialized} = $self->cache->get($id);
        return;
    }

    # Get session from backend
    $self->module->materialize($session);

    # Store session in cache
    $self->cache->set( $id, $session->{serialized} );

    return;
}

sub remove {
    my $self    = shift;
    my $session = shift;
    $self->{args} = $session->{args};

    #TODO: remove cache on all LL::NG instances if updateCache == 1

    unless ($session->{args}->{updateCache}
        and $session->{args}->{updateCache} == -1 )
    {

        # Remove session from cache
        my $id = $session->{data}->{_session_id};
        $self->cache->remove($id) if ( $self->cache->get($id) );
    }

    unless ($session->{args}->{updateCache}
        and $session->{args}->{updateCache} == 2 )
    {

        # Remove session from backend
        return $self->module->remove($session);
    }
}

sub close {
    my $self    = shift;
    my $session = shift;
    $self->{args} = $session->{args};

    return $self->module->close;
}

sub module {
    my $self = shift;
    return $self->{args}->{object_store};
}

sub cache {
    my $self = shift;

    return $self->{cache} if $self->{cache};

    my $module = $self->{args}->{localStorage};
    eval "use $module;";
    $self->{cache} = $module->new( $self->{args}->{localStorageOptions} );

    return $self->{cache};
}

1;
