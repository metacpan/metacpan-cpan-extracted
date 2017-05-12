use strict;
use warnings;
use Test::More;

eval { require Test::Pod; };

if ($@) {
   plan skip_all => 'Test::Pod not available';
} else {
   Test::Pod->import();
   my @poddirs = qw(lib ../lib);
   all_pod_files_ok(all_pod_files( @poddirs ));
}

done_testing();
