#! perl

use strict;
use warnings;

use IPC::PrettyPipe::DSL ':all';

use Test::More;
use Test::Exception;

throws_ok {

	pparg;

} qr/missing required/i, 'no args';

subtest 'arg' => sub {

    my $arg;
    lives_ok { $arg = pparg '-f' } 'pparg';
    is( $arg->name, '-f' );

};

subtest  'arg, value' => sub {

    my $arg;

    lives_ok { $arg = pparg -f => 'Makefile' } 'pparg';

    is( $arg->name, '-f' );
    is( $arg->value, 'Makefile' );

};

subtest  'sep, arg, value' => sub {

    my $arg;
    lives_ok { $arg = pparg argpfx '-', f => 'Makefile' } 'pparg';

    is( $arg->name, 'f' );
    is( $arg->value, 'Makefile' );
    is( $arg->pfx, '-' );

};

subtest  'sep, arg, sep, value' => sub {

    my $arg;
    lives_ok { $arg = pparg argpfx('-'), argsep('='), f => 'Makefile' } 'pparg';

    is( $arg->name, 'f' );
    is( $arg->value, 'Makefile' );
    is( $arg->pfx, '-' );
    is( $arg->sep, '=' );

};


done_testing;
