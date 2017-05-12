# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

BEGIN { $| = 1; print "1..13\n"; }
END { print "not ok 1\n" unless $loaded;}

use IO::LockedFile;
use diagnostics;
$loaded = 1;
print "ok 1\n";
use Fcntl;
use Cwd;

my $file_path = cwd()."/locked1.txt";

### check opening the file using the Perl mode ###

# create an exclussive locked file
my $file1 = new IO::LockedFile(">".$file_path);

# check that the file is locked exclussively
# try to open it to read
if (my $pid = fork()) {
    wait;
}
else { # in the child process
    my $file2 = new IO::LockedFile({ block => 0 },
				   ">".$file_path);
    print_ok(!$file2, 2, "the file is locked exclussivly, ".
	     "so we could not open it to write");
    $file2 = new IO::LockedFile({ block => 0 },
				   $file_path);
    print_ok(!$file2, 3, "the file is locked exclussivly, ".
	     "so we could not open it to read");
    exit 0; # exit from that process and continue in the "wait" above    
}

# close (and unlock) the file
$file1 = undef;

# create a shared locked file
$file1 = new IO::LockedFile($file_path);

# check that the file has a shared locked 
# try to open it to write
if (my $pid = fork()) {
    wait;
}
else { # in the child process
    my $file2 = new IO::LockedFile({ block => 0 },
				   ">".$file_path);
    print_ok(!$file2, 4, "the file has a shared lock, ".
	     "so we could not open it to write");
    $file2 = new IO::LockedFile({ block => 0 },
				$file_path);
    print_ok($file2, 5, "the file has a shared lock, ".
	     "so we could open it to read");
    exit 0; # exit from that process and continue in the "wait" above
}

# close (and unlock) the file
$file1 = undef;

### check opening the file using Numeric mode ###

# create an exclussive locked file
$file1 = new IO::LockedFile($file_path, O_CREAT | O_TRUNC);

# check that the file is locked exclussively
# try to open it to read
if (my $pid = fork()) {
    wait;
}
else { # in the child process
    my $file2 = new IO::LockedFile({ block => 0 },
				   $file_path, O_CREAT | O_TRUNC);
    print_ok(!$file2, 6, "the file is locked exclussivly, ".
	     "so we could not open it to write");
    $file2 = new IO::LockedFile({ block => 0 },
				   $file_path);
    print_ok(!$file2, 7, "the file is locked exclussivly, ".
	     "so we could not open it to read");
    exit 0; # exit from that process and continue in the "wait" above    
}

# close (and unlock) the file
$file1 = undef;

# create a shared locked file
$file1 = new IO::LockedFile($file_path);

# check that the file has a shared locked 
# try to open it to write
if (my $pid = fork()) {
    wait;
}
else { # in the child process
    my $file2 = new IO::LockedFile({ block => 0 },
				   $file_path, O_CREAT | O_TRUNC);
    print_ok(!$file2, 8, "the file has a shared lock, ".
	     "so we could not open it to write");
    $file2 = new IO::LockedFile({ block => 0 },
				$file_path);
    print_ok($file2, 9, "the file has a shared lock, ".
	     "so we could open it to read");
    exit 0; # exit from that process and continue in the "wait" above
}

# close (and unlock) the file
$file1 = undef;

### check opening the file using POSIX mode ###

# create an exclussive locked file
$file1 = new IO::LockedFile($file_path, "w");

# check that the file is locked exclussively
# try to open it to read
if (my $pid = fork()) {
    wait;
}
else { # in the child process
    my $file2 = new IO::LockedFile({ block => 0 },
				   $file_path, "w");
    print_ok(!$file2, 10, "the file is locked exclussivly, ".
	     "so we could not open it to write");
    $file2 = new IO::LockedFile({ block => 0 },
				   $file_path, "r");
    print_ok(!$file2, 11, "the file is locked exclussivly, ".
	     "so we could not open it to read");
    exit 0; # exit from that process and continue in the "wait" above    
}

# close (and unlock) the file
$file1 = undef;

# create a shared locked file
$file1 = new IO::LockedFile($file_path, "r");

# check that the file has a shared locked 
# try to open it to write
if (my $pid = fork()) {
    wait;
}
else { # in the child process
    my $file2 = new IO::LockedFile({ block => 0 },
				   $file_path, "w");
    print_ok(!$file2, 12, "the file has a shared lock, ".
	     "so we could not open it to write");
    $file2 = new IO::LockedFile({ block => 0 },
				$file_path, "r");
    print_ok($file2, 13, "the file has a shared lock, ".
	     "so we could open it to read");
    exit 0; # exit from that process and continue in the "wait" above
}

# close (and unlock) the file
$file1 = undef;

# remove the file
unlink($file_path);

#############################################
# print_ok ($expression, $number, $comment)
#############################################
sub print_ok {
    my $expression = shift;
    my $number =shift;
    my $string = shift || "";

    $string = "ok " . $number . " " . $string . "\n";
    if (! $expression) {
        $string = "not " . $string;
    }
    print $string;
} # print_ok



