# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 6;
use File::Signature;

#########################

SKIP: {
    open F, '>', './testfile' or skip 'unable to open testfile.';
    my $obj = File::Signature->new('./testfile'); 
    is( undef, $obj->error, 'object created.' ); 
    isnt( 1, $obj->changed, 'change() was false.' );
    print F 'foo'; 
    close F; 
    is( 1, $obj->changed, 'change() was true.' );
    unlink './testfile';
}

SKIP: {
    open F, '>', './testfile' or skip 'unable to open testfile.';
    my $obj = File::Signature->new('./testfile'); 
    is( undef, $obj->error, 'object created.' ); 
    print F 'foo'; 
    close F; 
    my @changed = $obj->changed;
    ok( eq_set(\@changed, [qw( digest size )]), "changed() in list context." );
    unlink './testfile';
}

{
    my $errobj = File::Signature->new('./nonexistent');
    eval { $errobj->changed() }; 
    like( $@, qr/bad method call/, 'threw exception' );
}

