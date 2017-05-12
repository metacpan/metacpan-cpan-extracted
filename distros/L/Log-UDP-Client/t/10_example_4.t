use strict;
use warnings;
use Test::More tests => 4;

use Log::UDP::Client;
use JSON ();

# Use of JSON serializer
my $logger = Log::UDP::Client->new( serializer_module => 'JSON' );
isa_ok($logger,'Log::UDP::Client','$logger is not a Log::UDP::Client instance');
is($logger->serializer_module, 'JSON', 'serializer_module constructor param not transfered');

# Will emit {"message":"Hi"} because JSON wants to wrap stuff into a hashref
is($logger->send("Hi"), 1, 'send simple scalar with JSON encoding failed');

my $string="Hi";
is($logger->serialize($string),'{"_serialized_object":"Hi"}', 'JSON serializing failed');
