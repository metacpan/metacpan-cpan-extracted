# -*- perl -*-

use Test::More tests => 10000;
use Cwd;
my $orig_cwd = cwd();
chdir('t') if -d 't';
use File::Spec::Functions;
unless(-d 'testdir') {
    mkdir('testdir');
    chdir('testdir');
    foreach my $i (1..10) {
	mkdir(catfile($i));
	foreach my $y (1..10) {
	    mkdir(catfile($i,$y));    
	    foreach my $j (1..10) {
		mkdir(catfile($i,$y,$j));
		foreach my $file (1..10) {
		    open(my $fh, "+>". catfile($i,$y,$j,"$file.txt")) || die $!;
		    print $fh "hi!";
		    close($fh);
		}
	    }
	}
    }
    chdir('..');
}
chdir('testdir');
foreach my $i (1..10) {
    foreach my $y (1..10) {
	foreach my $j (1..10) {
	    foreach my $file (1..10) {
		my $filename = catfile($i,$y,$j,"$file.txt"); 
		is(-e $filename, 1, "File '$filename' is there");
	    }
	}
    }
}
chdir($orig_cwd);


