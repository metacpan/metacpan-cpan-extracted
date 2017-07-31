package Lab::Moose::Connection;
#ABSTRACT: Role for connections
$Lab::Moose::Connection::VERSION = '3.554';
use 5.010;
use warnings;
use strict;


use Moose::Role;
use MooseX::Params::Validate qw/validated_hash/;
use Lab::Moose::Instrument qw/timeout_param/;
use namespace::autoclean;

requires qw/Read Write Clear/;


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

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Connection - Role for connections

=head1 VERSION

version 3.554

=head1 DESCRIPTION

This role should be consumed by all connections in the Lab::Moose::Connection
namespace. It declares the required methods.

=head2 Query

 my $data = $connection->Query(command => '*IDN?');

Call C<Write> followed by C<Read>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by the Lab::Measurement team; in detail:

  Copyright 2016       Simon Reinhardt
            2017       Andreas K. Huettel, Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
