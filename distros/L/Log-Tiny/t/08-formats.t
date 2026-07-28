#!perl

use strict;
use warnings;
use Test::More tests => 5;

BEGIN {
	use_ok( 'Log::Tiny' );
}

my ( $buf1, $buf2 ) = ( '', '' );
open( my $fh1, '>>', \$buf1 ) or die $!;
open( my $fh2, '>>', \$buf2 ) or die $!;

# log1 overrides the built-in %c (category) code; log2 is a plain
# default instance. Both use the same format string.
my $log1 = Log::Tiny->new( $fh1, "%c\n", { c => [ 's', sub { 'OVERRIDDEN' } ] } )
    or die Log::Tiny->errstr;
my $log2 = Log::Tiny->new( $fh2, "%c\n" ) or die Log::Tiny->errstr;

$log1->FOO("a");
$log2->FOO("a");
undef $log1;
undef $log2;
close $fh1;
close $fh2;

is( $buf1, "OVERRIDDEN\n", "Per-instance override applied" );
is( $buf2, "FOO\n",        "Other instance unaffected (default %c = category)" );

# The package template must not have been mutated by the customisation.
is( $Log::Tiny::formats{c}[1]->('CAT', 'msg'), 'CAT',
    "Package %formats 'c' still resolves to the category (not polluted)" );

# Overriding %m works too (e.g. to redact messages).
my $buf3 = '';
open( my $fh3, '>>', \$buf3 ) or die $!;
my $log3 = Log::Tiny->new( $fh3, "%m\n", { m => [ 's', sub { 'REDACTED' } ] } )
    or die Log::Tiny->errstr;
$log3->LOG("secret");
undef $log3;
close $fh3;
is( $buf3, "REDACTED\n", "Built-in %m can be overridden per-instance" );
