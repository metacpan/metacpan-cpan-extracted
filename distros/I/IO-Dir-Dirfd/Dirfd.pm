# ----------------------------------------------------------------------------
# "THE BEER-WARE LICENSE" (Revision 42)
# <tobez@catpipe.net> wrote this file.  As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return.   Anton Berezin
# ----------------------------------------------------------------------------
#
# $Id: Dirfd.pm,v 1.1.1.1 2001/11/21 17:30:15 tobez Exp $
#
package IO::Dir::Dirfd;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(dirfd);
@EXPORT_OK = qw(fileno);
$VERSION = '0.01';

sub dirfd(*);

bootstrap IO::Dir::Dirfd $VERSION;

sub fileno(*)
{
	no strict "refs";
	my $no;
	eval { $no = CORE::fileno($_[0]) };
	return $no if defined $no;
	my $arg = $_[0];
	$! = 0;
	unless (ref($arg) || $arg =~ /(^\*)|(::)/) {
		my $caller = caller || 'main';
		$arg = "${caller}::$arg";
	}
	$no = dirfd($arg);
	use strict "refs";
	$no;
}

1;
__END__

=head1 NAME

IO::Dir::Dirfd - Perl extension to extract the file descriptor from a dirhandle

=head1 SYNOPSIS

  use IO::Dir::Dirfd;

  opendir D, "." or die $!;
  my $fd = dirfd(D);

  use IO::Dir::Dirfd qw(fileno);

  opendir D, "." or die $!;
  my $fd = fileno(D);

=head1 DESCRIPTION

The IO::Dir::Dirfd module provides the possibility to extract the file
descriptor from a directory handle on platforms where this functionality
is available.

It exports a single sub, dirfd(), by default.  If you specify that you
want to export fileno(), the core fileno() will be overrided.  After
this you can use fileno() for both file- and dirhandles.

=head1 BUGS

As of now, the module was only tested on FreeBSD 4.4 and FreeBSD 5.0;
there's no garantee it will work as advertised elsewehere (or even on
FreeBSD, for that matter).

It is possible that the fileno(HANDLE) form will not work under all
circumstances.  Use fileno(*HANDLE) instead if in doubt.

=head1 AUTHOR

Anton Berezin, tobez@catpipe.net

=head1 SEE ALSO

dirfd(3).

=cut
