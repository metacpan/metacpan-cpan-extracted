#!/usr/bin/env perl

use Test::More;
use MarpaX::Repa::Test;
my $test = 'MarpaX::Repa::Test';


note "complete match completes";
{
    my ($lexer, $rec) = $test->recognize(
        tokens => { word => qr/XY/ }, input => "XY", complete => 1,
    );
    is_deeply( $rec->value, \{ rule => 'text', value => "XY" } );
    is ${$lexer->buffer}, '';
}

note "partial match fails";
{
    my ($lexer, $rec) = eval { $test->recognize(
        tokens => { word => qr/X/ }, input => "XY", complete => 1
    ) };
    ok !$lexer, "parser failed";
    diag $@;
}

note "empty match fails";
{
    my ($lexer, $rec) = eval { $test->recognize(
        rules => [
            ['text' => [] ],
            ['text' => ['word'] ],
        ],
        tokens => { word => qr/Z/ },
        input => "XY",
        complete => 1,
    ) };
    ok !$lexer, "parser failed";
    diag $@;
}

note "empty match successes";
{
    my ($lexer, $rec) = $test->recognize(
        rules => [
            ['text' => [] ],
            ['text' => ['word'] ],
        ],
        tokens => { word => qr/Z/ },
        input => "",
        complete => 1,
    );
    is_deeply( $rec->value, \{ rule => 'text', value => undef } );
}

done_testing;
