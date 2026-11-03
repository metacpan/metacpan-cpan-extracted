use 5.020;
use strict;
use warnings;
use Test::More;
use File::Path ();
use File::Spec ();
use File::Temp ();
use Devel::XSCover::Test ();

my $dir = File::Temp->newdir;
my $db  = File::Spec->catdir($dir, 'cover_db');
sub make_db { File::Path::make_path(File::Spec->catdir($db, 'runs')); open my $fh, '>', File::Spec->catfile($db, 'runs', 'x') or die; close $fh }

make_db();
ok(Devel::XSCover::Test->new(dir => "$dir", silent => 1)->reset_db, 'reset reports the removal');
ok(!-d $db, 'the db is gone');
ok(!Devel::XSCover::Test->new(dir => "$dir", silent => 1)->reset_db, 'nothing to remove the second time');

make_db();
ok(!Devel::XSCover::Test->new(dir => "$dir", silent => 1, delete => 0)->reset_db, 'no_delete keeps it');
ok(-d $db, 'still there');

ok(Devel::XSCover::Test->new(dir => "$dir", silent => 1, dry => 1)->reset_db, 'a dry reset says it would');
ok(-d $db, 'and leaves it');

ok(Devel::XSCover::Test->new(dir => "$dir", silent => 1, db => 'elsewhere')->reset_db == 0, 'another db name is untouched');
ok(-d $db, 'still there');

done_testing;
