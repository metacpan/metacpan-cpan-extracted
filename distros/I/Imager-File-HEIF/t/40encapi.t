#!perl
use strict;
use Test::More;

use Imager::File::HEIF;

my @encs = Imager::File::HEIF->encoders;
ok(@encs, "got some encoders");
for my $enc (@encs) {
    my $id = $enc->id;
    like($id, qr/^\w+$/, "$id: id must be id like");
    like($enc->name, qr/^.+$/, "$id: full name has no newlines and non-empty");
}

# we always have a HEVC encoder, since the module configuration fails
# without it
my @hevcenc = Imager::File::HEIF->encoders("hevc");
ok(@hevcenc, "found a HEVC decoder");

{
    my @desc;
    ok(!eval { @desc = Imager::File::HEIF->encoders("no such animal"); 1 },
       "die for unknown compression");
    like($@, qr/unknown HEIF compression type 'no such animal'/,
         "check message");
}

my ($x265) = grep $_->id eq "x265", @hevcenc;
 SKIP:
{
    $x265 or skip "No x265", 1;
    my @params = $x265->parameters;
    {
        my ($qparam) = grep $_->name eq "quality", @params;
        is $qparam->type, "integer", "quality type";
        is $qparam->minimum, 0, "quality minimum";
        is $qparam->maximum, 100, "quality maximum";
    }
}
done_testing;
