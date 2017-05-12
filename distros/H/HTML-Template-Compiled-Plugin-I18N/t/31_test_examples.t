#!perl

use strict;
use warnings;

use Test::More;
use Test::Differences;
use Cwd qw(getcwd chdir);

$ENV{TEST_EXAMPLE} or plan(
    skip_all => 'Set $ENV{TEST_EXAMPLE} to run this test.'
);

plan(tests => 3);

my @data = (
    {
        test   => 'using default translator',
        path   => 'example',
        script => 'using_default_translator.pl',
        result => <<'EOT',
text=foo &amp; bar
EOT
    },
    {
        test   => 'Locale-Maketext',
        path   => 'example/Locale-Maketext',
        script => 'example.pl',
        result => <<'EOT',
* placeholder
  Steffen is programming <Perl>.
* placeholder and escape
  Steffen is programming &lt;Perl&gt;.
* unescaped placeholder
  This is the <a href=http://www.perl.org/>&lt;link&gt;</a>.

* placeholder
  Steffen programmiert <Perl>.
* placeholder and escape
  Steffen programmiert &lt;Perl&gt;.
* unescaped placeholder
  Das ist der <a href=http://www.perl.org/>&lt;Link&gt;</a>.

EOT
    },
    {
        test   => 'Locale-TextDomain',
        path   => 'example/Locale-TextDomain',
        script => 'example.pl',
        result => <<'EOT',
* placeholder
  Steffen is programming <Perl>.
* placeholder and escape
  Steffen is programming &lt;Perl&gt;.
* unescaped placeholder
  This is the <a href=http://www.perl.org/>&lt;link&gt;</a>.
* no context
  No context.
* context
  Has context.
* plural
  shelf
  shelves
* context and plural
  good shelf<>
  good shelve<s>

* placeholder
  Steffen programmiert <Perl>.
* placeholder and escape
  Steffen programmiert &lt;Perl&gt;.
* unescaped placeholder
  Das ist der <a href=http://www.perl.org/>&lt;Link&gt;</a>.
* no context
  Kein Kontext.
* context
  Hat Kontext.
* plural
  Regal
  Regale
* context and plural
  gutes Regal<>
  gute Regal<e>

EOT
    },
);

for my $data (@data) {
    my $dir = getcwd();
    chdir("$dir/$data->{path}");
    my $result = qx{perl $data->{script} 2>&3};
    chdir($dir);
    eq_or_diff(
        $result,
        $data->{result},
        $data->{test},
    );
}