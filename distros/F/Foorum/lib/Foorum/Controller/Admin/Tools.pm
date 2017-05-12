package Foorum::Controller::Admin::Tools;

use strict;
use warnings;
our $VERSION = '1.001000';
use parent 'Catalyst::Controller';
use Data::Dumper;

sub auto : Private {
    my ( $self, $c ) = @_;

    # only administrator is allowed. site moderator is not allowed here
    unless ( $c->model('Policy')->is_admin( $c, 'site' ) ) {
        $c->forward( '/print_error', ['ERROR_PERMISSION_DENIED'] );
        return 0;
    }
    return 1;
}

sub flush_cache : Local {
    my ( $self, $c ) = @_;

    my $cache = $c->default_cache_backend;    # get backend

    my $result = 'Not available';
    if ( $cache->can('flush_all') ) {         # for Cache::Memcached
        $result = $cache->flush_all;
    } elsif ( $cache->can('Clear') )
    {    # for Cache::Cache, regardless namespace
        $result = $cache->Clear();
    } elsif ( $cache->can('clear') ) {    # for Cache::Cache, this namespace
        $result = $cache->clear();
    }

    $c->stash(
        {   template => 'admin/index.html',
            message  => Dumper( \$result ),
        }
    );
}

sub cache_stat : Local {
    my ( $self, $c ) = @_;

    my $cache = $c->default_cache_backend;    # get backend

    my $result = 'Not available';
    if ( $cache->can('stats') ) {             # for Cache::Memcached
        $result = $cache->stats;
    }

    $c->stash(
        {   template => 'admin/index.html',
            message  => Dumper( \$result ),
        }
    );
}

1;
__END__

=pod

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
