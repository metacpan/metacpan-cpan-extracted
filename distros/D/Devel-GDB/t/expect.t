use Test::More ;

qx/gdb -v/ or
  plan skip_all => "cannot execute 'gdb', please use -execfile => '/full/path/to/gdb' ";

eval "use Expect; 1" or
  plan skip_all => "cannot use 'Expect'" ;

plan tests => 8;

use_ok('Devel::GDB');
my $gdb = new Devel::GDB ( '-params' => '-q',
                           '-create-expect' => 1 );
ok($gdb);

my $e = $gdb->get_expect_obj;
ok($e);

ok($gdb->send_cmd("file $^X"));
ok($gdb->send_cmd("set args -p -e '\$_ = uc'"));
ok($gdb->send_cmd("-exec-run"));

$e->send("foo\n");

ok($e->expect(undef, '-re', '^.+$')
    and $e->match =~ /^FOO/);

$e->send("bar\n");

ok($e->expect(undef, '-re', '^.+$')
    and $e->match =~ /^BAR/);

$gdb->end;
