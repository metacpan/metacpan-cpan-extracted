# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 4;
use File::Signature;

#########################

SKIP: {
    open F, '>', './testfile' or skip 'unable to create testfile.'; 
    my $obj = File::Signature->new('./testfile'); 
    is (undef, $obj->error(), 'object created.'); 
    is (1, $obj->is_same(), 'is_same() was true.'); 
    print F 'foo'; 
    close F;
    isnt (1, $obj->is_same(), 'is_same() is false.'); 
    unlink './testfile';
}

{
    my $errobj = File::Signature->new('./nonexistent');
    eval { $errobj->changed() };
    like( $@, qr/bad method call/, 'threw exception' );
}


