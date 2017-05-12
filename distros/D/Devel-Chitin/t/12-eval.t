#!/usr/bin/env perl
use strict;
use warnings; no warnings 'void';

use lib 'lib';
use lib 't/lib';
use File::Basename;
use Devel::Chitin::TestRunner;

run_test(
    11,
    sub {
        no strict 'vars';
        no warnings 'once';
        $global = 'global';         # package global
        @Other::global = (1,2);     # different package
        sub context_dependant {
            return wantarray ? (1,2,3) : 1;
        }
        sub do_die { die "in do_die" }

        foo(3,2,1);
        sub foo {
            my $lex_scalar = 'scalar';  # lexical
            my %lex_hash = (key => 3);  # lexical
            my $undef = undef;
            $DB::single=1;
            27;
        }
    },
    \&test_eval,
    'done',
);
    
sub test_eval {
    my($db, $loc) = @_;

    $db->test_eval('$global', 0,
        sub { is(@_, 'global', 'package global variable') } );

    $db->test_eval('@Other::global', 0,
        sub { is(@_, 2, 'package global list in scalar context') });

    $db->test_eval('@Other::global', 1,
        sub { is(@_, [1,2], 'package global list in list context') });

    $db->test_eval('$lex_scalar', 0,
        sub { is(@_, 'scalar', 'lexical scalar') });

    $db->test_eval('%lex_hash', 1,
        sub { is(@_, [ key => 3 ], 'lexical hash') });

    $db->test_eval('$undef', 0,
        sub { is(@_, undef, 'undef variable') });

    $db->test_eval('context_dependant()', 0,
        sub { is(@_, 1, 'context dependant function in scalar context') });

    $db->test_eval('context_dependant()', 1,
        sub { is(@_, [1,2,3], 'context dependant function in list context') });

    $db->test_eval('@_', 1,
        sub { is(@_, [3,2,1], 'function args @_') });

    $db->test_eval('do_die()', 0,
        sub { is_exception(@_, qr(in do_die), 'generate exception') });

}

sub is {
    my($got, $exception, $cmp, $msg) = @_;
    Test::More::is_deeply([$got, $exception], [$cmp, ''] , $msg);
}

sub is_exception {
    my($got, $exception, $exc, $msg) = @_;
    Test::More::like($exception, $exc, $msg);
    Test::More::ok(! defined($got), 'exception evaluated to undef');
}
       

