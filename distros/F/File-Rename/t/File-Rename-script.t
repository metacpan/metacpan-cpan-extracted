# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl -I/usr/local/bin t/File-Rename-script.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
BEGIN { push @INC, qw(blib/script) if -d 'blib' };

my $script = ($^O =~ m{Win} ? 'file-rename' : 'rename');
my $require_ok =  eval { require($script) };
ok( $require_ok, 'require script - '. $script);
die $@ unless $require_ok;
like( $INC{$script}, qr{/ $script \z}msx, "required $script in \%INC");

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
        open my $fh, '>',  File::Spec->catfile($dir, $_) or die $!; 
        close $fh or die $!;
    } 
}

create qw(bing.txt bong.txt);

sub main_argv { local @ARGV = @_; main () } 

# test 2

main_argv( 's/i/a/', glob File::Spec->catfile($dir,'b*') ); 
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
    main_argv( 'substr $_, -7, 2, "u"' );
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

