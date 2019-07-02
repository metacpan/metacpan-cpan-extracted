package Lab::Moose::Sweep::DataFile;
$Lab::Moose::Sweep::DataFile::VERSION = '3.682';
# ABSTRACT: Store parameters of datafile and its plots.
use Moose;
use MooseX::Params::Validate 'validated_hash';

has params => ( is => 'ro', isa => 'HashRef', required => 1 );

has plots => (
    is      => 'ro', isa => 'ArrayRef[HashRef]',
    default => sub   { [] },
);

sub add_plot {
    my ( $self, %args )
        = validated_hash( \@_, MX_PARAMS_VALIDATE_ALLOW_EXTRA => 1 );
    push @{ $self->plots }, \%args;
}

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Sweep::DataFile - Store parameters of datafile and its plots.

=head1 VERSION

version 3.682

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2017       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
