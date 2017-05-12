#########
# Author:        rmp
# Last Modified: $Date: 2007/02/23 00:18:19 $ $Author: rmp $
# Id:            $Id: 00-distribution.t,v 1.41 2007/02/23 00:18:19 rmp Exp $
# Source:        $Source: /cvsroot/Bio-DasLite/Bio-DasLite/t/00-distribution.t,v $
# $HeadURL$
#
package distribution;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = do { my @r = (q$Revision: 1.41 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

eval {
  require Test::Distribution;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Distribution not installed';
} else {
  Test::Distribution->import('not' => 'prereq'); # Having issues with Test::Dist seeing my PREREQ_PM :(
}

1;
