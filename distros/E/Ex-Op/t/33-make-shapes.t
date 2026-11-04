#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Ex::Op ();

no strict 'refs';

{
    my $code = sub { my ($x) = @_; my $c = sub { my $t = 1; $t + $x }; $c };
    ok( !Ex::Op::make('cl', $code), 'a closure with a lexical of its own before the parameter it captures' );
    is( Ex::Op::why_not($code), 'it makes a closure over its own variables', '... is declined for the capture' );
}

{
    my $code = do { local $^P = $^P | 0x02; eval 'sub { my ($x) = @_; if ($x) { 1 } else { 2 } }' } or die $@;
    ok( Ex::Op::make('traced', $code), 'a body compiled with line tracing on' );
    is( &{"main::traced"}(1), 1, '... runs' );
}

{
    ok( Ex::Op::make('empty1', sub { }), 'an empty body' );
    ok( Ex::Op::make('empty2', sub { ; }), 'a body of one empty statement' );
    is_deeply( [ &{"main::empty2"}(1) ], [], '... returns nothing' );
    ok( Ex::Op::make('dob', sub { my ($x) = @_; do { $x + 1 } }), 'a do block as the tail' );
    is( &{"main::dob"}(1), 2, '... gives its value' );
}

{
    my $code = sub { my ($x, %h) = @_; $x };
    ok( !Ex::Op::make('hashed', $code), 'a hash among the parameters' );
    is( Ex::Op::why_not($code), 'its parameters end in an array or a hash', '... is declined' );
}

{
    BEGIN { $^H{'Ex::Op/strict'} = 0 }
    ok( !Ex::Op::make('ns', sub { shift }), 'with the strict hint set false a declined sub is only declined' );
}

like( eval { Ex::Op::make('ar', []); 1 } ? '' : $@, qr/^Ex::Op::make needs a code reference/, 'an array reference is not code' );

done_testing;
