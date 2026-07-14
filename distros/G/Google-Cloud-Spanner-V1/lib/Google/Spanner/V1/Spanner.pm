package Google::Spanner::V1::Spanner;

use strict;
use warnings;
use File::Spec;
use Protobuf;
use Protobuf::DescriptorPool;

our $VERSION = '0.01';

my ($vol, $dir, $file) = File::Spec->splitpath(__FILE__);
my $pb_path = File::Spec->catfile($dir, 'descriptors.pb');
if (-f $pb_path) {
    open my $fh, '<:raw', $pb_path or die "Cannot open $pb_path: $!";
    my $bytes = do { local $/; <$fh> };
    close $fh;
    my $pool = Protobuf::DescriptorPool->generated_pool;
    eval { $pool->add_serialized_file_descriptor_set($bytes) }
        || eval { $pool->add_serialized_file($bytes) };
}

1;
