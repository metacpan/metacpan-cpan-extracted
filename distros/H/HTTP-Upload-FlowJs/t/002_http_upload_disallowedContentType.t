#!perl -w
use strict;
use warnings;
use Test::More tests => 3;
use Data::Dumper;
use File::Temp 'tempdir';
use File::Copy 'cp';

use HTTP::Upload::FlowJs;

my $tempdir = tempdir();

my $called = 0;
my $flowjs = HTTP::Upload::FlowJs->new(
    incomingDirectory => $tempdir,
    allowedContentType => sub {
        $called++;
        $_[0] =~ m!^image/!
    },
);

# Try to "upload" a text file as image
my %info = (
        flowChunkNumber => 1,
        flowChunkSize => -s $0,
        flowCurrentChunkSize => -s $0,
        flowFilename => 'IMG_7363.JPG',
        flowIdentifier => '2226376-IMG_7363JPG',
        flowRelativePath => 'IMG_7363.JPG',
        flowTotalChunks => 1,
        flowTotalSize => -s $0,
        localChunkSize => 10_000_000,
        file => $0,
);
my $chunkname = $flowjs->chunkName( \%info, undef, 1 );
cp $0 => $chunkname
    or die "Couldn't copy $0 to '$chunkname': $!";
    
my @errors = $flowjs->validateRequest(
    'POST',
    \%info,
);

my( $content_type, $image_ext ) = $flowjs->sniffContentType(\%info);
is $content_type, 'application/x-perl', "We sniff the correct context type";

my $not_allowed = $flowjs->disallowedContentType( \%info );
ok $not_allowed, "Text files are not allowed";
is $called, 1, "We check for the file type once";
