package JSORB::Server::Simple;
use Moose;

use HTTP::Server::Simple;
use HTTP::Request;
use HTTP::Response;

use Try::Tiny;
use JSON::RPC::Common::Marshal::HTTP;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:STEVAN';

with 'MooseX::Traits';

has 'dispatcher' => (
    is       => 'ro',
    isa      => 'JSORB::Dispatcher::Path',
    required => 1,
);

has 'host' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { 'localhost' },
);

has 'port' => (
    is      => 'ro',
    isa     => 'Int',
    default => sub { 9999 },
);

has 'request_marshaler' => (
    is      => 'ro',
    isa     => 'JSON::RPC::Common::Marshal::HTTP',
    default => sub {
        JSON::RPC::Common::Marshal::HTTP->new
    },
);

has 'handler' => (
    is      => 'ro',
    isa     => 'CodeRef',
    lazy    => 1,
    builder => 'build_handler',
);

has 'server_engine' => (
    is      => 'ro',
    isa     => 'Moose::Meta::Class',
    lazy    => 1,
    default => sub {
        my $self    = shift;
        my $handler = $self->handler;
        Moose::Meta::Class->create_anon_class(
            superclasses => [ 'HTTP::Server::Simple' ],
            methods      => {
                'setup'   => sub {
                    my ($self, %setup) = @_;
                    $self->{'__setup__'} = \%setup;
                },
                'headers' => sub {
                    my ($self, $headers) = @_;
                    $self->{'__headers__'} = $headers;
                },
                'handler' => sub {
                    my $self   = shift;
                    my $output = $handler->(
                        HTTP::Request->new(
                            $self->{'__setup__'}->{'method'},
                            $self->{'__setup__'}->{'request_uri'},
                            $self->{'__headers__'}
                        )
                    )->as_string;
                    chomp($output);
                    $self->stdio_handle->print( "HTTP/1.0 $output" );
                }
            }
        );
    },
);

sub prepare_handler_args { () }

sub build_handler {
    my $self = shift;
    my $m    = $self->request_marshaler;
    my $d    = $self->dispatcher;
    return sub {
        my $request = shift;
        try {
            my $call   = $m->request_to_call($request);
            my $result = $d->handler(
                $call,
                $self->prepare_handler_args($call, $request)
            );
            $m->result_to_response($result);
        } catch {
            # NOTE:
            # should this return a JSONRPC error?
            # or is the standard HTTP Error okay?
            # - SL
            HTTP::Response->new( 500, 'Internal Server Error', [], $_ );
        };
    }
}

# NOTE:
# we need to initialize the server
# engine so that it can be run
# after a fork() such as in our
# tests. Otherwise the laziness
# messes things up. However it needs
# to be lazy in order to use the
# other attributes when creating
# itself.
# -SL
sub BUILD { (shift)->server_engine }

sub _setup_server {
    my $self   = shift;
    my $server = $self->server_engine->name->new;
    $server->port( $self->port );
    $server->host( $self->host );
    $server;
}

sub run        { (shift)->_setup_server->run        }
sub background { (shift)->_setup_server->background }

__PACKAGE__->meta->make_immutable;

no Moose; 1;

__END__

=pod

=head1 NAME

JSORB::Server::Simple - A simple HTTP server for JSORB

=head1 DESCRIPTION

This is just a simple JSORB server built on top of
L<HTTP::Server::Simple>. This is probably best used for
development and small standalone apps but probably not in
heavy production use (hence the ::Simple).

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
