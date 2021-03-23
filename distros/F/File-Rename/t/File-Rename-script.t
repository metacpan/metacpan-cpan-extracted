# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl -I/usr/local/bin t/File-Rename-script.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
push @INC, qw(blib/script) if -d 'blib';
unshift @INC, 't' if -d 't';
require 'testlib.pl';

my $script = script_name();
my $require_ok =  eval { require($script) };
ok( $require_ok, 'require script - '. $script);
die $@ unless $require_ok;
like( $INC{$script}, qr{/ $script \z}msx, "required $script in \%INC");

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $dir = tempdir();

create(qw(bing.txt bong.txt));

# test 2

main_argv( 's/i/a/', glob File::Spec->catfile($dir,'b*') ); 
is_deeply( [ sort( listdir( $dir ) ) ],
		[qw(bang.txt bong.txt)], 'rename - files' );

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
is_deeply( [ sort( listdir( $dir ) ) ],
		[qw(bang.txt bug.txt)], 'rename - list' );

File::Path::rmtree($dir); 

