#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

our $ran = 0;

sub _eval {
    my $code = shift;

    local $@;

    # double eval necessary for cleanup-time bugs
    my $ok = eval qq{
        use Lexical::SingleAssignment;
        $code;
        1;
    };

    return $ok ? '' : ( $@ || "unknown error" );
}

sub eval_ok {
    my ( $code, @args ) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    &is( _eval($code), '', @args );
}

sub eval_nok {
    my ( $code, $re, @args ) = @_;

    $re ||= qr/./;

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    &like( _eval($code), $re, @args );
}

eval_ok q{
    my $x = 4;
}, "sassign";

eval_ok q{
    my $x = 4;
    is( $x, 4, "sassign still works" );
}, "sassign";

eval_ok q{
    my $x = rand;
    ok( defined($x), "sassign still works" );
}, "sassign";

eval_ok q{
    my @y = qw(foo bar);
}, "simple aassign";

eval_ok q{
    my @y = qw(foo bar);
    is( scalar(@y), 2, "aassign still works" );
}, "simple aassign";

eval_ok q{
    my ( $x, @y ) = qw(foo bar);

    is( $x, "foo", "compound aasign still works");
    is( $y[0], "bar", "compound aassign still works");
}, "compound aassign";

eval_nok q{
    my $x = 4;
    $x = 5;
}, qr/declaration/, "sassign post declaration";

eval_nok q{
    my ( $x, @y ) = qw(foo bar);
    $x = "bar";
}, qr/declaration/, "sassign post declaration";

eval_nok q{
    my ( $x, @y ) = qw(foo bar);
    ( $x, @y ) = qw(bar foo);
}, qr/declaration/, "aassign post declaration";

eval_nok q{
    my $x = "foo";
    my $y = "bar";

    ( $x, $y ) = qw(bar foo);
}, qr/declaration/, "aassign post declaration";



eval_nok q{
    my ( $x, @y ) = qw(foo bar);

    $ran++;

    $y[0] = "foo";
}, qr/./, "aassign creates readonly array elements";

{
    local $TODO = "can't detect assignment to subscript over AV/HV yet, runtime error instead";
    is( $ran, 0, "caught at compile time" );
}




$ran = 0;

eval_nok q{
    my ( $x, @y ) = qw(foo bar);

    $ran++;

    pop @y;
}, qr/./, "aassign creates readonly arrays";

{
    local $TODO = "can't detect assignment to subscript over AV/HV yet, runtime error instead";
    is( $ran, 0, "caught at compile time" );
}


$ran = 0;

eval_nok q{
    my ( $x, %z ) = qw(foo bar baz);

    $ran++;

    $z{bar} = "foo";
}, qr/./, "aassign creates readonly hash elements";

{
    local $TODO = "can't detect assignment to subscript over AV/HV yet, runtime error instead";
    is( $ran, 0, "caught at compile time" );
}


$ran = 0;

eval_nok q{
    my ( $x, %z ) = qw(foo bar baz);

    $ran++;

    $z{new_key} = "foo";
}, qr/./, "aassign creates readonly hashes";

{
    local $TODO = "can't detect assignment to subscript over AV/HV yet, runtime error instead";
    is( $ran, 0, "caught at compile time" );
}



eval_nok q{
    my $x = 3;
    my $ref = \$x;
    $$ref = 3;
}, qr/read-only/, "sassign creates readonly scalars (by ref)";

eval_nok q{
    my ( $x, @y ) = qw(foo bar);

    my $ref = \$x;
    $$ref = "bar";
}, qr/read-only/, "aassign creates readonly scalars (by ref)";

eval_nok q{
    my ( $x, @y ) = qw(foo bar);

    my $ref = \@y;
    pop @$ref;
}, qr/read-only/, "aassign creates readonly arrays (by ref)";

eval_nok q{
    my ( $x, @y ) = qw(foo bar);

    my $ref = \@y;
    $ref->[0] = "foo";
}, qr/read-only/, "aassign creates readonly array elements (by ref)";

eval_nok q{
    my $x;
}, qr/lexical without assignment/, "declaration without assignment";

eval_nok q{
    my @y;
}, qr/lexical without assignment/, "declaration without assignment";

eval_nok q{
    my %h;
}, qr/lexical without assignment/, "declaration without assignment";

eval_ok q{
    {
        no Lexical::SingleAssignment;

        my $x;

        $x = 3;
    }
}, "unimport";

eval_nok q{
    my $x = 5;
    {
        no Lexical::SingleAssignment;

        $x = 3;
    }
}, qr/read-only/, "unimport, assignment to var declared in scope";

eval_nok q{
    my $x = 3;

    BEGIN { die "foo" }
}, qr/foo/, "unrelated errors pass through";

eval_nok q{
    my $x;

    BEGIN { die "foo" }
}, qr/foo/, "delayed padsv check does not clobber errors";

done_testing;

# ex: set sw=4 et:

