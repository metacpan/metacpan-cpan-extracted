package Lab::Moose::Connection;

use 5.010;
use warnings;
use strict;

our $VERSION = '3.543';

use Moose::Role;
use MooseX::Params::Validate qw/validated_hash/;
use Lab::Moose::Instrument qw/timeout_param/;
use namespace::autoclean;

requires qw/Read Write Clear/;

=head1 NAME

Lab::Moose::Connection - Role for connections.

=head1 DESCRIPTION

This role should be consumed by all connections in the Lab::Moose::Connection
namespace. It declares the required methods.

=cut

has timeout => (
    is      => 'ro',
    isa     => 'Num',
    default => 1,
);

sub _timeout_arg {
    my $self    = shift;
    my %arg     = @_;
    my $timeout = $arg{timeout};
    if ( not defined $timeout ) {
        $timeout = $self->timeout();
    }
    return $timeout;
}

=head2 Query

 my $data = $connection->Query(command => '*IDN?');

Call C<Write> followed by C<Read>.

=cut

sub Query {
    my ( $self, %arg ) = validated_hash(
        \@_,
        timeout_param,
        command => { isa => 'Str' },
    );

    my %write_arg = %arg;
    $self->Write(%write_arg);

    delete $arg{command};
    return $self->Read(%arg);
}

1;
