use Test::More ;

qx/gdb -v/ or
  plan skip_all => "cannot execute 'gdb', please use -execfile => '/full/path/to/gdb' " ;

eval "use threads; 1" or
  plan skip_all => "cannot use 'threads'" ;

plan tests => 4 ;

use_ok('Devel::GDB') ;
my $gdb = new Devel::GDB ( '-params' => '-q' ) ;
ok($gdb) ;
ok($gdb->{'-use-threads'}) ;
ok($gdb -> get( 'help')) ;
$gdb->end;
