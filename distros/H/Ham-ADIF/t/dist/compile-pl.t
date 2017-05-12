# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2013-11-25 22:31:26 +0000 (Mon, 25 Nov 2013) $
# Id:            $Id: 00-compile-pl.t 271 2013-11-25 22:31:26Z rmp $
# $HeadURL$
#
package compile;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use Carp;

our $VERSION = do { my @r = (q$Revision: 271 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

eval {
  require Test::Compile;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Compile not installed';
} else {
  Test::Compile->import;
  my @files = ();

  for my $dir (qw(bin scripts)) {
    eval {
      opendir my $dh, $dir or croak qq[Error opening $dir];
      push @files, grep { `file $_` =~ /perl.*script/smix }
                   grep { -f }
                   map  { "$dir/$_" } readdir $dh;
      closedir $dh or carp qq[Error closing $dir: $ERRNO];
    } or do {
      # nothing
    };
  }

  all_pl_files_ok(@files);
}

1;
