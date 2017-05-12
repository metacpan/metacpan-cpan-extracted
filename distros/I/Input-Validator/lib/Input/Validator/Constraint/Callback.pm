package Input::Validator::Constraint::Callback;

use strict;
use warnings;

use base 'Input::Validator::Constraint';

sub is_valid {
    my ($self, $value) = @_;

    my $cb = $self->args;

    my ($ok, $custom_error) = $cb->($value);
    return $ok if $ok;

    if (defined $custom_error) {
        $self->error($custom_error);
    }

    return 0;
}

sub error {
    my $self = shift;

    unless (@_) {
        return $self->{error} if defined $self->{error};
        return $self->SUPER::error;
    }

    $self->{error} = $_[0];

    return $self;
}

1;
__END__

=head1 NAME

Input::Validator::Constraint::Callback - Callback constraint

=head1 SYNOPSIS

    $validator->field('foo')->callback(sub {
        my $value = shift;

        return 1 if $value =~ m/^\d+$/;

        return (0, 'Value is not a number');
    });

=head1 DESCRIPTION

Run a callback to validate a field. Return a true value when validation
succeded, and false value when failed.

In order to set your own error instead of a default one return an array where
the error message is the second argument.

=head1 METHODS

=head2 C<is_valid>

Validates the constraint.

=head1 SEE ALSO

L<Input::Validator>, L<Input::Validator::Constraint>

=cut
