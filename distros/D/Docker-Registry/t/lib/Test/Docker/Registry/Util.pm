package Test::Docker::Registry::Util;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT = qw(
    new_fake_io
    new_auth_none
);

use Docker::Registry::Auth::None;

sub new_fake_io {
    return Test::Docker::Registry::FakeIO->new();
}

sub new_auth_none {
    return Docker::Registry::Auth::None->new();
}

package Test::Docker::Registry::FakeIO {
    use Moo;
    use Types::Standard qw/Int Str HashRef InstanceOf/;
    with 'Docker::Registry::IO';

    has status_code => (
        is      => 'rw',
        isa     => Int,
        default => 200,
        writer  => 'set_status_code',
        lazy    => 1,
    );

    has content => (
        is      => 'rw',
        isa     => Str,
        writer  => 'set_content',
        default => '',
        lazy    => 1,
    );

    has headers => (
        is      => 'rw',
        isa     => HashRef,
        writer  => 'set_headers',
        lazy    => 1,
        default => sub { {} },
    );

    has response_to_return => (
        is  => 'rw',
        isa => InstanceOf['Docker::Registry::Response'],
    );

    sub send_request {
        my $self = shift;

        return Docker::Registry::Response->new(
            content => $self->content,
            status  => $self->status_code,
            headers => $self->headers,
        );

    }
}

1;
