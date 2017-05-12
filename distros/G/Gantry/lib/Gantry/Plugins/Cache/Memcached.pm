package Gantry::Plugins::Cache::Memcached;

use strict;
use warnings;

use Cache::Memcached;
use Gantry::Plugins::Cache;

use base 'Exporter';

our @EXPORT = qw( 
    cache_del
    cache_get
    cache_set
    cache_clear
    cache_keys
    cache_init
    cache_purge
    cache_handle
    cache_inited
    cache_expires
    cache_namespace
);

sub cache_init {
    my ($gobj) = @_;

    my $cache;
    my $rehash = $gobj->fish_config('cache_rehash') || 'no';
    my $expire_time = $gobj->fish_config('cache_expires') || '3600';
    my $servers = $gobj->fish_config('cache_servers') || '127.0.0.1:11211';
    my $compress = $gobj->fish_config('cache_compress_threshold') || '1000';
    my $test_sets = $gobj->fish_config('cache_test_sets') || 0;

    eval {
        $cache = Cache::Memcached->new({servers => [$servers]});
        $cache->set_compress_threshold($compress);
        $cache->enable_compress(1);
        $cache->set_norehash() if ($rehash =~ /no/i);

        # If requested, test cache sets to see if they are successful.
        if ($test_sets) {
            # Set test.
            $cache->set('test-ns:test-var', 1, 120);

            # Get test.
            my $data = $cache->get('test-ns:test-var');

            # Die if set failed.
            unless ($data) {
                die "Test cache set failed. Please check cache configuration parameters.\n";
            }
        }
    };

    if ($@) {
        die("Unable to use - Gantry::Cache::Memcached; $@");
    }

    $gobj->cache_handle($cache);
    $gobj->cache_expires($expire_time);
    $gobj->cache_inited(1);

}

sub cache_inited {
    my ($gobj, $p) = @_;

    $$gobj{__CACHE_INITED__} = $p if defined $p;
    return($$gobj{__CACHE_INITED__});

}

sub cache_handle {
    my ($gobj, $p) = @_;

    $$gobj{__CACHE_HANDLE__} = $p if defined $p;
    return($$gobj{__CACHE_HANDLE__});

}

sub cache_namespace {
    my ($gobj, $p) = @_;

    $$gobj{__CACHE_NAMESPACE__} = $p if defined $p;
    return($$gobj{__CACHE_NAMESPACE__});

}

sub cache_expires {
    my ($gobj, $p) = @_;

    $$gobj{__CACHE_EXPIRES__} = $p if defined $p;
    return($$gobj{__CACHE_EXPIRES__});

}

sub cache_get {
    my ($gobj, $key) = @_;

    my $handle = $gobj->cache_handle();
    my $namespace = $gobj->cache_namespace();
    my $skey = $namespace . ':' . $key;

    return $handle->get($skey);

}

sub cache_set {
    my ($gobj, $key, $val, $expires) = @_;

    # Use global expires if the $expires parameter was not passed in.
    $expires ||= $gobj->cache_expires();

    my $handle = $gobj->cache_handle();
    my $namespace = $gobj->cache_namespace();
    my $skey = $namespace . ':' . $key;

    $handle->set($skey, $val, $expires);

}

sub cache_clear {
    my ($gobj) = @_;
    
    $gobj->cache_handle->flush_all;
}

sub cache_keys {
    # currently there is now way to retrieve the cache keys
}

sub cache_del {
    my ($gobj, $key) = @_;

    my $handle = $gobj->cache_handle();
    my $namespace = $gobj->cache_namespace();
    my $skey = $namespace . ':' . $key;

    $handle->remove($skey);
    
}

sub cache_purge {
    my ($gobj) = @_;
    
    my $handle = $gobj->cache_handle();

    return;

}

1;
    
__END__

=head1 NAME

Gantry::Plugins::Cache::Memcached - A Plugin interface to a caching subsystem

=head1 SYNOPSIS

It is sometimes desirable to cache data between page acceses. This 
module gives access to the Cache::Memcached module to store that data.

  <Perl>
    # ...
    use MyApp qw{ -Engine=CGI -TemplateEngine=TT Cache::Memcached };
  </Perl>

=head1 DESCRIPTION

This plugin mixes in methods to store data within a cache. This data
is then available for later retrival. Data is stored within the cache 
by key/value pairs. There are no restrictions on what information can be 
stored. This cache is designed for short term data storage. Cached 
data items will be timed out and purged at regular intervals. The caching 
system also has the concept of namespace. Namespaces are being used to make 
key's unique. So you may store multiple unique data items within
the cache.

=head1 CONFIGURATION

The following items can be set by configuration:

 cache_rehash              wither to attempt a failover to another server
 cache_expires             the expiration of items within the cache
 cache_servers             which cache servers to use
 cache_compress_threshold  the threshold to start compression

The following reasonable defaults are being used for those items:

 cache_rehash              no
 cache_expires             3600 seconds
 cache_servers             127.0.0.1:11212
 cache_compress_threshold  1000 bytes

Since this cache is being managed by Cache::Memcached, any changes to those
defaults should be consistent with that modules usage. 

=head1 METHODS

=over 4

=item cache_init

This method will initialize the cache. It should be called only once within 
the application.

 $self->cache_init();

=item cache_inited

For internal use.

Dual use accessor for init flag.  If cache_init has run this attribute
is 1, otherwise it's 0.

=item cache_namespace

This method will get/set the current namespace for cache operations.

 $self->cache_namespace($namespace);

=item cache_handle

This method returns the handle for the underlining cache. You can use
this handle to manipulate the cache directly. Doing so will be highly
specific to the underling cache handler.

 $handle = $self->cache_handle();

=item cache_purge

Equivalent to

 $self->cache_handle();

This method is for other cache plugins which support a purge method.

=item cache_get

This method returns the data associated with the current namespace/key 
combination.

 $self->cache_namespace($namespace);
 $data = $self->cache_get($key);

=item cache_set

This method stores the data associated with the current namespace/key
combination.

 $self->cache_namespace($namespace);
 $self->cache_set($key, $data);

=item cache_keys

This method is currently not available with memcached.

=item cache_clear

This method will clear the entire cache.

 $self->cache_clear();
     
=item cache_del

This method removes the data associated with the current namespace/key 
combination.

 $self->cache_namespace($namespace);
 $self->cache_del($key);

=item cache_expires

Retrieves the current expiration time for data items with thecache. The 
expiration time can be changed for this module. It is adviseable to not do 
so. Expiration time formats are highly specific to the underlining cache
handler.

 $expiration = $self->cache_expires();

=back

=head1 SEE ALSO

    Gantry

=head1 AUTHORS

Kevin L. Esteb <kesteb@wsipc.org>,
Tim Keefer <tim@timkeefer.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 Kevin L. Esteb

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

