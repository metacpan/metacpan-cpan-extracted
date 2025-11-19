#!/usr/bin/env perl

use Test2::V0;

use Dev::Util::Syntax;
use Dev::Util::Const;

use Socket;

plan tests => 5;

my $emt_str = q{};
my $sp      = q{ };
my $sq      = q{'};
my $dq      = q{"};
my $comm    = q{,};

is( $EMPTY_STR,    $emt_str, 'empty string' );
is( $SPACE,        $sp,      'space' );
is( $SINGLE_QUOTE, $sq,      'single quote' );
is( $DOUBLE_QUOTE, $dq,      'double quote' );
is( $COMMA,        $comm,    'comma' );

done_testing;

