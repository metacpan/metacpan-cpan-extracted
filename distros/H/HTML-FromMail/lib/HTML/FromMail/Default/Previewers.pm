# This code is part of Perl distribution HTML-FromMail version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package HTML::FromMail::Default::Previewers;{
our $VERSION = '4.00';
}

use base 'HTML::FromMail::Object';

use strict;
use warnings;

use Log::Report 'html-frommail';

use File::Basename qw/basename dirname/;

#--------------------

our @previewers = (
	'text/plain' => \&previewText,
	'text/html'  => \&previewHtml,
	'image'      => \&previewImage,  # added when Image::Magick is installed
);


sub previewText($$$$$)
{	my ($page, $message, $part, $attach, $args) = @_;

	my $decoded  = $attach->{decoded}->string;
	for($decoded)
	{	s/^\s+//;
		s/\s+/ /gs;     # lists of blanks
		s/([!@#$%^&*<>?|:;+=\s-]{5,})/substr($1, 0, 3)/ge;
	}

	my $max = $args->{text_max_chars} || 250;
	substr($decoded, $max) = '' if length $decoded > $max;

	+{	%$attach,
		image => '',            # this is not an image
		html  => { text => $decoded },
	 };
}


sub previewHtml($$$$$)
{	my ($page, $message, $part, $attach, $args) = @_;

	my $decoded = $attach->{decoded}->string;
	my $title   = $decoded =~ s!\<title\b[^>]*\>(.*?)\</title\>!!i ? $1 : '';
	for($title)
	{	s/\<[^>]*\>//g;
		s/^\s+//;
		s/\s+/ /gs;
	}

	for($decoded)
	{	s!\<\!\-\-.*?\>!!g;         # remove comment
		s!\<script.*?script\>!!gsi; # remove script blocks
		s!\<style.*?style\>!!gsi;   # remove style-sheets
		s!^.*\<body!<!gi;           # remove all before body
		s!\<[^>]*\>!!gs;            # remove all tags
		s!\s+! !gs;                 # unfold lines
		s/([!@#$%^&*<>?|:;+=\s-]{5,})/substr($1, 0, 3)/ge;
	}

	my $max = $args->{text_max_chars} || 250;
	if(length $title)
	{	$decoded = "<b>$title</b>, $decoded";
		$max    += 7;
	}
	substr($decoded, $max) = '' if length $decoded > $max;

	 +{	%$attach,
		image => '',            # this is not an image
		html  => { text => $decoded },
	  };
}


BEGIN
{	eval   { require Image::Magick };
	if($@) { warning __x"Image::Magick not installed." }
	else   { push @previewers, image => \&previewImage }
}

sub previewImage($$$$$)
{	my ($page, $message, $part, $attach, $args) = @_;

	my $filename = $attach->{filename};
	my $magick   = Image::Magick->new;
	my $error    = $magick->Read($filename);
	length $error
		and error __x"cannot read image from {fn}: {error}", fn => $filename, error => $error;

	my %image;
	my ($srcw, $srch) = @image{ qw/width height/ } = $magick->Get( qw/width height/ );

	my $base     = basename $filename;
	$base        =~ s/\.[^.]+$//;

	my $dirname  = dirname $filename;

	my $reqw     = $args->{img_max_width}  || 250;
	my $reqh     = $args->{img_max_height} || 250;

	if($reqw < $srcw || $reqh < $srch)
	{	# Size reduction is needed.
		$error   = $magick->Resize(width => $reqw, height => $reqh);
		length $error
			and error __x"cannot resize image from {fn}: {error}", fn => $filename, error => $error;

		my ($resw, $resh) = @image{ qw/smallwidth smallheight/ } = $magick->Get( qw/width height/ );

		my $outfile = File::Spec->catfile($dirname,"$base-${resw}x${resh}.jpg");
		@image{ qw/smallfile smallurl/ } = ($outfile, basename($outfile));

		$error      = $magick->Write($outfile);
		length $error
			and error __x"cannot write smaller image from {fn} to {out}: {error}", in => $filename, out => $outfile, error => $error;
	}
	else
	{	@image{ qw/smallfile smallurl smallwidth smallheight/ } = ($filename, $attach->{url}, $srcw, $srch);
	}

	+{	%$attach,
		image => \%image,
		html  => '',            # this is not text
	 };
}

1;
