use strict;
use warnings;
use Test::More;

use_ok( 'Devel::ModuleBreaker' );
use_ok( 'Devel::FileBreaker' );
use_ok( 'Devel::SubBreaker' );

diag "Devel::ModuleBreaker $^X $]";
done_testing();

