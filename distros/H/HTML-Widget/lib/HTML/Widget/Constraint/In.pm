package HTML::Widget::Constraint::In;
use base 'HTML::Widget::Constraint';

use strict;
use warnings;

__PACKAGE__->mk_accessors(qw/in/);

=head1 NAME

HTML::Widget::Constraint::In - Check that a value is one of a current set.

=head1 SYNOPSIS

    $widget->constraint( In => "foo" )->in(qw/possible values/);

=head1 DESCRIPTION

=head1 METHODS


=head2 validate

=cut

sub validate {
    my ( $self, $value ) = @_;

    # Return valid on an empty value
    return 1 unless defined($value);
    return 1 if ( $value eq '' );

    my $in = $self->in;

    my %in = map { $_ => 1 } ref $in ? @{ $self->in } : $in;

    return exists $in{$value};
}

=head2 in

Arguments: @values

A list of valid values for that element.

=cut

1;

