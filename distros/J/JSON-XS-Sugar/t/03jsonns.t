#!/usr/bin/perl

use 5.0014;
use strict;
use warnings;

use Test::More tests => 26;
use JSON::XS::Sugar qw(
    json_number json_string
);

use B;
use Test::Warn qw(warning_like);

## no critic (ValuesAndExpressions::ProhibitMismatchedOperators)
## no critic (Subroutines::ProhibitSubroutinePrototypes)

########################################################################

sub is_number($;$) {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $thingy = shift;
    my $label  = shift;

    my $obj = B::svref_2object( \$thingy );
    ok( $obj->isa('B::IV') || $obj->isa('B::NV'), $label // 'is number' )
        or diag ref $obj;
}

sub is_string($;$) {
    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $thingy = shift;
    my $label  = shift;

    my $obj = B::svref_2object( \$thingy );
    ok( $obj->isa('B::PV'), $label // 'is string' )
        or diag ref $obj;
}

########################################################################
# numbers
########################################################################

{
    my $thingy = json_number 14;
    is_number $thingy, '+ve int < IV';
    is $thingy, 14, 'check value is the same';
}

{
    my $thingy = json_number ~1;
    is_number $thingy, '+ve int < UV';
    is $thingy, ~1, 'check value is the same';
}

{
    my $thingy = json_number - 14;
    is_number $thingy, '-ve int < IV';
    is $thingy, -14, 'check value is the same';
}

{
    my $thingy = json_number - ( ~1 );
    is_number $thingy, '-ve int < UV';
    is $thingy, -( ~1 ), 'check value is the same';
}

{
    my $thingy = json_number 14.1;
    is_number $thingy, 'floating number';
    is $thingy, 14.1, 'check value is the same';
}

### same again, but passing in strings

{
    my $thingy = json_number q{} . 14;
    is_number $thingy, '+ve int < IV';
    is $thingy, 14, 'check value is the same';
}

{
    my $thingy = json_number q{} . ~1;
    is_number $thingy, '+ve int < UV';
    is $thingy, ~1, 'check value is the same';
}

{
    my $thingy = json_number q{} . -14;
    is_number $thingy, '-ve int < IV';
    is $thingy, -14, 'check value is the same';
}

{
    my $thingy = json_number q{} . -( ~1 );
    is_number $thingy, '-ve int < UV';
    is $thingy, -( ~1 ), 'check value is the same';
}

{
    my $thingy = json_number q{} . 14.1;
    is_number $thingy, 'floating number';
    is $thingy, 14.1, 'check value is the same';
}

########################################################################
# strings
########################################################################

{
    my $thingy = json_string 1234;
    is_string $thingy;
    is $thingy, 1234, 'check value is the same';
}

{
    my $thingy = json_string q{} . 1234;
    is_string $thingy;
    is $thingy, 1234, 'check value is the same';
}

########################################################################
# warnings
########################################################################

# these are a little fragile because they're string matching on Perl
# warning text.  Oh well.

my $file = quotemeta(__FILE__);

{
    my $line = __LINE__ + 2;
    warning_like {
        json_string undef;
    }
    qr/Use of uninitialized value in string at $file line $line./;
}

{
    my $line = __LINE__ + 2;
    warning_like {
        json_number 'abc123';
    }
    qr/Argument "abc123" isn't numeric in json_number at $file line $line./;
}
