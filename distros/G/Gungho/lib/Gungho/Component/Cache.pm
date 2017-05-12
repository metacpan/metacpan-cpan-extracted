# $Id: /mirror/gungho/lib/Gungho/Component/Cache.pm 31133 2007-11-27T01:57:33.833442Z lestrrat  $
#
# Copyright (c) 2007 Daisuke Maki <daisuke@endeworks.jp>
# All rights reserved.

package Gungho::Component::Cache;
use strict;
use warnings;
use base qw(Gungho::Component);

__PACKAGE__->mk_classdata( '_backends' => {} );
__PACKAGE__->mk_classdata( 'default_backend' );

sub setup
{
    my $c = shift;
    $c->next::method(@_);
    $c->setup_cache_backends();
}

sub setup_cache_backends
{
    my $c = shift;
    my $config = $c->config->{cache};

    if ($config->{default_backend}) {
        $c->default_backend($config->{default_backend});
    }

    my $backends = $c->_backends();
    while (my($name, $config) = each %{ $config->{backends} } ) {
        my $class = delete($config->{class}) || delete($config->{module});
        die "No class specified for cache backend" unless $class;
        my $pkg = $c->load_gungho_module( $class, __PACKAGE__);

        $backends->{$name} = $pkg->new(%$config);
    }
}

sub cache
{
    my ($c, $name) = @_;
    my $cache;

    if ($name) {
        $cache = $c->_backends->{$name} ;
        if (! $cache) {
            Carp::croak("No cache backend by name $name specified");
        }
    } else {
        if ($c->default_backend) {
            $cache = $c->_backends->{$c->default_backend};
        }
        if (! $cache) {
            Carp::croak("No default backend specified");
        }
    }
    return $cache;
}

1;

__END__

=head1 NAME 

Gungho::Component::Cache - Use Cache In Your App

=head1 SYNOPSIS

  components:
    - Cache
  cache:
    default_backend: small_things
    backends:
      large_things:
        module: '+Cache::Memcached::Managed',
        data: '127.0.0.1:11211'
      small_things:
        module: '+Cache::Memcached::Managed',
        data: '127.0.0.1:11212'

=head1 DESCRIPTION

This component allows you to setup cache(s) in your crawler application.

To use, simply specify the cache backends that you want to use via 
cache.backends, and then wherever in your app you can say:

  my $cache = $c->cache($name);

=head1 METHODS

=head2 setup

Setup the cache. 

=head2 setup_cache_backends

=head2 cache($name)

Returns the appropriate cache object from the specified backends.

If you omit $name, then the cache backend specified by the "default_backend"
configuration option.

If $name is omitted and no "default_backend" is specified, then this method
will croak.

=cut
