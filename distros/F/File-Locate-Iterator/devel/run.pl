#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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
use Carp;
use File::Locate::Iterator;

# uncomment this to run the ### lines
use Smart::Comments;

{
  use warnings 'layer';
  require File::Map;
  print "File::Map version ", File::Map->VERSION, "\n";

  my $use_mmap = 'if_possible';

  my $filename = File::Locate::Iterator->default_database_file;

  my $mode = '<:encoding(iso-8859-1)';
#   $mode = '<:utf8';
#   $mode = '<:raw';
#   $mode = '<:mmap';
  open my $fh, $mode, $filename
    or die;

  { local $,=' '; print "layers ", PerlIO::get_layers($fh), "\n"; }

  my $it = File::Locate::Iterator->new (database_fh => $fh,
                                        use_mmap => $use_mmap,
                                       );
  ### keys: keys %$it
  print exists $it->{'fm'} ? "using mmap\n" : "using fh\n";

  exit 0;
}


{
  my $it = File::Locate::Iterator->new
            (database_str => "\0LOCATE02\0\0/hello\0\006/world\0");
  print $it->next,"\n";
  print $it->next,"\n";
  print $it->next,"\n";
  exit 0;
}

{
  require Config;
  $Config::Config{useithreads}
    or die 'No ithreads in this Perl';
  eval { require threads } # new in perl 5.8, maybe
    or die "threads.pm not available -- $@";

  my $filename = 't/samp.locatedb';
  my $it = File::Locate::Iterator->new (database_file => $filename,
                                        use_mmap => 1);
  print "main   it: ",$it,"\n";
  print "main   fm: ",$it->{'fm'},"\n";

  my $t1 = threads->create(sub {
                             print "thread it: ",$it,"\n";
                             print "thread fm: ",$it->{'fm'},"\n";
                             print "thread: ", $it->next,"\n";
                             undef $it;
                             return 't1 done';
                           });

  print $t1->join,"\n";
  print "main: ", $it->next,"\n";
  exit 0;
}

{
  require Config;
  $Config::Config{useithreads}
    or die 'No ithreads in this Perl';

  my $filename = 't/samp.locatedb';
  open MYHANDLE, '<', $filename
    or die "cannot open: $!";

  eval { require threads } # new in perl 5.8, maybe
    or die "threads.pm not available -- $@";

  my $it = File::Locate::Iterator->new (database_fh => \*MYHANDLE,
                                        use_mmap => 0);

  my $t1 = threads->create(sub {
                             print "fileno ",fileno(MYHANDLE)," tell ",tell(MYHANDLE)," systell ",sysseek(MYHANDLE,0,1),"\n";
                             print "it ", $it->next,"\n";
                             close MYHANDLE;
                             return 't1 done';
                           });

  print $t1->join,"\n";
  print "in main\n";
  print "fileno ",fileno(MYHANDLE)," tell ",tell(MYHANDLE)," systell ",sysseek(MYHANDLE,0,1),"\n";
  print "it ", $it->next,"\n";

  #   while (defined (my $str = $it->next)) {
  #     print "got '$str'\n";
  #   }
  close MYHANDLE;
  exit 0;
}

{
  require PerlIO;
  print "F_UTF8 is ",PerlIO::F_UTF8(), "\n";
  print "F_CRLF is ",PerlIO::F_CRLF(), "\n";
  exit 0;
}

{
  require Storable;
  my $filename = 't/samp.locatedb';

  # GLOBs not storable
  #   open my $fh, '<', $filename or die "cannot open: $!";
  #   my $serialized = Storable::freeze(\$fh);

  # mmap copies whole mapped file contents
  require File::Map;
  File::Map::map_file (my $m, $filename);
  my $serialized = Storable::freeze(\$m);

  require Data::Dumper;
  print Data::Dumper->new([\$serialized],['serialized'])->Dump;
  exit 0;
}






# database_file is not kept to re-open
# fh can't be properly copied to have its own file position
#
sub File::Locate::Iterator::copy {
  my ($self) = @_;
  if (exists $self->{'fh'}) {
    return undef;
  } else {
    return bless { %$self }, ref $self;
  }

  #     ### copy to: $self
  #     if (my $fh = $self->{'database_fh'}) {
  #       open my $newfh, '<&', $fh
  #         or croak "Cannot dup database file handle: $!";
  #     }
  #     return $self;
}

=over 4

=item C<< $posstr = $it->tell() >>

=item C<< $success = $it->seek($posstr) >>

C<tell> returns a string of bytes representing the current position of
C<$it>.  (Its precise contents are unspecified and might change.)

C<seek> moves C<$it> to a previously recorded C<$posstr> position.  It
returns 1 if successful, or 0 and sets C<$!> if not.  A C<seek> can be
either forwards or backwards.  To work the underlying database file or
handle must be seekable.  A C<seek> in an mmap or a C<database_str> always
succeeds.

A C<$posstr> can be used with any iterator object operating on the same
database contents, by any of the string, handle or mmap methods.  It should
in fact work with any database which is byte-for-byte identical up to the
C<$posstr> position.

=back

=cut

  sub File::Locate::Iterator::tell {
    my ($self) = @_;
    my $pos;
    if (exists $self->{'mref'}) {
      $pos = $self->{'pos'};
    } else {
      if (($pos = tell($self->{'fh'})) < 0) {
        croak "Cannot get file handle position: $!";
      }
    }
    return "$pos $self->{'sharelen'} $self->{'entry'}";
  }

  sub File::Locate::Iterator::seek {
    my ($self, $posstr) = @_;
    my ($pos, $sharelen, $entry) = split / /,$posstr, 3;
    if (exists $self->{'mref'}) {
      $self->{'pos'} = $pos;
    } else {
      if (! seek($self->{'fh'}, $pos, 0)) {
        return 0;
      }
    }
    $self->{'entry'} = $entry;
    $self->{'sharelen'} = $sharelen;
    return 1;
  }



{
  my $filename = 't/samp.locatedb';
  open MYHANDLE, '<', $filename
    or die "cannot open: $!";
  my $it = File::Locate::Iterator->new (database_fh => \*MYHANDLE,
                                        use_mmap => 'if_possible');
  while (defined (my $str = $it->next)) {
    print "got '$str'\n";
  }
  close MYHANDLE;
  exit 0;
}

{
  my $str;
  {
    my $filename = 't/samp.locatedb';
    open my $fh, '<', $filename
      or die "oops, cannot open $filename: $!";
    binmode ($fh)
      or die "oops, cannot set binary mode on $filename";
    {
      local $/ = undef; # slurp
      $str = <$fh>;
    }
    close $fh
      or die "Error reading $filename: $!";
  }

  open my $fh, '<', \$str
    or die "oops, cannot open string";
  print "fileno ",fileno($fh),"\n";
  my $it = File::Locate::Iterator->new (database_fh => $fh,
                                        use_mmap => 'if_possible');
  print "using_mmap: ",$it->_using_mmap,"\n";

  while (defined (my $str = $it->next)) {
    print "got '$str'\n";
  }
  exit 0;
}



{
  my $filename = 't/samp.locatedb';
  # open my $fh, '<', $filename or die;
  open my $fh, '<', $filename or die;
#  binmode($fh) or die;
  require PerlIO;
  { local $,=' ';
    print PerlIO::get_layers($fh, details=>1),"\n";
  }
  exit 0;
}

{
  my $filename = 't/samp.locatedb';
  my $count = 0;
  my $it = File::Locate::Iterator->new (# globs => ['*.c','/z*'],
                                        use_mmap => 0,
                                        database_file => $filename,
                                       );
  print "fm: ",(defined $it->{'fm'} ? $it->{'fm'} : 'undef'),"\n";
  print "regexp: ",(defined $it->{'regexp'} ? $it->{'regexp'} : 'undef'),"\n";
  print "match: ",(defined $it->{'match'} ? $it->{'match'} : 'undef'),"\n";

  while (defined (my $str = $it->next)) {
    print "got '$str'\n";
    # print "  current ",$it->current,"\n";
    last if $count++ > 3;
  }
  exit 0;
}


{
  my $filename = 't/samp.locatedb';
  open my $fh, '<', $filename or die;
  require PerlIO;
  my $fm = File::Locate::Iterator::FileMap->get($fh);
  print "$fm\n";
  my $fm2 = File::Locate::Iterator::FileMap->get($fh);
  print "$fm2\n";
  exit 0;
}




{
  require File::FnMatch;
  print File::FnMatch::fnmatch('*.c','/foo/bar.c');
  exit 0;
}

{
  require File::Spec;

  # my $use_mmap = 1;
  my $use_mmap = 'if_possible';

   my $filename = '/tmp/frcode.out';
  # my $filename = File::Spec->devnull;

  open my $fh, '>', '/tmp/frcode.in' or die;
  print $fh <<'HERE' or die;
/usr/src
/usr/src/cmd/aardvark.c
/usr/src/cmd/armadillo.c
/usr/tmp/zoo
/usr/tmp/zoo/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
/usr/tmp/zoo/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx/y
HERE
  close $fh or die;
  system "/usr/lib/locate/frcode </tmp/frcode.in >/tmp/frcode.out";
  system "ls -l /tmp/frcode.out";

  my $it = File::Locate::Iterator->new (database_file => $filename,
                                        # suffix => '.c',
                                        glob => '/usr/tmp/*',
                                        use_mmap => $use_mmap,
                                       );
  print $it->{'regexp'},"\n";
  print exists $it->{'fm'} ? "using mmap\n" : "using fh\n";

  # require Perl6::Slurp;
  # Perl6::Slurp::slurp ($options{'database_file'}),

  # use Perl6::Slurp 'slurp';
  # my $str = slurp '/tmp/frcode.out';
  # $it->{'mref'} = \$str;

  while (defined (my $str = $it->next)) {
    print "got '$str'\n";
    # print "  current ",$it->current,"\n";
  }

  # my $str = 'jk';
  # my ($x) = unpack '@1c', $str;
  # print "$x\n";
  # print pos($str)+0;

  exit 0;
}

