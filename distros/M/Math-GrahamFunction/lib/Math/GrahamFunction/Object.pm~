package Math::GrahamFunction::Object;

use strict;
use warnings;

=head1 NAME

Math::GrahamFunction::Object - base class for all the Math::GrahamFunction
objects.

=cut

use parent qw(Class::Accessor);

=head1 FUNCTIONS

=head2 new

A constructor. Calls C<_initialize> with the arguments it receives.

=cut

sub new
{
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=cut

1;

