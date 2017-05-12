package IPC::ScoreBoard;

use 5.008008;
use strict;
use warnings;
use File::Map qw/:map/;
use Carp;

our $VERSION = '0.05';

require XSLoader;
XSLoader::load('IPC::ScoreBoard', $VERSION);

use constant {
  IVLEN=>length(pack "J", 0),
  MAGIC=>'PCSB',
};

# a slot is always a set of IVs.
# hence, $slotsize is given in units of IVLEN bytes.

sub anon {
  my ($class, $how_many, $slotsize, $score_extra);
  if( @_>3 or $_[0]!~/^\d/ ) {
    ($class, $how_many, $slotsize, $score_extra)=@_;
    $class=ref($class) || $class;
  } else {
    ($how_many, $slotsize, $score_extra)=@_;
    $class=__PACKAGE__;
  }

  use integer;
  $score_extra=0 unless defined $score_extra;

  my $slsz=$slotsize*IVLEN;
  map_anonymous my $scoreboard, (4+$how_many*$slotsize+$score_extra)*IVLEN;
  substr $scoreboard, 0, length(MAGIC), MAGIC;
  substr $scoreboard, IVLEN, 3*IVLEN,
    pack "J3", $how_many, $slotsize, $score_extra;

  return bless \$scoreboard, $class;
}

sub named {
  my ($class, $filename, $how_many, $slotsize, $score_extra);
  if( @_>4 or $_[1]!~/^\d/ ) {
    ($class, $filename, $how_many, $slotsize, $score_extra)=@_;
    $class=ref($class) || $class;
  } else {
    ($filename, $how_many, $slotsize, $score_extra)=@_;
    $class=__PACKAGE__;
  }

  use integer;
  $score_extra=0 unless defined $score_extra;

  open my $fh, '+>', $filename or croak "Cannot open $filename: $!";

  syswrite $fh, "\0" x((4+$how_many*$slotsize+$score_extra)*IVLEN);
  map_handle my $scoreboard, $fh, '+<';
  substr $scoreboard, 0, length(MAGIC), MAGIC;
  substr $scoreboard, IVLEN, 3*IVLEN,
    pack "J3", $how_many, $slotsize, $score_extra;

  return bless \$scoreboard, $class;
}

sub open {
  my ($class, $filename);
  if( @_>1 ) {
    ($class, $filename)=@_;
    $class=ref($class) || $class;
  } else {
    ($filename)=@_;
    $class=__PACKAGE__;
  }

  open my $fh, '+<', $filename or croak "Cannot open $filename: $!";
  map_handle my $scoreboard, $fh, '+<';

  croak "Invalid magic number in $filename"
    unless substr($scoreboard, 0, length(MAGIC)) eq MAGIC;

  return bless(\$scoreboard, $class), unpack 'x'.IVLEN.'J3', $scoreboard;
}

my $import_done;
sub import {
  return if @_>=2 and $_[1] eq ':noshortcuts';
  # create shortcuts
  return if $import_done;
  $import_done=1;
  no strict 'refs';
  for my $n (qw/anon named open get set incr decr sum get_all sum_all
		get_extra set_extra incr_extra decr_extra get_all_extra
		nslots slotsize nextra have_atomics offset_of/) {
    *{'SB::'.$n}=\&{$n};
  }
}

1;
__END__

=encoding utf8

=head1 NAME

IPC::ScoreBoard - IPC similar to the apache scoreboard

=head1 SYNOPSIS

 use IPC::ScoreBoard;

 # create an anonymous scoreboard
 my $sb=SB::anon $nslots, $slotsize, $extra;

 # create a file base board
 my $sb=SB::named $filename, $nslots, $slotsize, $extra;

 # open a file based board
 my ($sb, $nslots, $slotsize, $extra)=SB::open $filename;

 # set/set a value
 SB::set $sb, $slotidx, $elidx, $integer_value;
 $value=SB::get $sb, $slotidx, $elidx;
 @values=SB::get_all $sb, $slotidx;

 # increment/decrement
 SB::incr $sb, $slotidx, $elidx, $integer_value;
 SB::decr $sb, $slotidx, $elidx, $integer_value;

 # sum functions
 $sum=SB::sum $sb, $elidx;
 @sums=SB::sum_all $sb;

 # access extra space
 SB::set_extra $sb, $elidx, $integer_value;
 $value=SB::get_extra $sb, $elidx;
 @values=SB::get_all_extra $sb;

 SB::incr_extra $sb, $elidx, $integer_value;
 SB::decr_extra $sb, $elidx, $integer_value;

 # fetch parameters
 $nslots=SB::nslots $sb;
 $slotsize=SB::slotsize $sb;
 $nextra=SB::nextra $sb;

 # does the compiler provide atomic increment/decrement operations?
 if( SB::have_atomics ) {
   # increment and decrement operations are atomic
 }

=head1 DESCRIPTION

A scoreboard is a set of integer numbers residing in shared memory. It is
organized as 2-dimensional array where a line in one of the dimensions
is called a slot. So, in other words the scoreboard is a set of slots and
each slot is a set of integer numbers.

The idea is that in a system of processes or threads of execution each
process I<owns> a slot. A process can change the values in its own slot
at will but must adhere to read-only access to other slots.

There is one extra slot at the end of the scoreboard that is allowed to
be used by every process. However this module does not provide any kind
of locking to synchronize access.

The extra slot can differ in size from the other normal slots.

A scoreboard can be anonymous or it can have a name in the file system
and hence be accessed by unrelated processes.

=head2 What is that good for?

Suppose a system of processes that handle certain requests. Now, you want
to implement a monitor that shows the overall number of requests handled
so far by the system as a whole.

One way to do that is to use a shared variable that is incremented each
time a process has finished a request. But access to this variable has to
be synchronized by some type of locking. Otherwise 2 or even more processes
can read the shared variable at the same time. Then each of them increments
its own value and writes it back. In the end only the value written by the
last process hits the memory. All other increments are lost.

A lock free way could be to have each process increment its own variable.
Then the monitor would have to sum up all the variables of the processes.
But the system is now lock-free.

=head1 USAGE

A scoreboard object is a reference to a scalar. Its methods can be invoked
in the usual object style, C<< $sb->get(42,19) >>, or as subroutines,
C<< IPC::ScoreBoard::get $sb, 42, 19 >>. The latter variant is a bit faster
but involves a lot of typing.

To mitigate that all functions are exported to the C<< SB:: >> namespace
if the module is included via C<use>. If it is included via C<require>
nothing is exported. Neither is it if the parameter C<:noshortcuts> is
passed to C<use>:

 use IPC::ScoreBoard;                # generates shortcuts SB::get & co.
 use IPC::ScoreBoard ();             # no shortcuts
 use IPC::ScoreBoard ':noshortcuts'; # no shortcuts
 require IPC::ScoreBoard;            # no shortcuts

All data access functions throw an exception if access outside the boundaries
of the slot or scoreboard is tried.

The following section shows only the shortcut usage. Remember all functions
can also be called as

 $object_or_class->functionname(@param);

or as

 IPC::ScoreBoard::functionname $scoreboard, @param;

=head2 Scoreboard creation

=head3 SB::anon $nslots, $slotsize, $nextra

creates an anonymous scoreboard with space for C<$nslots> slots and
C<$slotsize> C<IV> values per slot. The extra slot contains C<$nextra>
C<IV> values.

C<anon> returns the scoreboard object.

In case of an error an exception is thrown.

Example:

 my $sb=IPC::ScoreBoard->anon($nslots, $slotsize, $nextra);
 my $sb=IPC::ScoreBoard::anon $nslots, $slotsize, $nextra;
 my $sb=SB::anon $nslots, $slotsize, $nextra;

=head3 SB::named $filename, $nslots, $slotsize, $nextra

similar to L<< C<anon>|/SB::anon $nslots, $slotsize, $nextra >>
but creates a named scoreboard with the name C<$filename>.

Example:

 my $sb=IPC::ScoreBoard->named($filename, $nslots, $slotsize, $nextra);
 my $sb=IPC::ScoreBoard::named $filename, $nslots, $slotsize, $nextra;
 my $sb=SB::named $filename, $nslots, $slotsize, $nextra;

=head3 SB::open $filename

similar to L<< C<anon>|/SB::anon $nslots, $slotsize, $nextra >>
but connects to or opens an existing named scoreboard with the name
C<$filename>.

Besides the scoreboard object the scoreboard parameters C<$nslots>,
C<$slotsize>, C<$nextra> are returned:

Example:

 my ($sb, $nslots, $slotsize, $extra)=IPC::ScoreBoard->open($filename);
 my ($sb, $nslots, $slotsize, $extra)=IPC::ScoreBoard::open $filename;
 my ($sb, $nslots, $slotsize, $extra)=SB::open $filename;

=head2 Data manipulation

=head3 SB::set $sb, $slotidx, $elidx, $value;

sets the C<$elidx>th (counting from C<0>) element in slot number C<$slotidx>
(also counting from C<0>) to C<$value>. C<$value> is interpreted as integer.

The new value is returned.

=head3 SB::get $sb, $slotidx, $elidx;

reads the value at position C<$elidx> in slot number C<$slotidx>.

=head3 SB::incr $sb, $slotidx, $elidx, $amount;

=head3 SB::decr $sb, $slotidx, $elidx, $amount;

these 2 functions increment or decrement the value at position C<$elidx>
in slot number C<$slotidx>. C<$amount> is optional. If ommitted C<1> is
used.

If supported by the compiler atomic operations are used to do that.
That means, even if multiple processes increment or decrement a certain
value in parallel nothing is lost as described in the
L<DESCRIPTION|/What is that good for?>.

The new value is returned.

=head3 SB::sum $sb, $elidx;

sums up the values at a position C<$elidx> over all slots (except for the
extra one).

=head3 SB::get_all $sb, $slotidx;

returns a list of all values of slot number C<$slotidx>.

=head3 SB::sum_all $sb;

returns a list of sums. The equivalent in perl could read:

 @sums=map { SB::sum $sb, $_ } 0..$slotsize;

=head3 SB::set_extra $sb, $elidx, $value;

sets the value at position C<$elidx> in the extra slot.

=head3 SB::get_extra $sb, $elidx;

reads the value at position C<$elidx> in the extra slot.

=head3 SB::incr_extra $sb, $elidx, $amount;

=head3 SB::decr_extra $sb, $elidx, $amount;

these 2 functions increment or decrement the value at position C<$elidx>
in the extra slot. C<$amount> is optional. If ommitted C<1> is used.

If supported by the compiler atomic operations are used to do that.
That means, even if multiple processes increment or decrement a certain
value in parallel nothing is lost as described in the
L<DESCRIPTION|/What is that good for?>.

The new value is returned.

=head3 SB::get_all_extra $sb;

returns the list of all values from the extra slot.

=head2 Auxiliary functions

=head3 SB::nslots $sb

returns the number of slots in the scoreboard

=head3 SB::slotsize $sb

returns the number of C<IV>s in each slot

=head3 SB::nextra $sb

returns the number of C<IV>s in the extra slot

=head3 SB::offset_of $sb, $slotidx, $elidx

converts a slotnumber and an index within the slot into a byte offset
from the beginning of the scoreboard.

If both C<$slotidx> and C<$elidx> are given the offset of the slot element
is returned. If C<$elidx> is ommitted or undefined C<$slotidx> is taken
as an element index within the extra slot:

 $sb->offset_of(2, 3);    # 3rd IV in 2nd slot
 SB::offset_of($sb, 3);   # 3rd IV of extra slot

This allows to store data other than integers.

Example:

 # store "hugo" in extra[2..4]
 substr($$sb, $sb->offset_of(2), 3*$ivlen, pack( "Z".(3*$ivlen), "hugo"));

 # retrieve "hugo"
 (unpack "x".$sb->offset_of(2)."Z*", $$sb)[0]

Notes on the example:

=over 4

=item *

Make sure the replacement string has exactly the length as given in the
3rd C<substr> parameter.

=item *

Don't use the lvalue form of C<substr>. It stores a reference to C<$$sb>
and hence if C<$$sb> goes out of scope the scoreboard won't be unmapped.

Don't do:

 substr($$sb, $sb->offset_of(2), 3*$ivlen)=pack( "Z".(3*$ivlen), "hugo");

=item *

Remember, the C<Z> pack format stores always a C<NULL> byte at the end of
the string. So, the example works because C<hugo> does not contain a
C<NULL> byte. If you need to store binary data a more sophisticated format
as C<W/a> could be used. But watch out for the maximum length.

=back

=head3 SB::have_atomics

returns true if C<IPC::ScoreBoard> has been compiled with a compiler that
supports atomic increment/decrement operations.

=head2 EXPORT

Nothing.

=head1 SEE ALSO

=over 4

=item * L<http://www.alexonlinux.com/multithreaded-simple-data-type-access-and-atomic-variables>

for more information about atomic operations

=item * L<File::Map>

the underlying memory mapper

=back

=head1 AUTHOR

Torsten Förtsch, E<lt>torsten.foertsch@gmx.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Torsten Förtsch

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
