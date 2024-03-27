package HTML::Template::Plugin::Dot::Helpers::Number;
$HTML::Template::Plugin::Dot::Helpers::Number::VERSION = '0.07';
use strict;
use warnings;
use base qw/Number::Format/;

sub format_price {
    my $self = shift;
    return unless @_ and defined $_[0]; # suppress a warning in parent
    $self->SUPER::format_price(@_);
}

sub equals
{
    return $_[1] == $_[2];
}

sub le
{
    return $_[1] <= $_[2];
}

sub lt
{
    return $_[1] < $_[2];
}

sub ge
{
    return $_[1] >= $_[2];
}

sub gt
{
    return $_[1] > $_[2];
}

1;

__END__

=head1 NAME

HTML::Template::Plugin::Dot::Helpers::Number - Number formatting and comparison functions

=head1 METHODS

See L<Number::Format> for formatting functions

=over 4

=item format_price

=item equals

=item le, lt, ge, gt

=back

=head1 SEE ALSO

L<HTML::Template::Plugin::Dot::Helpers> for detailed help, license, and contact information.

=cut

