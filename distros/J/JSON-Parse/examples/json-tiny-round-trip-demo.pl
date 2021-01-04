#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use utf8;
use JSON::Tiny '0.58', qw(decode_json encode_json);
use JSON::Parse;
use JSON::Create;
binmode STDOUT, ":encoding(utf8)";
my $cream = '{"clapton":true,"hendrix":false}';
my $jp = JSON::Parse->new ();
my $jc = JSON::Create->new (sort => 1);

print "First do a round-trip of our modules:\n\n";
print $jc->run ($jp->run ($cream)), "\n\n";

print "Now do a round-trip of JSON::Tiny:\n\n";
print encode_json (decode_json ($cream)), "\n\n";

print "🥴 First, incompatible mode:\n\n";
print 'tiny(parse): ', encode_json ($jp->run ($cream)), "\n";
print 'create(tiny): ', $jc->run (decode_json ($cream)), "\n\n";

# Set our parser to produce these things as literals:
$jp->set_true (JSON::Tiny::true);
$jp->set_false (JSON::Tiny::false);

print "🔄 Compatibility with JSON::Parse:\n\n";
print 'tiny(parse):', encode_json ($jp->run ($cream)), "\n\n";
$jc->bool ('JSON::Tiny::_Bool');

print "🔄 Compatibility with JSON::Create:\n\n";
print 'create(tiny):', $jc->run (decode_json ($cream)), "\n\n";

print "🔄 JSON::Parse and JSON::Create are still compatible too:\n\n";
print $jc->run ($jp->run ($cream)), "\n";
