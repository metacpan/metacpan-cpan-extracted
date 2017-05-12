#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN {
    use_ok( 'Devel::Declare::Parser::Sublike', 'sl' );
    use_ok( 'Devel::Declare::Parser::Codeblock', 'cb' );
    use_ok( 'Devel::Declare::Parser::Method', 'mth' );
    Devel::Declare::Interface::enhance( 'main', $_->[0], $_->[1] )
        for [ 'sl', 'sublike'   ],
            [ 'cb', 'codeblock' ],
            [ 'mth', 'method'   ],
}

sub
sl {
    $_[-1]->();
}

sub cb {
    $_[-1]->();
}

sub mth {
    $_[-1]->( 'self' );
}

sub beg {
    $_[-1]->();
};


our %ran;

sl a {
    $ran{sl}++;
}

sl {
    $ran{sl}++;
}

cb {
    $ran{cd}++;
}

mth a {
    is( $self, 'self', "got self" );
    $ran{mth}++;
}

is( $ran{sl}, 2, "ran sl twice" );
ok( $ran{cd}, "ran cd" );
ok( $ran{mth}, "ran mth" );

done_testing();
