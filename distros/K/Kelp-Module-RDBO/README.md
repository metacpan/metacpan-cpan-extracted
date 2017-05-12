# NAME

Kelp::Module::RDBO - Kelp interface to Rose::DB::Object

# SYNOPSIS

```perl
# conf/config.pl
{
    modules      => [qw/RDBO/],
    modules_init => {
        RDBO => {
            prefix         => 'MyApp::DB',
            default_domain => 'development',
            default_type   => 'main',
            source         => [
                {
                    domain => 'development',
                    type   => 'main',
                    driver => 'mysql',
                    ...
                },
                {
                    domain => 'development',
                    type   => 'readonly',
                    driver => 'mysql',
                    ...
                }
            ],
        },

    }
}

# lib/MyApp.pm

...

sub get_song {
    my ( $self, $song_id ) = @_;
    $self->rdb->do_transaction( ... )
    my $song = $self->rdbo('Song')->new( id => $song_id  )->load;
}
```

# DESCRIPTION

This [Kelp](https://metacpan.org/pod/Kelp) module creates a [Rose::DB](https://metacpan.org/pod/Rose::DB) connection at application startup,
provides an interface to it, and uses it behind the scenes to pass it to all
[Rose::DB::Object](https://metacpan.org/pod/Rose::DB::Object) derived objects. This way, the application developer
doesn't have to worry about passing a database object to each new RDBO instance.

# REGISTERED METHODS

This module registers the following methods into your application:

## rdb

A reference to the default [Rose::DB](https://metacpan.org/pod/Rose::DB) database object.

```perl
$self->rdb->do_transaction(sub{ ... });
```

To access a database of different type or domain, use parameters:

```perl
my $db = $self->rdb( domain => 'production', type => 'readonly' );
$db->do_transaction( sub { ... } );
```

## rdbo

A helper method, which prepares and returns a [Rose::DB::Object](https://metacpan.org/pod/Rose::DB::Object) child class.

```perl
get '/author/:id' => sub {
    my ( $self, $author_id ) = @_;
    my $author = $self->rdbo('Author')->new( id => $author_id )->load;
    return $author->as_tree;
};
```

Under the hood, the `rdbo` method looks for `MyApp::DB::Author`, assuming
that the name of your application is `MyApp`. A different prefix may be
specified via the ["prefix"](#prefix) configuration option. Then, the module is loaded,
and if it does not have its own `init_db` method, one is injected into it,
containing the already initialized `Rose::DB` object.

To understand the full benefit of this method, one should first make themselves
familiar with how RDBO objects are initialized. The RDBO docs provide several
ways to do that. One of them is to pass a `db` parameter to each constructor.

```perl
my $item = MyDB::Item->new( db => ... );
```

If the `db` parameter is missing, RDBO will look for an `init_db` method. The
`rdbo` method described here initializes that behind the scenes, so you don't
have to worry about any of the above.

To access a database of different type or domain, use parameters:

```perl
my $author = $self->rdbo('Author', type => 'readonly')
                  ->new( id => $author_id )
                  ->load;
```

# CONFIGURATION

The configuration of this module is very robust, and as such it may seem a bit
complicated in the beginning. Here is a list of all keys used:

## source

Source is a hashref or an array of hashrefs, containing arguments for the
["register\_db" in Rose::DB](https://metacpan.org/pod/Rose::DB#register_db) method. To give you an example, directly copied from
the RDB docs:

```perl
modules_init => {
    RDBO => {
        source => [
            {
                domain           => 'development',
                type             => 'main',
                driver           => 'Pg',
                database         => 'dev_db',
                host             => 'localhost',
                username         => 'devuser',
                password         => 'mysecret',
                server_time_zone => 'UTC',
            }, {
                domain           => 'production',
                type             => 'main',
                driver           => 'Pg',
                database         => 'big_db',
                host             => 'dbserver.acme.com',
                username         => 'dbadmin',
                password         => 'prodsecret',
                server_time_zone => 'UTC',
            }
        ]
    }
}
```

If you only have a single source, you may use a hashref as the `source` value.

## default\_type

Specifies a value for ["default\_type" in Rose::DB](https://metacpan.org/pod/Rose::DB#default_type).

## default\_domain

Specifies a value for ["default\_domain" in Rose::DB](https://metacpan.org/pod/Rose::DB#default_domain).

```perl
modules_init => {
    RDBO => {
        default_type   => 'main',
        default_domain => 'development'
    }
};
```

## prefix

Specifies the prefix for your RDBO classes. If missing, it will use the name
of your application class, plus "::DB". For example, if your app class is
called `MyApp`, then the default prefix will be `MyApp::DB`.

```perl
modules_init => {
    RDBO => {
        prefix => 'RDBO::Nest'
    }
};

# This will look for RDBO::Nest::Song now
$self->rdbo('Song')->new;
```

## preload

Setting this option to a non-zero value will cause the module to load all
RDBO classes under the specified ["prefix"](#prefix) at startup. It is advised that
you have this option on in your deployment config.

Preloading all modules may cause a noticeable delay after restarting the web
application. If you are impatient and dislike waiting for your application to
restart (like the author of this module), you are advised to set this option
to a false value in your development config.

# LINK BACK TO APP

This module injects a new method `app` into `Rose::DB::Object`, making
it available to all deriving classes. This method is a reference to the application
instance, and it can be accessed by all object classes that inherit from
`Rose::DB::Object`. A typical example of when this is useful is when you want
to use other modules initialized by your app inside an object class.
The following example uses the [Kelp::Module::Bcrypt](https://metacpan.org/pod/Kelp::Module::Bcrypt) module to bcrypt the
user password:

```perl
package MyApp::DB::User;

__PACKAGE__->meta->setup(
    table => 'users',
    auto  => 1,
);

# Add a triger to column 'password' to bcrypt it when it's being set.
__PACKAGE__->meta->column('password')->add_trigger(
    on_set => sub {
        my $self = shift;
        $self->password( $self->app->bcrypt( $self->password ) );
    }
);
```

# AUTHOR

Stefan G. minimal <at> cpan.org

# SEE ALSO

[Kelp](https://metacpan.org/pod/Kelp), [Rose::DB](https://metacpan.org/pod/Rose::DB), [Rose::DB::Object](https://metacpan.org/pod/Rose::DB::Object)

# LICENSE

Perl
