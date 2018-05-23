package Math::GrahamFunction::Object;

use strict;
use warnings;

=head1 NAME

Math::GrahamFunction::Object - base class for all the Math::GrahamFunction
objects.

=cut

use base qw(Class::Accessor);

=head1 FUNCTIONS

=head2 new

A constructor. Calls C<_initialize> with the arguments it receives.

=cut

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

=head1 AUTHOR

Shlomi Fish, C<< <shlomif at cpan.org> >>

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2007 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11.

B<Note:> the module meta-data says this module is released under the BSD
license. However, MIT X11 is the more accurate license, and "bsd" is
the closest option for the CPAN meta-data.

=cut

1;

