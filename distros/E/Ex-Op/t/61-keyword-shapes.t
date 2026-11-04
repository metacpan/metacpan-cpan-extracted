#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp ();

BEGIN { plan skip_all => 'the op keyword needs perl 5.14' if $] < 5.014 }

use Ex::Op ();

sub compile_err {
    my ($src) = @_;
    local $@;
    eval qq{package EO::KwShape${\ int rand 1e9};\nuse Ex::Op;\n#line 10 "kw.pl"\n$src\n1} and return undef;
    return $@;
}

like( compile_err('op a:b { 1 }'), qr/^Ex::Op: op a needs a block at kw\.pl line 10\b/, 'a single colon ends the name' );
like( compile_err('op a::; { 1 }'), qr/^Ex::Op: op a needs a block at kw\.pl line 10\b/, 'a double colon followed by no name ends it too' );
like( compile_err('op _under ($x) { $x +; }'), qr/syntax error/, 'a syntax error in the body is reported as perl reports it' );
is( eval "package EO::KwUnder; use Ex::Op; op _under (\$x) { \$x * 2 } _under(4)", 8, 'a name starting with an underscore' );

{
    my $fh = File::Temp->new(SUFFIX => '.pl');
    print $fh "package EO::KwEnd;\nuse strict;\nuse Ex::Op;\nop";
    close $fh;
    local $@;
    do "$fh";
    like( $@, qr/Bareword "op" not allowed/, 'op as the last word of a file is not the keyword' );
}

{
    my $fh = File::Temp->new(SUFFIX => '.pl');
    print $fh "sub op { 42 }\nop(1);\n";
    close $fh;
    is( do "$fh", 42, 'op as a plain sub in a file with no hints at all' );
}

is( eval q{ no warnings 'redefine'; BEGIN { $^H{'Ex::Op/op'} = 0 } sub op { 7 } op(1) }, 7, 'the hint set false leaves op a plain word' );

{
    my @inc = map { "-I$_" } grep { !ref } @INC;
    my $out = `"$^X" @inc -e "BEGIN { require Ex::Op } sub op { 42 } print op(1)"`;
    is( $out, 42, 'op as a plain sub in a program that never made a hints hash' );
}

done_testing;
