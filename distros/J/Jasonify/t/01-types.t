#! /usr/bin/env perl

# Proper testing requires a . at the end of the error message
use Carp 1.25;

use Test2::V0;
plan 62;

ok require Jasonify, 'Can require Jasonify';
#ok( Jasonify->VERSION, 'Jasonify version ' . Jasonify->VERSION );

can_ok(
    'Jasonify',
    qw(
        encode
        boolean literal number string
    )
);

my @array = ();
my @value = ();

my $false = Jasonify::Boolean::false();
my $true  = Jasonify::Boolean::true();

### Jasonify->boolean ###
is( Jasonify->boolean, 'Jasonify::Boolean', 'boolean returns correct class' );
### Jasonify->boolean (false) ###
for my $s (qw( undef \undef 0 \0 '' \'' )) {
    my $v = eval $s;
    push @array, Jasonify->boolean($v);
    push @value, $false;
    is( $array[-1], $value[-1], "boolean($s) is false" );
}
### Jasonify->boolean (true) ###
for my $s (qw( 1 \1 'string' \'string' )) {
    my $v = eval $s;
    push @array, Jasonify->boolean($v);
    push @value, $true;
    is( $array[-1], $value[-1], "boolean($s) is true" );
}

### Jasonify->literal ###
is( Jasonify->literal, 'Jasonify::Literal', 'literal returns correct class' );
for my $s (qw( 0 1 'string' '"1"' '"string"' )) {
    my $v = eval $s;
    push @array, Jasonify->literal($v);
    push @value, $v;
    is( $array[-1], $value[-1], "literal($s) is correct" );
    ok(
        $v ? $array[-1] ? 1 : 0 : $array[-1] ? 0 : 1,
        "$s as literal in boolean context is correct"
    );
}
for my $s (qw( '"0"' '""' 'false' 'null' )) {
    # Values that are false, but are not 0, empty string, or undef.
    my $v = eval $s;
    push @array, Jasonify->literal($v);
    push @value, $v;
    is( $array[-1], $value[-1], "literal($s) is correct" );
    ok(
        $array[-1] ? 0 : 1,
        "$s as literal in boolean context is correct"
    );
}

### Jasonify->number ###
is( Jasonify->number, 'Jasonify::Number', 'number returns correct class' );
### Jasonify->number (unformatted) ###
for my $s (qw( -1 0 1 123456789.0123456789 )) {
    push @array, Jasonify->number($s);
    push @value, $s;
    is( $array[-1], $value[-1], "number($s) is correct" );
    ok(
        $s ? $array[-1] ? 1 : 0 : $array[-1] ? 0 : 1,
        "$s as number in boolean context is correct"
    );
}
### Jasonify->number (formatted %.2f) ###
for my $s (qw( -1234 0 56789 )) {
    push @array, Jasonify->number( '%.2f', $s );
    push @value, "$s.00";
    is( $array[-1], $value[-1], "number( '%.2f', $s ) is correct" );
    ok(
        $s ? $array[-1] ? 1 : 0 : $array[-1] ? 0 : 1,
        "$s as number in boolean context is correct"
    );
}
### Jasonify->number (formatted) ###
for my $s (qw( -123.456 987654.3210 -1234567890.123456 123 )) {
    my ( $i, $lengthi, $f, $lengthf )
        = map { $_, length() } split( /\./, $s, 2 ), '';
    my $lengths = $lengthi + $lengthf + !!$lengthf;
    my $fmt = "%${lengths}.${lengthf}f";
    push @array, Jasonify->number( $fmt, $s );
    push @value, $s;
    ok( $array[-1] ? 1 : 0, "$s as number in boolean context is correct" );
}
for my $s (qw( 0.000 )) {
    my ( $i, $lengthi, $f, $lengthf )
        = map { $_, length() } split( /\./, $s, 2 ), '';
    my $lengths = $lengthi + $lengthf + !!$lengthf;
    my $fmt = "%${lengths}.${lengthf}f";
    push @array, Jasonify->number( $fmt, $s );
    push @value, $s;
    ok( $array[-1] ? 0 : 1, "$s as number in boolean context is correct" );
}

### Jasonify->string ###
is( Jasonify->string, 'Jasonify::Literal', 'string returns correct class' );
for my $s (qw( 0 '' 1 'string' )) {
    my $v = eval $s;
    push @array, Jasonify->string($v);
    push @value, qq!"$v"!;
    is( $array[-1], $value[-1], "string($s) is correct" );
    ok(
        $v ? $array[-1] ? 1 : 0 : $array[-1] ? 0 : 1,
        "$s as string in boolean context is correct"
    );
}

my $value = '[' . join( ', ', @value ) . ']';
is( Jasonify->encode(\@array), $value, 'Everything encodes correctly');
