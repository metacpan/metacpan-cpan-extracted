
#########################

use Test::More tests => 4017;
BEGIN { use_ok('HTML::GenerateUtil') };
use HTML::GenerateUtil qw(:consts escape_html generate_attributes generate_tag);
use strict;

my $border_size = 100;
my @border = 'x' x $border_size;

is ('<foo>', generate_tag('foo', undef, undef, 0));
is ('<foo>', generate_tag('foo', undef, undef, GT_ESCAPEVAL));
is ('<foo />', generate_tag('foo', undef, undef, GT_CLOSETAG));
is ('<foo>', generate_tag('foo', { }, undef, 0));
is ('<foo />', generate_tag('foo', { }, undef, GT_CLOSETAG));
is ('<foo a="abc">', generate_tag('foo', { a => 'abc' }, undef, 0));
is ('<foo abc="abc">', generate_tag('foo', { AbC => 'abc' }, undef, 0));
is ('<foo abc="abc" />', generate_tag('foo', { AbC => 'abc' }, undef, GT_CLOSETAG));
is ('<foo a="abc">bar</foo>', generate_tag('foo', { a => 'abc' }, 'bar', 0));
is ('<foo a="abc">bar</foo>' . "\n", generate_tag('foo', { a => 'abc' }, 'bar', GT_ADDNEWLINE));
is ('<foo a="abc">ba<>"&r</foo>', generate_tag('foo', { a => 'abc' }, 'ba<>"&r', 0));
is ('<foo a="abc">ba&lt;&gt;&quot;&amp;r</foo>', generate_tag('foo', { a => 'abc' }, 'ba<>"&r', GT_ESCAPEVAL));
is ('<foo a="abc" />ba&lt;&gt;&quot;&amp;r</foo>', generate_tag('foo', { a => 'abc' }, 'ba<>"&r', GT_ESCAPEVAL | GT_CLOSETAG));
is ('<foo a="abc">ba&lt;&gt;&quot;&amp;r</foo>' . "\n", generate_tag('foo', { a => 'abc' }, 'ba<>"&r', GT_ESCAPEVAL | GT_ADDNEWLINE));

our $Val = -2209132800;
is ("<td a=\"abc\">-2209132800</td>\n", generate_tag('td', { a => 'abc' }, $Val, 2));

push @border, 'x' x $border_size;

for (1 .. 1000) {

  my $tag = RandStr(10);
  my %attr;
  for (1 .. int(rand(10))) {
    $attr{RandStr(10)} = rand() < 0.2 ? undef : RandStr(20, 1);
  }
  my $tval = RandStr(100, 1);

  my $a = generate_tag($tag, \%attr, $tval, GT_ESCAPEVAL);

  my ($rtag, $rattr, $rval, $rendtag) =
    ($a =~ /^<(\S+) ?([^>]*)>([^<]*)<\/(\S+)>$/);

  is($rtag, $tag);
  is($rendtag, $tag);

  $tval =~ s/&/&amp;/g;
  $tval =~ s/</&lt;/g;
  $tval =~ s/>/&gt;/g;
  $tval =~ s/\"/&quot;/g;

  is($tval, $rval);

  my $sortattr = join(' ', sort grep { defined $_ } ($rattr =~ /([^= ]+)(?: |\z)|([^= ]+="[^"]+")(?: |\z)/g));

  my @attr;
  for (keys %attr) {
    my $val = $attr{$_};
    if (!defined $val) {
      push @attr, $_;
      next;
    }

    $val =~ s/&/&amp;/g;
    $val =~ s/</&lt;/g;
    $val =~ s/>/&gt;/g;
    $val =~ s/\"/&quot;/g;

    push @attr, $_ . '="' . $val . '"';
  }

  is($sortattr, join(' ', sort @attr));
}

sub RandStr {
  my ($MaxLen, $IncFunny) = @_;

  my $str = '';
  my $Len = int(rand($MaxLen-3)) + 3;
  while (length($str) < $Len) {
    my $rnd = rand();
    if ($rnd < 0.05 && $IncFunny)    { $str .= '<'; }
    elsif ($rnd < 0.10 && $IncFunny) { $str .= '>'; }
    elsif ($rnd < 0.15 && $IncFunny) { $str .= '&'; }
    elsif ($rnd < 0.20 && $IncFunny) { $str .= '"'; }
    elsif ($rnd < 0.98 || !$IncFunny) { $str .= chr(ord('a') + rand(26)); }
    else { $str .= chr(ord('a') + rand(10000)); }
  }

  return $str;
}

push @border, 'x' x $border_size;

is(join('', @border), 'x' x ($border_size * @border));

