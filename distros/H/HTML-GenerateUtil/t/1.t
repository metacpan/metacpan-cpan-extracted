
#########################

use Test::More tests => 2063;
BEGIN { use_ok('HTML::GenerateUtil') };
use HTML::GenerateUtil qw(:consts escape_html generate_attributes generate_tag);
use Encode;
use strict;

my $border_size = 100;
my @border = 'x' x $border_size;

ok (!defined escape_html(undef, 0));
ok (!defined escape_html(undef, EH_INPLACE));

push @border, 'x' x $border_size;

is ('1', escape_html(1, 0));
is ('-1000000000', escape_html(-1000000000, 0));
is ('1.25', escape_html(1.25, 0));

my ($a, $b) = (1, 1.25);
escape_html($a, EH_INPLACE);
escape_html($b, EH_INPLACE);
is ('1', $a);
is ('1.25', $b);

is ('&lt;', escape_html('<', 0));
is ('&gt;', escape_html('>', 0));
is ('&amp;', escape_html('&', 0));
is ('&quot;', escape_html('"', 0));

push @border, 'x' x $border_size;

is ("\n", escape_html("\n", 0));
is ("<br>", escape_html("\n", EH_LFTOBR));

push @border, 'x' x $border_size;

is ('  ', escape_html('  ', 0));
is ('&nbsp; ', escape_html('  ', EH_SPTONBSP));
is (' &nbsp; ', escape_html('   ', EH_SPTONBSP));

is (' ', escape_html(' ', 0));
is ('&nbsp;', escape_html(' ', EH_SPTONBSP));

is ('  ', escape_html('  '));
is ('&lt;', escape_html('<'));
is ('&amp;amp;', escape_html('&amp;'));

push @border, 'x' x $border_size;

$a = '<>&"';
$b = escape_html($a, 0);
is ('<>&"', $a);
is ('&lt;&gt;&amp;&quot;', $b);

# Test with special string offsets

$a = '<>&"';
$a =~ s/^.//;
is ('&gt;&amp;&quot;', escape_html($a, 0));
escape_html($a, EH_INPLACE);
is ('&gt;&amp;&quot;', $a);

$b = '<>&"                               ';
$b =~ s/^.//;
$b =~ s/\s+$//;
is ('&gt;&amp;&quot;', escape_html($b, 0));
escape_html($b, EH_INPLACE);
is ('&gt;&amp;&quot;', $b);

is ('&amp;', escape_html('&', EH_LEAVEKNOWN));
is ('&amp;', escape_html('&amp;', EH_LEAVEKNOWN));
is ('&amp ', escape_html('&amp ', EH_LEAVEKNOWN));
is ('&amp;amp', escape_html('&amp', EH_LEAVEKNOWN));
is ('&nbsp;', escape_html('&nbsp;', EH_LEAVEKNOWN));
is ('&nbsp ', escape_html('&nbsp ', EH_LEAVEKNOWN));
is ('&amp;nbsp', escape_html('&nbsp', EH_LEAVEKNOWN));
is ('&#1234;', escape_html('&#1234;', EH_LEAVEKNOWN));
is ('&#1234 ', escape_html('&#1234 ', EH_LEAVEKNOWN));
is ('&amp;#1234', escape_html('&#1234', EH_LEAVEKNOWN));
is ('&amp;&amp;&amp;&amp;', escape_html('&&amp;&&amp;', EH_LEAVEKNOWN));
is ('&amp;&amp;&amp;<br>&amp;', escape_html("&&amp;&\n&amp;", EH_LEAVEKNOWN | EH_LFTOBR));

$a = '&';
is ('&amp;', escape_html($a, EH_LEAVEKNOWN | EH_INPLACE));
$a = '&amp;';
is ('&amp;', escape_html($a, EH_LEAVEKNOWN | EH_INPLACE));
$a = '&amp ';
is ('&amp ', escape_html($a, EH_LEAVEKNOWN | EH_INPLACE));
$a = '&amp';
is ('&amp;amp', escape_html($a, EH_LEAVEKNOWN | EH_INPLACE));
$a = '&nbsp;';
is ('&nbsp;', escape_html($a, EH_LEAVEKNOWN | EH_INPLACE));
$a = '&nbsp ';
is ('&nbsp ', escape_html($a, EH_LEAVEKNOWN | EH_INPLACE));
$a = '&nbsp';
is ('&amp;nbsp', escape_html($a, EH_LEAVEKNOWN | EH_INPLACE));
$a = '&#1234;';
is ('&#1234;', escape_html($a, EH_LEAVEKNOWN | EH_INPLACE));
$a = '&#1234 ';
is ('&#1234 ', escape_html($a, EH_LEAVEKNOWN | EH_INPLACE));
$a = '&#1234';
is ('&amp;#1234', escape_html($a, EH_LEAVEKNOWN | EH_INPLACE));
$a = '&&amp;&&amp;';
is ('&amp;&amp;&amp;&amp;', escape_html($a, EH_LEAVEKNOWN | EH_INPLACE));
$a = "&&amp;&\n&amp;";
is ('&amp;&amp;&amp;<br>&amp;', escape_html($a, EH_LEAVEKNOWN | EH_INPLACE | EH_LFTOBR));

$a = "&&amp;&\n&amp;                             ";
$a =~ s/\s+$//;
is ('&amp;&amp;&amp;<br>&amp;', escape_html($a, EH_LEAVEKNOWN | EH_INPLACE | EH_LFTOBR));
is ('&amp;&amp;&amp;&lt;br&gt;&amp;', escape_html($a, EH_LEAVEKNOWN | EH_INPLACE | EH_LFTOBR));

push @border, 'x' x $border_size;

is ('a&amp;bc&nbsp;de&amp;f', escape_html('a&bc&nbsp;de&f', EH_LEAVEKNOWN));
is ('a&amp;bc&nbsp de&amp;x', escape_html('a&bc&nbsp de&x', EH_LEAVEKNOWN));
is ('a&amp;bc&#1234;de&amp;#f', escape_html('a&bc&#1234;de&#f', EH_LEAVEKNOWN));
is ('a&amp;bc&#x1ab4;de&amp;#xf', escape_html('a&bc&#x1ab4;de&#xf', EH_LEAVEKNOWN));
is ('a&amp;bc&#x1ab4;def', escape_html('a&bc&#x1ab4;def', EH_LEAVEKNOWN));

push @border, 'x' x $border_size;

$a = '<>&"' . "\x{1234}";
$b = escape_html($a, 0);
is ('<>&"' . "\x{1234}", $a);
is ('&lt;&gt;&amp;&quot;' . "\x{1234}", $b);
ok (Encode::is_utf8($b));

push @border, 'x' x $border_size;

for (1 .. 1000) {
  my $str = '';
  for (1 .. int(rand(30))) {
    my $rnd = rand();
    if ($rnd < 0.05)    { $str .= '<'; }
    elsif ($rnd < 0.10) { $str .= '>'; }
    elsif ($rnd < 0.15) { $str .= '&'; }
    elsif ($rnd < 0.20) { $str .= '"'; }
    elsif ($rnd < 0.25) { $str .= "\n"; }
    elsif ($rnd < 0.30) { $str .= '  '; }
    elsif ($rnd < 0.98) { $str .= chr(ord('a') + rand(26)); }
    else { $str .= chr(ord('a') + rand(10000)); }
  }

  my $pstr = $str;
  $pstr =~ s/&/&amp;/g;
  $pstr =~ s/</&lt;/g;
  $pstr =~ s/>/&gt;/g;
  $pstr =~ s/\"/&quot;/g;
  $pstr =~ s/\n/<br>/g;
  $pstr =~ s/  /&nbsp; /g;

  my $estr = escape_html($str, EH_LFTOBR | EH_SPTONBSP);
  is ($estr, $pstr);
  is (Encode::is_utf8($str), Encode::is_utf8($estr));
}

push @border, 'x' x $border_size;

is(join('', @border), 'x' x ($border_size * @border));

