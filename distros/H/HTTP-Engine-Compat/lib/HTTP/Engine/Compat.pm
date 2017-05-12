package HTTP::Engine::Compat;
use Moose;
our $VERSION = '0.03';

#extends 'HTTP::Engine';
use HTTP::Engine;
use HTTP::Engine::Request;
use HTTP::Engine::ResponseFinalizer;
use HTTP::Engine::Compat::Context;
use HTTP::Engine::Role::Interface;

our $rh;
my @wraps;

sub import {
    my ( $class, %args ) = @_;

    $class->_modify(
        'HTTP::Engine::Request',
        sub {
            my $meta = shift;
            $meta->add_attribute(
                context => {
                    is       => 'rw',
                    isa      => 'HTTP::Engine::Compat::Context',
                    weak_ref => 1,
                }
            );
        }
    );

    $class->_modify(
        'HTTP::Engine::Response',
        sub {
            my $meta = shift;
            $meta->add_attribute(
                location => {
                    is  => 'rw',
                    isa => 'Str',
                }
            );
            $meta->add_method(
                redirect => sub {
                    my $self = shift;

                    if (@_) {
                        $self->location(shift);
                        $self->status( shift || 302 );
                    }

                    $self->location;
                }
            );
        }
    );

    $class->_modify(
        'HTTP::Engine',
        sub {
            my $meta = shift;
            $meta->add_around_method_modifier(
                'new' => sub {
                    my ($next, @args) = @_;
                    my $instance = $next->(@args);

                    $class->_setup_interface($instance->interface->meta);
                    $instance;
                },
            );
        },
    );

    do {
        my $meta =
          Class::MOP::Class->initialize('HTTP::Engine::ResponseFinalizer')
          or die "cannot get meta";
        $meta->add_around_method_modifier(
            finalize => sub {
                my $code = shift;
                my ( $self, $req, $res ) = @_;
                if ( my $location = $res->location ) {
                    $res->header( Location => $req->absolute_url($location) );
                    $res->body( $res->status . ': Redirect' ) unless $res->body;
                }
                $code->(@_);
            },
        );
    };

    return unless $args{middlewares} && ref $args{middlewares} eq 'ARRAY';
    $class->load_middlewares( @{ $args{middlewares} } );
}

my %initialized;
sub _setup_interface {
    my ($class, $inter) = @_;

    return if $initialized{$inter->name}++;

    $inter->make_mutable;

    $inter->add_method(
        'call_handler' => sub {
            my $req = shift;
            $rh->( $req );
        }
    );
    $class->_wrap( $inter, \&_extract_context );
    $class->_wrap( $inter, $_ ) for @wraps;

    $inter->make_mutable;
    $inter->add_method(
        'handle_request' => sub {
            my ( $self, %args ) = @_;

            my $c = HTTP::Engine::Compat::Context->new(
                req => HTTP::Engine::Request->new(
                    request_builder => $self->request_builder,
                    %args,
                ),
                res => HTTP::Engine::Response->new( status => 200 ),
            );

            eval {
                local $rh = $self->request_handler;
                my $res = $inter->get_method('call_handler')->($c);
                if (Scalar::Util::blessed($res) && $res->isa('HTTP::Engine::Response')) {
                    $c->res( $res );
                }
            };
            if ( my $e = $@ ) {
                print STDERR $e;
                $c->res->status(500);
                $c->res->body('internal server error');
            }

            HTTP::Engine::ResponseFinalizer->finalize( $c->req => $c->res );

            $self->response_writer->finalize( $c->req => $c->res );
            return $c->res;
        },
    );

    $inter->make_immutable;
}

sub load_middlewares {
    my ($class, @middlewares) = @_;
    for my $middleware (@middlewares) {
        $class->load_middleware( $middleware );
    }
}

sub load_middleware {
    my ($class, $middleware) = @_;

    my $pkg;
    if (($pkg = $middleware) =~ s/^(\+)//) {
        Class::MOP::load_class($pkg);
    } else {
        $pkg = 'HTTP::Engine::Middleware::' . $middleware;
        unless (eval { Class::MOP::load_class($pkg) }) {
            $pkg = 'HTTPEx::Middleware::' . $middleware;
            Class::MOP::load_class($pkg);
        }
    }

    if ($pkg->meta->has_method('setup')) {
        $pkg->setup();
    }

    if ($pkg->meta->has_method('wrap')) {
        push @wraps, $pkg->meta->get_method('wrap')->body;
    }
}

sub _wrap {
    my ($class, $interface, $code ) = @_;
    $interface->make_mutable;
    $interface->add_around_method_modifier(
        call_handler => $code,
    );
    $interface->make_immutable;
}

sub _extract_context {
    my ($code, $arg) = @_;

    # process argument
    if (Scalar::Util::blessed($arg) ne 'HTTP::Engine::Compat::Context') {
    }

    my $ret = $code->($arg);

    # process return value
    my $res;
    if (Scalar::Util::blessed($ret) && $ret->isa('HTTP::Engine::Response')) {
        $res = $ret;
    } else {
        $res = $arg->res;
    }

    return $res;
}

sub _modify {
    my ($class, $target, $cb) = @_;
    my $meta = $target->meta;
    $meta->make_mutable if $meta->can('make_mutable');
    $cb->($meta);
    $meta->make_immutable if $meta->can('make_immutable');
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

=encoding utf8

=for stopwords middlewares Middleware middleware nothingmuch kan namespace HTTPEx

=head1 NAME

HTTP::Engine::Compat - version 0.0.12 Compatibility layer of HTTP::Engine

=head1 SYNOPSIS

  use HTTP::Engine::Compat;
  my $engine = HTTP::Engine->new(
      interface => {
          module => 'ServerSimple',
          args   => {
              host => 'localhost',
              port =>  1978,
          },
          request_handler => 'main::handle_request',# or CODE ref
      },
  );
  $engine->run;

  use Data::Dumper;
  sub handle_request {
      my $c = shift;
      $c->res->body( Dumper($c->req) );
  }

=head1 DESCRIPTION

HTTP::Engine::Compat is version 0.0.12 Compatibility layer of HTTP::Engine.

The element of Context and Middleware are added to HTTP::Engine.

=head1 MIDDLEWARES

For all non-core middlewares (consult #codrepos@freenode first), use the HTTPEx::
namespace. For example, if you have a plugin module named "HTTPEx::Middleware::Foo",
you could load it as

  use HTTP::Engine::Compat middlewares => [ qw( +HTTPEx::Plugin::Foo ) ];

=head1 METHODS

=over 4

=item HTTP::Engine::Compat->load_middleware(middleware)

=item HTTP::Engine::Compat->load_middlewares(qw/ middleware middleware /)

Loads the given middleware into the HTTP::Engine.

=back

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom@gmail.comE<gt>

Kazuhiro Osawa

=head1 SEE ALSO

L<HTTP::Engine>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
