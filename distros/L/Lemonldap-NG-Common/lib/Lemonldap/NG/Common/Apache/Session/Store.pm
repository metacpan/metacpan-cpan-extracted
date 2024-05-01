
package Lemonldap::NG::Common::Apache::Session::Store;

use strict;

our $VERSION = '2.19.0';

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
    $self->storeInCache( $id, $session->{serialized} );

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
        $self->removeFromCache($id) if ( $self->getFromCache($id) );
        $self->storeInCache( $id, $session->{serialized} );
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
    if ( !$self->{args}->{noCache} and $self->getFromCache($id) ) {
        $session->{serialized} = $self->getFromCache($id);
        eval { JSON::from_json( $session->{serialized} ); };
        if ($@) {
            print STDERR "Local data corrupted, ignore cached session\n";
            $session->{serialized} = undef;
        }
        else {
            return;
        }
    }

    # Get session from backend
    $self->module->materialize($session);

    # Store session in cache
    $self->storeInCache( $id, $session->{serialized} );

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
        $self->removeFromCache($id) if ( $self->getFromCache($id) );
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

sub storeInCache { _cache_call( 'set', @_ ); }

sub getFromCache { _cache_call( 'get', @_ ); }

sub removeFromCache { _cache_call( 'remove', @_ ); }

sub _cache_call {
    my ( $sub, $self, @args ) = @_;
    my $res = eval { $self->cache->$sub(@args); };
    print STDERR "Unable to use cache: $@\n" if $@;
    return $res;
}

1;
