
# test module loading

use strict ;
use warnings ;

use Test::NoWarnings ;

use Test::More qw(no_plan);
use Test::Exception ;

BEGIN { use_ok( 'File::Find::Repository' ) or BAIL_OUT("Can't load module"); } ;

my $config = new File::Find::Repository ;

is(defined $config, 1, 'default constructor') ;
isa_ok($config, 'File::Find::Repository');

my $new_config = $config->new() ;
is(defined $new_config, 1, 'constructed from object') ;
isa_ok($new_config , 'File::Find::Repository');

dies_ok
	{
	File::Find::Repository::new () ;
	} "invalid constructor" ;

