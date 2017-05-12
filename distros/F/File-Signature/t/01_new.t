# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;

use File::Signature;

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $METHOD = qr/File::Signature::new\(\)/;

### No pathname 
{
    eval { my $obj = File::Signature->new() }; 
    like( $@, qr/^$METHOD: pathname required/, "no pathname");
}

### Null pathname 
{
    eval { my $obj = File::Signature->new('') }; 
    like( $@, qr/^$METHOD: pathname was null/, "null pathname");
}


##     new("good.txt"); 
SKIP: {
    skip "Couldn't create test file.", 2, unless open F, '>', './testfile'; 
    my $sig = File::Signature->new('./testfile');
    is( undef, $sig->error, 'no error' );
    like( $sig->{pathname}, qr!^/!, 'constructed absolute pathname' ); 
    unlink "./testfile";
}

##     new("unreadable");
SKIP: {
    skip "Couldn't create test file.", 2, unless open F, '>', './unreadable'; 
    skip "Couldn't chmod test file.", 2, unless chmod 0222, './unreadable'; 
    my $sig = File::Signature->new('./unreadable'); 
    like( $sig->error, qr!open failure!, 'unreadable file' ); # Cannot read.
    unlink './unreadable'; 
}

##     new("nonexistent");
{
    my $sig = File::Signature->new('./nonexistent');
    like( $sig->error, qr!stat failure!, 'nonexistent file' ); # Cannot stat.
}

