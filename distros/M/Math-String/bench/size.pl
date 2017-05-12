#!/usr/bin/perl -w

use Math::BigInt lib => 'Calc';
use Math::String;
use Devel::Size::Report qw/report_size/;

print "Math::String v$Math::String::VERSION\n";

Math::BigInt->import( lib => 'Calc' );

my $x = Math::String->new ( 'abc', [ 'a' .. 'z' ] );

delete $x->{_set};

print report_size($x, { class => 1 } ), "\n";

my $set_big = Math::String::Charset->new( [ 'a'..'z', 'A'..'Z', '0'..'9' ] );
my $set_a_z = Math::String::Charset->new( [ 'a'..'z' ] );
my $set_0_9 = Math::String::Charset->new( [ '0'..'9' ] );

my $set_grp = Math::String::Charset->new( { sets => { 0 => $set_a_z, 1 => $set_a_z, -1 => $set_big } } );

print "a..z,A..Z,0..9:\n", report_size($set_big, { class => 1, terse => 1, total => 1 }), "\n";
print "a..z:\n", report_size($set_a_z, { class => 1, terse => 1, total => 1 }), "\n";
print "grouped:\n", report_size($set_grp, { class => 1, terse => 1, total => 1 }), "\n";
