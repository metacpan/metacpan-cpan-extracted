# 99pod.t -- Minimally check POD for problems.
#
# $Id: 98podsyn.t,v 1.1 2005/12/11 19:02:00 tbe Exp $

use strict;
use warnings;
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
