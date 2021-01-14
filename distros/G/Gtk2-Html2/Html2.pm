#
# $Id$
#

package Gtk2::Html2;

use 5.008;
use strict;
use warnings;

use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.06';

sub dl_load_flags { 0x01 }

bootstrap Gtk2::Html2 $VERSION;

# Preloaded methods go here.

1;
__END__

=head1 NAME

Gtk2::Html2 - (DEPRECATED) HTML Viewer widget for Gtk2-Perl

=head1 SYNOPSIS

 # NOTE: not a complete example, just a quick overview
 use Gtk2;
 use Gtk2::Html2;

 # create a new view.
 my $view = new Gtk2::Html2::View;
 $scrolled_window->add ($view);

 # create and hook up a document
 my $document = new Gtk2::Html2::Document;
 $document->signal_connect (request_url => \&request_url);
 $document->signal_connect (link_clicked => \&link_clicked);
 # tell the view to display this document.
 $view->set_document ($document);

 # feed data into the document, which will parse it as it goes.
 # if necessary, the request-url signal will fire when the
 # the document needs to fetch a stylesheet or image or whatever.
 $document->clear;
 $document->open_stream ("text/html");
 while ($data = fetch_data_chunk_from_someplace()) {
     $document->write_stream ($data);
 }
 
 ...

=head1 ABSTRACT

B<DEPRECATED> The Gtk2::Html2 extension allows a perl developer to use the
gtkhtml2 html display widget with Gtk2-Perl.

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

Perl URL: https://gitlab.gnome.org/GNOME/perl-gtk2-html2

=item *

Upstream URL: https://gitlab.gnome.org/Archive/gtkhtml2

=item *

Last upstream version: 2.11.1

=item *

Last upstream release date: 2007-08-13

=item *

Migration path for this module: maybe Gtk3::WebKit

=item *

Migration module URL: https://metacpan.org/pod/Gtk3::WebKit

=back

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>


The Gtk2::Html2 extension allows a perl developer to use the gtkhtml2 html
display widget with Gtk2-Perl.

gtkhtml2 is tuned for html display; for html editing, you want gtkhtml3.
There appears to be very little documentation about gtkhtml2 on the web.
Take what you can get, and add to this module's documentation if you can.

To discuss gtk2-perl, ask questions and flame/praise the authors,
join gtk-perl-list@gnome.org at lists.gnome.org.

Also have a look at the gtk2-perl website and sourceforge project page,
http://gtk2-perl.sourceforge.net

=head1 SEE ALSO

L<Gtk2::Html2::index> lists the perl API reference pods.

L<http://cia.navi.cx/stats/project/gnome/gtkhtml2>

L<Gtk2>, L<Glib>, L<perl>.

You will probably also want libraries for fetching and otherwise manipulating
urls; Gnome provides L<Gnome2::VFS> in addition to the venerable native perl
L<LWP>.

=head1 BUGS

This is very alpha, and very incomplete.  The DOM stuff is not bound at
all.

=head1 AUTHOR

muppet.  if you would like to own this project, please drop me a line.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by muppet <scott at asofyet dot org>

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; if not, see
<https://www.gnu.org/licenses/>.

=cut
