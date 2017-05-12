package Image::PNG::Util;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/safe_to_copy copy_chunks/;
use warnings;
use strict;
use Carp;
use Image::PNG::Libpng ':all';
use Image::PNG::Const ':all';

use constant {
    PNG_CHUNK_NAME_LENGTH => 4,
};

# A list of chunks which we know about.

my @known_chunks = qw/bKGD cHRM gAMA hIST iCCP IDAT IHDR iTXt oFFs pCAL pHYs PLTE sBIT sCAL sPLT sRGB tEXt tIME tRNS zTXt /;

# The properties of the chunks (things we can do with them, routines
# to manipulate them, whether they appear in the "valid" thing).

my %chunk_properties = (

bKGD => {
    name => 'bKGD',
    in_valid => 1,
    get => \&get_bKGD,
    set => \&set_bKGD,
},
cHRM => {
    name => 'cHRM',
    in_valid => 1,
    get => \&get_cHRM,
    set => \&set_cHRM,
},
gAMA => {
    name => 'gAMA',
    in_valid => 1,
    get => \&get_gAMA,
    set => \&set_gAMA,
},
hIST => {
    name => 'hIST',
    in_valid => 1,
    get => \&get_hIST,
    set => \&set_hIST,
},
iCCP => {
    name => 'iCCP',
    in_valid => 1,
    get => \&get_iCCP,
    set => \&set_iCCP,
},
IDAT => {
    name => 'IDAT',
    in_valid => 1,
},
IHDR => {
    name => 'IHDR',
    get => \&get_IHDR,
    set => \&set_IHDR,
},
iTXt => {
    name => 'iTXt',
    is_text => 1,
},
oFFs => {
    name => 'oFFs',
    in_valid => 1,
    get => \&get_oFFs,
    set => \&set_oFFs,
},
pCAL => {
    name => 'pCAL',
    in_valid => 1,
    get => \&get_pCAL,
    set => \&set_pCAL,
},
pHYs => {
    name => 'pHYs',
    in_valid => 1,
    get => \&get_pHYs,
    set => \&set_pHYs,
},
PLTE => {
    name => 'PLTE',
    in_valid => 1,
    get => \&get_PLTE,
    set => \&set_PLTE,
},
sBIT => {
    name => 'sBIT',
    in_valid => 1,
    get => \&get_sBIT,
    set => \&set_sBIT,
},
sCAL => {
    name => 'sCAL',
    in_valid => 1,
    get => \&get_sCAL,
    set => \&set_sCAL,
},
sPLT => {
    name => 'sPLT',
    in_valid => 1,
    get => \&get_sPLT,
    set => \&set_sPLT,
},
sRGB => {
    name => 'sRGB',
    in_valid => 1,
    get => \&get_sRGB,
    set => \&set_sRGB,
},
tEXt => {
    name => 'tEXt',
    is_text => 1,
},
tIME => {
    name => 'tIME',
    in_valid => 1,
    get => \&get_tIME,
    set => \&set_tIME,
},
tRNS => {
    name => 'tRNS',
    in_valid => 1,
    get => \&get_tRNS,
    set => \&set_tRNS,
},
zTXt => {
    name => 'zTXt',
    is_text => 1,
},
);
#line 41 "Util.pm.tmpl"

sub check_chunk_name
{
    my ($chunk_name) = @_;
    if (length $chunk_name != PNG_CHUNK_NAME_LENGTH) {
        carp "Bad chunk name '$chunk_name': wrong length";
        return;
    }
    return 1;
}

sub critical
{
    my ($chunk_name) = @_;
    if (! check_chunk_name ($chunk_name)) {
        return;
    }
    my $first_byte = substr ($chunk_name, 0, 1);
    if (uc $first_byte eq $first_byte) {
        return 1;
    }
    else {
        return;
    }
}

sub safe_to_copy
{
    my ($chunk_name) = @_;
    if (! check_chunk_name ($chunk_name)) {
        return;
    }
    my $fourth_byte = substr ($chunk_name, 3, 1);
    if (uc $fourth_byte eq $fourth_byte) {
        return;
    }
    else {
        return 1;
    }
}

sub copy_chunks
{
    my ($in_png, $out_png, $chunk_list, $verbose) = @_;
    if (! defined $chunk_list) {
        carp "You have not supplied a list of chunks to copy";
        return;
    }
    if (ref $chunk_list ne 'ARRAY') {
        carp "Your list of chunks is not an array reference";
        return;
    }
    my @chunks;
    # Set to true to copy critical chunks (stupid idea)
    my $critical;
    my $copy_all_text;
    if ($verbose) {
        print "Looking at your list ", join (", ", @$chunk_list), "\n";
    }
    for my $chunk (@$chunk_list) {
        if ($chunk eq 'all') {
            push @chunks, @known_chunks;
        }
        elsif ($chunk eq 'safe') {
            my @safe_chunks = grep { safe_to_copy ($_); } @known_chunks;
            push @chunks, @safe_chunks;
        }
        elsif ($chunk eq 'text') {
            $copy_all_text = 1;
        }
        elsif ($chunk eq 'critical') {
            carp "Copying critical chunks is a bad idea";
            $critical = 1;
        }
        else {
            if (check_chunk_name ($chunk)) {
                push @chunks, $chunk;
            }
        }
    }
    if (! $critical) {
        if ($verbose) {
            print "Deleting critical chunks from list @chunks.\n";
        }
        @chunks = grep { ! critical ($_); } @chunks;
    }
    # Unique chunks
    my %chunk_hash;
    @chunk_hash{@chunks} = (1) x @chunks;
    if ($chunk_hash{IDAT}) {
        carp "Sorry this module can't copy IDAT chunks";
        delete $chunk_hash{IDAT};
    }
    delete @chunk_hash{qw/tEXt iTXt zTXt/};
    @chunks = sort keys %chunk_hash;
    if ($verbose) {
        print "I am going to copy THESE chunks: @chunks.\n";
    }
    if (! @chunks) {
        if ($verbose) {
            print "No chunks need to be copied";
        }
    }
    my $valid = get_valid ($in_png);
    # List of chunks which were not copied on the first pass.
    my @uncopied_chunks;
    my @text_chunks;
    # First of all, look for the chunks we know what to do with
    for my $chunk (@chunks) {
        my $copied;
        my $chunk_not_present;
        my $copy_ok;
        my $props = $chunk_properties{$chunk};
        if ($props) {
            if ($props->{in_valid}) {
                if ($valid->{$chunk}) {
                    $copy_ok = 1;
                }
                else {
                    $chunk_not_present = 1;
                }
            }
            elsif ($props->{is_text}) {
                # There is no facility to copy some but not all types
                # of text chunks, so here we just skip that.
                $copied = 1;
            }
            else {
                # Try to copy it with a known function
                $copy_ok = 1;
            }
            if ($copy_ok) {
                my $chunk_contents = &{$props->{get}} ($in_png);
                if (defined $chunk_contents) {
                    &{$props->{set}} ($out_png, $chunk_contents);
                    if ($verbose) {
                        print "Copied the $chunk chunk.\n";
                    }
                    $copied = 1;
                }
                else {
                    warn "Image inconsistency: image does not have a $chunk chunk to copy but it claims to.\n";
                }
            }
            else {
                if ($verbose) {
                    print "Request to copy $chunk chunk but image does not have it.\n";
                }
            }
        }
        if (! $chunk_not_present && ! $copied) {
            push @uncopied_chunks, $chunk;
        }
    }
    if ($copy_all_text) {
        if ($verbose) {
            print "Copying text\n";
        }
        my $text = get_text ($in_png);
        if (defined $text) {
        if ($verbose) {
            printf "There are %d text chunks\n", scalar @$text;
        }
            set_text ($out_png, $text);
        }
        else {
            if ($verbose) {
                print "Image does not have any text chunks to copy.\n";
            }
        }
    }
    for my $chunk (@uncopied_chunks) {
        carp "I don't know how to copy your chunk '$chunk'";
    }
}

1;

# Local variables:
# mode: perl
# End:
