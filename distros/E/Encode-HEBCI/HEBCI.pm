# Encode::HEBCI: HTML-Entity Based Codepage Inference
#
# Detect the encoding used for HTML form submissions.  See the POD for
# more information
#
# Copyright (c) 2005 Josh Myer <josh@joshisanerd.com>.
# All Rights Reserved.
#
#
# Released under the Artistic License or the LGPL v2 or later
#

package Encode::HEBCI;

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK $VERSION @CONFIG);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw();

@EXPORT_OK = qw();

$VERSION = '0.01';

use Carp;


# Entities used in fingerprinting
our @entities = qw/divide curren sect hellip deg middot rdquo rsquo times oelig Scaron oslash uml thorn euro eacute pound auml laquo/; 
# Supported Encodings

our @encodings = qw/UTF-8 UTF-7 SHIFT_JISX0213 ISO-2022-JP-3 ISO-2022-JP-2 GB18030 CP1252 CP1254 
		    UHC ISO-2022-KR JOHAB CP1258 CP1256 CP1257 CP1250 ISO-2022-CN-EXT ISO-2022-CN 
		    GBK MAC-SAMI MAC-IS EUC-JP EUC-CN MAC-UK WIN-SAMI-2 ISO-8859-13 ISO-8859-1 ISO-8859-9 
		    ISO-8859-3 ISO-8859-8 ISO-8859-4 ISO-8859-2 ISO-IR-197 ISO-IR-209 BIG5HKSCS CP1255 
		    EUC-TW MACROMAN ISO-2022-JP ISO-8859-15 KOI8-U CP1253 CP1251 KOI8-T CP1125 ISIRI-3342 
		    SEN_850200_C SEN_850200_B ISO-8859-6 ASMO_449 ISO-8859-16 ISO-8859-7 ISO-8859-10 
		    ISO-8859-14 ISO-8859-5 ARMSCII-8 TSCII BS_4730 ISO-8859-11/;

our %fingerprints = (		 
		     "UTF-8" => ['c3b7', 'c2a4', 'c2a7', 'e280a6', 'c2b0', 'c2b7', 'e2809d', 'e28099', 'c397', 'c593', 'c5a0', 'c3b8', 'c2a8', 'c3be', 'e282ac', 'c3a9', 'c2a3', 'c3a4', 'c2ab'], 
		     "UTF-7" => ['592d2b4150', '4d2d2b414b', '592d2b414b', '492d2b4943', '382d2b414c', '592d2b414c', '772d2b4942', '672d2b4942', '592d2b414e', '492d2b4156', '4d2d2b4157', '632d2b4150', '632d2b414b', '302d2b4150', '512d2b494b', '672d2b414f', '492d2b414b', '4d2d2b414f', '6f2d2b414b'], 
		     "SHIFT_JISX0213" => ['8180', '8543', '8198', '8163', '818b', '854d', '8168', '8166', '817e', '8649', '85a4', '858d', '814e', '8593', '8540', '857e', '8192', '8579', '8547'], 
		     "ISO-2022-JP-3" => ['1b28421b24422160', '1b28421b24284f2924', '1b28421b24422178', '1b28421b24422144', '1b28421b2442216b', '1b28421b24284f292e', '1b28421b24422149', '1b28421b24422147', '1b28421b2442215f', '1b28421b24284f2b2a', '1b28421b24284f2a26', '1b28421b24284f296d', '1b28421b2442212f', '1b28421b24284f2973', '1b24284f2921', '1b28421b24284f295f', '1b28421b24422172', '1b28421b24284f295a', '1b28421b24284f2928'], 
		     "ISO-2022-JP-2" => ['1b28421b24422160', '1b28421b2428442270', '1b28421b24422178', '1b24422144', '1b28421b2442216b', '1b28421b2e411b4e37', '1b28421b24422149', '1b28421b24422147', '1b28421b2442215f', '1b28421b242844294d', '1b28421b2428442a5e', '1b28421b242844294c', '1b28421b2442212f', '1b28421b2428442950', '1b2428432266', '1b28421b2428442b31', '1b28421b24422172', '1b28421b2428442b23', '1b28421b2e411b4e2b'], 
		     "GB18030" => ['a1c2', 'a1e8', 'a1ec', 'a1ad', 'a1e3', 'a1a4', 'a1b1', 'a1af', 'a1c1', '81309334', '81309437', '81308b33', 'a1a7', '81308b36', 'a2e3', 'a8a6', '81308435', '81308a31', '81308530'],
		     "CP1252" => ['f7', 'a4', 'a7', '85', 'b0', 'b7', '94', '92', 'd7', '9c', '8a', 'f8', 'a8', 'fe', '80', 'e9', 'a3', 'e4', 'ab'],
		     "CP1254" => ['f7', 'a4', 'a7', '85', 'b0', 'b7', '94', '92', 'd7', '9c', '8a', 'f8', 'a8', '', '80', 'e9', 'a3', 'e4', 'ab'],
		     "UHC" => ['a1c0', 'a2b4', 'a1d7', 'a1a6', 'a1c6', 'a1a4', 'a1b1', 'a1af', 'a1bf', 'a9ab', '', 'a9aa', 'a1a7', 'a9ad', 'a2e6', '', '', '', ''],
		     "ISO-2022-KR" => ['0e2140', '0e2234', '0e2157', '0e2126', '0e2146', '0f0e2124', '0f0e2131', '0f0e212f', '0e213f', '0f0e292b', '', '0f0e292a', '0f0e2127', '0e292d', '0e2266', '', '', '', ''],
		     "JOHAB" => ['d950', 'd9b4', 'd967', 'd936', 'd956', 'd934', 'd941', 'd93f', 'd94f', 'dd3b', '', 'dd3a', 'd937', 'dd3d', '', '', '', '', ''], 
		     "CP1258" => ['f7', 'a4', 'a7', '85', 'b0', 'b7', '94', '92', 'd7', '9c', '', 'f8', 'a8', '', '80', 'e9', 'a3', 'e4', 'ab'], 
		     "CP1256" => ['f7', 'a4', 'a7', '85', 'b0', 'b7', '94', '92', 'd7', '9c', '', '', 'a8', '', '80', 'e9', 'a3', '', 'ab'], 
		     "CP1257" => ['f7', 'a4', 'a7', '85', 'b0', 'b7', '94', '92', 'd7', '', 'd0', 'b8', '8d', '', '80', 'e9', 'a3', 'e4', 'ab'], 
		     "CP1250" => ['f7', 'a4', 'a7', '85', 'b0', 'b7', '94', '92', 'd7', '', '8a', '', 'a8', '', '80', 'e9', '', 'e4', 'ab'], 
		     "ISO-2022-CN-EXT" => ['1b2429410e2142', '0f1b2429410e2168', '1b2429410e216c', '1b2429410e212d', '1b2429410e2163', '1b2429470e2131', '0f1b2429410e2131', '0f1b2429410e212f', '1b2429410e2141', '', '', '', '0f1b2429410e2127', '', '', '0f1b2429410e2826', '0f1b2429450e216a', '', ''], 
		     "ISO-2022-CN" => ['1b2429410e2142', '1b2429410e2168', '1b2429410e216c', '1b2429410e212d', '1b2429410e2163', '1b2429470e2131', '0f1b2429410e2131', '0f1b2429410e212f', '1b2429410e2141', '', '', '', '0f1b2429410e2127', '', '', '0f1b2429410e2826', '', '', ''], 
		     "GBK" => ['a1c2', 'a1e8', 'a1ec', 'a1ad', 'a1e3', 'a1a4', 'a1b1', 'a1af', 'a1c1', '', '', '', 'a1a7', '', '', 'a8a6', '', '', ''], 
		     "MAC-SAMI" => ['d6', 'db', 'a4', 'c9', 'a1', 'e1', 'd3', 'd5', '', 'cf', 'b4', 'bf', 'ac', 'df', '', '8e', 'a3', '8a', 'c7'], 
		     "MAC-IS" => ['d6', 'db', 'a4', 'c9', 'a1', 'e1', 'd3', 'd5', '', 'cf', '', 'bf', 'ac', 'df', '', '8e', 'a3', '8a', 'c7'], 
		     "EUC-JP" => ['a1e0', '8fa2f0', 'a1f8', 'a1c4', 'a1eb', '', 'a1c9', 'a1c7', 'a1df', '8fa9cd', '8faade', '8fa9cc', 'a1af', '8fa9d0', '', '8fabb1', 'a1f2', '8faba3', ''], 
		     "EUC-CN" => ['a1c2', 'a1e8', 'a1ec', 'a1ad', 'a1e3', '', 'a1b1', 'a1af', 'a1c1', '', '', '', 'a1a7', '', '', 'a8a6', '', '', ''], 
		     "MAC-UK" => ['d6', 'ff', 'a4', 'c9', 'a1', '', 'd3', 'd5', '', '', '', '', '', '', '', '', 'a3', '', 'c7'], 
		     "WIN-SAMI-2" => ['f7', 'a4', 'a7', '', 'b0', 'b7', '94', '92', 'd7', '9c', '8a', 'f8', 'a8', 'fe', '80', 'e9', 'a3', 'e4', 'ab'], 
		     "ISO-8859-13" => ['f7', 'a4', 'a7', '', 'b0', 'b7', 'a1', 'ff', 'd7', '', 'd0', 'b8', '', '', '', 'e9', 'a3', 'e4', 'ab'], 
		     "ISO-8859-1" => ['f7', 'a4', 'a7', '', 'b0', 'b7', '', '', 'd7', '', '', 'f8', 'a8', 'fe', '', 'e9', 'a3', 'e4', 'ab'], 
		     "ISO-8859-9" => ['f7', 'a4', 'a7', '', 'b0', 'b7', '', '', 'd7', '', '', 'f8', 'a8', '', '', 'e9', 'a3', 'e4', 'ab'], 
		     "ISO-8859-3" => ['f7', 'a4', 'a7', '', 'b0', 'b7', '', '', 'd7', '', '', '', 'a8', '', '', 'e9', 'a3', 'e4', ''], 
		     "ISO-8859-8" => ['ba', 'a4', 'a7', '', 'b0', 'b7', '', '', 'aa', '', '', '', 'a8', '', '', '', 'a3', '', 'ab'], 
		     "ISO-8859-4" => ['f7', 'a4', 'a7', '', 'b0', '', '', '', 'd7', '', 'a9', 'f8', 'a8', '', '', 'e9', '', 'e4', ''], 
		     "ISO-8859-2" => ['f7', 'a4', 'a7', '', 'b0', '', '', '', 'd7', '', 'a9', '', 'a8', '', '', 'e9', '', 'e4', ''], 
		     "ISO-IR-197" => ['f7', '', 'a7', '85', 'b0', 'b7', '94', '92', 'd7', '9c', 'b2', 'f8', '', 'fe', '', 'e9', '88', 'e4', 'ab'], 
		     "ISO-IR-209" => ['f7', '', 'a7', '85', 'b0', 'b7', '94', '92', 'd7', '9c', 'b2', 'f8', '', 'fe', '', 'e9', '88', 'e4', ''], 
		     "BIG5HKSCS" => ['a1d2', '', 'a1b1', 'a14b', 'a258', 'a150', 'a1a8', 'a1a6', 'a1d1', 'c8fa', '', 'c8fb', 'c6d8', '', '', '886d', 'a247', '', ''], 
		     "CP1255" => ['ba', '', 'a7', '85', 'b0', 'b7', '94', '92', 'aa', '', '', '', 'a8', '', '80', '', 'a3', '', 'ab'], 
		     "EUC-TW" => ['a2b3', '', 'a1f0', 'a1ac', 'a2f8', 'a1b1', 'a1e7', 'a1e5', 'a2b2', '', '', '', '', '', '', '', '', '', ''], 
		     "MACROMAN" => ['d6', '', 'a4', 'c9', 'a1', 'e1', 'd3', 'd5', '', 'cf', '', 'bf', 'ac', '', 'db', '8e', 'a3', '8a', 'c7'], 
		     "ISO-2022-JP" => ['1b24422160', '', '1b24422178', '1b24422144', '1b2442216b', '', '1b28421b24422149', '1b28421b24422147', '1b2442215f', '', '', '', '1b28421b2442212f', '', '', '', '1b28421b24422172', '', ''], 
		     "ISO-8859-15" => ['f7', '', 'a7', '', 'b0', 'b7', '', '', 'd7', 'bd', 'a6', 'f8', '', 'fe', 'a4', 'e9', 'a3', 'e4', 'ab'], 
		     "KOI8-U" => ['9f', '', '', '', '9c', '9e', '', '', '', '', '', '', '', '', '', '', '', '', ''], 
		     "CP1253" => ['', 'a4', 'a7', '85', 'b0', 'b7', '94', '92', '', '', '', '', 'a8', '', '80', '', 'a3', '', 'ab'], 
		     "CP1251" => ['', 'a4', 'a7', '85', 'b0', 'b7', '94', '92', '', '', '', '', '', '', '88', '', '', '', 'ab'], 
		     "KOI8-T" => ['', 'a4', 'a7', '85', 'b0', 'b7', '94', '92', '', '', '', '', '', '', '', '', '', '', 'ab'], 
		     "CP1125" => ['', 'fd', '', '', '', 'fa', '', '', '', '', '', '', '', '', '', '', '', '', ''], 
		     "ISIRI-3342" => ['', 'a4', '', '', '', '', '', '', 'aa', '', '', '', '', '', '', '', '', '', 'e6'], 
		     "SEN_850200_C" => ['', '24', '', '', '', '', '', '', '', '', '', '', '', '', '', '60', '', '7b', ''], 
		     "SEN_850200_B" => ['', '24', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '7b', ''], 
		     "ISO-8859-6" => ['', 'a4', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''], 
		     "ASMO_449" => ['', '24', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''], 
		     "ISO-8859-16" => ['', '', 'a7', '', 'b0', 'b7', 'b5', '', '', 'bd', 'a6', '', '', '', 'a4', 'e9', '', 'e4', 'ab'], 
		     "ISO-8859-7" => ['', '', 'a7', '', 'b0', 'b7', '', 'a2', '', '', '', '', 'a8', '', '', '', 'a3', '', 'ab'], 
		     "ISO-8859-10" => ['', '', 'a7', '', 'b0', 'b7', '', '', '', '', 'aa', 'f8', '', 'fe', '', 'e9', '', 'e4', ''], 
		     "ISO-8859-14" => ['', '', 'a7', '', '', '', '', '', '', '', '', 'f8', '', '', '', 'e9', 'a3', 'e4', ''], 
		     "ISO-8859-5" => ['', '', 'fd', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''], 
		     "ARMSCII-8" => ['', '', '', 'ae', '', '', '', '', '', '', '', '', '', '', '', '', '', '', 'a7'], 
		     "TSCII" => ['', '', '', '', '', '', '94', '92', '', '', '', '', '', '', '', '', '', '', ''], 
		     "BS_4730" => ['', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '23', '', ''], 
		     "ISO-8859-11" => ['', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', ''], 
		    );

sub new {
  my $class = shift;
  my $self = {};
  bless($self, $class);

  return $self;
}

# Run fingerprints
# Argument: hashref, entity->value
sub fingerprint (%) {
  my $self = shift;
  my ($vals_hr) = (@_);

  my %vals = %{$vals_hr};

  my @pages = keys %fingerprints;

  my @results;

  #print "<!-- vals: " .  join(", ", keys(%vals)) .  " -->\n";

 PAGE: foreach my $page (@encodings) {
    #print "page: $page\n";
    my $ar = $fingerprints{$page};
    my @a = @{$ar};

    # print "<!-- $page: @a -->\n";

    for (my $i = 0; $i < scalar(@entities); $i++) {
      my $ent = $entities[$i];

      my $c = $vals{$ent};

      next unless(defined($vals{$ent}));

      if ($a[$i]) {
	# We have positive evidence to check
	my $curval = unpack("H*", $vals{$ent});
	if ($a[$i] ne $curval) {
	  # print "<!-- EX $page $ent $a[$i] : $curval -->\n";
	  next PAGE;
	}
      } else {
	# We _might_ have negative evidence to check
	my $amper = substr($vals{$ent}, 0, 1);

	if ($amper ne "&") {
	  # print "<!-- NE $page $ent $a[$i] : $amper -->\n";
	  next PAGE;
	}
      }
    }
    push(@results, $page);
  }

  return @results;
}

sub supported_entities () {
  return @entities;
}

sub supported_encodings () {
  return @encodings;
}

sub master_fingerprints () {
  return %fingerprints;
}

1;

__END__

=head1 NAME

HEBCI - HTML Entity Based Codepage Inference

=head1 SYNOPSIS

    use Encode::HEBCI;

    $hebci = new Encode::HEBCI();
    @fingerprint_entities = $hebci->supported_entities();
    @possible_encodings = $hebci->fingerprint(%entities_to_values);

=head1 DESCRIPTION

The C<Encode::HEBCI> module provides a mechanism to determine the character
encoding used to submit an HTML form.  It does this by using the encoded
values of specially-chosen HTML entities to infer which encodings were
possibly used, returning a list to the user.

Full details are available at the HEBCI homepage,
L<http://www.joshisanerd.com/set/>.

=head1 MODULE

To use the module, simply C<use> it.

    use Encode::HEBCI;

=head2 Methods

=head3 Encode::HEBCI->new()

Returns a new HEBCI object.

=head3 Encode::HEBCI->supported_entities();

Returns an array containing the HTML entities that will give the best
fingerprint, in order of decreasing utility.

=head3 Encode::HEBCI->fingerprint(%entity_values)

Returns an array of possible encodings given the values in
C<%entity_values>.  C<%entity_values> should be a hash with keys of HTML
entity names (i.e. without the ampersand or semicolon) to the raw bytes
returned to your application by the webbrowser.

=head3 Encode::HEBCI->supported_encodings()

Returns an array containing the encodings this copy of HEBCI can
distinguish between.

=head3 Encode::HEBCI->master_fingerprints()

Returns the fingerprint table.  You probably don't want this.

=head1 EXAMPLES

An example CGI is distributed with the source code.

