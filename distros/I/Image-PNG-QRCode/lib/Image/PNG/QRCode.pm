package Image::PNG::QRCode;
require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw/qrpng/;
%EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
use warnings;
use strict;
use Carp;
our $VERSION = '0.09';
require XSLoader;
XSLoader::load ('Image::PNG::QRCode', $VERSION);

sub qrpng
{
    my (%options) = @_;
    if ($options{in}) {
	if ($options{text}) {
	    carp "Overwriting input text '$options{text}' with contents of file $options{in}";
	}
	$options{text} = '';
	open my $in, "<:raw", $options{in} or die $!;
	while (<$in>) {
	    $options{text} .= $_;
	}
	close $in or die $!;
    }
    if (! $options{text}) {
	croak "No input";
    }
    if ($options{quiet}) {
	if ($options{quiet} < 0) {
	    croak "quiet zone cannot be negative";
	}
	if ($options{quiet} > 100) {
	    croak "requested quiet zone, $options{quiet}, exceeds arbitrary maximum of 100";
	}
    }
    if ($options{scale}) {
	if ($options{scale} < 1) {
	    croak "negative or zero scale $options{scale}";
	}
	if ($options{scale} != int $options{scale}) {
	    croak "scale option needs to be an integer";
	}
	if ($options{scale} > 100) {
	    croak "requested scale, $options{scale}, exceeds arbitrary maximum of 100";
	}
    }
    if ($options{version}) {
	if ($options{version} < 1 || $options{version} > 40 ||
	    $options{version} != int ($options{version})) {
	    croak "Bad version number $options{version}: use integer between one and forty";
	}
    }
    if ($options{level}) {
	if ($options{level} < 1 || $options{level} > 4 ||
	    $options{level} != int ($options{level})) {
	    croak "Bad level number $options{level}: use integer between one and four";
	}
    }
    if ($options{size}) {
	if (ref $options{size} ne 'SCALAR') {
	    carp "size option requires a scalar reference";
	    delete $options{size};
	}
    }
    # If true, user will use the return value.
    my $r;
    # If true, user wants to write the PNG data into a scalar.
    my $s;
    # Check what kind of output the user wants.
    if (defined (wantarray ())) {
	# User wants a return value.
	$options{out_sv} = 1;
	$r = 1;
    }
    if ($options{out}) {
	if (ref $options{out} eq 'SCALAR') {
	    # User wants to write the PNG data into a scalar.
	    $options{out_sv} = 1;
	    $s = 1;
	    if ($r) {
		# User wants both the return value and to use as
		# scalar, for some reason.
		carp "Return value used twice";
	    }
	}
	# Else user wants to write the PNG data to a file.
    }
    else {
	if (! $r) {
	    # Don't know what the user wants, tell them they haven't
	    # specified how to output and give up.
	    carp "Output discarded: use return value or specify 'out => \\\$value'";
	    return undef;
	}
    }
    qrpng_internal (\%options);
    if ($s) {
	${$options{out}} = $options{png_data};
    }
    if ($r) {
	return $options{png_data};
    }
    return undef;
}

1;
