#
# Copyright (c) 2005 by Emmanuele Bassi (see the file AUTHORS)
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Library General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Library General Public License for more details.
#
# You should have received a copy of the GNU Library General Public
# License along with this library; if not, see
# <https://www.gnu.org/licenses/>.

package Gtk2::Recent;

use 5.008;
use strict;
use warnings;

use Glib;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Gtk2::Recent ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.052';

sub dl_load_flags { 0x01 }

require XSLoader;
XSLoader::load('Gtk2::Recent', $VERSION);

1;
__END__

=head1 NAME

Gtk2::Recent - (DEPRECATED) Perl wrapper to the recent files spec Gtk
implementation

=head1 SYNOPSIS

  use Gnome2::VFS '-init';
  use Gtk2::Recent;

  my $model = Gtk2::Recent::Model->new('none');
  $model->add('file:///tmp/some_picture.png');

  my $item = Gtk2::Recent::Item->new;
  $item->set_uri('file:///music/REM_-_Leaving_New_York.ogg');
  $item->set_mime_type('application/ogg');
  $item->set_group('Rhythmbox');

  $model->add_full($item);

  my $new_model = Gtk2::Recent::Model->new('mru');
  $model->set_filter_mime_types('image/*');
  foreach my $i ($model->get_list) {
  	print "URI: "       . $i->get_uri       . "\n";
	print "MIME Type: " . $i->get_mime_type . "\n";
	print "\n";
  }

=head1 ABSTRACT

B<DEPRECATED> Perl bindings to the recent files spec Gtk implementation, for
use with gtk2-perl.

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

Perl URL: https://gitlab.gnome.org/GNOME/perl-gtk2-recent

=item *

Upstream URL: https://gitlab.gnome.org/Archive/libgnome

=item *

Last upstream version: 2.32.1

=item *

Last upstream release date: 2011-01-31

=item *

Migration path for this module: Gtk3::Recent*

=item *

Migration module URL: https://metacpan.org/pod/Gtk3

=back

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>


This model allows you to access, modify and show the recent files list,
using the recent files specification provided by freedesktop.org and
implemented using the Gtk libraries.

The recent files list are accessed using the Gtk2::Recent::Model object;
single entries in the recent files list are represented using the
Gtk2::Recent::Item object.

To discuss gtk2-perl, ask questions and flame/praise the authors, join
gtk-perl-list@gnome.org at lists.gnome.org.

Find out more about Gnome at http://www.gnome.org.

=head1 CAVEAT

This binding uses the EggRecent objects provided by libegg.  As such,
it is not api stable, nor it is installed as a shared object

=head1 SEE ALSO

L<perl>(1), L<Gtk2>(3pm), L<Gnome2>(3pm) and the recent files spec on
http://freedesktop.org

=head1 AUTHOR

Emmanuele Bassi E<lt>ebassi (at) gmail.comE<gt>

gtk2-perl created by the gtk2-perl team: http://gtk2-perl.sf.net

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Emmanuele Bassi

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
