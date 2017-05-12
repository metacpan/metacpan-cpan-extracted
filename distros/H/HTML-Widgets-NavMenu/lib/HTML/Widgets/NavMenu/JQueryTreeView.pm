package HTML::Widgets::NavMenu::JQueryTreeView;

use strict;
use warnings;

use base 'HTML::Widgets::NavMenu';

require HTML::Widgets::NavMenu::Iterator::JQTreeView;

sub _get_nav_menu_traverser
{
    my $self = shift;

    return
        HTML::Widgets::NavMenu::Iterator::JQTreeView->new(
            $self->_get_nav_menu_traverser_args()
        );
}

1;

__END__

=head1 NAME

HTML::Widgets::NavMenu::JQueryTreeView - A Specialized HTML::Widgets::NavMenu
sub-class

=head1 SYNOPOSIS

Mostly the same as L<HTML::Widgets::NavMenu> execpt that it renders a fully
expanded tree suitable for input to JQuery's treeview plugin

=head1 DESCRIPTION

This module renders all nodes but places C< class="open" >
and C< class="close" > attributes in the opening C<< <li> >> tags.

An example of this use can be found in Shlomi Fish's Homepage
( L<http://www.shlomifish.org/> ).

=head1 SEE ALSO

L<HTML::Widgets::NavMenu> for the complete documentation of the super-class.

=head1 AUTHORS

Shlomi Fish ( L<http://www.shlomifish.org/> ).

=head1 COPYRIGHT AND LICENSE

Copyright 2004, Shlomi Fish. All rights reserved.

You can use, modify and distribute this module under the terms of the MIT X11
license. ( L<http://www.opensource.org/licenses/mit-license.php> ).

=cut

