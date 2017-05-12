#
# $Id: 03_pod.t,v 1.2 2003/12/28 00:15:15 james Exp $
#

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

#
# EOF

