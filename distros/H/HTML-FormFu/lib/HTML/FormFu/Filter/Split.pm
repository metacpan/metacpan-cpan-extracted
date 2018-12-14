use strict;

package HTML::FormFu::Filter::Split;
$HTML::FormFu::Filter::Split::VERSION = '2.07';
# ABSTRACT: filter splitting a singe value into an arrayref

use Moose;
use MooseX::Attribute::Chained;
extends 'HTML::FormFu::Filter';

has regex => ( is => 'rw', traits => ['Chained'] );
has limit => ( is => 'rw', traits => ['Chained'] );

sub filter {
    my ( $self, $value ) = @_;

    return if !defined $value;

    my $regex = $self->regex;
    my $limit = $self->limit || 0;

    $regex = '' if !defined $regex;

    my @values = split /$regex/, $value, $limit;

    return if !@values;

    return \@values;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Filter::Split - filter splitting a singe value into an arrayref

=head1 VERSION

version 2.07

=head1 SYNOPSIS

    type: Split
    regex: '-'

=head1 DESCRIPTION

Split a single input value into an arrayref of values.

=head1 METHODS

=head2 regex

A regex object or string to be passed as the C<PATTERN> argument to C<split>.

Default Value: '' (empty string)

=head2 limit

A number passed as the C<LIMIT> argument to C<split>.

Default Value: 0

=head1 AUTHOR

Carl Franks, C<cfranks@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Carl Franks <cpan@fireartist.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Carl Franks.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
