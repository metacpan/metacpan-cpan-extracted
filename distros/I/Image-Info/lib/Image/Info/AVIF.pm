package Image::Info::AVIF;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.01";

sub die_for_info($) { die bless({ err=>$_[0] }, __PACKAGE__."::__ERROR__") }

BEGIN {
    if("$]" >= 5.008) {
	*io_string = sub ($) { open(my $fh, "<", \$_[0]); $fh };
    } else {
	require IO::String;
	*io_string = sub ($) { IO::String->new($_[0]) };
    }
}

sub read_block($$) {
    my($fh, $len) = @_;
    my $d = "";
    while(1) {
	my $dlen = length($d);
	last if $dlen == $len;
	my $n = read($fh, $d, $len - $dlen, $dlen);
	if(!defined($n)) {
	    die_for_info "read error: $!";
	} elsif($n == 0) {
	    die_for_info "truncated file";
	}
    }
    return $d;
}

sub read_nulterm($) {
    my($fh) = @_;
    my $d = do { local $/ = "\x00"; <$fh> };
    defined($d) && $d =~ /\x00\z/ or die_for_info "truncated file";
    chop $d;
    return $d;
}

sub read_heif($$) {
    my($fh, $box_types_to_keep) = @_;
    my %boxes;
    while(!eof($fh)) {
	my($len, $type) = unpack("Na4", read_block($fh, 8));
	my $pos = 8;
	my $bufp;
	if($type =~ $box_types_to_keep && !exists($boxes{$type})) {
	    $boxes{$type} = "";
	    $bufp = \$boxes{$type};
	}
	if($len == 1) {
	    my($lenhi, $lenlo) = unpack("NN", read_block($fh, 8));
	    $pos += 8;
	    $len = ($lenhi << 32) | $lenlo;
	    $len >> 32 == $lenhi or die_for_info "box size overflow";
	}
	$len >= $pos or die_for_info "bad box length";
	$len -= $pos;
	while($len) {
	    my $toread = $len < (1<<16) ? $len : (1<<16);
	    my $d = read_block($fh, $toread);
	    defined($bufp) and $$bufp .= $d;
	    $len -= $toread;
	}
    }
    return \%boxes;
}

my @primaries_type;
$primaries_type[$_] = "RGB" foreach 1, 4, 5, 6, 7, 9, 11, 22;
$primaries_type[10] = "CIEXYZ";

sub process_file {
    my($info, $source) = @_;
    if(!eval { local $SIG{__DIE__};
	my $boxes = read_heif($source, qr/\A(?:ftyp|meta)\z/);
	my $ftyp = $boxes->{ftyp};
	defined $ftyp or die_for_info "no ftyp box";
	length($ftyp) >= 8 && !(length($ftyp) & 3)
	    or die_for_info "malformed ftyp box";
	substr($ftyp, 0, 4) eq "avif"
	    or die_for_info "major brand is not \"avif\"";
	$info->replace_info(0, file_media_type => "image/avif");
	$info->replace_info(0, file_ext => "avif");
	my $mboxes;
	{
	    my $meta = $boxes->{meta};
	    defined $meta or die_for_info "no meta box";
	    my $metafh = io_string($meta);
	    read_block($metafh, 1) eq "\x00"
		or die_for_info "malformed meta box";
	    read_block($metafh, 3);
	    $mboxes = read_heif($metafh, qr/\A(?:hdlr|iprp)\z/);
	}
	{
	    my $hdlr = $mboxes->{hdlr};
	    defined $hdlr or die_for_info "no hdlr box";
	    my $hdlrfh = io_string($hdlr);
	    read_block($hdlrfh, 1) eq "\x00"
		or die_for_info "malformed hdlr box";
	    read_block($hdlrfh, 3);
	    unpack("N", read_block($hdlrfh, 4)) == 0
		or die_for_info "non-zero pre-defined value";
	    read_block($hdlrfh, 4) eq "pict"
		or die_for_info "handler type is not \"pict\"";
	    read_block($hdlrfh, 12);
	    read_nulterm($hdlrfh);
	}
	my $pboxes;
	{
	    my $iprp = $mboxes->{iprp};
	    defined $iprp or die_for_info "no iprp box";
	    my $iprpfh = io_string($iprp);
	    $pboxes = read_heif($iprpfh, qr/\Aipco\z/);
	}
	my $cboxes;
	{
	    my $ipco = $pboxes->{ipco};
	    defined $ipco or die_for_info "no ipco box";
	    my $ipcofh = io_string($ipco);
	    $cboxes = read_heif($ipcofh,
			qr/\A(?:irot|clap|ispe|pixi|colr|pasp)\z/);
	}
	my $rot = 0;
	if(defined(my $irot = $cboxes->{irot})) {
	    length($irot) >= 1 or die_for_info "malformed irot box";
	    my($angle) = unpack("C", $irot);
	    !($angle & -4) or die_for_info "malformed irot box";
	    $rot = 1 if $angle & 1;
	}
	if(defined(my $clap = $cboxes->{clap})) {
	    length($clap) >= 32 or die_for_info "malformed clap box";
	    my($width_num, $width_den, $height_num, $height_den) =
		unpack("NNNN", $clap);
	    $width_den != 0 && $height_den != 0
		or die_for_info "malformed clap box";
	    my $width = int($width_num/$width_den);
	    my $height = int($height_num/$height_den);
	    ($width, $height) = ($height, $width) if $rot;
	    $info->replace_info(0, width => $width);
	    $info->replace_info(0, height => $height);
	} elsif(defined(my $ispe = $cboxes->{ispe})) {
	    length($ispe) >= 12 or die_for_info "malformed ispe box";
	    my($ver, undef, $width, $height) = unpack("Ca3NN", $ispe);
	    $ver == 0 or die_for_info "malformed ispe box";
	    ($width, $height) = ($height, $width) if $rot;
	    $info->replace_info(0, width => $width);
	    $info->replace_info(0, height => $height);
	}
	if(defined(my $pixi = $cboxes->{pixi})) {
	    length($pixi) >= 5 or die_for_info "malformed pixi box";
	    my($ver, undef, $planes) = unpack("Ca3C", $pixi);
	    $ver == 0 or die_for_info "malformed pixi box";
	    length($pixi) >= 5+$planes or die_for_info "malformed pixi box";
	    $info->replace_info(0, SamplesPerPixel => $planes);
	    $info->replace_info(0, BitsPerSample =>
		[ map { unpack(q(C), substr($pixi, 5+$_, 1)) } 0..$planes-1 ]);
	}
	if(defined(my $colr = $cboxes->{colr})) {
	    length($colr) >= 4 or die_for_info "malformed colr box";
	    my $type = substr($colr, 0, 4);
	    if($type eq "nclx") {
		length($colr) >= 11 or die_for_info "malformed colr box";
		my($prim) = unpack("n", substr($colr, 4, 2));
		if(defined(my $ctype = $primaries_type[$prim])) {
		    $info->replace_info(0, color_type => $ctype);
		}
	    }
	}
	if(defined(my $pasp = $cboxes->{pasp})) {
	    length($pasp) >= 8 or die_for_info "malformed pasp box";
	    my($hspc, $vspc) = unpack("NN", $pasp);
	    $info->replace_info(0, resolution => "$vspc/$hspc");
	}
	1;
    }) {
	my $err = $@;
	if(ref($err) eq __PACKAGE__."::__ERROR__") {
	    $info->replace_info(0, error => $err->{err});
	} else {
		die $err;
	}
    }
}

1;

=begin register

MAGIC: /\A....ftypavif/s

Supports the basic standard info key names.

=end register

=head1 NAME

Image::Info::AVIF - AV1 Image File Format support for Image::Info

=head1 SYNOPSIS

    use Image::Info qw(image_info);

    $info = image_info("image.avif");
    if($error = $info->{error}) {
	die "Can't parse image info: $error\n";
    }
    $color = $info->{color_type};

=head1 DESCRIPTION

This module supplies information about AVIF files within the
L<Image::Info> system.  It supports the basic standard info key names.

=head1 SEE ALSO

L<Image::Info>

=head1 AUTHOR

Andrew Main (Zefram) <zefram@fysh.org>

=head1 COPYRIGHT

Copyright (C) 2023 Andrew Main (Zefram) <zefram@fysh.org>

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 ACKNOWLEDGEMENT

The development of this module was funded by
Preisvergleich Internet Services AG.

=cut
