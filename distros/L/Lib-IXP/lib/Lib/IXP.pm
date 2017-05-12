#
# $Id: IXP.pm 21 2015-01-20 18:26:46Z gomor $
#
package Lib::IXP;
use strict; use warnings;

our $VERSION = '0.12';

use Exporter;
use DynaLoader;
our @ISA = qw(Exporter DynaLoader);
our %EXPORT_TAGS = (
   subs => [qw(
      ixp_mount
      ixp_mountfd
      ixp_unmount
      ixp_clientfd
      ixp_create
      ixp_open
      ixp_remove
      ixp_stat
      ixp_read
      ixp_write
      ixp_close
      ixp_errbuf
      xls
      xread
      xwrite
      xcreate
      xremove
   )],
   consts => [qw(
      P9_OREAD
      P9_OWRITE
      P9_ORDWR
      P9_DMDIR
   )],
);
our @EXPORT = (
   @{$EXPORT_TAGS{subs}},
   @{$EXPORT_TAGS{consts}},
);

__PACKAGE__->bootstrap($VERSION);

use constant P9_OREAD  => 0;
use constant P9_OWRITE => 1;
use constant P9_ORDWR  => 2;

use constant P9_DMDIR => 0x80000000;

1;

__END__

=head1 NAME

Lib::IXP - binding for libixp

=head1 SYNOPSIS

   #
   # See perlwmii.pl from examples directory of this tarball
   # You need to customize a little bit for now, and then copy it
   # to your ~/.wmii/wmiirc file.
   #

=head1 DESCRIPTION

Lib::IXP is a binding for the libixp library. This library is used to configure wmii, a window manager. Thus, this binding is used to configure wmii from a Perl program.

libixp may be found at: http://www.suckless.org/libs/libixp.html

wmii may be found at: http://www.suckless.org/wmii/

=head1 LOW-LEVEL FUNCTIONS

=over 4

=item B<ixp_mount (scalar)>

=item B<ixp_mountfd (scalar)>

=item B<ixp_unmount (scalar)>

=item B<ixp_clientfd (scalar)>

=item B<ixp_create (scalar, scalar, scalar, scalar)>

=item B<ixp_open (scalar, scalar, scalar)>

=item B<ixp_remove (scalar, scalar)>

=item B<ixp_stat (scalar, scalar)>

=item B<ixp_read (scalar, scalar, scalar)>

=item B<ixp_write (scalar, scalar, scalar)>

=item B<ixp_close (scalar)>

=item B<ixp_errbuf ()>

=item B<ixp_message (scalar, scalar, scalar)>

=back

=head1 HIGH-LEVEL FUNCTIONS

=over 4

=item B<xread (scalar, scalar, scalar)>

=item B<xwrite (scalar, scalar, scalar)>

=item B<xls (scalar, scalar)>

=item B<xcreate (scalar, scalar, scalar)>

=item B<xremove (scalar, scalar)>

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
