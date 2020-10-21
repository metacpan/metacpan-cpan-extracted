package Gtk2::MozEmbed;

# $Id$

use 5.008;
use strict;
use warnings;

use Gtk2;
eval "use Mozilla::DOM; 1;";

require DynaLoader;

our @ISA = qw(DynaLoader);

our $VERSION = '0.10';

sub import {
  my $self = shift();
  $self -> VERSION(@_);
}

sub dl_load_flags { $^O eq 'darwin' ? 0x00 : 0x01 }

Gtk2::MozEmbed -> bootstrap($VERSION);

1;
__END__

=head1 NAME

Gtk2::MozEmbed - Perl interface to the Mozilla embedding widget

=head1 SYNOPSIS

  #!/usr/bin/perl
  use strict;
  use warnings;
  use Glib qw(TRUE FALSE);
  use Gtk2 -init;
  use Gtk2::MozEmbed;

  Gtk2::MozEmbed -> set_profile_path($ENV{ HOME } . "/.mybrowser",
                                     "MyBrowser");

  my $window = Gtk2::Window -> new();
  my $moz = Gtk2::MozEmbed -> new();

  $window -> signal_connect(delete_event => sub {
    Gtk2 -> main_quit;
    return FALSE;
  });

  $window -> set_title("MyBrowser");
  $window -> set_default_size(600, 400);
  $window -> add($moz);
  $window -> show_all();

  $moz -> load_url("http://gtk2-perl.sf.net");

  Gtk2 -> main;

See examples/pumzilla in the source tarball for a more complete example.

=head1 ABSTRACT

B<DEPRECATED> This module allows a Perl developer to use the Mozilla embedding
widget.

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

Perl URL: https://gitlab.gnome.org/GNOME/perl-gtk2-mozembed

=item *

Upstream URL: https://www-archive.mozilla.org/releases/mozilla1.7.13/

=item *

Last upstream version: 1.7.13

=item *

Last upstream release date: 2006-04-21

=item *

Migration path for this module: maybe Gtk3::WebKit?

=item *

Migration module URL: https://metacpan.org/pod/Gtk3::WebKit

=back

B<NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE NOTICE>

=head1 SEE ALSO

L<Gtk2::MozEmbed::index>(3pm), L<Gtk2>(3pm), L<Gtk2::api>(3pm).

=head1 AUTHORS

=over

=item Torsten Schoenfeld E<lt>kaffeetisch at gmx dot deE<gt>

=item Scott Lanning E<lt>lannings at who dot intE<gt>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004-2011 by the gtk2-perl team

=cut
