
#########################

use Test::More tests => 1543;
BEGIN { use_ok('HTML::GenerateUtil') };
use HTML::GenerateUtil qw(:consts escape_uri);
use Encode;
use strict;

my $border_size = 100;
my @border = 'x' x $border_size;

ok (!defined escape_uri(undef, 0));
ok (!defined escape_uri(undef, EU_INPLACE));

push @border, 'x' x $border_size;

is ('1', escape_uri(1, 0));
is ('-1000000000', escape_uri(-1000000000, 0));
is ('1.25', escape_uri(1.25, 0));

my ($a, $b) = (1, 1.25);
escape_uri($a, EU_INPLACE);
escape_uri($b, EU_INPLACE);
is ('1', $a);
is ('1.25', $b);

is ('%3C', escape_uri('<', 0));
is ('%26', escape_uri('&', 0));
is ('%3F', escape_uri('?', 0));
is ('%25', escape_uri('%', 0));
is ('%3E', escape_uri('>', 0));
is ('%23', escape_uri('#', 0));

push @border, 'x' x $border_size;

is ('%3C%26%3F%25%3E%23', escape_uri('<&?%>#', 0));

push @border, 'x' x $border_size;

is ('%20', escape_uri(' ', 0));
is ('abc', escape_uri('abc', 0));
is ('%25abc%25', escape_uri('%abc%', 0));
is ('%3Cabc%3E', escape_uri('<abc>', 0));
is ('123%3Cabc%3E123', escape_uri('123<abc>123', 0));
is ('%3Cabc%3E123', escape_uri('<abc>123', 0));
is ('123%3Cabc%3E', escape_uri('123<abc>', 0));
is ('123%3C%3Eabc', escape_uri('123<>abc', 0));

push @border, 'x' x $border_size;

$a = '<&?%>#';
$b = escape_uri($a, 0);
is ('<&?%>#', $a);
is ('%3C%26%3F%25%3E%23', $b);

# Test with special string offsets

$a = '<&?%>#';
$a =~ s/^.//;
is ('%26%3F%25%3E%23', escape_uri($a, 0));
escape_uri($a, EU_INPLACE);
is ('%26%3F%25%3E%23', $a);

$b = '<&?%>#                               ';
$b =~ s/^.//;
$b =~ s/\s+$//;
is ('%26%3F%25%3E%23', escape_uri($b, 0));
escape_uri($b, EU_INPLACE);
is ('%26%3F%25%3E%23', $b);

push @border, 'x' x $border_size;

$a = '<&?%>#' . "\x{1234}";
$b = escape_uri($a, 0);
is ('<&?%>#' . "\x{1234}", $a);
is ('%3C%26%3F%25%3E%23%E1%88%B4', $b);
ok (Encode::is_utf8($a));
ok (!Encode::is_utf8($b));

push @border, 'x' x $border_size;

for (1 .. 255) {
  $a = chr($_);
  $b = escape_uri($a);

  my ($c) = ($a =~ /^([A-Za-z0-9\-_.!~*'()])$/);
  my ($d) = ($a =~ /^([\x00-\x1F "#\$%&+\,\/:;<=>?@\[\]\^`{}\\|\x7F\x80-\xFF])$/);

  ok(defined $c || defined $d);
  is($c, $b) if $c;
  is(sprintf('%%%02X', ord($d)), $b) if $d;
}

for (1 .. 1000) {
  my $str = '';
  for (1 .. int(rand(30))) {
    my $rnd = rand();
    if ($rnd < 0.05)    { $str .= '<'; }
    elsif ($rnd < 0.10) { $str .= '&'; }
    elsif ($rnd < 0.15) { $str .= '?'; }
    elsif ($rnd < 0.20) { $str .= '%'; }
    elsif ($rnd < 0.25) { $str .= 'a'; }
    elsif ($rnd < 0.30) { $str .= ' '; }
    elsif ($rnd < 0.98) { $str .= chr(ord('a') + rand(26)); }
    else { $str .= chr(ord('a') + rand(10000)); }
  }

  my $pstr = $str;
  Encode::_utf8_off($pstr);
  $pstr =~ s/([^A-Za-z0-9\-_.!~*`()])/sprintf('%%%02X', ord($1))/ge;

  my $estr = escape_uri($str, 0);
  is ($estr, $pstr);
}

push @border, 'x' x $border_size;

is(join('', @border), 'x' x ($border_size * @border));

