#
# $Id: 02_pod.t 4496 2010-06-18 15:19:43Z james $
#

use strict;
use warnings;

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

#
# EOF
