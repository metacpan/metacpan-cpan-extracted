use strict;

package HTML::FormFu::Role::GetProcessors;
# ABSTRACT: processor getter roles
$HTML::FormFu::Role::GetProcessors::VERSION = '2.07';
use Moose::Role;

use HTML::FormFu::Util qw(
    _parse_args
    _filter_components
);

sub get_deflators {
    my $self = shift;
    my %args = _parse_args(@_);

    my @x = map { @{ $_->get_deflators(@_) } } @{ $self->_elements };

    return _filter_components( \%args, \@x );
}

sub get_filters {
    my $self = shift;
    my %args = _parse_args(@_);

    my @x = map { @{ $_->get_filters(@_) } } @{ $self->_elements };

    return _filter_components( \%args, \@x );
}

sub get_constraints {
    my $self = shift;
    my %args = _parse_args(@_);

    my @x = map { @{ $_->get_constraints(@_) } } @{ $self->_elements };

    return _filter_components( \%args, \@x );
}

sub get_inflators {
    my $self = shift;
    my %args = _parse_args(@_);

    my @x = map { @{ $_->get_inflators(@_) } } @{ $self->_elements };

    return _filter_components( \%args, \@x );
}

sub get_validators {
    my $self = shift;
    my %args = _parse_args(@_);

    my @x = map { @{ $_->get_validators(@_) } } @{ $self->_elements };

    return _filter_components( \%args, \@x );
}

sub get_transformers {
    my $self = shift;
    my %args = _parse_args(@_);

    my @x = map { @{ $_->get_transformers(@_) } } @{ $self->_elements };

    return _filter_components( \%args, \@x );
}

sub get_plugins {
    my $self = shift;
    my %args = _parse_args(@_);

    return _filter_components( \%args, $self->_plugins );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Role::GetProcessors - processor getter roles

=head1 VERSION

version 2.07

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
