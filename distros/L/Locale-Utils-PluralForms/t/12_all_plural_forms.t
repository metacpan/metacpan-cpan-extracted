#!perl -T

use strict;
use warnings;

use Test::More tests => 3;
use Test::NoWarnings;
use Test::Differences;
BEGIN {
    use_ok('Locale::Utils::PluralForms');
}

my $obj = Locale::Utils::PluralForms->new(
    _all_plural_forms_html => <<'EOT',
<tr class="row-odd"><td>ar</td>
<td>Arabic <a class="footnote-reference" href="#f1" id="id2">[1]</a></td>
<td>nplurals=6; plural=(n==0 ? 0 : n==1 ? 1 : n==2 ? 2 : n%100&gt;=3 &amp;&amp; n%100&lt;=10 ? 3 : n%100&gt;=11 ? 4 : 5);</td>
</tr>
<tr class="row-odd"><td>de</td>
<td>German</td>
<td>nplurals=2; plural=(n != 1);</td>
</tr>
<tr class="row-even"><td>ru</td>
<td>Russian</td>
<td>nplurals=3; plural=(n%10==1 &amp;&amp; n%100!=11 ? 0 : n%10&gt;=2 &amp;&amp; n%10&lt;=4 &amp;&amp; (n%100&lt;10 || n%100&gt;=20) ? 1 : 2);</td>
</tr>
EOT
);

is_deeply(
    $obj->all_plural_forms,
    {
        ar => {
            english_name => 'Arabic',
            plural_forms => 'nplurals=6; plural=(n==0 ? 0 : n==1 ? 1 : n==2 ? 2 : n%100>=3 && n%100<=10 ? 3 : n%100>=11 ? 4 : 5)',
        },
        de => {
            english_name => 'German',
            plural_forms => 'nplurals=2; plural=(n != 1)',
        },
        ru => {
            english_name => 'Russian',
            plural_forms => 'nplurals=3; plural=(n%10==1 && n%100!=11 ? 0 : n%10>=2 && n%10<=4 && (n%100<10 || n%100>=20) ? 1 : 2)',
        },
    },
    'all_plural_forms',
);
