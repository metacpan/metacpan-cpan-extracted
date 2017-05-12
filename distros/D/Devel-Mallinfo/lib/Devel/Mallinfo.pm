# Copyright 2007, 2008, 2009, 2010, 2011, 2014 Kevin Ryde

# This file is part of Devel-Mallinfo.
#
# Devel-Mallinfo is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Devel-Mallinfo is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Devel-Mallinfo.  If not, see <http://www.gnu.org/licenses/>.

package Devel::Mallinfo;
use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

use Exporter;
use DynaLoader;
@ISA = ('Exporter', 'DynaLoader');

$VERSION = 14;

@EXPORT_OK = ('mallinfo');
%EXPORT_TAGS = (all => \@EXPORT_OK);

Devel::Mallinfo->bootstrap($VERSION);
if (defined &malloc_info)         { push @EXPORT_OK, 'malloc_info';  }
if (defined &malloc_info_string)  { push @EXPORT_OK, 'malloc_info_string';  }
if (defined &malloc_stats)        { push @EXPORT_OK, 'malloc_stats'; }
if (defined &malloc_trim)         { push @EXPORT_OK, 'malloc_trim'; }

1;
__END__

=for stopwords malloc bss runtime mmapped unbuffered PerlIO UTF8 errno Glibc libc builtin Devel-Mallinfo Ryde sbrk kbytes eg

=head1 NAME

Devel::Mallinfo -- mallinfo() memory statistics and more

=head1 SYNOPSIS

 use Devel::Mallinfo;
 my $hashref = Devel::Mallinfo::mallinfo();
 print "uordblks used space ", $hashref->{'uordblks'}, "\n";

 Devel::Mallinfo::malloc_stats();  # GNU systems

=head1 DESCRIPTION

C<Devel::Mallinfo> is an interface to the C library C<mallinfo()> function
giving various totals for memory used by C<malloc()>.  It's meant for
development use, to give an idea how much memory a program and libraries are
using.  Interfaces to some GNU C Library specific malloc information are
provided too, when available.

C<malloc()> isn't the only way memory may be used.  Program and library data
and bss segments and the occasional direct C<mmap()> don't show up in
C<mallinfo()>.  But normally almost all runtime space goes through
C<malloc()> so it's close to the total and dynamic usage is often what's of
interest anyway.

See the F<examples> directory in the Devel-Mallinfo sources for some
programs printing malloc info.

=head1 EXPORTS

Nothing is exported by default.  Call with fully qualified function names
or import in the usual way (see L<Exporter>),

    use Devel::Mallinfo 'mallinfo';
    $h = mallinfo();

C<":all"> imports everything

    use Devel::Mallinfo ':all';
    mallinfo_stats();  # on a GNU system

=head1 FUNCTIONS

=over 4

=item C<$hashref = Devel::Mallinfo::mallinfo()>

Return a reference to a hash of C<struct mallinfo> values obtained from
C<mallinfo()>.  The keys are field name strings and the values are integers.
For example

    { 'arena'    => 16384,
      'uordblks' => 1234,
      ...
    }

So to print (in random order)

    my $info = Devel::Mallinfo::mallinfo();
    foreach my $field (keys %$info) {
      print "$field is $info->{$field}\n";
    }

Field names are grepped from C<struct mallinfo> in F<malloc.h> at build
time, so everything on the system should be available.  If C<mallinfo()> is
not available at all in whatever C<malloc()> library Perl is using then
C<mallinfo()> returns a reference to an empty hash.

A new hash is created and returned each time, so later calls don't change
previously returned info.

=back

=head2 Fields

See the C<mallinfo()> man page or the GNU C Library Reference Manual section
"Statistics for Memory Allocation with `malloc'" for details of what the
fields mean.  On a modern system,

    arena         bytes from sbrk()
    hblkhd        bytes from mmap()

    within the arena amount:

    uordblks      bytes in use, ordinary blocks
    usmblks       bytes in use, small blocks
    fordblks      free bytes, ordinary blocks
    fsmblks       free bytes, small blocks
    keepcost      part of fordblks or fsmblks at top

    totals:

    arena+hblkhd             total taken from the system
    uordblks+usmblks+hblkhd  total in use by program
    fordblks+fsmblks         total free within program

C<hblkhd> mmapped space is immediately returned to the system when freed.
C<arena> sbrk space is only shrunk when there's enough free at the top to be
worth shrinking.  C<keepcost> is the current bytes there.  Usually C<free()>
automatically shrinks when C<keepcost> exceeds C<M_TRIM_THRESHOLD> from
C<mallopt()>, for example 128 kbytes.

=head1 EXTRA FUNCTIONS

=head2 GNU C Library

The following are available in recent versions of the GNU C Library.  If not
available then they're not provided by C<Devel::Mallinfo>.

=over 4

=item C<Devel::Mallinfo::malloc_stats()>

Print a malloc usage summary to standard error.

C<malloc_stats()> uses C C<stderr>, not Perl C<STDERR>, so in the unlikely
event Perl C<STDERR> is buffered you might have to flush to keep output in
sequence.  (Perl's C<STDERR> is unbuffered by default.)

=item C<$status = Devel::Mallinfo::malloc_info ($options, $fh)>

=item C<$str = Devel::Mallinfo::malloc_info_string ($options)>

Print malloc usage information to file handle C<$fh>, or return it as a
string C<$str>.  There are no C<$options> values yet and that parameter
should be 0.

C<malloc_info()> returns 0 on success.  It writes to C<$fh> as a C C<FILE*>,
so PerlIO layers are ignored and a the XSUB casting might forcibly turn off
any UTF8 flag.  Perhaps this will improve in the future.

    Devel::Mallinfo::malloc_info(0,\*STDOUT) == 0
      or die "oops, malloc_info() error";

C<malloc_info_string()> is an extra in C<Devel::Mallinfo> getting the output
as a string (currently implemented through a temporary file).  On error it
returns C<undef> and sets errno C<$!>.

    my $str = Devel::Mallinfo::malloc_info_string(0)
      // die "Cannot get malloc_info(), error: $!";

The output is vaguely XML and has more detail than C<mallinfo()> gives.  If
doing a strict parse then note Glibc 2.10.1 and earlier missed some closing
quotes in the final "E<lt>systemE<gt>" elements.

=item C<$status = Devel::Mallinfo::malloc_trim ($bytes)>

Trim free space at the top of the arena down to C<$bytes>.  Return 1 if
memory was freed, 0 if not.  Normally C<free()> itself trims when there's
enough to be worth releasing, but if you think the C<keepcost> which is the
space there is too high then you can explicitly release some.

Glibc only frees whole pages (C<sysconf(_SC_PAGESIZE)> bytes), so if
reducing to C<$bytes> doesn't free at least one whole page then the return
will be 0.  Glibc also notices if something else in the program has
allocated memory with C<sbrk()> and it won't free that.

=back

=head1 BUGS

On a 64-bit system with a 32-bit C C<int> type, the C<int> fields in
C<struct mallinfo> may overflow and wrap around to small or negative values,
or maybe cap at C<INT_MAX>.  This is a known C library problem and
C<Devel::Mallinfo> doesn't try to do anything about it.

The C<mallopt()> function would be a logical companion to C<mallinfo()>, but
generally it must be called before the first ever C<malloc()>, so anything
at the Perl level is much too late.  Similarly C<mcheck()> to enable
consistency checks would have to be before the first ever C<malloc()>.

=head1 SEE ALSO

L<mallinfo(3)>, GNU C Library Manual "Statistics for Memory Allocation with
`malloc'"

L<Devel::Peek/Memory footprint debugging>, for statistics if using Perl's
builtin C<malloc()>

L<Memory::Usage>

=head1 HOME PAGE

http://user42.tuxfamily.org/devel-mallinfo/index.html

=head1 LICENSE

Devel-Mallinfo is Copyright 2007, 2008, 2009, 2010, 2011, 2014 Kevin Ryde

Devel-Mallinfo is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation; either version 3, or (at your option) any later
version.

Devel-Mallinfo is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Devel-Mallinfo.  If not, see <http://www.gnu.org/licenses/>.

=cut
