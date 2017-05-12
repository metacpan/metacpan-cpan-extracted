package HTML::Entities::ImodePictogram;

use strict;
use vars qw($VERSION);
$VERSION = 0.06;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
require Exporter;
@ISA       = qw(Exporter);
@EXPORT    = qw(encode_pictogram decode_pictogram remove_pictogram);
@EXPORT_OK = qw(find_pictogram);
%EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );

my $one_byte  = '[\x00-\x7F\xA1-\xDF]';
my $two_bytes = '[\x81-\x9F\xE0-\xFC][\x40-\x7E\x80-\xFC]';

use vars qw($Sjis_re $Pictogram_re $ExtPictorgram_re);
$Sjis_re      = qr<$one_byte|$two_bytes>;
$Pictogram_re = '\xF8[\x9F-\xFC]|\xF9[\x40-\x7E\x80-\xB0]';
$ExtPictorgram_re = '\xF9[\xB1-\xFC]';

sub find_pictogram (\$&) {
    my($r_text, $callback) = @_;

    my $num_found = 0;
    $$r_text =~ s{(($Pictogram_re)|($ExtPictorgram_re)|$Sjis_re)}{
	my $orig_match = $1;
	if (defined $2 || defined $3) {
	    $num_found++;
	    my $number = unpack 'n', $orig_match;
	    $callback->($orig_match, $number, _num2cp($number));
	}
	else {
	    $orig_match;
	}
    }eg;

    return $num_found;
}

sub encode_pictogram {
    my($text, %opt) = @_;
    find_pictogram($text, sub {
		       my($char, $number, $cp) = @_;
		       if ($opt{unicode} || $cp >= 59148) {
			   return sprintf '&#x%x;', $cp;
		       } else {
			   return '&#' . $number . ';';
		       }
		   });
    return $text;
}

sub decode_pictogram {
    my $html = shift;
    $html =~ s{(\&\#(\d{5});)|(\&\#x([0-9a-fA-F]{4});)}{
	if (defined $1) {
	    my $cp = _num2cp($2);
	    defined $cp ? pack('n', $2) : $1;
	} elsif (defined $3) {
	    my $num = _cp2num(hex($4));
	    defined $num ? pack('n', $num) : $3;
	}
    }eg;
    return $html;
}

sub remove_pictogram {
    my $text = shift;
    find_pictogram($text, sub {
		       return '';
		   });
    return $text;
}

sub _num2cp {
    my $num = shift;
    if ($num >= 63647 && $num <= 63740) {
	return $num - 4705;
    } elsif (($num >= 63808 && $num <= 63817) ||
	     ($num >= 63824 && $num <= 63838) ||
             ($num >= 63858 && $num <= 63870)) {
	return $num - 4772;
    } elsif ($num >= 63872 && $num <= 63996) {
	return $num - 4773;
    } else {
	return;
    }
}

sub _cp2num {
    my $cp = shift;
    if ($cp >= 58942 && $cp <= 59035) {
	return $cp + 4705;
    } elsif (($cp >= 59036 && $cp <= 59045) ||
	     ($cp >= 59052 && $cp <= 59066) ||
	     ($cp >= 59086 && $cp <= 59098)) {
	return $cp + 4772;
    } elsif (($cp >= 59099 && $cp <= 59146) ||
	     ($cp >= 59148 && $cp <= 59223)) {
	return $cp + 4773;
    } else {
	return;
    }
}


1;
__END__

=head1 NAME

HTML::Entities::ImodePictogram - encode / decode i-mode pictogram

=head1 SYNOPSIS

  use HTML::Entities::ImodePictogram;

  $html      = encode_pictogram($rawtext);
  $rawtext   = decode_pictogram($html);
  $cleantext = remove_pictogram($rawtext);

  use HTML::Entities::ImodePictogram qw(find_pictogram);

  $num_found = find_pictogram($rawtext, \&callback);

=head1 DESCRIPTION

HTML::Entities::ImodePictogram handles HTML entities for i-mode
pictogram (emoji), which are assigned in Shift_JIS private area.

See http://www.nttdocomo.co.jp/i/tag/emoji/index.html for details
about i-mode pictogram.

=head1 FUNCTIONS

In all functions in this module, input/output strings are asssumed as
encoded in Shift_JIS. See L<Jcode> for conversion between Shift_JIS
and other encodings like EUC-JP or UTF-8.

This module exports following functions by default.

=over 4

=item encode_pictogram

  $html = encode_pictogram($rawtext);
  $html = encode_pictogram($rawtext, unicode => 1);

Encodes pictogram characters in raw-text into HTML entities. If
$rawtext contains extended pictograms, they are encoded in Unicode
format. If you add C<unicode> option explicitly, all pictogram
characters are encoded in Unicode format (C<&#xFFFF;>). Otherwise,
encoding is done in decimal format (C<&#NNNNN;>).

=item decode_pictogram

  $rawtext = decode_pictogram($html);

Decodes HTML entities (both for C<&#xFFFF;> and C<&#NNNNN;>) for
pictogram into raw-text in Shift_JIS.

=item remove_pictogram

  $cleantext = remove_pictogram($rawtext);

Removes pictogram characters in raw-text.

=back

This module also exports following functions on demand.

=over 4

=item find_pictogram

  $num_found = find_pictorgram($rawtext, \&callback);

Finds pictogram characters in raw-text and executes callback when
found. It returns the total numbers of charcters found in text.

The callback is given three arguments. The first is a found pictogram
character itself, and the second is a decimal number which represents
Shift_JIS codepoint of the character. The third is a Unicode
codepoint. Whatever the callback returns will replace the original
text.

Here is a stub implementation of encode_pictogram(), which will be the
good example for the usage of find_pictogram(). Note that this example
version doesn't support extended pictograms.

  sub encode_pictogram {
      my $text = shift;
      find_pictogram($text, sub {
			 my($char, $number, $cp) = @_;
			 return '&#' . $number . ';';
		     });
      return $text;
  }

=back

=head1 CAVEAT

=over 4

=item *

This module works so slow, because regex used here matches C<ANY>
characters in the text. This is due to the difficulty of extracting
character boundaries of Shift_JIS encoding.

=item *

Extended pictogram support of this module is not complete. If you
handle pictogram characters in Unicode, try Encode module with perl
5.8.0, or Unicode::Japanese.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<HTML::Entities>, L<Unicode::Japanese>,
http://www.nttdocomo.co.jp/p_s/imode/tag/emoji/

=cut

