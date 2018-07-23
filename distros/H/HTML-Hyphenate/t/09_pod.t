use strict;
use warnings;
use utf8;

use Test::More;
if ( !eval { require Test::Pod; 1 } ) {
	plan skip_all => "Test::Pod required for testing POD";
}
Test::Pod::all_pod_files_ok();
