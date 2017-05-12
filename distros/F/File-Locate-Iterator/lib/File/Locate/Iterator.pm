# Copyright 2009, 2010, 2011, 2012, 2013, 2014 Kevin Ryde.
#
# This file is part of File-Locate-Iterator.
#
# File-Locate-Iterator is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option)
# any later version.
#
# File-Locate-Iterator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with File-Locate-Iterator; see the file COPYING.  Failing that, go to
# <http://www.gnu.org/licenses/>.


# Maybe:
#     ignore_case
#     glob_ignore_case
#     suffix_ignore_case
#


package File::Locate::Iterator;
use 5.006;  # for qr//, and open anon handles
use strict;
use warnings;
use Carp;

use DynaLoader;
our @ISA = ('DynaLoader');

our $VERSION = 23;

# uncomment this to run the ### lines
#use Devel::Comments;


if (eval { __PACKAGE__->bootstrap($VERSION) }) {
  ### FLI next() from XS
} else {
  ### FLI next() in perl, XS didn't load: $@

  eval "\n#line ".(__LINE__+1)." \"".__FILE__."\"\n" . <<'HERE' or die;
use strict;
use warnings;
use File::FnMatch;

sub _UNEXPECTED_EOF {
  my ($self) = @_;
  undef $self->{'entry'};
  croak 'Invalid database contents (unexpected EOF)';
}
sub _ERROR_READING {
  my ($self) = @_;
  undef $self->{'entry'};
  croak 'Error reading database: ',$!;
}
sub _BAD_SHARE {
  my ($self, $sharelen) = @_;
  undef $self->{'entry'};
  croak "Invalid database contents (bad share length $sharelen)";
}
sub next {
  my ($self) = @_;
  ### FLI PP next()

  my $sharelen = $self->{'sharelen'};
  my $entry = $self->{'entry'};
  my $regexp = $self->{'regexp'};
  my $globs = $self->{'globs'};

  if (my $mref = $self->{'mref'}) {
    my $pos = $self->{'pos'};
  MREF_LOOP: for (;;) {
      #### pos in map: sprintf('%#x', $pos)
      if ($pos >= length ($$mref)) {
        undef $self->{'entry'};
        return; # end of file
      }

      my ($adjshare) = unpack 'c', substr ($$mref, $pos++, 1);
      if ($adjshare == -128) {
        #### 2byte pos: sprintf('%#X', $pos)
        # print ord(substr ($$mref,$pos,1)),"\n";
        # print ord(substr ($$mref,$pos+1,1)),"\n";

        if ($pos+2 > length ($$mref)) { goto &_UNEXPECTED_EOF; }

        # for perl 5.10 up could use 's>' for signed 16-bit big-endian,
        # instead of getting unsigned and stepping down
        ($adjshare) = unpack 'n', substr ($$mref, $pos, 2);
        if ($adjshare >= 32768) { $adjshare -= 65536; }

        $pos += 2;
      }
      ### $adjshare
      $sharelen += $adjshare;
      # print "share now $sharelen\n";
      if ($sharelen < 0 || $sharelen > length($entry)) {
        push @_, $sharelen; goto &_BAD_SHARE;
      }

      my $end = index ($$mref, "\0", $pos);
      # print "$pos to $end\n";
      if ($end < 0) { goto &_UNEXPECTED_EOF; }

      $entry = (substr($entry,0,$sharelen)
                . substr ($$mref, $pos, $end-$pos));
      $pos = $end + 1;

      if ($regexp) {
        last if $entry =~ $regexp;
      } elsif (! $globs) {
        last;
      }
      if ($globs) {
        foreach my $glob (@$globs) {
          last MREF_LOOP if File::FnMatch::fnmatch($glob,$entry)
        }
      }
    }
    $self->{'pos'} = $pos;

  } else {
    local $/ = "\0"; # readline() to \0

    my $fh = $self->{'fh'};
    ### pos tell(fh): sprintf('%#x',tell($fh))
  IO_LOOP: for (;;) {
      my $adjshare;
      unless (my $got = read $fh, $adjshare, 1) {
        if (defined $got) {
          undef $self->{'entry'};
          return; # EOF
        }
        goto &_ERROR_READING;
      }

      ($adjshare) = unpack 'c', $adjshare;
      if ($adjshare == -128) {
        my $got = read $fh, $adjshare, 2;
        if (! defined $got) { goto &_ERROR_READING; }
        if ($got != 2) { goto &_UNEXPECTED_EOF; }

        # for perl 5.10 up could use 's>' for signed 16-bit big-endian
        # pack, instead of getting unsigned and stepping down
        ($adjshare) = unpack 'n', $adjshare;
        if ($adjshare >= 32768) { $adjshare -= 65536; }
      }
      ### $adjshare

      $sharelen += $adjshare;
      ### share now: $sharelen
      if ($sharelen < 0 || $sharelen > length($entry)) {
        push @_, $sharelen; goto &_BAD_SHARE;
      }

      my $part;
      {
        # perlfunc.pod of 5.10.0 for readline() says you can clear $!
        # then check it afterwards for an error indication, but that's
        # wrong, $! ends up set to EBADF when filling the PerlIO buffer,
        # which means if the readline crosses a 1024 byte boundary
        # (something in attempting a fast gets then falling back ...)

        $part = readline $fh;
        if (! defined $part) { goto &_UNEXPECTED_EOF; }

        ### part: $part
        chomp $part or goto &_UNEXPECTED_EOF;
      }

      $entry = substr($entry,0,$sharelen) . $part;

      if ($regexp) {
        last if $entry =~ $regexp;
      } elsif (! $globs) {
        last;
      }
      if ($globs) {
        foreach my $glob (@$globs) {
          last IO_LOOP if File::FnMatch::fnmatch($glob,$entry)
        }
      }
    }
  }

  $self->{'sharelen'} = $sharelen;
  return ($self->{'entry'} = $entry);
}

1;

HERE
}

use constant default_use_mmap => 'if_sensible';
my $header = "\0LOCATE02\0";


# Default path these days is /var/cache/locate/locatedb.
#
# Back in findutils 4.1 it was $(localstatedir)/locatedb, but there seems to
# have been no way to ask about the location.
#
sub default_database_file {
  # my ($class) = @_;
  if (defined (my $env = $ENV{'LOCATE_PATH'})) {
    return $env;
  } else {
    return '/var/cache/locate/locatedb';
  }
}

# The fields, all meant to be private, are:
#
# regexp
#     qr// regexp of all the 'regexp', 'regexps', 'suffix' and 'suffixes'
#     parameters.  If no such matches then no such field.  When the field
#     exists an entry must match the regexp or is skipped.
#
# globs
#     arrayref of strings which are globs to fnmatch().  If no globs then no
#     such field.  When the field exists an entry must match at least one of
#     the globs.
#
# mref
#     Ref to a scalar which holds the database contents, or undef if using
#     fh instead.  It's either a ref to the 'database_str' parameter passed
#     in, or a ref to a scalar created as an mmap of the file.  The mmap one
#     is shared among iterators through the File::Locate::Iterator::FileMap
#     caching.
#
# fh
#     When mref is undef, ref file handle which is to be read from,
#     otherwise no such field.  This can be either the 'database_fh'
#     parameter or an opened anonymous handle of the 'database_file'
#     parameter.
#
#     When mmap is used the 'database_fh' is not held here.  The mmap is
#     made (or rather, looked up in the FileMap cache), and the handle is
#     then no longer needed and can be closed or garbage collected in the
#     caller.
#
# fh_start
#     When fh is set, the tell($fh) position just after the $header in that
#     fh.  This is where to seek() back to for a $it->rewind.  If tell()
#     failed then this is -1 and $it->rewind is not possible.
#
#     Normally fh_start is simply length($header) for a database starting at
#     the start of the file, but a database_fh arg which is positioned at
#     some offset into a file can be read and remembering an fh_start
#     position lets $it->rewind work on it too.
#
# fm
#     When using mmap, a File::Locate::Iterator::FileMap object which is the
#     cache entry for the database file, otherwise no such field.  This is
#     hung onto to keep it alive while in use.  $self->{'mref'} is
#     $fm->mmapref in this case.
#
# pos
#     When mref is not undef, an integer offset into the $$mref string which
#     is the current read position.  The file header is checked in new() so
#     the initial value is length($header), ie. 10, the position of the
#     first entry (or possibly EOF).
#
# entry
#     String of the last database entry returned, or no such field before
#     the first is read, or undef after EOF is hit.  Might be undef instead
#     of not existing if a hypothetical seek() goes back to the start of the
#     file.
#
# sharelen
#     Integer which is the number of leading bytes of 'entry' which the next
#     entry will share with that previous entry.  Initially 0.
#
#     This is modified successively by the "adjshare" of each entry as each
#     takes more or less of the preceding entry.  An adjshare can range from
#     -sharelen to take nothing at all of the previous entry, up to
#     length($entry)-sharelen to increment up to take all of the previous
#     entry.
#
sub new {
  my ($class, %options) = @_;
  ### FLI new(): %options

  # delete 'regexp' field if it's undef, as the XS code wants no 'regexp'
  # field for no regexps, not a field set to undef
  my @regexps;
  if (defined (my $regexp = delete $options{'regexp'})) {
    push @regexps, $regexp;
  }
  if (my $regexps = delete $options{'regexps'}) {
    push @regexps, @$regexps;
  }
  foreach my $suffix (defined $options{'suffix'} ? $options{'suffix'} : (),
                      @{$options{'suffixes'}}) {
    push @regexps, quotemeta($suffix) . '$';
  }
  ### @regexps

  # as per findutils locate.c locate() function, pattern with * ? or [ is a
  # glob, anything else is a literal match
  #
  my @globs = (defined $options{'glob'} ? $options{'glob'} : (),
               @{$options{'globs'} || []});
  @globs = grep { ($_ =~ /[[*?]/
                   || do { push @regexps, quotemeta($_); 0 })
                } @globs;
  ### @globs

  my $self = bless { entry    => '',
                     sharelen => 0,
                   }, $class;

  if (@regexps) {
    my $regexp = join ('|', @regexps);
    $self->{'regexp'} = qr/$regexp/s;
  }
  if (@globs) {
    $self->{'globs'} = \@globs;
  }

  ### regexp: $self->{'regexp'}
  ### globs : $self->{'globs'}

  if (defined (my $ref = $options{'database_str_ref'})) {
    $self->{'mref'} = $ref;

  } elsif (defined $options{'database_str'}) {
    $self->{'mref'} = \$options{'database_str'};

  } else {
    my $use_mmap = (defined $options{'use_mmap'}
                    ? $options{'use_mmap'}
                    : $class->default_use_mmap);
    ### $use_mmap
    if ($use_mmap) {
      if (! eval { require File::Locate::Iterator::FileMap }) {
        ### FileMap not possible: $@
        $use_mmap = 0;
      }
    }

    my $fh = $options{'database_fh'};
    if (defined $fh) {
      if ($use_mmap eq 'if_sensible'
          && File::Locate::Iterator::FileMap::_have_mmap_layer($fh)) {
        ### already have mmap layer, not sensible to mmap again
        $use_mmap = 0;
      }
    } else {
      my $file = (defined $options{'database_file'}
                  ? $options{'database_file'}
                  : $class->default_database_file);
      ### open database_file: $file

      # Crib note: '<:raw' means without :perlio buffering, whereas
      # binmode() preserves that buffering, assuming it's in the $ENV{'PERLIO'}
      # defaults.  Also :raw is not available in perl 5.6.
      open $fh, '<', $file
        or croak "Cannot open $file: $!";
      binmode($fh)
        or croak "Cannot set binary mode";
    }

    if ($use_mmap eq 'if_sensible') {
      $use_mmap = (File::Locate::Iterator::FileMap::_mmap_size_excessive($fh)
                   ? 0
                   : 'if_possible');
      ### if_sensible after size check becomes: $use_mmap
    }

    if ($use_mmap) {
      ### attempt mmap: $fh, (-s $fh)

      # There's many ways an mmap can fail, just chuck an eval on FileMap /
      # File::Map it to catch them all.
      # - An ordinary readable file of length zero may fail per POSIX, and
      #   that's how it is in linux kernel post 2.6.12.  However File::Map
      #   0.20 takes care of returning an empty string for that.
      # - A char special usually gives 0 for its length, even for instance
      #   linux kernel special files like /proc/meminfo.  Char specials can
      #   often be mapped perfectly well, but without a length don't know
      #   how much to look at.  For that reason "if_possible" restricts to
      #   ordinary files, though forced "use_mmap=>1" just goes ahead anyway.
      #
      if ($use_mmap eq 'if_possible') {
        if (! -f $fh) {
          ### if_possible, not a plain file, consider not mmappable
        } else {
          if (! eval { $self->{'fm'}
                         = File::Locate::Iterator::FileMap->get($fh) }) {
            ### mmap failed: $@
          }
        }
      } else {
        $self->{'fm'} = File::Locate::Iterator::FileMap->get($fh);
      }
    }
    if ($self->{'fm'}) {
      $self->{'mref'} = $self->{'fm'}->mmap_ref;
    } else {
      $self->{'fh'} = $fh;
    }
  }

  if (my $mref = $self->{'mref'}) {
    unless ($$mref =~ /^\Q$header/o) { goto &_ERROR_BAD_HEADER }
    $self->{'pos'} = length($header);
  } else {
    my $got = '';
    read $self->{'fh'}, $got, length($header);
    if ($got ne $header) { goto &_ERROR_BAD_HEADER }
    $self->{'fh_start'} = tell $self->{'fh'};
  }

  return $self;
}
sub _ERROR_BAD_HEADER {
  croak 'Invalid database contents (no LOCATE02 header)';
}

sub rewind {
  my ($self) = @_;

  $self->{'sharelen'} = 0;
  $self->{'entry'} = '';
  if ($self->{'mref'}) {
    $self->{'pos'} = length($header);
  } else {
    $self->{'fh_start'} > 0
      or croak "Cannot seek database";
    seek ($self->{'fh'}, $self->{'fh_start'}, 0)
      or croak "Cannot seek database: $!";
  }
}

# return true if mmap is in use
# (an actual mmap, not the slightly similar 'database_str' option)
# this is meant for internal use as a diagnostic ...
sub _using_mmap {
  my ($self) = @_;
  return defined $self->{'fm'};
}

# Not yet documented, likely worthwhile as long as it works properly.
# Return empty list for nothing yet?  Same as next().
# Return empty list at EOF?  At EOF 'entry' is undefed out.
#
# =item C<< $entry = $it->current >>
#
# Return the current entry from the database, meaning the same as the last
# call to C<next> returned.  At the start of the database (before the first
# C<next>) or at end of the database the return is an empty list.
#
#     while (defined $it->next) {
#         ...
#         print $it->current,"\n";
#     }
#
sub _current {
  my ($self) = @_;
  if (defined $self->{'entry'}) {
    return $self->{'entry'};
  } else {
    return;
  }
}


1;
__END__

=for stopwords filename filenames filesystem slocate filehandle arrayref mmap mmaps seekable PerlIO mmapped XSUB coroutining fd Findutils Ryde wildcard charset wordsize wildcards Taintedness taintedness untaint ie

=head1 NAME

File::Locate::Iterator -- read "locate" database with an iterator

=head1 SYNOPSIS

 use File::Locate::Iterator;
 my $it = File::Locate::Iterator->new;
 while (defined (my $entry = $it->next)) {
   print $entry,"\n";
 }

=head1 DESCRIPTION

C<File::Locate::Iterator> reads a "locate" database file in iterator style.
Each C<next()> call on the iterator returns the next entry from the
database.

    /
    /bin
    /bin/bash
    /bin/cat

Locate databases normally hold filenames as a way of finding files by name
faster than searching through all directories.  Optional glob, suffix and
regexp options on the iterator can restrict the entries returned.

See F<examples/native.pl> in the File-Locate-Iterator sources for a simple
sample read, or F<examples/mini-locate.pl> for a whole locate program
simulation.

Only "LOCATE02" format files are supported, as per current versions of GNU
C<locate>, not the previous "slocate" format.

Iterators from this module are stand-alone, they don't need any of the
various Perl iterator frameworks.  But see L<Iterator::Locate>,
L<Iterator::Simple::Locate> and L<MooseX::Iterator::Locate> to inter-operate
with those frameworks.  Those frameworks include ways to grep, map and
otherwise manipulate iterations.

=head2 Forks and Threads

If an iterator using a file handle is cloned to a new thread or a process
level C<fork()> then generally it can be used by the parent or the child but
not both.  The underlying file descriptor position is shared by parent and
child, so when one of them reads it upsets the position for the other.  This
sort of thing affects almost all code working with file handles across
C<fork()> and threads.  Perhaps some thread C<CLONE> code could let threads
work correctly (but slower), but a C<fork()> is probably doomed.

Iterators using C<mmap> work correctly for both forks and threads, except
that the size calculation and sharing for C<if_sensible> is not thread-aware
beyond the mmaps existing when the thread is spawned.  C<File::Map> knows
the mmaps across all threads, but does not reveal them.

=head2 Taint Mode

Under taint mode (see L<perlsec/Taint mode>), strings read from a file or
file handle are always tainted, the same as other file input.  Taintedness
of a C<database_str> string propagates to the entry strings returned.

For C<database_str_ref> the initial taintedness of the database string
propagates to the entries.  If you untaint it during iteration then
subsequent entries returned are still tainted because they may depend on the
data back from when the input was tainted.  A C<rewind()> will reset to the
new taintedness of the database string though.

For reference, taint mode is only a small slowdown for the XS iterator code,
and usually (it seems) only a little more for the pure Perl.

=head2 Other Notes

The locate database format is only designed to be read forwards, hence no
C<prev()> method on the iterator.  The start of a previous record can't be
distinguished by its content, and the "front coding" means the state at a
given point may depend on records an arbitrary distance back too.  A "tell"
which gave file position plus state would be possible, though perhaps a
"clone" of the whole iterator would be more use.

On some systems C<mmap()> may be a bit too effective, giving a process more
of the CPU than other processes which make periodic C<read()> system calls.
This is a matter of OS scheduling, but you might have to turn down the
C<nice> or C<ionice> if doing a lot of mmapped work (see L<nice(1)>,
L<ionice(1)>, L<perlfunc/setpriority>, and L<ioprio_set(2)>).

=head1 FUNCTIONS

=head2 Constructor

=over 4

=item C<< $it = File::Locate::Iterator->new (key=>value,...) >>

Create and return a new locate database iterator object.  The following
optional key/value pairs can be given,

=over 4

=item C<database_file> (filename)

=item C<database_fh> (handle ref)

The file to read, either as filename or file handle.  The default file is
the C<default_database_file()> below.

    $it = File::Locate::Iterator->new
            (database_file => '/foo/bar.db');

A filehandle is read with the usual C<PerlIO> so it can use layers and come
from various sources, but it should be in binary mode (see
L<perlfunc/binmode> and L<PerlIO/:raw>).

=item C<database_str> (string)

=item C<database_str_ref> (ref to string)

The database contents to read in the form of a byte string.

    $it = File::Locate::Iterator->new
      (database_str => "\0LOCATE02\0\0/hello\0\006/world\0");

C<database_str> is copied in the iterator.  C<database_str_ref> can be used
to act on a given scalar without copying,

    my $str = "\0LOCATE02\0\0/hello\0\006/world\0";
    $it = File::Locate::Iterator->new
            (database_str_ref => \$str);

For C<database_str_ref> if the originating scalar is tied or has other magic
then that is re-run for each access, in the usual way.  This might be a good
thing, or you might prefer the copying of C<database_str> in that case.

=item C<suffix> (string)

=item C<suffixes> (arrayref of strings)

=item C<glob> (string)

=item C<globs> (arrayref of strings)

=item C<regexp> (string or regexp object)

=item C<regexps> (arrayref of strings or regexp objects)

Restrict the entries returned to those with given suffix(es) or matching the
given glob(s) or regexp(s).  For example,

    # C code files on the system, .c and .h
    $it = File::Locate::Iterator->new
            (suffixes => ['.c','.h']);

If multiple patterns or suffixes are given then matches of all of them are
returned.

Globs are in the style of the C<locate> program which means C<fnmatch> with
no options (see L<File::FnMatch>).  The match is on the full entry if
there's wildcards ("*", "?" or "["), or any part if the pattern is a fixed
string.

    glob => '*.c'  # .c files, no .cxx files
    glob => '.c'   # fixed str, foo.cxx matches too

Globs should be byte strings (not wide chars) since that's how the database
entries are handled.  Suspect C<fnmatch> has no notion of charset coding for
its strings and patterns.

=item C<use_mmap> (string, default "if_sensible")

Whether to use C<mmap()> to access the database.  C<mmap> is fast and
resource-efficient, when available.  To use mmap you must have the
C<File::Map> module (version 0.38 or higher), the file must fit in available
address space, and for a C<database_fh> handle there mustn't be any
transforming C<PerlIO> layers.  The C<use_mmap> choices are

    undef           \
    "default"       | use mmap if sensible
    "if_sensible"   /
    "if_possible"   use mmap if possible, otherwise file I/O
    0               don't use mmap
    1               must use mmap, croak if cannot
    

Setting C<default>, C<undef> or omitted means C<if_sensible>.
C<if_sensible> uses mmap if available, and the file size is reasonable, and
for C<database_fh> if it isn't already using an C<:mmap> layer.
C<if_possible> uses mmap whenever it can be done, without those qualifiers.

    $it = File::Locate::Iterator->new
            (use_mmap => 'if_possible');

When multiple iterators access the same file they share the mmap.  The size
check for C<if_sensible> counts space in all distinct
C<File::Locate::Iterator> mappings and won't go beyond 1/5 of available data
space.  Data space is assumed to be a quarter of the wordsize, so for a
32-bit system a net mmap total at most 200Mb.

C<if_possible> and C<if_sensible> both only mmap ordinary files because
generally the file size on char specials is not reliable.

=back

=item C<< $filename = File::Locate::Iterator->default_database_file() >>

Return the default database file used for C<new> above.  This is meant to be
the same as the C<locate> program uses and currently means

    $ENV{'LOCATE_PATH'}            if that env var set
    /var/cache/locate/locatedb     otherwise

Perhaps in the future it might be possible to check how C<findutils> has
been installed rather than assuming F</var/cache/locate/>.

=back

=head2 Operations

=over 4

=item C<< $entry = $it->next() >>

Return the next entry from the database, or no values at end of file.  No
values means C<undef> in scalar context or an empty list in array context so
you can loop with either

    while (defined (my $filename = $it->next)) ...

or

    while (my ($filename) = $it->next) ...

The return is a byte string since it's normally a filename and Perl handles
filenames as byte strings.

=item C<< $it->rewind() >>

Rewind C<$it> back to the start of the database.  The next C<$it-E<gt>next>
call will return the first entry.

This is only possible when the underlying database file or handle is
seekable, ie. C<seek()> works, which will usually mean a plain file, or
PerlIO layers with seek support.

=back

=head1 ENVIRONMENT VARIABLES

=over 4

=item C<LOCATE_PATH>

Default locate database.

=back

=head1 FILES

=over 4

=item F</var/cache/locate/locatedb>

Default locate database, if C<LOCATE_PATH> environment variable not set.

=back

=head1 OTHER WAYS TO DO IT

C<File::Locate> reads a locate database with callbacks instead.  Whether you
want callbacks or an iterator is generally a matter of personal preference.
Iterators let you write your own loop and can have multiple searches in
progress simultaneously.

The speed of an iterator is about the same as callbacks when
C<File::Locate::Iterator> is built with its XSUB code (which requires Perl
5.10.0 or higher currently).

Iterators are good for cooperative coroutining like C<POE> or C<Gtk> where
state must be held in some sort of variable to be progressed by calls from
the main loop.  Note that C<next()> will block on reading from the database,
so the database should generally be a plain file rather than a socket or
something, so as not to hold up a main loop.

If you have the recommended C<File::Map> module then iterators share an
C<mmap()> of the database file.  Otherwise the database file is a separate
open handle in each iterator, meaning a file descriptor and PerlIO buffering
each.  Sharing a handle and having each seek to its desired position would
be possible, but a seek drops buffered data and so would be slower.  Some
C<PerlIO> or C<IO::Handle> trickery might transparently share an fd and keep
buffered blocks from multiple file positions.

=head1 SEE ALSO

L<Iterator::Locate>, L<Iterator::Simple::Locate>,
L<MooseX::Iterator::Locate>

L<File::Locate>, L<locate(1)>, L<locatedb(5)>, GNU Findutils manual,
L<File::FnMatch>, L<File::Map>

=head1 HOME PAGE

http://user42.tuxfamily.org/file-locate-iterator/index.html

=head1 COPYRIGHT

Copyright 2009, 2010, 2011, 2012, 2013, 2014 Kevin Ryde

File-Locate-Iterator is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

File-Locate-Iterator is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
File-Locate-Iterator.  If not, see http://www.gnu.org/licenses/

=cut
