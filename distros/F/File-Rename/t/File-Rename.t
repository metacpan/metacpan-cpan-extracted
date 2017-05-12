# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl File-Rename.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 3;
BEGIN { use_ok('File::Rename') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use File::Spec;
use File::Path ();

my $dir = 'temp';
File::Path::rmtree $dir if -d $dir;
File::Path::mkpath $dir; 

sub create (@) {
    for (@_) { 
	local *FILE;
        open  FILE, '>'. File::Spec->catfile($dir, $_) or die $!; 
	print FILE "This is @_\n";
        close FILE or die $!;
    } 
}

create qw(bing.txt bong.txt);

# test 2

File::Rename::rename( [ glob File::Spec->catfile($dir,'b*') ], 's/i/a/' );
opendir DIR, $dir or die $!;
is_deeply( [ sort grep !/^\./, readdir DIR ], 
		[qw(bang.txt bong.txt)], 'rename - files' );
closedir DIR or die $!; 

# test 3

close STDIN or die;
pipe(STDIN, WRITE) or die;
my $pid = fork;
die unless defined $pid;

unless( $pid ) {	# CHILD
    close WRITE;
    File::Rename::rename( [], 'substr $_, -7, 2, "u"' );
    # diag "Child: $$";
# Test::Builder 0.15 does _ending in children
    Test::Builder->new->no_ending(1) unless
        $Test::Builder::VERSION > 0.15;
    exit; 
}

close STDIN; 
print WRITE File::Spec->catfile($dir,'bong.txt');
print WRITE "\n"; 
close WRITE or die $!;
# diag "Parent: $$";
wait;

# diag "Waited: $pid";
opendir DIR, $dir or die $!;
is_deeply( [ sort grep !/^\./, readdir DIR ], 
		[qw(bang.txt bug.txt)], 'rename - list' );
closedir DIR or die $!; 

File::Path::rmtree $dir; 

