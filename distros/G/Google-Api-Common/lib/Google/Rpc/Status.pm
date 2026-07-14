package Google::Rpc::Status;

use strict;
use warnings;
use MIME::Base64 ();
use Protobuf;
use Protobuf::DescriptorPool;

our $VERSION = '0.01';

BEGIN {
    my $descriptor_b64 = 'Chdnb29nbGUvcnBjL3N0YXR1cy5wcm90bxIKZ29vZ2xlLnJwYyInCgZTdGF0dXMSDAoEY29kZRgBIAEoBRIPCgdtZXNzYWdlGAIgASgJYgZwcm90bzM=';
    Protobuf::DescriptorPool->generated_pool->add_serialized_file(MIME::Base64::decode_base64($descriptor_b64));
}

1;
