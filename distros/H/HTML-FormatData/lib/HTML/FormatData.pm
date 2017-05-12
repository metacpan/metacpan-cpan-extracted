package HTML::FormatData;

=pod

=head1 NAME

HTML::FormatData - formats strings and dates for web display/storage

=head1 SYNOPSIS

  use HTML::FormatData;

  my $f = HTML::FormatData->new();

  my $string = "<b>bolded</b>";
  my $formatted = $f->format_text( $string, strip_html=>1 );
  # $string eq 'bolded'

  my $dt = $f->parse_date( $dt_string, '%Y%m%d%H%M%S' );
  my $yrmoday = $f->format_date( $dt, '%Y%m%d' );
  $yrmoday = $f->reformat_date( $dt_string, '%Y%m%d%H%M%S', '%Y%m%d' ); # shortcut

=head1 DESCRIPTION

HTML::FormatData contains utility functions to format strings and dates.
These utilities are useful for formatting data to be displayed on webpages,
or for cleaning and date data during server-side validation before storage
in a database or file.

While doing web development work in the past, I noticed that I was having
to do the same operations time and again: strip HTML from form submissions,
truncate strings for display as table data, URI-encode strings for use in
links, translate Unix timestamps into mm/dd/yyyy format, etc. Rather than 
try to keep straight the different modules and functions used, I decided to 
write a wrapper with a single, consistent interface.

=head1 METHODS

=cut

use 5.006;
use strict;
use warnings;

use Carp qw( croak );
use DateTime;
use DateTime::Format::Strptime;
use HTML::Entities;
use HTML::Parser;
use URI::Escape;

our $VERSION = '0.10';

=pod

=head2 new()

This method creates a new HTML::FormatData object.
Returns the blessed object.

=cut

sub new {
	my $class = shift;
	my $config = shift;

	bless {}, $class;
}

=pod

=head2 format_text( $string, %args )>

Wrapper function for the text formatting routines below.  Formats a string 
according to parameters passed in. While the functions this routine calls 
can be called directly, it will usually be best to always go thru this function.

Returns the formatted string.

=cut

sub format_text {
	my $self = shift;
	my $string = shift;
	croak( "Odd number of parameters passed to format_text." ) if @_ % 2;
	my %args = @_;

	return unless defined $string;
	return '' if $string eq '';

	my @jobs = qw(
		decode_xml decode_html decode_uri
		strip_html strip_whitespace
		clean_high_ascii clean_encoded_html clean_encoded_text
		clean_whitespace clean_whitespace_keep_full_breaks clean_whitespace_keep_all_breaks
		force_lc force_uc
		truncate truncate_with_ellipses
		encode_xml encode_html encode_uri
	);

	foreach my $job ( @jobs ) {
		next unless exists $args{$job};
		if ( $job =~ /^truncate/ ) {
			$string = $self->$job( $string, $args{$job} );
		} else {
			$string = $self->$job( $string );
		}
	}

	return $string;
}
		
=pod

=head2 decode_xml( $string )

A copy of XML::Comma::Util::XML_basic_unescape. Returns
an XML-unescaped string.

=cut

sub decode_xml {
	my $self = shift;
	my $string = shift;
	
	$string =~ s/\&amp;/&/g ;
	$string =~ s/\&lt;/</g ;
	$string =~ s/\&gt;/>/g ;
	
	return $string;
}
						
=pod

=head2 decode_html( $string )

Returns an HTML-unescaped string.

=cut

sub decode_html {
	my $self = shift;
	my $string = shift;

	return HTML::Entities::decode( $string );
}

=pod

=head2 decode_uri( $string )

Returns an URI-unescaped string.

=cut

sub decode_uri {
	my $self = shift;
	my $string = shift;

	return URI::Escape::uri_unescape( $string );
}

=pod

=head2 strip_html( $string )

Strips all HTML tags from string. Returns string.

=cut

sub strip_html {
	my $self = shift;
	my $string = shift;
	
	our $output;
	$output = '';

	sub default_handler {
		$output .= shift;
	}

	my $p = HTML::Parser->new( api_version => 3 );
	$p->handler( default => \&default_handler, "text" );
	$p->handler( start => "" );
	$p->handler( end => "" );
	$p->handler( comment => '' );
	$p->handler( declaration => '' );
	$p->handler( process => '' );

	$p->ignore_elements( qw( script style ) );

	$p->parse( "$string " );

	return $output;
}

=pod

=head2 strip_whitespace( $string )

Strips all whitespace ( \s ) characters from string.
Returns string.

=cut

sub strip_whitespace {
	my $self = shift;
	$_ = shift;
	s/\s+//g;
	return $_;
}

=pod

=head2 clean_high_ascii( $string )

Converts 8-bit ascii characters to their 7-bit counterparts.
Tested with MS-Word documents; might not work right with high-ascii
text from other sources. Returns string.

=cut

sub clean_high_ascii {
	my $self = shift;
	$_ = shift;

	my ( $high, $low );

	### single quotes
	$high = chr(145); $high = qr{$high};
	$low = qr{'};
	s/$high/$low/g;

	$high = chr(146); $high = qr{$high};
	s/$high/$low/g;

	### double quotes
	$high = chr(147); $high = qr{$high};
	$low = qr{"};
	s/$high/$low/g;

	$high = chr(148); $high = qr{$high};
	s/$high/$low/g;

	### endash
	$high = chr(150); $high = qr{$high};
	$low = qr{-};
	s/$high/$low/g;
	
	### emdash
	$high = chr(151); $high = qr{$high};
	$low = qr{--};
	s/$high/$low/g;
	
	### ellipsis
	$high = chr(133); $high = qr{$high};
	$low = qr{...};
	s/$high/$low/g;
	
	### unknown
	$high = chr(194); $high = qr{$high};
	s/$high//g;

	return $_;
}

=pod

=head2 clean_html_encoded_text( $string )

Properly encodes some entities skipped by HTML::Entities::encode.
Returns the modified string.

=cut

sub clean_html_encoded_text {
	my $self = shift;
	$_ = shift;
	
	### properly encode m-dashes
	s/\&#151;/\&#8212;/g;
	s/--/\&#8212;/g;

	### properly encode ellipses
	s/\.\.\./\&#8230;/g;

	### encode apostrophes
	#s/'/&#8217;/g;

	return $_;
}

=pod

=head2 decode_select_entities( $string )

Takes HTML::Entities::encoded HTML and selectively unencodes certain entities 
for display on webpage. Returns modified string.

=cut

sub decode_select_entities {
	my $self = shift;
	$_ = shift;

	### restore angle brackets
	s/\&lt;/</g;
	s/\&gt;/>/g;

	### restore quotes inside angle brackets
	1 while s/(<[^>]*)(\&quot;)/$1\"/gs;

	return $_;
}

=pod

=head2 clean_encoded_html( $string )

Formats HTML-encoded HTML for display on webpage. Returns modified string.

=cut

sub clean_encoded_html {
	my $self = shift;
	my $string = shift;

	$string = $self->decode_select_entities( $string );
	$string = $self->clean_html_encoded_text( $string );

	return $string;
}

=pod

=head2 clean_encoded_text( $string )

Formats HTML-encoded text for display on webpage. Returns modified string.

=cut

sub clean_encoded_text {
	my $self = shift;
	my $string = shift;

	$string = $self->clean_html_encoded_text( $string );

	return $string;
}

=pod

=head2 clean_whitespace( $string [keep_full_breaks => 1 | keep_all_breaks => 1] )

Cleans up whitespace in HTML and plain text. If passed an argument for handling
line breaks, it will either keep full breaks (\n\n) or all breaks (any \n). Otherwise,
all line breaks will be converted to spaces. Returns the modified string.

=cut

sub clean_whitespace {
	my $self = shift;
	$_ = shift;
	croak( "Odd number of parameters passed to format_text." ) if @_ % 2;
	my %args = @_;

	s/\r\n/\n/g;
	s/\r/\n/g;
	1 while s/\n\n\n/\n\n/g;
	s/^[ \t\f]+//g;
	s/[ \t\f]+$//g;

	if ( $args{keep_all_breaks} ) {
		1 while s/  / /g;
	} elsif ( $args{keep_full_breaks} ) {
		s/\n\n/\$\$\$/g;
		s/\n/ /g;
		1 while s/  / /g;
		s/\$\$\$/\n\n/g;
	} else {
		s/\n/ /g;
		1 while s/  / /g;
	}

	return $_;
}

=pod

=head2 clean_whitespace_keep_full_breaks( $string )

Cleans up whitespace in HTML and plain text while preserving all full breaks (\n\n).
Returns the modified string.

=cut

sub clean_whitespace_keep_full_breaks {
	my $self = shift;
	my $string = shift;

	return $self->clean_whitespace( $string, keep_full_breaks => 1 );
}

=pod

=head2 clean_whitespace_keep_all_breaks( $string )

Cleans up whitespace in HTML and plain text while preserving all line breaks (\n).
Returns the modified string.

=cut

sub clean_whitespace_keep_all_breaks {
	my $self = shift;
	my $string = shift;

	return $self->clean_whitespace( $string, keep_all_breaks => 1 );
}

=pod

=head2 force_lc( $string )

Returns lc( $string ).

=cut

sub force_lc {
	my $self = shift;
	my $string = shift;

	return lc $string;
}

=pod

=head2 force_uc( $string )

Returns uc( $string ).

=cut

sub force_uc {
	my $self = shift;
	my $string = shift;

	return uc $string;
}

=pod

=head2 truncate( $string, $count )

Returns the first $count characters of string.

=cut

sub truncate {
	my $self = shift;
	my $string = shift;
	my $count = shift;

	if ( length( $string ) > $count ) {
		$string = substr( $string, 0, $count );
	}
	
	return $string;
}

=pod

=head2 truncate_with_ellipses( $string, $count )

Returns the first $count - 3 characters of string followed by '...'.

=cut

sub truncate_with_ellipses {
	my $self = shift;
	my $string = shift;
	my $count = shift;

	if ( $count > 3 ) {
		if ( length( $string ) > $count ) {
			$string = substr( $string, 0, ( $count - 3 ) ) . '...';
		}
	}
	
	return $string;
}

=pod

=head2 encode_xml( $string )

A copy of XML::Comma::Util::XML_basic_escape. Returns
an XML-escaped string.

=cut

sub encode_xml {
	my $self = shift;
	my $string = shift;
	
	# escape &
	$string =~ s/\&/&amp;/g;
	
	# escape < >
	$string =~ s/</\&lt;/g ;
	$string =~ s/>/\&gt;/g ;
	
	return $string;
}
						
=pod

=head2 encode_html( $string )

Returns an HTML-escaped string.

=cut

sub encode_html {
	my $self = shift;
	my $string = shift;

	return HTML::Entities::encode( $string );
}

=pod

=head2 encode_uri( $string )

Returns an URI-escaped string.

=cut

sub encode_uri {
	my $self = shift;
	my $string = shift;

	return URI::Escape::uri_escape( $string );
}

=pod

=head2 reformat_date( $string, $oldformat, $newformat )

Takes a date string in $oldformat and returns a new string in
$new_format.

=cut

sub reformat_date {
	my $self = shift;
	my $string = shift;
	my $oldformat = shift;
	my $newformat = shift;

	my $dt = $self->parse_date( $string, $oldformat );
	return $self->format_date( $dt, $newformat );
}


=pod

=head2 parse_date( $string [, $format] )

Takes a $string representing a date and time, and tries to 
produce a valid DateTime object. Returns the object upon success,
otherwise undef.

Setting $string to 'now' creates a DateTime object of the current
date and time. Setting $string to 'today' creates a DateTime object 
of today's date and time set to midnight.

Otherwise, you must pass a $format to parse the string correctly.
$format can be set to one of the following "shortcuts": 'date8',
'date14', or 'rfc822'.

=cut

sub parse_date {
	my $self = shift;
	my $string = shift;
	my $format = shift;

	return unless $string;
	
	if ( $string eq 'now' ) {
		return DateTime->now( time_zone => 'local' );
	}

	if ( $string eq 'today' ) {
		return DateTime->today( time_zone => 'local' );
	}

	return unless $format;
	
	$format = '%Y%m%d' if $format eq 'date8';
	$format = '%Y%m%d%H%M%S' if $format eq 'date14';
	$format = '%a, %d %b %Y %H:%M:%S %z' if $format eq 'rfc822';

	if ( $format eq '%s' ) {
		return DateTime->from_epoch( epoch => $string, time_zone => 'local' );
	} else {
		my $parser = DateTime::Format::Strptime->new( 
			pattern => $format, 
			on_error => 'undef', 
			time_zone => 'local' 
		);
		return $parser->parse_datetime( $string );
	}

}

=pod

=head2 format_date( $dt, $format )

Takes a DateTime object ($dt) and a $format, and
returns the formatted string.

$format is a DateTime 'strftime' format string. $format can be
set to one of the following "shortcuts": 'date8', 'date14', 
and 'rfc822'.

=cut

sub format_date {
	my $self = shift;
	my $dt = shift;
	my $format = shift;
	
	return unless ref $dt eq 'DateTime';

	$format = '%Y%m%d' if $format eq 'date8';
	$format = '%Y%m%d%H%M%S' if $format eq 'date14';
	$format = '%a, %d %b %Y %H:%M:%S %z' if $format eq 'rfc822';
	
	return $dt->strftime( $format );
}

=pod

=head1 AUTHOR

Eric Folley, E<lt>eric@folley.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Eric Folley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
