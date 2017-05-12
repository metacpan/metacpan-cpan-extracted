package HTML::Widgets::NavMenu::HeaderRole;

use strict;
use warnings;

use base 'HTML::Widgets::NavMenu';

require HTML::Widgets::NavMenu::Iterator::NavMenu::HeaderRole;

sub _get_nav_menu_traverser
{
    my $self = shift;

    return
        HTML::Widgets::NavMenu::Iterator::NavMenu::HeaderRole->new(
            $self->_get_nav_menu_traverser_args()
        );
}

1;

__END__

=head1 NAME

HTML::Widgets::NavMenu::HeaderRole - A Specialized HTML::Widgets::NavMenu
sub-class

=head1 SYNOPOSIS

Mostly the same as L<HTML::Widgets::NavMenu> except for the ability to
specify C<'role' =E<gt> "header"> as one of the node attributes.

=head1 DESCRIPTION

This module is constructed and invoked similarly to HTML::Widgets::NavMenu.
The only difference is that it is meaningful to specify C<"header"> as the
value of the C<'role'>.

In that case, the link or bolded label will be rendered within its own
C<E<lt>h2E<gt>> header. The HTML will look something like this:

    </ul>
    <h2>
    <a href="../me/" title="About Myself">About Me</a>
    </h2>
    <ul>

An example of this use can be found on the Perl Beginners Site
( L<http://perl-begin.org/> ).

=head1 SEE ALSO

L<HTML::Widgets::NavMenu> for the complete documentation of the super-class.

=head1 AUTHORS

Shlomi Fish, L<http://www.shlomifish.org> .

=cut

