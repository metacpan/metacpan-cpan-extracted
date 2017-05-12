# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2013-02-19 21:32:28 +0000 (Tue, 19 Feb 2013) $
# Id:            $Id: 00-compile-pm.t 68 2013-02-19 21:32:28Z rmp $
# $HeadURL$
#
package compile;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = do { my @r = (q$Revision: 68 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

eval {
  require Test::Compile;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Compile not installed';
} else {
  Test::Compile->import;
  all_pm_files_ok(all_pm_files(qw(blib)));
}

1;
