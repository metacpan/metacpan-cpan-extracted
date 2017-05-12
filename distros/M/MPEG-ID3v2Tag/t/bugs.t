use strict;
use warnings;

use FindBin;
use File::Basename;
use File::Spec;
use Test::More tests => 5;

use_ok('MPEG::ID3v2Tag');

my $OUTPUT_FILENAME = File::Spec->catfile($FindBin::Bin, "test_output.mp3");

{
    # Bug report: http://rt.cpan.org/Ticket/Display.html?id=22271

    my @test_files = map { File::Spec->catfile($FindBin::Bin, $_) }
                     "test_file_v23.mp3", "test_file_v24.mp3";

    for my $file (@test_files) {
        open my $fh, "<", $file
            or die "$file: $!\n";

        binmode $fh;

        my $tag = MPEG::ID3v2Tag->parse($fh);

        my @comments = grep { $_->frameid eq "COMM" } $tag->frames;
        ok(scalar @comments, basename($file) . " has comment frame");
    }
}

{
    # Bug report: http://rt.cpan.org/Ticket/Display.html?id=13591
    
    # Test a text-based tag
    write_tag(
        $OUTPUT_FILENAME,
        MPEG::ID3v2Tag->new->add_frame("TIT2", "Test title")
    );
    my $title_terminator = read_tag_bytes($OUTPUT_FILENAME, -2, 2);
    is($title_terminator, "e\0", "TIT2 terminator");

    # Test a picture tag
    my $tag = MPEG::ID3v2Tag->new;
    $tag->add_frame(
        "APIC",
        -picture_type => 0,
        -file         => File::Spec->catfile($FindBin::Bin, "test_picture.gif"),
    );
    $tag->add_frame("TIT2", "Test title");
    write_tag(
        $OUTPUT_FILENAME,
        $tag
    );
    my $apic_mimetype = read_tag_bytes($OUTPUT_FILENAME, 21, 19);
    is($apic_mimetype, "image/gif\0\0 \0GIF87a", "APIC terminator");

    unlink $OUTPUT_FILENAME;
}

sub write_tag {
    my ($filename, $tag) = @_;

    open my $outfh, ">", $filename
        or die "$filename: $!\n";
    binmode $outfh;
    print $outfh $tag->as_string();
    close $outfh;
}

sub read_tag_bytes {
    my ($filename, $offset, $length) = @_;

    open my $infh, "<", $filename
        or die "$filename: $!\n";
    binmode $infh;
    read $infh, my $data, -s $filename;
    return substr $data, $offset, $length;
}
