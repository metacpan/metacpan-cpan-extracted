#! /usr/bin/perl
## ----------------------------------------------------------------------------
#  Image::Identicon/example/identicon.cgi.
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2007 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Image-Identicon/example/identicon.cgi 337 2007-02-02T12:31:38.414450Z hio  $
# -----------------------------------------------------------------------------
use strict;
use warnings FATAL => 'all';
#use base qw(Exporter);
#our @EXPORT_OK = qw();
#our %EXPORT_TAGS = ( all => \@EXPORT_OK );

use CGI;
use CGI::Carp qw(fatalsToBrowser);
use lib 'lib';
use Image::Identicon;

our $DEBUG;

&do_work;

sub do_work
{
	my $CGI = CGI->new();
	
	my $DEBUG = $CGI->param('debug');
	local($Image::Identicon::DEBUG) = $DEBUG;
	
	if( $DEBUG )
	{
		print "Content-Type: text/html\r\n\r\n";
		print "<html>\n<head><title>identicon</title>\n</head>\n<body>\n<pre>";
		print "Image::Identicon version $Image::Identicon::VERSION\n";
	}
	
	my $SALT = "TEST";
	my $identicon = Image::Identicon->new({ salt=>$SALT });
	
	my $code  = $CGI->param('code');
	my $size  = $CGI->param('size');
	my $scale = $CGI->param('scale');
	
	$code ||= $identicon->identicon_code($CGI->param('addr') || $CGI->param('ar'));
	$code =~ /^(-?\d+)$/ or die "invalid code: $code";
	
	$size  && $size !~/^(\d+)$/ and die "invalid size: $size\n";
	$scale && $scale!~/^(\d+)$/ and die "invalid scale: $scale\n";
	$scale && $scale>=100 and $scale=100;
	
	my $r = $identicon->render({ code => $code, scale=>$scale, size=>$size, });
	my $image = $r->{image};
	if( !$DEBUG )
	{
		binmode(*STDOUT);
		my $bin = $image->png;
		my $len = length $bin;
		print "Content-Type: image/png\r\n";
		print "Content-Length: $len\r\n";
		print "\r\n";
		print $bin;
	}else
	{
		print qq{</pre>\n};
		print_as_text($image);
	}
}

sub print_as_text
{
	my $image = shift;
	print qq{<pre style="">};
	my $width  = $image->width;
	my $height = $image->height;
	print "(width, height) = ($width, $height)\n";
	for my $y (0..$image->width-1)
	{
		for my $x (0..$image->height-1)
		{
			my $p = $image->getPixel($x, $y);
			#$p = sprintf('[%3d]', $p);
			print $p==0x00FFFFFF ? '.' : '*';
		}
		print "\n";
	}
	print qq{</pre>\n};
}

__END__

=encoding utf8

=for stopwords
	YAMASHINA
	Hio
	ACKNOWLEDGEMENTS
	AnnoCPAN
	CPAN
	RT
	identicon

=head1 NAME

identicon.cgi - identicon generate sample

=head1 SEE ALSO

L<Image::Identicon>

