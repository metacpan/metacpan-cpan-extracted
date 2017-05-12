use Test::Simple 'no_plan';
use Cwd;

unlink cwd().'/t/copy.db';
ok(1);
