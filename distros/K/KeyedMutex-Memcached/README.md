# NAME

KeyedMutex::Memcached - An interprocess keyed mutex using memcached

# SYNOPSIS

    use KeyedMutex::Memcached;

    my $key   = 'query:XXXXXX';
    my $cache = Cache::Memcached::Fast->new( ... );
    my $mutex = KeyedMutex::Memcached->new( cache => $cache );

    until ( my $value = $cache->get($key) ) {
      {
        if ( my $lock = $mutex->lock( $key, 1 ) ) {
          #locked read from DB
          $value = get_from_db($key);
          $cache->set($key, $value);
          last;
        }
      };
    }

# DESCRIPTION

KeyedMutex::Memcached is an interprocess keyed mutex using memcached.
This module is inspired by [KeyedMutex](https://metacpan.org/pod/KeyedMutex).

# METHODS

## new( %args )

Following parameters are recognized.

- cache

    **Required**. [Cache::Memcached::Fast](https://metacpan.org/pod/Cache::Memcached::Fast) object or similar interface object.

- interval

    Optional. The seconds for busy loop interval. Defaults to 0.01 seconds.

- trial

    Optional. When the value is being set zero, lock() method will be waiting until lock becomes released.
    When the value is being set positive integer value, lock() method will be stopped on reached trial count.
    Defaults to 0.

- timeout

    Optional. The seconds until lock becomes released. Defaults to 30 seconds.

- prefix

    Optional. Prefix of key to store memcached. The real key is prefix + ':' + key. Defaults to `'km'`.

## lock($key, \[ $use\_raii \])

Get lock by each key. When getting lock successfully, returns 1, on failed returns 0.
If use\_raii is being set true, return [Scope::Guard](https://metacpan.org/pod/Scope::Guard) object as RAII.

## locked

Which is the object has locked.

## release

Release lock.

# AUTHOR

Toru Yamaguchi <zigorou@cpan.org>

# SEE ALSO

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
