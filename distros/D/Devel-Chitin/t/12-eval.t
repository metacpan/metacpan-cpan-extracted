use strict;
use warnings;

use Test2::V0;  no warnings 'void'; no warnings 'once';
use lib 't/lib';
use TestHelper qw(is_eval is_eval_exception);

our $global = 'global';
@Other::global = (1,2);  # different package
foo('a', 'b', 'c');

sub context_dependant {
    return wantarray ? (1,2,3) : 1;
}

sub do_die { die "in do_die" }

sub foo {
    my $lex_scalar = 'scalar';
    my %lex_hash = (key => 3);
    my $undef = undef;
    $DB::single=1;
    25;
}

sub __tests__ {
    plan tests => 10;

    is_eval('$global', 0, 'global', 'package global variable');
    is_eval('@Other::global', 0, 2, 'package global list in scalar context');
    is_eval('@Other::global', 1, [1,2], 'package global list in list context');
    is_eval('$lex_scalar', 0, 'scalar', 'lexical scalar');
    is_eval('%lex_hash', 1, [ key => 3 ], 'lexical hash');
    is_eval('$undef', 0, undef, 'undef variable');
    is_eval('context_dependant()', 0, 1, 'context_dependant function in scalar context');
    is_eval('context_dependant()', 1, [1,2,3], 'context_dependant function in list context');
    is_eval('@_', 1, ['a', 'b', 'c'], 'function args @_');
    is_eval_exception('do_die()', 0, qr(in do_die), 'generate exception');
}
