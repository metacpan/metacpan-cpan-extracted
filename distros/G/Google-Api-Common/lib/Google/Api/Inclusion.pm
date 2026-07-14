package Google::Api::Inclusion;

use strict;
use warnings;
use MIME::Base64 ();
use Protobuf;
use Protobuf::DescriptorPool;

our $VERSION = '0.01';

BEGIN {
    my $descriptor_b64 = 'Chpnb29nbGUvYXBpL2luY2x1c2lvbi5wcm90bxIKZ29vZ2xlLmFwaWIGcHJvdG8z';
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

1;
