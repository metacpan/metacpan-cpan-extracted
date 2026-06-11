package IFNGENO::GenoPheno::Utils;

use strict;
use warnings;
use Exporter 'import';
use JSON;

our $VERSION = '0.01';

# Functions that can be imported
our @EXPORT_OK = qw(
    clean
    normalise_gene_key
    normalise_locus_key
    normalise_raw_gt
    extract_locus_number
    parse_locus_header
    read_json
    write_json
    get_excel_value
);

# --------------------------------------------------
# Clean string (trim whitespace)
# --------------------------------------------------
sub clean {
    my ($v) = @_;
    return '' unless defined $v;
    $v =~ s/^\s+|\s+$//g;
    return $v;
}

# --------------------------------------------------
# Normalise gene key
# --------------------------------------------------
sub normalise_gene_key {
    my ($gene) = @_;
    $gene = clean($gene);
    $gene =~ s/[^A-Za-z0-9]//g;

    if ($gene =~ /^betaCasein$/i) {
        return "betaCasein";
    }
    return $gene;
}

# --------------------------------------------------
# Normalise locus key (BC-Locus-X -> betaCasein-Locus-X)
# --------------------------------------------------
sub normalise_locus_key {
    my ($locus_col) = @_;
    $locus_col = clean($locus_col);

    if ($locus_col =~ /BC-Locus-(\d+)/i) {
        return "betaCasein-Locus-$1";
    }

    die "Invalid BC-Locus column name: '$locus_col'\n";
}

# --------------------------------------------------
# Normalise genotype (uppercase, no spaces)
# --------------------------------------------------
sub normalise_raw_gt {
    my ($gt) = @_;
    $gt = clean($gt);
    $gt =~ s/\s+//g;
    return uc($gt);
}

# --------------------------------------------------
# Extract numeric part from locus key
# --------------------------------------------------
sub extract_locus_number {
    my ($text) = @_;

    die "Invalid locus column name: '$text'\n"
        unless defined $text && $text =~ /Locus-(\d+)/i;

    return $1;
}

# --------------------------------------------------
# Parse locus header (example: "1: 6_85451043")
# --------------------------------------------------
sub parse_locus_header {
    my ($text) = @_;
    $text = clean($text);

    if ($text =~ /^(.+?)\s*:\s*(\S+)$/) {
        my $locus_label  = clean($1);
        my $chr_position = clean($2);
        return ($locus_label, $chr_position);
    }

    return (undef, undef);
}

# --------------------------------------------------
# Read JSON file
# --------------------------------------------------
sub read_json {
    my ($file) = @_;

    open(my $in, "<", $file)
        or die "Cannot read JSON file $file: $!\n";

    local $/;
    my $json_text = <$in>;
    close $in;

    return JSON->new->utf8(0)->decode($json_text);
}

# --------------------------------------------------
# Write JSON file
# --------------------------------------------------
sub write_json {
    my ($file, $data_ref) = @_;

    open(my $out, ">", $file)
        or die "Cannot write JSON file $file: $!\n";

    print $out JSON->new->utf8(0)
        ->canonical(1)
        ->pretty(1)
        ->encode($data_ref);

    close $out;
}

# --------------------------------------------------
# Read value from Excel sheet structure
# --------------------------------------------------
sub get_excel_value {
    my ($sheet, $col_ref, $row, $col_name) = @_;

    return '' unless exists $col_ref->{$col_name};

    return $sheet->{cell}[ $col_ref->{$col_name} ][$row] // '';
}

# --------------------------------------------------
1;   # VERY IMPORTANT (module must return true)