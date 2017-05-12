#!/usr/bin/perl -w


# tell() in expanded bytes, so can go back to middle of an entry line
#
# catch next() errors as $! instead
# read directly without glob/regexp matching ?





# Copyright 2011 Kevin Ryde

# This file is part of File-Locate-Iterator.
#
# File-Locate-Iterator is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# File-Locate-Iterator is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with File-Locate-Iterator.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;

# uncomment this to run the ### lines
use Smart::Comments;

{
  package File::Locate::Iterator::TieHandle;
  use strict;
  use Carp;
  use File::Locate::Iterator;
  use vars '@ISA';
  @ISA = ('File::Locate::Iterator');

  sub TIEHANDLE {
    my $class = shift;
    ### FLI TIEHANDLE: @_
    my $self = $class->new (@_);
    $self->{'tie_buffer'} = '';
    return $self;
  }

  sub WRITE {
    my ($self, $buf, $len, $offset) = @_;
    require POSIX;
    $! = POSIX::EBADF();
    return undef;

    $self->PRINT (substr($buf,$offset,$len));
  }
  sub PRINT {
    my $self = shift;
    require POSIX;
    $! = POSIX::EBADF();
    return undef;

    while (@_) {
      $self->{'writebuf'} .= shift;
      while (my $pos = index ($\, $self->{'writebuf'})) {
        my $entry = substr($self->{'writebuf'}, 0, $pos);
        $self->{'writebuf'} = substr($self->{'writebuf'}, $pos+length($\));

        if (length $entry > 32767) {
          require POSIX;
          $! = POSIX::EINVAL();
          return undef;
        }

        my $common_len = string_common($entry, $self->{'prev'});
        my $delta = $common_len - $self->{'prev_len'};
        $self->{'prev'} = substr ($entry, $common_len);
        $self->{'prev_len'} = $common_len;

        print ($delta > 127 || $delta < -127
               ? "\x80", pack('n',$delta)
               : pack('c',$delta)),
                 substr($entry,$common_len),"\0"
                   or return undef;
      }
    }
  }
  sub PRINTF {
    my $self = shift;
    my $fmt = shift;
    $self->PRINT (sprintf($fmt, @_));
  }

  sub READ {
    my ($self, undef, $buflen, $offset) = @_;
    ### FLI READ ...
    my $retlen = 0;
    while ($retlen < $buflen) {
      my $tb = $self->{'tie_buffer'};
      while (length($tb) == 0) {
        $tb = $self->next;
        if (! defined $tb) {
          ### eof: $retlen
          $self->{'tell'} += $retlen;
          return $retlen;
        }
        if (defined $/) {
          $tb .= $/;
        }
      }

      if (! defined ($_[1])) {
        $_[1] = '';
      }
      if (length($_[1]) < $offset) {
        $_[1] .= "\0" x ($offset - length($_[1]));
      }

      if ($retlen + length($tb) > $buflen) {
        ### return part of tb
        substr ($_[1], $offset+$retlen) = substr($tb, 0, $buflen-$retlen);
        $self->{'tie_buffer'} = substr ($tb, $buflen-$retlen);
        ### buf: $_[1]
        $self->{'tell'} += $buflen;
        return $buflen;
      }
      ### all of tb
      substr ($_[1], $offset+$retlen) = $tb;
      $self->{'tie_buffer'} = '';
      ### buf: $_[1]
    }
  }

  sub GETC {
    my ($self) = @_;
    ### FLI GETC
    my $tb = $self->{'tie_buffer'};
    while (length($tb) == 0) {
      $tb = $self->next;
      if (! defined $tb) {
        ### eof
        return undef;
      }
      if (defined $/) {
        $tb .= $/;
      }
    }
    $self->{'tie_buffer'} = substr ($tb, 1);
    $self->{'tell'}++;
    return substr($tb, 0, 1);
  }

  sub READLINE {
    my ($self) = @_;
    ### FLI READLINE

    if (wantarray) {
      my @ret;
      if (length(my $tb = $self->{'tie_buffer'})) {
        $self->{'tie_buffer'} = '';
        @ret = ($tb);
      }
      while (defined (my $tb = $self->next)) {
        if (defined $/) {
          $tb .= $/;
        }
        push @ret, $tb;
      }
      return @ret; # empty at eof

    } else {
      my $ret;
      if (length($ret = $self->{'tie_buffer'})) {
        $self->{'tie_buffer'} = '';
      } else {
        $ret = $self->next;
        if (defined $ret && defined $/) {
          $ret .= $/;
        }
      }
      $self->{'tell'} += length($ret);
      return $ret; # undef at eof
    }
  }
  # my $x = 23;
  #   $r = \$x;
  # sub READLINE {
  #   my $r = shift;
  #   if (wantarray) {
  #     return ("all remaining\n",
  #             "lines up\n",
  #             "to eof\n");
  #   } else {
  #     return "READLINE called $$r times\n";
  #   }
  # }

  sub CLOSE {
    my ($self) = @_;
    delete $self->{'fh'};
    delete $self->{'fm'};
    delete $self->{'mref'};
  }

  sub FILENO {
    my ($self) = @_;
    if (my $fh = $self->{'fh'}) {
      return fileno($fh);
    }
    return undef;
  }
  sub EOF {
    my ($self) = @_;
    ### FLI EOF()
    if (length($self->{'tie_buffer'})) {
      return 0;
    }
    if (my $fh = $self->{'fh'}) {
      return eof($fh);
    } else {
      return ($self->{'pos'} < length(${$self->{'mref'}}));
    }
  }

  sub SEEK {
    my ($self, $position, $whence) = @_;
    my $target;
    if ($whence == 2) {
      ### SEEK_END

      $self->{'tell'} += length($self->{'tie_buffer'});
      $self->{'tie_buffer'} = '';
      my $rslen = (defined $/ ? length($/) : 0);
      while (defined (my $entry = $self->next)) {
        $self->{'tell'} += length($entry) + $rslen;
      }
      $position = $self->{'tell'} - $position;  # to absolute

    } elsif ($whence == 1) {
      ### SEEK_CUR, relative
      $position += $self->{'tell'};   # to absolute

    } else { # $whence == 0
      ### SEEK_SET, absolute already
    }

    if ($position < $self->{'tell'}) {
      # backwards, re-read whole file
      $self->rewind;
      $self->{'tell'} = 0;
    }

    my $tb = $self->{'tie_buffer'};
    while ((my $more = $position - $self->{'tell'}) > 0) {
      if (length($tb) >= $more) {
        $self->{'tell'} += $more;
        $self->{'tie_buffer'} = substr($tb,$more);
        return 1; # successful
      }
      $self->{'tell'} += length($tb);
      if (! defined ($tb = $self->next)) {
        $self->{'tie_buffer'} = '';
        $! = POSIX::EINVAL();  # past end of file
        return 0;
      }
    }
  }
  sub TELL {
    my ($self) = @_;
    return $self->{'tell'};
  }

  sub BINMODE {
    my ($self) = @_;
    if (my $fh = $self->{'fh'}) {
      return binmode($fh);
    } else {
      # turn off utf8 on $self->{'mref'} ?
    }
  }

  sub OPEN {
    # my ($self, $mode, ...) = @_;
    croak "Cannot re-open ".__PACKAGE__;
  }
}

use Smart::Comments;
{
  tie *FH, 'File::Locate::Iterator::TieHandle',
    use_mmap => 1,
      database_file => 't/samp.locatedb',
        ;
  open FH, '</etc/motd' or die $!;

  { my $eof = eof(FH);
    ### $eof
  }
  while (defined (readline(FH))) { } # to eof
  { my $eof = eof(FH);
    ### $eof
  }
  my $entry = readline(FH);
  ### $entry
  $entry = readline(FH);
  ### $entry
  my @entries = readline(FH);
  ### @entries
  exit 0;
}
 
{
  tie *FH, 'File::Locate::Iterator::TieHandle',
    use_mmap => 0,
      database_file => 't/samp.locatedb',
        ;
  my $fileno = fileno(FH);
  my $pos = tell(FH);
  ### $fileno
  ### $pos
  my $line = <FH>;
  ### $line
  $line = <FH>;
  ### $line

  my $buf; # = 'x';
  my $ret = read(FH,$buf,2,3);
  ### $ret
  ### $buf

  my $c = getc(FH);
  ### $c
  $c = getc(FH);
  ### $c
  # $line = <FH>;
  # ### $line

  $pos = tell(FH);
  ### $pos
  my @entries = readline(FH);
  ### @entries
  exit 0;
}
{
  open FH, '</etc/passwd' or die;
  my $buf;
  my $ret = read(FH,$buf,8,3);
  ### $ret
  ### $buf

  print <FH>;
  exit 0;
}



1;
__END__

=for stopwords filename filenames filesystem slocate filehandle arrayref mmap mmaps seekable PerlIO mmapped XSUB coroutining fd Findutils Ryde wildcard charset wordsize wildcards

=head1 NAME

File::Locate::Iterator::TieHandle -- file handle tied to read "locate" database

=head1 SYNOPSIS

 use File::Locate::Iterator::TieHandle;
 tie *FH, 'File::Locate::Iterator::TieHandle';
 while (defined (my $line = <FH>)) {
   chomp $line;
   print "entry is \"$line\"\n";
 }

=head1 DESCRIPTION

C<File::Locate::Iterator::TieHandle> ties a file handle to read entries from
a "locate" database file.  Each C<readline()> returns an entry from the
database.  C<read()> and C<getc()> can also be used.  Writing is not
implemented (as yet).

Each entry has the input record separator C<$/> appended (see L<perlvar>) as
if it was a line from an ordinary file.  This can be stripped with C<chomp>
etc in the usual way (see L<perlfunc/chomp>.

=head2 C<seek> and C<tell>

C<tell> gives the current database position in bytes.  Normally the only use
for this is to pass to C<seek> to go back to that position again.

C<seek> works as long as the underlying locate database file or handle is
seekable, as per C<rewind()> of L<File::Locate::Iterator/Operations>.

Seeking back to the start of the file is simply an iterator C<rewind>.
Seeking back by a small amount is slow in the current implementation because
the database must be re-read from the start to the target position, but at
least it works.

=head1 SEE ALSO

L<File::Locate::Iterator>, L<perltie>

=head1 HOME PAGE

http://user42.tuxfamily.org/file-locate-iterator/index.html

=head1 COPYRIGHT

Copyright 2011 Kevin Ryde

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
