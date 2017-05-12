# $Id: 9_pod.t,v 1.1 2003/11/10 09:38:27 grantm Exp $

use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok(); 
