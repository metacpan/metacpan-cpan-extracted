package Gtk2::SourceView2;

=head1 NAME

Gtk2::SourceView2 - (DEPRECATED) Enhanced source code editor widget

=head1 SYNOPSIS

	use Glib qw(TRUE FALSE);
	use Gtk2 '-init';
	use Gtk2::SourceView2;
	
	my $window = Gtk2::Window->new();
	my $view = Gtk2::SourceView2->new();
	$window->add($view);
	$window->set_size_request(480, 120);
	$window->show_all();
	
	$window->signal_connect(delete_event => sub {
		Gtk2->main_quit();
		return TRUE;
	});
	
	Gtk2->main();

=head1 ABSTRACT

B<DEPRECATED> Gtk2::SourceView2 is the Perl binding for the C library
gtksourceview-2.0.

=head1 DESCRIPTION

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>

This module has been deprecated by the Gtk-Perl project.  This means that the
module will no longer be updated with security patches, bug fixes, or when
changes are made in the Perl ABI.  The Git repo for this module has been
archived (made read-only), it will no longer possible to submit new commits to
it.  You are more than welcome to ask about this module on the Gtk-Perl
mailing list, but our priorities going forward will be maintaining Gtk-Perl
modules that are supported and maintained upstream; this module is neither.

Since this module is licensed under the LGPL v2.1, you may also fork this
module, if you wish, but you will need to use a different name for it on CPAN,
and the Gtk-Perl team requests that you use your own resources (mailing list,
Git repos, bug trackers, etc.) to maintain your fork going forward.

=over

=item *

Perl URL: https://gitlab.gnome.org/GNOME/perl-gtk2-sourceview2

=item *

Upstream URL: https://gitlab.gnome.org/GNOME/gtksourceview

=item *

Last compatible upstream version: 2.10.5

=item *

Last upstream release date: 2010-09-28

=item *

Migration path for this module: G:O:I

=item *

Migration module URL: https://metacpan.org/pod/Glib::Object::Introspection

=back


Gtk2::SourceView2 is the Perl binding for the C library gtksourceview-2.0. This
is the same widget that's used by gedit, MonoDevelop, Anjuta and several other
projects.

This widget extends the standard GTK+ framework for multiline text editing with
support for configurable syntax highlighting, unlimited undo/redo, UTF-8
compliant caseless searching, printing and other features typical of a source
code editor.

For more information about gtksourceview-2.0 see:
L<http://projects.gnome.org/gtksourceview/>.

=head1 AUTHORS

Emmanuel Rodriguez E<lt>potyl@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2009-2010 by Emmanuel Rodriguez (see the file AUTHORS)

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as
published by the Free Software Foundation; either version 2 of
the License, or (at your option) any later version; or the
Artistic License, version 2.0.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details; or the Artistic License.

You should have received a copy of the GNU Library General Public
License along with this library; if not, see
<https://www.gnu.org/licenses/>.

=cut

use warnings;
use strict;
use base 'DynaLoader';

use Gtk2;

our $VERSION = '0.12';

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

__PACKAGE__->bootstrap($VERSION);

1;
