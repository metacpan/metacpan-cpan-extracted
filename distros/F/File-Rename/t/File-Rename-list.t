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

my $dir = do { require File::Temp; File::Temp::tempdir(); };
chdir $dir or die;

my $file = 'list.txt';
create_file($file);

our $found;
our $print;
our $warn;
local $SIG{__WARN__} = sub { $warn .= $_[0] };

sub test_rename { goto &test_rename_list; }

my $s = sub { s/foo/bar/ };

{
  open my $fh, '<', $file or die "Can't open $file: $!\n";
  test_rename($s, $fh, 1, undef, "Reading filenames from file handle" );
}
ok( $found, "rename_list");
diag_rename();

{ 
  open my $fh, '<', $file or die "Can't open $file: $!\n";
  *{$fh} = \"XYZZY";
  test_rename($s, $fh, 1, undef, "Reading filenames from XYZZY" );
}
ok( $found, "rename_list - using *FH{SCALAR}");
diag_rename();

END { 	chdir File::Spec->rootdir;
	File::Path::rmtree($dir); 
	ok( !-d $dir, "test dir removed");  
}
 
