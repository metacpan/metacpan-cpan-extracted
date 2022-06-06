#!/usr/bin/perl -w

# Copyright 2010, 2011, 2012, 2013, 2014, 2018, 2019, 2020 Kevin Ryde

# This file is part of Math-NumSeq.
#
# Math-NumSeq is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Math-NumSeq is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Math-NumSeq.  If not, see <http://www.gnu.org/licenses/>.

use 5.004;
use strict;
use POSIX;

# uncomment this to run the ### lines
use Smart::Comments;


{
  # ~/OEIS/A000110.internal.txt
  # ~/OEIS/b000110.txt
  require Math::NumSeq::OEIS::File;
  my $seq = Math::NumSeq::OEIS::File->new(
                                          # anum => 'A007450',
                                          # anum=>'A088218',
                                          # anum=>'A000290',

                                          anum=>'A021913',
                                          _dont_use_internal=>1,
                                          _dont_use_afile=>1,
                                          _dont_use_bfile=>0,
                                         );
  ### $seq
  ### description: $seq->description
  ### characteristic(increasing): $seq->characteristic('increasing')
  ### characteristic(smaller): $seq->characteristic('smaller')
  ### values_min: $seq->values_min
  ### values_max: $seq->values_max
  ### i_start: $seq->i_start
  ### tell: $seq->tell_i
  exit 0;
}
{
  require Math::NumSeq::OEIS::File;
  my $anum = 'A000032';
  my $num = 218181;

  # open my $fh, '<', "$ENV{HOME}/OEIS/stripped" or die $!;
  # open my $fh, '<:gzip', "$ENV{HOME}/OEIS/stripped.gz" or die $!;
  open my $fh, '<:gzip', "$ENV{HOME}/OEIS/names.gz" or die $!;

  my $line = Math::NumSeq::OEIS::File::_bsearch_textfile
    ($fh, sub {
       my ($line) = @_;
       $line =~ /^A(\d+)/ or return -1;
       return ($1 <=> $num);
     });
  ### $line
  exit 0;
}
{
  # no seek() at all in IO::Zlib 1.10, AUTOLOAD error
  seek STDIN, 0,0
    or print "STDIN ", $!+0," $!\n";

  use IO::Zlib;
  {
    package IO::Zlib;

    # No seek() yet.
    #
    # With Compress::Zlib could gzseek() to support forward seeks and
    # gztell() for current position.
    #
    # With external gunzip could read and discard to seek forward.  Might
    # have to remember the file position explicitly to support TELL.
    #
    # POSIX.1 specifies ESPIPE for attempting to seek a pipe.  Maybe could
    # return that if available, instead of EINVAL.
    #
    sub SEEK {
      require POSIX;
      $! = POSIX::EINVAL();
      return 0;
    }
    sub TELL {
      require POSIX;
      $! = POSIX::EINVAL();
      return -1;
    }
  }

  tie *FH, 'IO::Zlib', "$ENV{HOME}/OEIS/stripped.gz", "rb";
  seek FH, 0,0
    or print "tiedFH seek ", $!+0," $!\n";

  { my $tell = tell(FH);
    print "tiedFH tell $tell, ", $!+0, "$!\n";
  }
  # my $fh = \*FH;
  # my $line = readline $fh;
  # print $line;
  #  seek $fh, 0,0 or die $!;
  exit 0;
}
{
  require IO::Uncompress::Gunzip;
  my $z = IO::Uncompress::Gunzip->new("$ENV{HOME}/OEIS/stripped.gz");
  $z->getline;
  $z->seek(0,0) or die $!;
  exit 0;
}


{
  require Math::NumSeq::OEIS;
  print "o\n";
  my $info = Math::NumSeq::OEIS->parameter_info_array;
  ### $info
  exit 0;
}


{
  # how many i to be sure of increasing / non_decreasing
  # 100 in A179635 median of digits

  require Math::NumSeq::OEIS::File;
  my $oeis_dir = Math::NumSeq::OEIS::File->oeis_dir;
  my $count = 0;
  my $max_anum;
  my $max_i = -1;
  foreach my $filename (<$oeis_dir/A*.internal>) {
    $filename =~ /(A[0-9]+)/;
    my $anum = $1;
    my $seq = Math::NumSeq::OEIS::File->new (anum => $anum);
    my (undef, $prev_value) = $seq->next;
    while (my ($i, $value) = $seq->next) {
      if ($value < $prev_value) {
        if ($i > $max_i) {
          $max_anum = $anum;
          $max_i = $i;
        }
        last;
      }
    }
    $count++;
  }
  print "total $count A-numbers\n";
  print "max_i $max_i in $max_anum\n";
  exit 0;
}

{
  # _anum_is_good() files

  require Math::NumSeq::OEIS::File;
  my $oeis_dir = Math::NumSeq::OEIS::File->oeis_dir;
  my $count = 0;
  foreach my $filename (<$oeis_dir/a*[0-9].txt>) {
    open my $fh, '<', $filename or die;
    my $seq = { fh => $fh,
                filename => $filename };
    if (! Math::NumSeq::OEIS::File::_afile_is_good($seq)) {
      print "$filename:1: not good\n";
    }
    $count++;
  }
  print "total $count a-files\n";
  exit 0;
}

{
  # speed of anum_after();

  require Math::NumSeq::OEIS::Catalogue;

  require Devel::TimeThis;
  my $t = Devel::TimeThis->new('x');

  my $count = 0;
  for (my $anum = 'A00000';
       defined $anum;
       $anum = Math::NumSeq::OEIS::Catalogue->anum_after($anum)) {
    # ### $anum
    $count++;
  }
  ### $count
  exit 0;
}


{
  require Math::NumSeq::OEIS::Catalogue;
  my $anum = 'A055508';
  my $info = Math::NumSeq::OEIS::Catalogue->anum_to_info($anum);
  ### $info

  require Math::NumSeq::OEIS;
  my $seq = Math::NumSeq::OEIS->new(anum=>$anum);
  ### $seq
  exit 0;
}
{
  unshift @INC,'t';
  require MyOEIS;
  my @ret = MyOEIS::read_values('008683');
  ### @ret
  exit 0;
}
{
  require Math::NumSeq::OEIS::Catalogue::Plugin::ZZ_Files;
  require Math::NumSeq::OEIS::Catalogue::Plugin::FractionDigits;
  foreach my $info (Math::NumSeq::OEIS::Catalogue::Plugin::FractionDigits->info_arrayref) {
    ### info: $info->[0]
    my $anum = $info->[0]->{'anum'};
    require Math::NumSeq::OEIS;
    my $seq = Math::NumSeq::OEIS->new(anum=>$anum);
  }
  exit 0;
}

{
  require Math::NumSeq::OEIS::Catalogue;
  my $info = Math::NumSeq::OEIS::Catalogue->anum_to_info('A000290');
  ### $info
  { my $anum = Math::NumSeq::OEIS::Catalogue->anum_first;
    ### $anum
  }
  { my $anum = Math::NumSeq::OEIS::Catalogue->anum_last;
    ### $anum
  }
  {
    my $anum = Math::NumSeq::OEIS::Catalogue->anum_after('A000032');
    ### $anum
  }
  {
    my $anum = Math::NumSeq::OEIS::Catalogue->anum_before('A000032');
    ### $anum
  }
  # my @list = Math::NumSeq::OEIS::Catalogue->anum_list;
  # ### @list

  {
    require Math::NumSeq::OEIS::Catalogue;
    foreach my $plugin (Math::NumSeq::OEIS::Catalogue->plugins) {
      ### $plugin
      ### first: $plugin->anum_first
      ### last: $plugin->anum_last
    }
  }

  exit 0;
}



{
  {
    require File::Find;
    my $old = \&File::Find::find;
    no warnings 'redefine';
    *File::Find::find = sub {
      print "File::Find::find\n";
      print "  $_[1]\n";
      goto $old;
    };
  }
  require Math::NumSeq::OEIS::Catalogue;
  Math::NumSeq::OEIS::Catalogue->plugins;
  print "\n";
  Math::NumSeq::OEIS::Catalogue->plugins;
  print "\n";
  Math::NumSeq::OEIS::Catalogue->plugins;
}

{
  require Math::NumSeq::OEIS::Catalogue::Plugin::Files;
  my $info = Math::NumSeq::OEIS::Catalogue::Plugin::Files->anum_to_info(32);
  ### $info
exit 0;
}

