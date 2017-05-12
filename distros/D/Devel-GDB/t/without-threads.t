use Test::More ;

qx/gdb -v/ or
  plan skip_all => "cannot execute 'gdb', please use -execfile => '/full/path/to/gdb' " ;

plan tests => 4 ;

use_ok('Devel::GDB') ;
my $gdb = new Devel::GDB ( '-params' => '-q' ) ;
ok($gdb) ;
ok(!$gdb->{'-use-threads'}) ;
ok($gdb -> get( 'help')) ;

