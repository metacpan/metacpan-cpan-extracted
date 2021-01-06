package Gnome2::Wnck;

# $Id$

use 5.008;
use strict;
use warnings;

use Gtk2;

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.18';

sub import {
  my $self = shift();
  $self -> VERSION(@_);
}

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

Gnome2::Wnck -> bootstrap($VERSION);

1;
__END__

=head1 NAME

Gnome2::Wnck - (DEPRECATED) Perl interface to the Window Navigator
Construction Kit

=head1 SYNOPSIS

  use Gtk2 -init;
  use Gnome2::Wnck;

  my $screen = Gnome2::Wnck::Screen -> get_default();
  $screen -> force_update();

  my $pager = Gnome2::Wnck::Pager -> new($screen);
  my $tasklist = Gnome2::Wnck::Tasklist -> new($screen);

=head1 ABSTRACT

B<DEPRECATED> This module allows a Perl developer to use the Window Navigator
Construction Kit library (libwnck for short) to write tasklists and pagers.

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

Perl URL: https://gitlab.gnome.org/GNOME/perl-gnome2-wnck

=item *

Upstream URL: https://gitlab.gnome.org/GNOME/libwnck

=item *

Last upstream version: 2.30.7

=item *

Last upstream release date: 2011-08-31

=item *

Migration path for this module: G:O:I

=item *

Migration module URL: https://metacpan.org/pod/Glib::Object::Introspection

=back

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>

=head1 SEE ALSO

L<Gnome2::Wnck::index>(3pm), L<Gtk2>(3pm), L<Gtk2::api>(3pm) and the source
code of libwnck.

=head1 AUTHOR

Torsten Schoenfeld E<lt>kaffeetisch@web.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2003-2006 by the gtk2-perl team

=cut
