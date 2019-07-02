package Lab::Moose::Connection;
$Lab::Moose::Connection::VERSION = '3.682';
#ABSTRACT: Role for connections

use 5.010;
use warnings;
use strict;

use Moose::Role;
use MooseX::Params::Validate qw/validated_hash/;
use Lab::Moose::Instrument qw/timeout_param read_length_param/;
use namespace::autoclean;

requires qw/Read Write Clear/;


has timeout => (
    is      => 'ro',
    isa     => 'Num',
    default => 1,
);

sub _timeout_arg {
    my $self = shift;
    my %arg  = @_;
    return $arg{timeout} // $self->timeout();
}

has read_length => (
    is      => 'ro',
    isa     => 'Int',
    default => 32768
);

sub _read_length_arg {
    my $self = shift;
    my %arg  = @_;
    return $arg{read_length} // $self->read_length();
}


sub Query {
    my ( $self, %arg ) = validated_hash(
        \@_,
        timeout_param,
        read_length_param,
        command => { isa => 'Str' },
    );

    my %write_arg = %arg;
    delete $write_arg{read_length};
    $self->Write(%write_arg);

    delete $arg{command};
    return $self->Read(%arg);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Connection - Role for connections

=head1 VERSION

version 3.682

=head1 DESCRIPTION

This role should be consumed by all connections in the Lab::Moose::Connection
namespace. It declares the required methods.

=head2 Query

 my $data = $connection->Query(command => '*IDN?');

Call C<Write> followed by C<Read>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
