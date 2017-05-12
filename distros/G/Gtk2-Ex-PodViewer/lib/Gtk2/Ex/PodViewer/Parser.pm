# $Id: Parser.pm,v 1.26 2008/10/04 14:00:24 gavin Exp $
# Copyright (c) 2003-2008 Gavin Brown. All rights reserved. This program is
# free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.
package Gtk2::Ex::PodViewer::Parser;
use base 'Pod::Parser';
use Carp;
use IO::Scalar;
use vars qw(%ENTITIES $LINK_TEXT_TEMPLATE $GETTEXT);
use Exporter;
use bytes;
use strict;

require 5.8.0;

our @EXPORT_OK = qw(&decode_entities);

# This table is taken near verbatim from Pod::PlainText in Pod::Parser, which
# got it near verbatim from the original Pod::Text.  It is therefore credited
# to Tom Christiansen, and I'm glad I didn't have to write it.  :)  "iexcl" to
# "divide" added by Tim Jenness.
our %ENTITIES	= (
	'amp'		=>	'&',		# ampersand
	'apos'		=>	"'",		# apostrophe
	'lt'		=>	'<',		# left chevron, less-than
	'gt'		=>	'>',		# right chevron, greater-than
	'quot'		=>	'"',		# double quote
	'sol'		=>	'/',		# solidus (forward slash)
	'verbar'	=>	'|',		# vertical bar
	"Aacute"	=>	"\xC1",		# capital A, acute accent
	"aacute"	=>	"\xE1",		# small a, acute accent
	"Acirc"		=>	"\xC2",		# capital A, circumflex accent
	"acirc"		=>	"\xE2",		# small a, circumflex accent
	"AElig"		=>	"\xC6",		# capital AE diphthong (ligature)
	"aelig"		=>	"\xE6",		# small ae diphthong (ligature)
	"Agrave"	=>	"\xC0",		# capital A, grave accent
	"agrave"	=>	"\xE0",		# small a, grave accent
	"Aring"		=>	"\xC5",		# capital A, ring
	"aring"		=>	"\xE5",		# small a, ring
	"Atilde"	=>	"\xC3",		# capital A, tilde
	"atilde"	=>	"\xE3",		# small a, tilde
	"Auml"		=>	"\xC4",		# capital A, dieresis or umlaut mark
	"auml"		=>	"\xE4",		# small a, dieresis or umlaut mark
	"Ccedil"	=>	"\xC7",		# capital C, cedilla
	"ccedil"	=>	"\xE7",		# small c, cedilla
	"Eacute"	=>	"\xC9",		# capital E, acute accent
	"eacute"	=>	"\xE9",		# small e, acute accent
	"Ecirc"		=>	"\xCA",		# capital E, circumflex accent
	"ecirc"		=>	"\xEA",		# small e, circumflex accent
	"Egrave"	=>	"\xC8",		# capital E, grave accent
	"egrave"	=>	"\xE8",		# small e, grave accent
	"ETH"		=>	"\xD0",		# capital Eth, Icelandic
	"eth"		=>	"\xF0",		# small eth, Icelandic
	"Euml"		=>	"\xCB",		# capital E, dieresis or umlaut mark
	"euml"		=>	"\xEB",		# small e, dieresis or umlaut mark
	"Iacute"	=>	"\xCD",		# capital I, acute accent
	"iacute"	=>	"\xED",		# small i, acute accent
	"Icirc"		=>	"\xCE",		# capital I, circumflex accent
	"icirc"		=>	"\xEE",		# small i, circumflex accent
	"Igrave"	=>	"\xCC",		# capital I, grave accent
	"igrave"	=>	"\xEC",		# small i, grave accent
	"Iuml"		=>	"\xCF",		# capital I, dieresis or umlaut mark
	"iuml"		=>	"\xEF",		# small i, dieresis or umlaut mark
	"Ntilde"	=>	"\xD1",		# capital N, tilde
	"ntilde"	=>	"\xF1",		# small n, tilde
	"Oacute"	=>	"\xD3",		# capital O, acute accent
	"oacute"	=>	"\xF3",		# small o, acute accent
	"Ocirc"		=>	"\xD4",		# capital O, circumflex accent
	"ocirc"		=>	"\xF4",		# small o, circumflex accent
	"Ograve"	=>	"\xD2",		# capital O, grave accent
	"ograve"	=>	"\xF2",		# small o, grave accent
	"Oslash"	=>	"\xD8",		# capital O, slash
	"oslash"	=>	"\xF8",		# small o, slash
	"Otilde"	=>	"\xD5",		# capital O, tilde
	"otilde"	=>	"\xF5",		# small o, tilde
	"Ouml"		=>	"\xD6",		# capital O, dieresis or umlaut mark
	"ouml"		=>	"\xF6",		# small o, dieresis or umlaut mark
	"szlig"		=>	"\xDF",		# small sharp s, German (sz ligature)
	"THORN"		=>	"\xDE",		# capital THORN, Icelandic
	"thorn"		=>	"\xFE",		# small thorn, Icelandic
	"Uacute"	=>	"\xDA",		# capital U, acute accent
	"uacute"	=>	"\xFA",		# small u, acute accent
	"Ucirc"		=>	"\xDB",		# capital U, circumflex accent
	"ucirc"		=>	"\xFB",		# small u, circumflex accent
	"Ugrave"	=>	"\xD9",		# capital U, grave accent
	"ugrave"	=>	"\xF9",		# small u, grave accent
	"Uuml"		=>	"\xDC",		# capital U, dieresis or umlaut mark
	"uuml"		=>	"\xFC",		# small u, dieresis or umlaut mark
	"Yacute"	=>	"\xDD",		# capital Y, acute accent
	"yacute"	=>	"\xFD",		# small y, acute accent
	"yuml"		=>	"\xFF",		# small y, dieresis or umlaut mark
	"laquo"		=>	"\xAB",		# left pointing double angle quotation mark
	"lchevron"	=>	"\xAB",		# synonym (backwards compatibility)
	"raquo"		=>	"\xBB",		# right pointing double angle quotation mark
	"rchevron"	=>	"\xBB",		# synonym (backwards compatibility)
	"iexcl"		=>	"\xA1",		# inverted exclamation mark
	"cent"		=>	"\xA2",		# cent sign
	"pound"		=>	"\xA3",		# (UK) pound sign
	"curren"	=>	"\xA4",		# currency sign
	"yen"		=>	"\xA5",		# yen sign
	"brvbar"	=>	"\xA6",		# broken vertical bar
	"sect"		=>	"\xA7",		# section sign
	"uml"		=>	"\xA8",		# diaresis
	"copy"		=>	"\xA9",		# Copyright symbol
	"ordf"		=>	"\xAA",		# feminine ordinal indicator
	"not"		=>	"\xAC",		# not sign
	"shy"		=>	'',		# soft (discretionary) hyphen
	"reg"		=>	"\xAE",		# registered trademark
	"macr"		=>	"\xAF",		# macron, overline
	"deg"		=>	"\xB0",		# degree sign
	"plusmn"	=>	"\xB1",		# plus-minus sign
	"sup2"		=>	"\xB2",		# superscript 2
	"sup3"		=>	"\xB3",		# superscript 3
	"acute"		=>	"\xB4",		# acute accent
	"micro"		=>	"\xB5",		# micro sign
	"para"		=>	"\xB6",		# pilcrow sign	= paragraph sign
	"middot"	=>	"\xB7",		# middle dot	= Georgian comma
	"cedil"		=>	"\xB8",		# cedilla
	"sup1"		=>	"\xB9",		# superscript 1
	"ordm"		=>	"\xBA",		# masculine ordinal indicator
	"frac14"	=>	"\xBC",		# vulgar fraction one quarter
	"frac12"	=>	"\xBD",		# vulgar fraction one half
	"frac34"	=>	"\xBE",		# vulgar fraction three quarters
	"iquest"	=>	"\xBF",		# inverted question mark
	"times"		=>	"\xD7",		# multiplication sign
	"divide"	=>	"\xF7",		# division sign
	"nbsp"		=>	"\x01",		# non-breaking space
);

our $LINK_TEXT_TEMPLATE = '{section} in the {document} manpage';

our $GETTEXT = 0;
eval qq(
	use Locale::gettext;
	$GETTEXT = 1;
);

=pod

=head1 NAME

Gtk2::Ex::PodViewer::Parser - a custom POD Parser for Gtk2::Ex::PodViewer.

=head1 SYNOPSIS

	$Gtk2::Ex::PodViewer::Parser::LINK_TEXT_TEMPLATE = '{section} in the {document} manpage';

	my $parser = Gtk2::Ex::PodViewer::Parser->new(
		buffer	=> $Gtk2TextView->get_buffer,
	);

	$parser->parse_from_file($file);

=head1 DESCRIPTION

Gtk2::Ex::PodViewer::Parser is a custom Pod parser for the Gtk2::Ex::PodViewer widget. You should never need to use it directly.

It is based on L<Pod::Parser>.

=head1 METHODS

=cut

sub new {
	my $package = shift;
	my %args = @_;
	my $parser = $package->SUPER::new;
	$parser->{buffer} = $args{buffer};
	$parser->{iter} = $parser->{buffer}->get_iter_at_offset(0);
	bless($parser, $package);
	return $parser;
}

sub command {
	my ($parser, $command, $paragraph, $line_num) = @_;
	if ($command =~ /^head/i) {
		$paragraph =~ s/[\s\r\n]*$//g;
		my $mark = $parser->{buffer}->create_mark($paragraph, $parser->{iter}, 1);
		push(@{$parser->{marks}}, [$paragraph, $mark, $parser->{iter}]);
		$parser->insert_text($paragraph, $line_num, $command);
		$parser->insert_text("\n\n", $line_num);
	} elsif (lc($command) eq 'item') {
		my $dot = chr(183);
		$paragraph =~ s/\n*$//g;
		if ($paragraph eq '*') {
			$parser->insert_text("$dot ", $line_num, qw(word_wrap bold indented));
		} elsif ($paragraph =~ /^\*\s*/) {
			$paragraph =~ s/^\*\s*//;
			$parser->insert_text("$dot ", $line_num, qw(word_wrap bold indented));
			$parser->insert_text("$paragraph\n\n", $line_num, qw(word_wrap indented));
		} elsif ($paragraph =~ /^\d+$/i) {
			$parser->insert_text("$paragraph ", $line_num, qw(word_wrap bold indented));
		} else {
			$parser->insert_text("$dot ", $line_num, qw(word_wrap bold indented));
			$parser->insert_text("$paragraph\n\n", $line_num, qw(word_wrap indented));
		}
	} elsif ($command !~ /^(pod|cut|for|over|back)$/i) {
		carp("unknown command: '$command' on line $line_num");
		$parser->insert_text($paragraph, $line_num, qw(word_wrap));
	}
}

sub verbatim {
	my ($parser, $paragraph, $line_num) = @_;
	$parser->insert_text($paragraph, $line_num, qw(monospace));
}

sub textblock {
	my ($parser, $paragraph, $line_num) = @_;
	$paragraph =~ s/[\r\n]/ /sg;
	$paragraph .= "\n\n";
	$parser->insert_text($paragraph, $line_num, qw(word_wrap));
}

sub insert_text {
	my ($parser, $paragraph, $line_num, @tags) = @_;

	my %tagnames = (
		I	=> 'italic',
		B	=> 'bold',
		C	=> 'typewriter',
		L	=> 'link',
		F	=> 'italic',
		S	=> 'monospace',
		E	=> 'word_wrap',
		X	=> 'normal',
		Z	=> 'normal',
	);

	$parser->parse_text(
		{
			-expand_ptree => sub {
				my ($parser, $ptree) = @_;

				foreach ($ptree->children) {
					if (ref($_) eq 'Pod::InteriorSequence') {
						my $sequence = $_;
						my $command = $sequence->cmd_name;
						my $text = $sequence->parse_tree->raw_text;

						if ($command eq 'E') {
							$text = $ENTITIES{$text} || $text;

						} elsif ($command eq 'L') {
							push(@{$parser->{links}}, [$text, $parser->{iter}->get_offset]);

							if ($text =~ /\|/) {
								($text, undef) = split(/\|/, $text, 2);
							}

							if ($text =~ /\/[^:]/ && $text !~ /:\/\//) {
								my ($doc, $section) = split(/\//, $text, 2);
								if ($doc eq '') {
									$text = $section;
								} else {
									$text = ($GETTEXT ? gettext($LINK_TEXT_TEMPLATE) : $LINK_TEXT_TEMPLATE);
									$text =~ s/\{section\}/$section/g;
									$text =~ s/\{document\}/$doc/g;
								}
							}

						}
						if (!exists($tagnames{$command})) {
							carp("warning: unknown formatting code '$command'\n");

						} else {
							$parser->{buffer}->insert_with_tags_by_name($parser->{iter}, decode_entities($text), $tagnames{$command}, @tags);

						}

					} else {
						my $text = $_;
						$parser->{buffer}->insert_with_tags_by_name($parser->{iter}, decode_entities($text), @tags);

					}
				}
			}
		},
		$paragraph,
		$line_num
	);

	return 1;
}

sub clear_marks {
	$_[0]->{marks} = [];
	return 1;
}

sub get_marks {
	my @names;
	map { push(@names, @{$_}[0]) } @{$_[0]->{marks} };
	return @names;
}

sub get_mark {
	my ($parser, $name) = @_;
	foreach my $mark (@{$parser->{marks}}) {
		return @{$mark}[1] if (@{$mark}[0] eq $name);
	}
	return undef;
}

sub parse_from_file {
	my ($self, $file) = @_;
	if (!open(FILE, '<:utf8', $file)) {
		carp("Cannot open '$file': $!");
		return undef;

	} else {
		my $data;
		while (<FILE>) {
			$data .= $_;
		}
		close(FILE);
		return $self->parse_from_string($data);
	}
}

=pod

One neat method not implemented by Pod::Parser is

	$parser->parse_from_string($string);

This parses a scalar containing POD data, using IO::Scalar to create a tied filehandle.

=cut

sub parse_from_string {
	my ($self, $string) = @_;
	my $handle = IO::Scalar->new(\$string);
	$self->{_source} = $string;
	$self->parse_from_filehandle($handle);
	$handle->close;
	return 1;
}

=pod

=head1 IMPORTABLE FUNCTIONS

	use Gtk2::Ex::PodViewer::Parser qw(decode_entities);
	my $text = decode_entities($pod);

This function takes a string of POD, and returns it with all the POD entities (eg C<EE<lt>gtE<gt>> =E<gt> "E<gt>") decoded into readable characters.

=cut

sub decode_entities {
	my $text = shift;
	$text =~ s/E<([^<]*)>/$ENTITIES{$1}/g;
	$text =~ s/\w{1}<([^<]*)>/$1/g;
	return $text;
}

sub source {
	my $self = shift;
	return $self->{_source};
}

=pod

=head1 VARIABLES

The C<$LINK_TEXT_TEMPLATE> class variable contains a string that is used to generate link text for POD links for the form

	LE<lt>foo/barE<gt>

This string is run through the C<gettext()> function from L<Locale::gettext> (if installed) before it is used, so if your application supports internationalisation, then the string will be translated if it appears in your translation domain. It contains two tokens, C<{section}> and C<{document}>, that are replaced with C<foo> and C<bar> respectively.

=head1 SEE ALSO

=over

=item *

L<Gtk2::Ex::PodViewer>

=item *

L<Pod::Parser>

=item *

L<Locale::gettext>

=back

=head1 AUTHORS

Gavin Brown, Torsten Schoenfeld and Scott Arrington.

=head1 COPYRIGHT

(c) 2003-2005 Gavin Brown (gavin.brown@uk.com). All rights reserved. This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself. 

=cut

1;
