package Image::PNG::FileConvert;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/file2png png2file/;
use warnings;
use strict;
our $VERSION = '0.10';
use Carp;
use Image::PNG::Libpng ':all';
use Image::PNG::Const ':all';

use constant {
    default_row_length => 0x800,
    default_max_rows => 0x800,
};

sub file2png
{
    my ($file, $png_file, $options) = @_;
    if (! -f $file) {
        carp "I can't find '$file'";
        return;
    }
    if (! $png_file) {
        carp "I need a name for the PNG output";
        return;
    }
    if (-f $png_file) {
        carp "Output PNG file '$png_file' already exists";
        return;
    }
    if (! $options) {
        $options = {};
    }
    if (! $options->{row_length}) {
        $options->{row_length} = default_row_length;
    }
    if (! $options->{max_rows}) {
        $options->{max_rows} = default_max_rows;
    }
    my @rows;
    my $bytes = -s $file;
    open my $input, "<:raw", $file;
    my $i = 0;
    my $total_red = 0;
    while (! eof ($input)) {
        my $red = read ($input, $rows[$i], $options->{row_length});
        if ($red != $options->{row_length}) {
            if ($total_red + $red != $bytes) {
                warn "Short read of $red bytes at row $i.\n"
            }
        }
        $total_red += $red;
        $i++;
    }
    close $input;
    if ($options->{verbose}) {
        printf "Read 0x%X rows.\n", $i;
    }

    # Fill the final row up with useless bytes so that we are not
    # reading from unallocated memory.

    # The number of bytes in the last row.
    my $end_bytes = $bytes % $options->{row_length};
    if ($end_bytes > 0) {
        $rows[-1] .= "X" x ($options->{row_length} - $end_bytes);
    }

    # Create the PNG data in a Perl structure.

    my $png = create_write_struct ();
    my %IHDR = (
        width => $options->{row_length},
        height => scalar @rows,
        color_type => PNG_COLOR_TYPE_GRAY,
        bit_depth => 8,
    );
    set_IHDR ($png, \%IHDR);
    set_rows ($png, \@rows);

    # Write the PNG data to a file.

    open my $output, ">:raw", "$png_file";
    init_io ($png, $output);

    # Set the timestamp of the PNG file to the current time.

    set_tIME ($png);
    my $name;
    if ($options->{name}) {
        $name = $options->{name};
    }
    else {
        $name = $file;
    }
    # Put the name and size of the file into the file as text
    # segments.
    set_text ($png, [{key => 'bytes',
                      text => $bytes,
                      compression => PNG_TEXT_COMPRESSION_NONE},
                     {key => 'name',
                      text => $name,
                      compression => PNG_TEXT_COMPRESSION_NONE},
                    ]);
    write_png ($png);
    close $output;
}

sub png2file
{
    my ($png_file, %options) = @_;
    my $me = __PACKAGE__ . "::png2file";
    if (! $png_file) {
        croak "$me: please specify a file";
    }
    if (! -f $png_file) {
        croak "$me: can't find the PNG file '$png_file'";
    }
    my $verbose = $options{verbose};
    open my $input, "<:raw", $png_file;
    my $png = create_read_struct ();
    init_io ($png, $input);
    if ($verbose) {
        print "Reading file\n";
    }
    read_png ($png);
    my $IHDR = get_IHDR ($png);
    # Check that the IHDR data looks like something created by
    # file2png.
    if ($IHDR->{color_type} != PNG_COLOR_TYPE_GRAY) {
	croak "$me: Wrong color type $IHDR->{color_type}; expected " .
	    PNG_COLOR_TYPE_GRAY;
    }
    if ($IHDR->{bit_depth} != 8) {
	croak "$me: Wrong bit depth $IHDR->{bit_depth}; expected 8";
    }
    if ($verbose) {
        print "Getting rows\n";
    }
    my $rows = get_rows ($png);
    if ($verbose) {
        print "Finished reading file\n";
    }
    close $input;
    my $text_segments = get_text ($png);
    if (! defined $text_segments) {
        croak "$me: the PNG file '$png_file' does not have any text segments, so either it was not created by " . __PACKAGE__ . "::file2png, or it has had its text segments removed";
        return;
    }
    my $name;
    my $bytes;
    for my $text_segment (@$text_segments) {
        if ($text_segment->{key} eq 'name') {
            $name = $text_segment->{text};
        }
        elsif ($text_segment->{key} eq 'bytes') {
            $bytes = $text_segment->{text};
        }
        else {
            carp "$me: unknown text segment with key '$text_segment->{key}' in '$png_file'";
        }
    }
    if ($options{name}) {
	if ($verbose) {
	    print "Overriding file name $name to $options{name}.\n";
	}
	$name = $options{name};
    }
    if (! $name) {
        croak "$me: no file name for '$png_file'";
    }
    if (! $bytes) {
        croak "$me: byte count is missing from '$png_file'";
    }
    if ($bytes <= 0) {
        croak "$me: the byte file size $bytes in '$png_file' is impossible";
    }
    my $row_bytes = get_rowbytes ($png);
    if (-f $name) {
        croak "$me: a file with the name '$name' already exists";
    }
    open my $output, ">:raw", $name or die "Can't open $name: $!";
    for my $i (0..$#$rows - 1) {
        print $output $rows->[$i];
    }
    my $final_row = substr ($rows->[-1], 0, $bytes % $row_bytes);
    print $output $final_row;
    close $output;
    return;
}

1;
