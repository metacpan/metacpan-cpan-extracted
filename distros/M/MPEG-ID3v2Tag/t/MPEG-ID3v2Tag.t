use strict;
use warnings;

use FindBin;
use File::Basename;
use File::Spec;
use Test::More tests => 8;

use_ok('MPEG::ID3v2Tag');

my $OUTPUT_FILENAME = File::Spec->catfile($FindBin::Bin, "test_output.mp3");

{
    my $tag = MPEG::ID3v2Tag->new();

    $tag->add_frame("TIT2", "Test song");

    $tag->add_frame(
        "APIC",
        -picture_type => 0,
        -file         => File::Spec->catfile($FindBin::Bin, "test_picture.gif"),
    );

    my $frame = MPEG::ID3Frame::TALB->new("Test album");
    $tag->add_frame($frame);

    $tag->add_frame("WCOM", "http://www.example.com/test/url");

    dump_tag($OUTPUT_FILENAME, $tag);

    ok((-e $OUTPUT_FILENAME), "Existence of " . basename($OUTPUT_FILENAME) . " without padding");
    is((-s $OUTPUT_FILENAME), 2712, "Size of " . basename($OUTPUT_FILENAME) . " without padding");

    unlink $OUTPUT_FILENAME;

    $tag->set_padding_size(256);

    dump_tag($OUTPUT_FILENAME, $tag);

    ok((-e $OUTPUT_FILENAME), "Existence of " . basename($OUTPUT_FILENAME) . " with padding");
    is((-s $OUTPUT_FILENAME), 2978, "Size of " . basename($OUTPUT_FILENAME) . " with padding");
}

{
    open my $fh, "<", $OUTPUT_FILENAME
        or die "$OUTPUT_FILENAME: $!\n";
    binmode $fh;
    my $tag = MPEG::ID3v2Tag->parse($fh);

    my %expected_value_of = (
        TIT2 => "Test song",
        TALB => "Test album",
        WCOM => "http://www.example.com/test/url",
    );

    for my $frame ($tag->frames()) {
        next if $frame->frameid eq "APIC";

        if ($frame->frameid =~ /^T/) {
            is($expected_value_of{$frame->frameid}, $frame->text, "Round trip of " . $frame->frameid);
        }
        elsif ($frame->frameid =~ /^W/) {
            is($expected_value_of{$frame->frameid}, $frame->url, "Round trip of " . $frame->frameid);
        }
        else {
            fail("Extra frame " . $frame->frameid);
        }
    }

    unlink $OUTPUT_FILENAME;
}

sub dump_tag {
    my ($filename, $tag) = @_;

    open my $outfh, ">", $filename
        or die "$filename: $!\n";
    binmode $outfh;
    print $outfh $tag->as_string();
    close $outfh;
}
