package Mail::URLFor::Role::Template;
use Moo::Role;
use URI::Escape 'uri_escape';
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';

use namespace::autoclean;

requires 'template';

our $VERSION = '0.03';

sub munge_messageid( $self, $messageid ) {
    uri_escape($messageid)
}

sub render( $self, $rfc822id ) {
    return sprintf $self->template, $self->munge_messageid( $rfc822id )
}

1;

=head1 REPOSITORY

The public repository of this module is
L<http://github.com/Corion/Mail::URLFor>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Mail-URLFor>
or via mail to L<mail-urlfor-Bugs@rt.cpan.org>.

=head1 AUTHOR

Max Maischein C<corion@cpan.org>

=head1 COPYRIGHT (c)

Copyright 2019 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
