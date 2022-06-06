# Copyright 2011, 2012, 2013, 2014, 2016, 2019, 2020 Kevin Ryde

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

package Math::NumSeq::OEIS::Catalogue::Plugin::ZZ_Files;
use 5.004;
use strict;
use File::Spec;
use Math::NumSeq::OEIS::File;

use vars '@ISA';
use Math::NumSeq::OEIS::Catalogue::Plugin;
@ISA = ('Math::NumSeq::OEIS::Catalogue::Plugin');

use Math::NumSeq::OEIS::Catalogue::Plugin::FractionDigits;
*_anum_to_num
  = \&Math::NumSeq::OEIS::Catalogue::Plugin::FractionDigits::_anum_to_num;

use vars '$VERSION';
$VERSION = 75;

# uncomment this to run the ### lines
#use Smart::Comments;


sub _make_info {
  my ($anum) = @_;
  ### _make_info(): $anum
  return { anum => $anum,
           class => 'Math::NumSeq::OEIS::File',
           parameters => [ anum => $anum ] };
}

sub anum_to_info {
  my ($class, $anum) = @_;
  ### Catalogue-ZZ_Files num_to_info(): @_

  my $dir = Math::NumSeq::OEIS::File::oeis_dir();
  foreach my $anum ($anum,
                    # A0123456 shortened to A123456
                    ($anum =~ /A0(\d{6})/ ? "A$1" : ())) {
    foreach my $basename
      ("$anum.internal",
       "$anum.internal.html",
       "$anum.html",
       "$anum.htm",
       Math::NumSeq::OEIS::File::anum_to_bfile($anum),
       Math::NumSeq::OEIS::File::anum_to_bfile($anum,'a')) {
      my $filename = File::Spec->catfile ($dir, $basename);
      ### $filename
      if (-e $filename) {
        return _make_info($anum);
      }
    }
  }
  return undef;
}

# on getting up to perhaps 2000 files of 500 anums it becomes a bit slow
# re-reading the directory on every anum_next(), cache a bit for speed

my $cached_arrayref = [];
my $cached_mtime = -1;
my $cached_time = -1;

sub info_arrayref {
  my ($class) = @_;

  # stat() at most once per second
  my $time = time();
  if ($cached_time != $time) {
    $cached_time = $time;

    # if $dir mtime changed then re-read
    my $dir = Math::NumSeq::OEIS::File::oeis_dir();
    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks) = stat($dir);
    if (! defined $mtime) { $mtime = -1; } # if $dir doesn't exist
    if ($cached_mtime != $mtime) {
      $cached_mtime = $mtime;
      $cached_arrayref = nocache_info_arrayref($dir);
    }
  }
  return $cached_arrayref;
}

sub nocache_info_arrayref {
  my ($dir) = @_;
  ### nocache_info_arrayref(): $dir

  my @ret;
  _anum_traverse(sub {
                   my ($num) = @_;
                   my $anum = _num_to_anum($num);
                   push @ret, _make_info($anum);
                   return 1; # continue
                 });
  return \@ret;
}
sub _anum_traverse {
  my ($callback) = @_;

  my $dir = Math::NumSeq::OEIS::File::oeis_dir();
  if (! opendir DIR, $dir) {
    ### cannot opendir: $!
    return;
  }
  my %seen;
  while (defined (my $basename = readdir DIR)) {
    ### $basename

    # stat() on every file is a bit slow ...
    # unless (-e File::Spec->catfile($dir,$basename)) {
    #   ### skip dangling symlink ...
    #   next;
    # }

    # Case insensitive for MS-DOS.  But dunno what .internal or
    # .internal.html will be or should be on an 8.3 DOS filesystem.  Maybe
    # "A000000.int", maybe "A000000i.htm" until 7-digit A-numbers.
    next unless $basename =~ m{^(
                                 A(\d*)(\.internal)?(\.html?)?  # $2 num
                               |[ab](\d*)\.txt                  # $5 num
                               )$}ix;
    my $num = ($2||$5)+0;   # numize
    next if $seen{$num}++;  # uniquify
    last unless &$callback($num);
  }
  closedir DIR or die "Error closing $dir: $!";
}

# Works, but cached array might be enough.
#
# sub anum_after {
#   my ($class, $after_anum) = @_;
#   my $after_num = _anum_to_num($after_anum);
#   ### $after_num
#   my $ret_num;
#   _anum_traverse(sub {
#                    my ($num) = @_;
#                    ### $num
#                    if ($num > $after_num
#                        && (! defined $ret_num || $num < $ret_num)) {
#                      $ret_num = $num;
#                      ### new ret: $ret_num
#                      if ($ret_num == $after_num + 1) {
#                        return 0;  # stop, found after+1
#                      }
#                    }
#                    return 1; # continue
#                  });
#   return _num_to_anum($ret_num);
# }
# sub anum_before {
#   my ($class, $before_anum) = @_;
#   my $before_num = _anum_to_num($before_anum);
#   my $ret_num;
#   _anum_traverse(sub {
#                    my ($num) = @_;
#                    if ($num > $before_num
#                        && (! defined $ret_num || $num < $ret_num)) {
#                      $ret_num = $num;
#                      if ($ret_num == $before_num - 1) {
#                        return 0;  # stop, found before-1
#                      }
#                    }
#                    return 1; # continue
#                  });
#   return _num_to_anum($ret_num);
# }

#------------------------------------------------------------------------------

sub _num_to_anum {
  my ($num) = @_;
  if (defined $num) {
    return sprintf 'A%06d', $num;
  } else {
    return undef;
  }
}

1;
__END__


# sub anum_after {
#   my ($class, $anum) = @_;
#   ### anum_after(): $anum
#
#   my $dir = Math::NumSeq::OEIS::File::oeis_dir();
#
#   if (! opendir DIR, $dir) {
#     ### cannot opendir: $!
#     return undef;
#   }
#
#   $anum =~ /([0-9]+)/;
#   my $anum_num = $1 || 0;
#
#   my $after_num;
#   while (defined (my $basename = readdir DIR)) {
#     # ### $basename
#     if ($basename =~ /^A(\d*)\.(html?|internal)
#                     |[ab](\d*)\.txt/xi) {
#       my $num = ($1||$3);
#       if ($num > $anum_num
#           && (! defined $after_num
#               || $after_num > $num)) {
#         $after_num = $num;
#       }
#     }
#   }
#   closedir DIR or die "Error closing $dir: $!";
#
#   if (defined $after_num) {
#     $after_num = "A$after_num";
#   }
#
#   ### $after_num
#   return $after_num;
# }
