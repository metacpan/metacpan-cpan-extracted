#! /usr/bin/perl
#---------------------------------------------------------------------
# 20-utf8.t
#---------------------------------------------------------------------

use strict;
use warnings;

use Test::More tests => 5;

use HTML::Element 3.21;

BEGIN {
    use_ok('HTML::Embellish');
}

my $nb    = chr(0x00A0);
my $mdash = chr(0x2014);
my $lsquo = chr(0x2018);
my $rsquo = chr(0x2019);
my $ldquo = chr(0x201C);
my $rdquo = chr(0x201D);

#=====================================================================
sub fmt
{
  my ($html) = @_;

  my $text = $html->as_HTML("<>&", undef, {});
  $text =~ s/\s*\z/\n/;         # Ensure it ends with a single newline

  return $text;
} # end fmt

#=====================================================================

##my $utf8text1 = qq{"Here\xA0we \x2014have };
##utf8::upgrade($utf8text1);
##
##my $utf8text = qq{'some\xA0text'};
###utf8::upgrade($utf8text);

my $utf8text = q{Jackson nodded. "I'm afraid so. I'd hoped the cannons..." He waved that thought away impatiently. "I'll need to rely on you and your regulars, Lemuel. Pass the word to Colonel Williams to get ready."};

my $utf8text1 = $utf8text;
utf8::upgrade($utf8text1);

my $utf8textRef = \$utf8text;

$$utf8textRef = substr($utf8text1, 0, length($$utf8textRef), '');

my $source_list = [
  p => $utf8text
];

#---------------------------------------------------------------------
my $html = HTML::Element->new_from_lol($source_list);

embellish($html);
is(fmt($html), <<"", 'default processing');
<p>Jackson nodded. ${ldquo}I${rsquo}m afraid so. I${rsquo}d hoped the cannons${nb}.${nb}.${nb}.${rdquo} He waved that thought away impatiently. ${ldquo}I${rsquo}ll need to rely on you and your regulars, Lemuel. Pass the word to Colonel Williams to get ready.$rdquo</p>

#---------------------------------------------------------------------
$html = HTML::Element->new_from_lol($source_list);

embellish($html, default => 0);
is(fmt($html), <<"", 'all disabled');
<p>Jackson nodded. "I'm afraid so. I'd hoped the cannons..." He waved that thought away impatiently. "I'll need to rely on you and your regulars, Lemuel. Pass the word to Colonel Williams to get ready."</p>

#---------------------------------------------------------------------
$html = HTML::Element->new_from_lol($source_list);

embellish($html, ellipses => 1, default => 0);
is(fmt($html), <<"", 'ellipses only');
<p>Jackson nodded. "I'm afraid so. I'd hoped the cannons${nb}.${nb}.${nb}." He waved that thought away impatiently. "I'll need to rely on you and your regulars, Lemuel. Pass the word to Colonel Williams to get ready."</p>

#---------------------------------------------------------------------
$html = HTML::Element->new_from_lol($source_list);

embellish($html, quotes => 1, default => 0);
is(fmt($html), <<"", 'quotes only');
<p>Jackson nodded. ${ldquo}I${rsquo}m afraid so. I${rsquo}d hoped the cannons...${rdquo} He waved that thought away impatiently. ${ldquo}I${rsquo}ll need to rely on you and your regulars, Lemuel. Pass the word to Colonel Williams to get ready.$rdquo</p>

#END
