package FormValidator::LazyWay::Rule::Email;

use strict;
use warnings;
use Email::Valid;
use Email::Valid::Loose;

sub email {
    my $text = shift;
    my $args = shift;

    return Email::Valid->address( -address => $text, %{$args} ) ? 1 : 0;
}

sub email_loose {
    my $text = shift;
    my $args = shift;

    return Email::Valid::Loose->address( -address => $text, %{$args} ) ? 1 : 0;
}

1;

=head1 NAME

FormValidator::LazyWay::Rule::Email - Email Rule

=head1 METHOD

=head2 email

=head2 email_loose

=cut

