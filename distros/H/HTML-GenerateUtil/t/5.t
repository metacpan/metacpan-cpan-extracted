
use Test::More;
eval "use GTop ()";
if ($@) {
  plan skip_all => 'No GTop installed, no memory leak tests';
} else {
  plan tests => 3;
}
use HTML::GenerateUtil qw(:consts escape_html generate_attributes generate_tag);
use strict;

my $NIter = 10000;

my $GTop = GTop->new;

TestLeak(\&escape_html_leak);
TestLeak(\&generate_attributes_leak);
TestLeak(\&generate_tag_leak);

sub escape_html_leak {
  for (1 .. $NIter) {
    my $a = escape_html('abc', 0);
    my $b = escape_html('<a>b"c&', 0);
    my ($t1, $t2) = ('abc', '<a>b"c&');
    my $c = escape_html($t1, EH_INPLACE);
    my $d = escape_html($t2, EH_INPLACE);
    $t1 = escape_html($t1, EH_INPLACE);
    $t2 = escape_html($t2, EH_INPLACE);

    my $e = escape_html('abc', EH_LFTOBR);
    my $f = escape_html('<a>b"c&' . "\n", EH_LFTOBR);
    my $g = escape_html('abc' . "\x{1234}", 0);
    my $h = escape_html('<a>b"c&' . "\x{1234}", 0);

    ($t1, $t2) = ('abc' . "\x{1234}", '<a>b"c&' . "\x{1234}");
    my $i = escape_html($t1, EH_INPLACE);
    my $j = escape_html($t2, EH_INPLACE);
    $t1 = escape_html($t1, EH_INPLACE);
    $t2 = escape_html($t2, EH_INPLACE);

    my $k = escape_html(' ', EH_SPTONBSP);
    my $l = escape_html('    ', EH_SPTONBSP);
    ($t1, $t2) = (' ', '    ');
    my $m = escape_html($t1, EH_INPLACE | EH_SPTONBSP);
    my $n = escape_html($t2, EH_INPLACE | EH_SPTONBSP);
    $t1 = escape_html($t1, EH_INPLACE | EH_SPTONBSP);
    $t2 = escape_html($t2, EH_INPLACE | EH_SPTONBSP);

    my $o = "<&1234;abc&&nbsp;&abc&xabc1;&asd";
    $t1 = escape_html($o, EH_INPLACE | EH_LEAVEKNOWN);
  }
}

sub generate_attributes_leak {
  for (1 .. $NIter) {
    my $a = generate_attributes({ a => 'abc' });
    my $b = generate_attributes({ a => 'abc', d => 'efg' });
    my $c = generate_attributes({ ALongerString => 'abc', AnotherLongerString => 'efg' });
    my $d = generate_attributes({ ALongerString => 'And something with funnies <>&"', AnotherLongerString => 'something with funnies <>&" efg' });

    my $i = generate_attributes({ a => 'abc' . "\x{1234}" });
    my $k = generate_attributes({ ALongerString => 'abc', AnotherLongerString => 'efg' . "\x{1234}" });
  }
}

sub generate_tag_leak {
  for (1 .. $NIter) {
    my $a = generate_tag('tag', undef, undef, 0);
    my $b = generate_tag('tag', { a => 'abc' }, undef, 0);
    my $d = generate_tag('tag', undef, 'some text', 0);
    my $e = generate_tag('tag', { a => 'abc' }, 'some text', 0);
    my $f = generate_tag('tag', { a => 'abc' }, 'some <>&; text', GT_ESCAPEVAL);
    my $g = generate_tag('tag', { a => 'abc' }, 'some <>&; text' . "\x{1234}", GT_ESCAPEVAL);
    my $h = generate_tag(123, { a => 'abc' }, 123, GT_ESCAPEVAL);
    my $i = generate_tag(-123123123, { a => 'abc' }, -123123123, GT_ESCAPEVAL);
  }
}

sub TestLeak {
  my $Sub = shift;

  my $Before = $GTop->proc_mem($$)->size;
  eval {
    $Sub->();
  };
  if ($@) {
    ok(0, "leak test died: $@");
  } else {
    my $After = $GTop->proc_mem($$)->size;
    my $Growth = ($After - $Before)/1024;

    ok( $Growth < 20, "leak test > 20k? Growth=${Growth}k");
  }
}

