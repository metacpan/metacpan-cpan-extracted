# Before `make install' is performed this script should be runnable with
# `make test'. 

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;

BEGIN { use_ok('File::Rename') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use File::Path;
use File::Temp;

my $dir = File::Temp::tempdir;
chdir $dir or die;

my $file = 'list.txt';
create_file($file);

sub create_file {
    my($file) = @_;
    local *FILE; 
    open  FILE, '>'. $file or die "Can't create $file: $!\n";
    # print FILE "This is $file\n" or die $!;
    close FILE or die $!;
} 

my $warn;
local $SIG{__WARN__} = sub { $warn .= $_[0] };

my $print;
my $found;

sub test_rename {
  my($sub, $fh, $verbose, $warning, $printed) = @_;

  { local *STDOUT;
    open STDOUT, '>'. 'log' or die "Can't create log file: $!\n";
    undef $warn;
    File::Rename::rename_list($sub, $verbose, $fh);
    close STDOUT or die;
  }

  { local *READ; 
    open READ, '<'. 'log' or die "Can't read log file: $!\n";
    local $/;
    $print = <READ>; 
    close READ or die;
  }

    undef $found;
    if( $warning ) {
	if( $warn ) {
	    if( $warn =~ s/^\Q$warning\E\b.*\n//sm ) { $found ++ }
	}
    	else { $warn = "(no warning)\n" }
	     
	unless( $found ) {
	    $warning =~ s/^/EXPECT: WARN: /mg; diag $warning;
	}
    }
    elsif( $printed ) {
	if( $print ) {
	    if( $print =~ s/^\Q$printed\E(\s.*)?\n//sm ) { $found ++ }
	}
    	else { $print = "(no output)\n" }
	     
	unless( $found ) {
	    $printed =~ s/^/EXPECT: PRINT: /mg; diag $printed;
	}
    }
    else {
	$found++ unless $warn or $print;
    }	
}

sub diag_rename {
    if( $warn ) { $warn =~ s/^/WARN: /mg; diag $warn; }
    if( $print ) { $print =~ s/^/PRINT: /mg; diag $print; }
}

my $s = sub { s/foo/bar/ };

{
  open my $fh, '<', $file or die "Can't open $file: $!\n";
  test_rename($s, $fh, 1, undef, "Reading filenames from file handle" );
}
ok( $found, "rename_list");
diag_rename;

{ 
  open my $fh, '<', $file or die "Can't open $file: $!\n";
  *{$fh} = \"XYZZY";
  test_rename($s, $fh, 1, undef, "Reading filenames from XYZZY" );
}
ok( $found, "rename_list - using *FH{SCALAR}");
diag_rename;

END { 	chdir File::Spec->rootdir; rmtree $dir; 
	ok( !-d $dir, "test dir removed");  
}
 
