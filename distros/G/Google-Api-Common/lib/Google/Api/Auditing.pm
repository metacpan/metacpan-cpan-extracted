package Google::Api::Auditing;

use strict;
use warnings;
use MIME::Base64 ();
use Protobuf;
use Protobuf::DescriptorPool;

our $VERSION = '0.01';

BEGIN {
    my $descriptor_b64 = 'Chlnb29nbGUvYXBpL2F1ZGl0aW5nLnByb3RvEgpnb29nbGUuYXBpYgZwcm90bzM=';
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

1;
