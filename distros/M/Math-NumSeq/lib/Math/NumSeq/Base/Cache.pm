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


# Experimental ...


package Math::NumSeq::Base::Cache;
use 5.004;
use strict;

use vars '$VERSION', '@ISA', '@EXPORT_OK';
$VERSION = 75;
@ISA = ('Exporter');
@EXPORT_OK = ('cache_hash', 'make_key');

use vars '%cache';
my $tempdir;
use constant::defer cache_hash => sub {
  require SDBM_File;
  require File::Temp;
  $tempdir = File::Temp->newdir;
  ### $tempdir
  ### tempdir: $tempdir->dirname
  tie (%cache, 'SDBM_File',
       File::Spec->catfile ($tempdir->dirname, "cache"),
       Fcntl::O_RDWR()|Fcntl::O_CREAT(),
       0666)
    or die "Couldn't tie SDBM file 'filename': $!; aborting";

  END {
    if ($tempdir) {
      ### unlink cache ...
      untie %cache;
      my $dirname = $tempdir->dirname;
      unlink File::Spec->catfile ($dirname, "cache.pag");
      unlink File::Spec->catfile ($dirname, "cache.dir");
    }
  }
  # END {
  #   if ($tempdir) {
  #     ### cache diagnostics ...
  #     my $count = 0;
  #     while (each %cache) {
  #       $count++;
  #     }
  #     untie %cache;
  #     my $dirname = $tempdir->dirname;
  #     print "cache final $count file sizes cache.pag ",
  #       (-s File::Spec->catfile($dirname,"cache.pag")),
  #         " cache.dir ",
  #           (-s File::Spec->catfile($dirname,"cache.dir")),
  #             "\n";
  #   }
  # }
  return \%cache;
};

my $cache_key = 0;
sub make_key {
  my $params = "CacheKey:" . join (',',@_);
  ### $params
  if (my $c = cache_hash()->{$params}) {
    return $c;
  }
  return sprintf 'k%X:', (cache_hash()->{$params} = $cache_key++);
}

1;
__END__
