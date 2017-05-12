#! perl

# Format.pm -- 
# Author          : Johan Vromans
# Created On      : Thu Jul 14 12:54:08 2005
# Last Modified By: Johan Vromans
# Last Modified On: Tue Mar  8 20:26:23 2011
# Update Count    : 102
# Status          : Unknown, Use with caution!

package main;

our $cfg;
our $dbh;

package EB::Format;

use strict;

use EB;

use base qw(Exporter);

my $stdfmt0;
my $stdfmtw;
my $btwfmt0;
my $btwfmtw;
my $numpat;
my $btwpat;
my $decimalpt;
my $thousandsep;

our @EXPORT;
our $amount_width;
our $date_width;

sub numround_ieee {
    # This somethimes does odd things.
    # E.g. 892,5 -> 892 and 891,5 -> 892.
    0 + sprintf("%.0f", $_[0]);
}

use POSIX qw(floor ceil);

sub numround_posix {
    my ($val) = @_;
    if ( $val < 0 ) {
	ceil($val - 0.5);
    }
    else {
	floor($val + 0.5);
    }
}

use POSIX qw(floor);

my $_half;

sub numround_bankers {

    # Based on Math::Round::round_even.

    my $x = shift;
    return 0 unless $x;

    my $sign = ($x >= 0) ? 1 : -1;
    $x = abs($x);
    my $in = int($x);

    # Round to next even if exactly 0.5.
    if ( ($x - $in) == 0.5 ) {
	return $sign * (($in % 2 == 0) ? $in : $in + 1);
    }

    unless ( defined($_half) ) {

	# Determine what value to use for "one-half". Because of the
	# perversities of floating-point hardware, we must use a value
	# slightly larger than 1/2. We accomplish this by determining
	# the bit value of 0.5 and increasing it by a small amount in
	# a lower-order byte. Since the lowest-order bits are still
	# zero, the number is mathematically exact.

	my $halfhex = unpack('H*', pack('d', 0.5));
	if ( substr($halfhex,0,2) ne '00' && substr($halfhex, -2) eq '00' ) {
	    # Big-endian.
	    substr($halfhex, -4) = '1000';
	} else {
	    # Little-endian.
	    substr($halfhex, 0, 4) = '0010';
	}
	$_half = unpack('d', pack('H*', $halfhex));
    }

    $sign * POSIX::floor($x + $_half);
}

sub init_formats  {

    assert( NUMGROUPS != AMTPRECISION, "NUMGROUPS != AMTPRECISION" );

    ################ BTW display format ################

    $btwfmt0 = '%.' . (BTWPRECISION-2) . 'f';
    $btwfmtw = '%' . BTWWIDTH . "." . (BTWPRECISION-2) . 'f';
    $btwpat = qr/^([-+])?(\d+)?(?:[.,])?(\d{1,@{[BTWPRECISION-2]}})?$/;

    ################ Amount display format ################

    $amount_width = $cfg->val(qw(text numwidth), AMTWIDTH);
    if ( $amount_width =~ /^\+(\d+)$/ ) {
	$amount_width = AMTWIDTH + $1;
    }
    elsif ( $amount_width =~ /^\-(\d+)$/ ) {
	$amount_width = AMTWIDTH - $1;
    }
    elsif ( $amount_width =~ /^(\d+)%$/ ) {
	$amount_width = int((AMTWIDTH * $1) / 100);
    }
    elsif ( $amount_width !~ /^\d+$/ ) {
	warn("?"._T("Configuratiefout: [format]numwidth moet een getal zijn")."\n");
	$amount_width = AMTWIDTH;
    }

    $decimalpt = $cfg->val(qw(locale decimalpt), undef);
    $thousandsep = $cfg->val(qw(locale thousandsep), undef);

    my $fmt = $cfg->val(qw(format amount), undef);
    if ( $fmt || !defined($decimalpt) ) {
	$fmt = _T("1.234,56") unless defined $fmt;
	Carp::croak(__x("Configuratiefout: ongeldige waarde voor {item}",
			item => "format".':'."amount")."\n")
	    unless $fmt =~ /^\d+([.,])\d\d$/
	      || $fmt =~ /^\d+(\.\d\d\d)*(\,)\d\d$/
	      || $fmt =~ /^\d+(\,\d\d\d)*(\.)\d\d$/;
	if ( defined $2 ) {
	    $decimalpt = $2;
	    $thousandsep = substr($1, 0, 1);
	}
	else {
	    $decimalpt = $1;
	    $thousandsep = "";
	}
	$amount_width = length($fmt) if length($fmt) > $amount_width;
    }
    else {
	$amount_width += int(($amount_width - AMTPRECISION - 2) / 3) if $thousandsep;
    }

    $stdfmt0 = '%.' . AMTPRECISION . 'f';
    $stdfmtw = '%' . $amount_width . "." . AMTPRECISION . 'f';

    my $sub = "";

    $sub .= <<EOD;
    my \$v = shift;
    if ( \$v == int(\$v) && \$v >= 0 ) {
	\$v = ("0" x (@{[AMTPRECISION + 1]} - length(\$v))) . \$v if length(\$v) <= @{[AMTPRECISION]};
	substr(\$v, length(\$v) - @{[AMTPRECISION]}, 0) = q\000$decimalpt\000;
    }
    else {
	\$v = sprintf("$stdfmt0", \$v/@{[AMTSCALE]});
EOD
    $sub .= <<EOD if $decimalpt ne '.';
	\$v =~ s/\\./$decimalpt/;
EOD
    $sub .= <<EOD;
    }
    \$v =~ s/^\\+//;
EOD

    eval("sub numfmt_plain { $sub; \$v }");
    die($@) if $@;

    $sub .= <<EOD if $thousandsep;
    \$v = reverse(\$v);
    \$v =~ s/(\\d\\d\\d)(?=\\d)(?!\\d*@{[quotemeta($decimalpt)]})/\${1}$thousandsep/g;
    \$v = scalar(reverse(\$v));
EOD

    eval("sub numfmt { $sub; \$v }");
    die($@) if $@;

    $numpat = qr/^([-+])?(\d+)?(?:[.,])?(\d{1,@{[AMTPRECISION]}})?$/;

    ################ Rounding Algorithms ################

    my $numround = lc($cfg->val(qw(strategy round), "ieee"));
    unless ( defined &{"numround_$numround"} ) {
	die("?".__x("Onbekende afrondingsmethode: {meth}",
		    meth => $numround)."\n");
    }
    *numround = \&{"numround_$numround"};

    ################ Date display format ################

    $fmt = $cfg->val(qw(format date), "YYYY-MM-DD");

    $sub          = "sub datefmt { \$_[0] }";
    my $sub_full  = "sub datefmt_full { \$_[0] }";
    my $sub_plain = "sub datefmt_plain { \$_[0] }";
    if ( lc($fmt) eq "dd-mm-yyyy" ) {
	$sub      = q<sub datefmt { join("-", reverse(split(/-/, $_[0]))) }>;
	$sub_full = q<sub datefmt_full { join("-", reverse(split(/-/, $_[0]))) }>;
    }
    elsif ( lc($fmt) eq "dd-mm" ) {
	$sub      = q<sub datefmt { $_[0] =~ /(\d+)-(\d+)-(\d+)/; "$3-$2" }>;
	$sub_full = q<sub datefmt_full { join("-", reverse(split(/-/, $_[0]))) }>;
    }
    elsif ( lc($fmt) ne "yyyy-mm-dd" ) {
	die("?".__x("Ongeldige datumformaatspecificatie: {fmt}",
		    fmt => $fmt)."\n");
    }
    for ( $sub, $sub_full, $sub_plain ) {
	eval($_);
	die($_."\n".$@) if $@;
    }
    $date_width = length(datefmt("2006-01-01"));
}

sub numxform_strict {
    $_ = shift;
    my $err = __x("Ongeldig bedrag: {num}", num => $_);

    my $sign = "";
    $sign = $1 if s/^([-+])// && $1 eq '-';

    # NNNN -> NNNN.00
    if ( /^\d+$/ ) {
	s/^0+(\d)$/$1/;
	return $sign . $_ . "." . ("0" x AMTPRECISION);
    }

    # N,NNN -> NNNN.00
    if ( /^(\d{1,@{[NUMGROUPS]}})(\,\d{@{[NUMGROUPS]}})*$/ && $1 ) {
	s/\,//g;
	s/^0+(\d)$/$1/;
	return $sign . $_ . "." . ("0" x AMTPRECISION);
    }

    # N.NNN -> NNNN.00
    if ( /^(\d{1,@{[NUMGROUPS]}})(\.\d{@{[NUMGROUPS]}})*$/ && $1 ) {
	s/\.//g;
	s/^0+(\d)$/$1/;
	return $sign . $_ . "." . ("0" x AMTPRECISION);
    }

    # N.NNN,NN or N,NNN.NN
    return $err
      unless /^([\d.]+)(\,)(\d{@{[AMTPRECISION]}})$/
	  || /^([\d,]+)(\.)(\d{@{[AMTPRECISION]}})$/;

    my ($mant, $sep, $frac) = ( $1, $2, $3 );

    # N.NNN , NN -> NNNN NN
    if ( $sep eq "," ) {
	$mant =~ s/\.//g
	  if $mant =~ /^\d{1,@{[NUMGROUPS]}}(\.\d{@{[NUMGROUPS]}})*$/;
    }

    # N,NNN . NN -> NNNN NN
    else {
	$mant =~ s/\,//g
	  if $mant =~ /^\d{1,@{[NUMGROUPS]}}(\,\d{@{[NUMGROUPS]}})*$/;
    }

    # NNNN NN -> NNNN.NN
    $mant =~ s/^0+(\d)$/$1/;
    return $sign . $mant . "." . $frac if $mant =~ /^\d+$/;

    die("?$err\n");		# not well-formed

}

sub numxform_loose {
    $_ = shift;
    my $err = __x("Ongeldig getal: {num}", num => $_);

    # If there's a single comma, make decimal point.
    s/,/./ if /^.*,.*$/;

    return $_ if /^[-+]*\d+(\.\d+)?$/;

    die("?$err\n");		# not well-formed

}

sub numxform {
    my ($n) = @_;
    my $res = numxform_strict($n);
    return $res if defined $res;
#    return $n if $n =~ /^[-a+]?\d+[.,]\d+$/;	# a ?
    return $n if $n =~ /^[-+]?\d+[.,]\d+$/;
    return undef;
}

sub amount($) {
    my $val = shift;
    my $debug = $cfg->val(__PACKAGE__, "debugexpr", 0);
    if ( $val =~ /.[-+*\/\(\)]/ ) {
	print STDERR ("val \"$val\" -> ") if $debug;
	$val =~ s/([.,\d]+)/numxform_loose($1)/ge;
	print STDERR ("\"$val\" -> ") if $debug;

	my $res = eval($val);
	warn("$val: $@"), return undef if $debug && $@;
	return undef if $@;
	$val = sprintf($stdfmt0, $res);
	print STDERR ("$val\n") if $debug;
    }
    else {
	return undef
	  unless $val = numxform_strict($val); # fortunately, 0.00 is true
    }

    return undef unless $val =~ $numpat;
    my ($s, $w, $f) = ($1 || "", $2 || 0, $3 || 0);
    $f .= "0" x (AMTPRECISION - length($f));
    return 0 + ($s.$w.$f);
}

sub numfmtw {
    my $v = shift;
    if ( $v == int($v) && $v >= 0  ) {
	$v = ("0" x (AMTPRECISION - length($v) + 1)) . $v if length($v) <= AMTPRECISION;
	$v = (" " x (AMTWIDTH - length($v))) . $v if length($v) < AMTWIDTH;
	substr($v, length($v) - AMTPRECISION, 0) = $decimalpt;
    }
    else {
	$v = sprintf($stdfmtw, $v/AMTSCALE);
	$v =~ s/\./$decimalpt/;
    }
    $v;
}

#### UNUSED
sub numfmtv {
    my $v = shift;
    if ( $v == int($v) && $v >= 0  ) {
	$v = ("0" x (AMTPRECISION - length($v) + 1)) . $v if length($v) <= AMTPRECISION;
	$v = (" " x ($_[0] - length($v))) . $v if length($v) < $_[0];
	substr($v, length($v) - AMTPRECISION, 0) = $decimalpt;
    }
    else {
	$v = sprintf('%'.$_[0].'.'.AMTPRECISION.'f', $v/AMTSCALE);
	$v =~ s/\./$decimalpt/;
    }
    $v;
}

sub btwfmt {
    my $v = sprintf($btwfmt0, 100*$_[0]/BTWSCALE);
    $v =~ s/\./$decimalpt/;
    $v;
}

sub btwpat { $btwpat }

################ Code ################

push( @EXPORT,
      qw(amount numround btwfmt),
      qw($amount_width numfmt numfmt_plain),
      qw($date_width datefmt datefmt_full datefmt_plain),
    );

1;
