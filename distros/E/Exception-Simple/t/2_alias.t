use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;
use FindBin qw/$Bin/;
use lib "$Bin/lib";

subtest 'alias' => sub {
    plan tests => 6;

    use Exception::Simple qw/E/;

    throws_ok{
        E->throw(error => 'this is an error');
    } 'Exception::Simple';

    my $e = $@;

    is($e, 'this is an error', 'stringifaction works' );
    is( $e->error, 'this is an error', 'error method works' );

    throws_ok{
        $e->rethrow;
    } 'Exception::Simple';
    is($@, 'this is an error', 'rethrow: stringifaction works');
    is( $@->error, 'this is an error', 'rethrow: error method works' );
};

sub dont_replace_me { 1 }
subtest 'redefine sub' => sub {
    plan tests => 5;

    #because it's already imported into this package above
    dies_ok{
        #can't "use" as that's done at compile time
        Exception::Simple->import( qw/E/ );
    } 'redefine dies';
    like( $@, qr!sub E already exists in main at t/2_alias\.t line 37!, 'error correct' );

    dies_ok{
        Exception::Simple->import( qw/dont_replace_me/ );
    } 'redefine dies';
    like( $@, qr!sub dont_replace_me already exists in main at t/2_alias\.t line 42!, 'error correct' );

    is( dont_replace_me(), 1, "sub wasn't replaced");

};

subtest 'alais_subclass' => sub {
    plan tests => 3;
    use Derived qw/F/;

    throws_ok{
        F->throw(
            'error' => 'this is an error',
            'noclobber' => 'clobbered'
        );
    } 'Derived';

    my $e = $@;
    is( $e->noclobber, 'original', 'derived override class accessors are preserved' );
    is( $e, 'Error=this is an error', 'stringify works for derived overridden classes' );
};
