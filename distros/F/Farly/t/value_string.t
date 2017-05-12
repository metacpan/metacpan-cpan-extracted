use strict;
use warnings;

use Test::Simple tests => 11;

use Farly::Value::String;

my $s1 = Farly::Value::String->new(" x");
my $s2 = Farly::Value::String->new("x");
my $s3 = Farly::Value::String->new("y");

eval { my $s4 = Farly::Value::String->new(); };

ok ( $@ =~ /string required/, "null input" );

ok( $s1->equals($s2), "equals" );

ok( !$s1->equals($s3), "!equals" );

ok( $s2->contains($s1), "contains" );

ok ( $s1->as_string() eq "x", "as_string");

ok ( $s1->intersects($s2), "intersects");

ok ( ! $s1->intersects($s3), "!intersects");

my $s4 = Farly::Value::String->new("string31");

my $s5 = Farly::Value::String->new("string11");

ok ( ! $s4->intersects($s5), "!intersects");

my $s6 = Farly::Value::String->new("x");
my $s7 = Farly::Value::String->new("y");

ok( $s6->compare( $s2 ) == 0, "compare equal");

ok( $s6->compare( $s7 ) == -1, "compare less than");

ok( $s7->compare( $s6 ) == 1, "compare greater than");

