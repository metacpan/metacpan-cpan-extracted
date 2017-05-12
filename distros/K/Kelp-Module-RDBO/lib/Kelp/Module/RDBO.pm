package Kelp::Module::RDBO;
use Kelp::Base 'Kelp::Module';
use Rose::DB;
use Rose::DB::Object;
use Plack::Util;
use Class::Inspector;
use Module::Find;
use Digest::MD5 'md5_base64';

our $VERSION = 0.205;

sub build {
    my ( $self, %args ) = @_;

    # Set default prefix to AppName::DB
    $args{prefix} //= ref( $self->app ) . '::DB';

    my @source =
      ref( $args{source} ) eq 'ARRAY'
      ? @{ $args{source} }
      : ( $args{source} );

    Rose::DB->register_db(%$_) for @source;
    Rose::DB->default_type( $args{default_type} )     if $args{default_type};
    Rose::DB->default_domain( $args{default_domain} ) if $args{default_domain};

    # Insert the app into Rose::DB::Object
    no strict 'refs';
    *{"Rose::DB::Object::app"} = sub { $self->app };

    # Preload all modules, if requested
    if ( $ENV{KELP_RDBO_PRELOAD} || $args{preload} ) {
        useall $args{prefix};
    }

    # Parameters and cache for the rdb closure
    my %rdb_cache  = ();
    my @rdb_params = ();
    my $rdb_code = sub {
        my $key = md5_base64( join( ':', @rdb_params ) );
        my $db = $rdb_cache{$key} //= Rose::DB->new(@rdb_params);
        @rdb_params = ();
        return $db;
    };

    $self->register(
        rdb => sub {
            shift;
            @rdb_params = @_;
            return $rdb_code->();
        },

        rdbo => sub {
            my ( $app, $name, @params ) = @_;
            @rdb_params = @params;

            # Load the class
            my $full_name = $args{prefix} . '::' . $name;
            my $class =
              Class::Inspector->loaded($full_name)
              ? $full_name
              : Plack::Util::load_class($full_name);

            # Insert an init_db method, if none found
            my $glob = "${class}::init_db";
            *{$glob} = $rdb_code unless ( *{$glob}{CODE} );

            # Return class only
            return $class;
        }
    );
}

1;

__END__

=pod

=head1 NAME

Kelp::Module::RDBO - Kelp interface to Rose::DB::Object

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This L<Kelp> module creates a L<Rose::DB> connection at application startup,
provides an interface to it, and uses it behind the scenes to pass it to all
L<Rose::DB::Object> derived objects. This way, the application developer
doesn't have to worry about passing a database object to each new RDBO instance.

=head1 REGISTERED METHODS

This module registers the following methods into your application:

=head2 rdb

A reference to the default L<Rose::DB> database object.

    $self->rdb->do_transaction(sub{ ... });

To access a database of different type or domain, use parameters:

    my $db = $self->rdb( domain => 'production', type => 'readonly' );
    $db->do_transaction( sub { ... } );

=head2 rdbo

A helper method, which prepares and returns a L<Rose::DB::Object> child class.

    get '/author/:id' => sub {
        my ( $self, $author_id ) = @_;
        my $author = $self->rdbo('Author')->new( id => $author_id )->load;
        return $author->as_tree;
    };

Under the hood, the C<rdbo> method looks for C<MyApp::DB::Author>, assuming
that the name of your application is C<MyApp>. A different prefix may be
specified via the L</prefix> configuration option. Then, the module is loaded,
and if it does not have its own C<init_db> method, one is injected into it,
containing the already initialized C<Rose::DB> object.

To understand the full benefit of this method, one should first make themselves
familiar with how RDBO objects are initialized. The RDBO docs provide several
ways to do that. One of them is to pass a C<db> parameter to each constructor.

    my $item = MyDB::Item->new( db => ... );

If the C<db> parameter is missing, RDBO will look for an C<init_db> method. The
C<rdbo> method described here initializes that behind the scenes, so you don't
have to worry about any of the above.

To access a database of different type or domain, use parameters:

    my $author = $self->rdbo('Author', type => 'readonly')
                      ->new( id => $author_id )
                      ->load;

=head1 CONFIGURATION

The configuration of this module is very robust, and as such it may seem a bit
complicated in the beginning. Here is a list of all keys used:

=head2 source

Source is a hashref or an array of hashrefs, containing arguments for the
L<Rose::DB/register_db> method. To give you an example, directly copied from
the RDB docs:

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

If you only have a single source, you may use a hashref as the C<source> value.

=head2 default_type

Specifies a value for L<Rose::DB/default_type>.

=head2 default_domain

Specifies a value for L<Rose::DB/default_domain>.

    modules_init => {
        RDBO => {
            default_type   => 'main',
            default_domain => 'development'
        }
    };

=head2 prefix

Specifies the prefix for your RDBO classes. If missing, it will use the name
of your application class, plus "::DB". For example, if your app class is
called C<MyApp>, then the default prefix will be C<MyApp::DB>.

    modules_init => {
        RDBO => {
            prefix => 'RDBO::Nest'
        }
    };

    # This will look for RDBO::Nest::Song now
    $self->rdbo('Song')->new;

=head2 preload

Setting this option to a non-zero value will cause the module to load all
RDBO classes under the specified L</prefix> at startup. It is advised that
you have this option on in your deployment config.

Preloading all modules may cause a noticeable delay after restarting the web
application. If you are impatient and dislike waiting for your application to
restart (like the author of this module), you are advised to set this option
to a false value in your development config.

=head1 LINK BACK TO APP

This module injects a new method C<app> into C<Rose::DB::Object>, making
it available to all deriving classes. This method is a reference to the application
instance, and it can be accessed by all object classes that inherit from
C<Rose::DB::Object>. A typical example of when this is useful is when you want
to use other modules initialized by your app inside an object class.
The following example uses the L<Kelp::Module::Bcrypt> module to bcrypt the
user password:

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

=head1 AUTHOR

Stefan G. minimal E<lt>atE<gt> cpan.org

=head1 SEE ALSO

L<Kelp>, L<Rose::DB>, L<Rose::DB::Object>

=head1 LICENSE

Perl

=cut
