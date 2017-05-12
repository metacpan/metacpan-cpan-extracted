# $Id: Pstat.pm,v 1.1 2003/03/31 17:42:16 deschwen Exp $

package HPUX::Pstat;

use strict;
use vars qw($VERSION @ISA);
require DynaLoader;

@ISA = qw(DynaLoader);
$VERSION = '1.01';

bootstrap HPUX::Pstat $VERSION;

1;
__END__

=head1 NAME

HPUX::Pstat - Perl wrapper for C<pstat()> functions


=head1 SYNOPSIS

use HPUX::Rstat;

$pst = HPUX::Pstat::getstatic();

$psd = HPUX::Pstat::getdynamic();

$psv = HPUX::Pstat::getvminfo();

$pss = HPUX::Pstat::getswap(size = 1, start = 0);

$pss = HPUX::Pstat::getproc(size = 1, start = 0);

$pss = HPUX::Pstat::getprocessor(size = 1, start = 0);


=head1 DESCRIPTION

This Perl modules lets you call some of the L<pstat(2)> functions and
returns system performance data in Perl data structures. C<HPUX::Pstat>
is meant as a foundation to build performance monitoring tools upon.

The C<HPUX::Pstat::getstatic>, C<HPUX::Pstat::getdynamic> and
C<HPUX::Pstat::getvminfo> functions each return a hashref containing
most of the respective C structure members.

The C<HPUX::Pstat::getswap>, C<HPUX::Pstat::getproc> and
C<HPUX::Pstat::getprocessor> functions take up to two arguments and
return a reference to an array-of-hashes. The arguments specify
the number of records to fetch and the index of the first record
and are equivalents to the C<elemcount> and C<index> arguments of
the respective C<pstat> functions. In any case only valid data is
returned (Example: If you call C<HPUX::Pstat::getprocessor(4)> on a
2-processor box, the resulting array will contain only two entries).


=head1 DATA FORMAT

The included C<example1.pl> dumps the data structures of all functions.
For more information read F</usr/include/sys/pstat.h>.


=head1 PORTABILITY

According to the L<pstat(2)> manpage the calling interface is kernel
dependent. So do not expect too much. C<HPUX::Pstat> was written and
tested on a S<HPUX 11.0> box and compiles well with S<Perl 5.6.1>
and gcc.

=head1 BUGS AND DESIGN LIMITATIONS

So far the list of imported struct members is hardcoded in C<pack.c.>
I also left out some of the more obscure struct members and all of the
members marked as deprecated.

As any software this package may contain bugs. Please feel free to
contact me if you find one.


=head1 AUTHOR

Axel Schwenke <axel.schwenke@gmx.net>

Copyright (c) 2003 Axel Schwenke. All rights reserved.  This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.


=head1 VERSION

Version 1.01 (31 March 2003)


=head1 SEE ALSO

L<pstat(2)>.

=cut
