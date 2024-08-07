use strict;

package HTML::FormFu::Constraint::Length;
$HTML::FormFu::Constraint::Length::VERSION = '2.07';
# ABSTRACT: Min/Max Length String Constraint

use Moose;
use MooseX::Attribute::Chained;
use MooseX::Aliases;

extends 'HTML::FormFu::Constraint';

has minimum => (
    is     => 'rw',
    alias  => 'min',
    traits => ['Chained'],
);

has maximum => (
    is     => 'rw',
    alias  => 'max',
    traits => ['Chained'],
);

sub constrain_value {
    my ( $self, $value ) = @_;

    return 1 if !defined $value || $value eq '';

    if ( defined( my $min = $self->minimum ) ) {
        return 0 if length $value < $min;
    }

    if ( defined( my $max = $self->maximum ) ) {
        return 0 if length $value > $max;
    }

    return 1;
}

sub _localize_args {
    my ($self) = @_;

    return $self->min, $self->max;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTML::FormFu::Constraint::Length - Min/Max Length String Constraint

=head1 VERSION

version 2.07

=head1 DESCRIPTION

Checks the input value meets both a minimum and maximum length.

This constraint doesn't honour the C<not()> value.

=head1 METHODS

=head2 minimum

=head2 min

The minimum input string length.

L</min> is an alias for L</minimum>.

=head2 maximum

=head2 max

The maximum input string length.

L</max> is an alias for L</maximum>.

=head1 SEE ALSO

Is a sub-class of, and inherits methods from L<HTML::FormFu::Constraint>

L<HTML::FormFu>

=head1 AUTHOR

Carl Franks C<cfranks@cpan.org>

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
