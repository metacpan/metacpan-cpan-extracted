use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;

use Exception::Simple;

use FindBin qw/$Bin/;
use lib "$Bin/lib";
use Derived;
use Test;

subtest 'basic' => sub {
    plan tests => 6;

    throws_ok{
        Exception::Simple->throw(error => 'this is an error');
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

subtest 'hash' => sub {
    plan tests => 3;

    throws_ok{
        Exception::Simple->throw(error => 'this is an error', 'other' => 'foobar' );
    } 'Exception::Simple';

    my $e = $@;
    isa_ok( $e, 'Exception::Simple' );
    is( $e->other, 'foobar', 'other accessor has been created' );
};

subtest 'rethrow not redefined' => sub {
    plan tests => 3;

    throws_ok{
        Exception::Simple->throw(
            'error' => 'this is an error',
            'other' => 'foobar',
            'rethrow' => 'i has no accessor',
        );
    } 'Exception::Simple';

    my $e = $@;
    isa_ok( $e, 'Exception::Simple' );
    throws_ok{
        $e->rethrow;
    } 'Exception::Simple';
};

subtest 'Derived class' => sub {
    plan tests => 3;

    throws_ok{
        Derived->throw(
            'error' => 'this is an error',
            'noclobber' => 'clobbered'
        );
    } 'Derived';

    my $e = $@;
    is( $e->noclobber, 'original', 'derived override class accessors are preserved' );
    is( $e, 'Error=this is an error', 'stringify works for derived overridden classes' );
};

subtest 'package' => sub {
    plan tests => 4;

    my $test = Test->new;

    throws_ok{
        $test->something
    } 'Exception::Simple';
    my $e = $@;
    is( $e->_filename, "$Bin/lib/Test.pm", 'filename set correctly' );
    is( $e->_line, 6, 'line set correctly' );
    is( $e->_package, 'Test', 'package set correctly' );
};
