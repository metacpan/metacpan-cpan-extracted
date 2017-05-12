# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl -I/usr/local/bin t/File-Rename-script.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;
BEGIN { push @INC, qw(blib/script) if -d 'blib' };

my $script = ($^O =~ m{Win} ? 'file-rename' : 'rename');
my $require_ok =  eval { require($script) };
ok( $require_ok, 'require script - '. $script);
die $@ unless $require_ok;

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

main_argv('-E', 's/i/a/', '-E', 's/g/j/',
	glob File::Spec->catfile($dir,'b*') ); 
opendir DIR, $dir or die $!;
is_deeply( [ sort grep !/^\./, readdir DIR ], 
		[qw(banj.txt bonj.txt)], 'rename - files' );
closedir DIR or die $!; 

File::Path::rmtree $dir;
