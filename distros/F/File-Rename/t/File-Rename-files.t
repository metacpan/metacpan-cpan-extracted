# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 11;

BEGIN { use_ok('File::Rename') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

unshift @INC, 't' if -d 't';
require 'testlib.pl';

sub test_rename { goto &test_rename_files; }

my $dir = do { require File::Temp; File::Temp::tempdir() };
chdir $dir or die;
my($test_foo, $test_bar, $copy_foo, $copy_bar, $new1, $new2, $old2, $old3) =
	qw(test.foo test.bar copy.foo copy.bar 1.new 2.new 2.old 3.old);

my $subdir = 'food';
File::Path::mkpath($subdir) or die;
my $sub_test = File::Spec->catfile($subdir,'test.txt');

for my $file ($test_foo, $copy_foo, $copy_bar, $new1, $old2, $sub_test) {
    create_file($file) or die;
}

our $found;
our $print;
our $warn;
local $SIG{__WARN__} = sub { $warn .= $_[0] };

my $s = sub { s/foo/bar/ };
 
test_rename($s, $test_foo); 
ok( (-e $test_bar and !-e $test_foo and $found), "rename foo->bar");
diag_rename();

test_rename($s, $new1);
ok( (-e $new1 and $found), "rename: filename not changed");
diag_rename();

test_rename($s, $copy_foo, undef, "$copy_foo not renamed");
ok( (-e $copy_foo and $found), "rename: file exists"); 
diag_rename();

test_rename($s, $copy_foo, {over_write=>1});
ok( (!-e $copy_foo and $found), "rename: over_write"); 
diag_rename();

create_file($copy_foo);
test_rename($s, $copy_foo, {over_write=>1, verbose=>1},
 		undef, "$copy_foo renamed as $copy_bar");
ok( (!-e $copy_foo and $found), "rename: over_write+verbose"); 
diag_rename();

test_rename($s, $sub_test, undef, "Can't rename $sub_test");
ok( (-e $sub_test and $found), "rename: can't rename"); 
diag_rename();

my $inc = sub { s/(\d+)/ $1 + 1 /e unless /\.old\z/ };

test_rename($inc, $new1, {no_action=>1}, undef, "rename($new1, $new2)");
ok( (-e $new1 and !-e $new2 and $found), "rename: no_action");
diag_rename();

test_rename($inc, $new1, 1, undef, "$new1 renamed as $new2");
ok( (-e $new2 and !-e $new1 and $found), "rename 1->2");
diag_rename();

test_rename($inc, $old2, 1); 
ok( (-e $old2 and !-e $old3 and $found), 
	"rename: filename not changed (1->2)");
diag_rename();

END { 	chdir File::Spec->rootdir;
	File::Path::rmtree($dir); 
	ok( !-d $dir, "test dir removed");  
}
 
