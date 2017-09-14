# -*- Perl -*-
#
# a string object (mostly so ->render can recurse through the parse tree)

package Lingua::Awkwords::String;

use strict;
use warnings;
use Moo;
use namespace::clean;

our $VERSION = '0.05';

has string => ( is => 'ro' );

sub render { $_[0]->string // '' }

sub walk {
    my ($self, $callback) = @_;
    $callback->($self);
    return;
}

1;
__END__

=head1 NAME

Lingua::Awkwords::String - a static string

=head1 SYNOPSIS

This module is typically automagically used via L<Lingua::Awkwords>.

=head1 DESCRIPTION

This module implements a static string choice for L<Lingua::Awkwords>.

=head1 ATTRIBUTES

=over 4

=item I<string>

Where the string should be stored.

=back

=head1 METHODS

=over 4

=item B<new>

Constructor. May and probably should be passed the B<string> attribute
to set the string.

=item B<render>

Returns the string, or the empty string if the B<string> has not been
set. This will typically be called from L<Lingua::Awkwords::Set> as part
of a higher-level B<render> call on a parse tree.

=item B<walk> I<callback>

Calls the I<callback> function with itself as the argument.

=back

=head1 BUGS

=head2 Reporting Bugs

Please report any bugs or feature requests to
C<bug-lingua-awkwords at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-Awkwords>.

Patches might best be applied towards:

L<https://github.com/thrig/Lingua-Awkwords>

=head2 Known Issues

None at this time.

=head1 SEE ALSO

L<Lingua::Awkwords>, L<Lingua::Awkwords::Parser>

=head1 AUTHOR

thrig - Jeremy Mates (cpan:JMATES) C<< <jmates at cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 by Jeremy Mates

This program is distributed under the (Revised) BSD License:
L<http://www.opensource.org/licenses/BSD-3-Clause>

=cut
