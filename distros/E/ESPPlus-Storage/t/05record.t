use strict;
use warnings;
use Test::More tests => 12;
use File::Basename;
use File::Spec::Functions;
use ESPPlus::Storage;

my $test_dir = dirname( $0 );


my $rec_num = 1;
my $timestamp = "1004408651";
my $header = "H=56;T=-3;L=10;C=4;U=$timestamp;A=abcd;AFP=v10/29/01,o0;";
my $record_body = "\37\235\220\61\144\314\240\121\303\306\15\34\71\140\0";

# Hows that for a hokey uncompress routine, eh?
sub uncompress { \ "1234567890" }
sub vis { map join('', map +(/[^[:print:]]/ ? sprintf("\\%o",ord) : $_), split //, $_), @_ }

my $rec = ESPPlus::Storage::Record->new
  ({ header_text         => \ $header,
     compressed          => \ $record_body,
     uncompress_function => \ &uncompress,
     record_number       => $rec_num });
ok( $rec,
    '::Record->new(...) returns something' );
is( ref $rec,
    'ESPPlus::Storage::Record',
    '::Record->new( ... ) isa ::Record' );

is( $rec->header_length,
    length $header,
    "::Record->header_length" );

is( ${$rec->header_text},
    $header,
    "::Record->header_text" );

is( $rec->expected_length,
    length ${uncompress()},
    "::Record->expected_length" );

is( $rec->application,
    'abcd',
    "::Record->application" );

is( $rec->timestamp,
    $timestamp,
    "::Record->timestamp" );

is( vis(${$rec->compressed}),
    vis($record_body),
    "::Record->compressed" );

is( $rec->uncompressed,
    undef,
    "::Record->uncompressed 1" );

is( ${$rec->body},
    ${uncompress()},
    "::Record->body 1" );

is( ${$rec->body},
    ${uncompress()},
    "::Record->body 2" );

is( ${$rec->uncompressed},
    ${uncompress()},
    "::Record->uncompressed 2" );
