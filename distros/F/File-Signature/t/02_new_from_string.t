# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
use File::Signature;

#########################

my $METHOD = qr/File::Signature::new_from_string\(\)/;

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.


eval { my $obj = File::Signature->new_from_string() }; 
like( $@, qr/^$METHOD: argument required/, "exception: argument required");

eval { my $obj = File::Signature->new_from_string('') }; 
like( $@, qr/^$METHOD: argument was null/, "exception: argument was null");

eval { my $obj = File::Signature->new_from_string('badstring') }; 
like( $@, qr/^$METHOD: bad object string/, "exception: bad object string");

eval { my $obj = File::Signature->new_from_string("\0ERROR\0") }; 
like( $@, qr/^$METHOD: bad errobj string/, "exception: bad errobj string");

{
    do 't/util.pl';
    touch_testfile;
    my $o1 = File::Signature->new('./testfile');
    my $o2 = File::Signature->new_from_string("$o1");
    is( $o1->pathname,  $o2->pathname , "success with good object");
}

{
    my $o1 = File::Signature->new('./nonexistent');
    my $o2 = File::Signature->new_from_string("$o1");
    is( scalar $o1->error,  scalar $o2->error, "success with error object");
}





