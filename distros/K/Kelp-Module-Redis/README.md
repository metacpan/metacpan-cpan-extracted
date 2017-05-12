# NAME

Kelp::Module::Redis - Use Redis within Kelp

# SYNOPSIS

First ...

```perl
# conf/config.pl
{
    modules      => ['Redis'],
    modules_init => {
        Redis => {
            server => 'redis.example.com:8080',  # example
            name   => 'my_connection_name'       # example
        }
    }
}
```

Then ...

```perl
package MyApp;
use Kelp::Base 'Kelp';

sub some_route {
    my $self = shift;
    $self->redis->set( key => 'value' );
}
```

# REGISTERED METHODS

This module registers only one method into the application: `redis`.
It is an instance of a [Redis](http://search.cpan.org/perldoc?Redis) class.

## AUTHOR

Stefan Geneshky minimal@cpan.org

## LICENCE

Perl
