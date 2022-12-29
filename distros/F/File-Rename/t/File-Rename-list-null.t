# Before `make install' is performed this script should be runnable with
# `make test'. 

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;

BEGIN { use_ok('File::Rename') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

unshift @INC, 't' if -d 't';
require 'testlib.pl';

sub test_rename { goto &test_rename_list; }

my $dir = do { require File::Temp; File::Temp::tempdir() };
chdir $dir or die;

my @files = ('file.txt', 'bad file', "new\nline");
my @target = grep { create_file($_) } @files;
die unless @target;

my $file = 'list.txt';
create_file($file, map qq($_\0), @target) or die;

our $found;
our $print;
our $warn;
local $SIG{__WARN__} = sub { $warn .= $_[0] };

my $s = sub { s/\W// };

{
  open my $fh, '<', $file or die "Can't open $file: $!\n";
  test_rename($s, $fh, {verbose=>1, input_null=>1}, 0,
	  	"Reading filenames from file handle" );
}
ok( $found, "rename_list");
diag_rename();

s/\W// for @target;
is_deeply( [ sort(listdir('.')) ],
	[sort($file, @target)],
	'rename - list - null' );

END { 	chdir File::Spec->rootdir; 
	File::Path::rmtree($dir); 
	ok( !-d $dir, "test dir removed");  
}
 
