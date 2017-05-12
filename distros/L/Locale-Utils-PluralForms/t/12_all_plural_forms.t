#!perl -T

use strict;
use warnings;

use Test::More tests => 2 + 1;
use Test::NoWarnings;
use Test::Differences;
BEGIN {
    use_ok('Locale::Utils::PluralForms');
}

my $obj = Locale::Utils::PluralForms->new(
    _all_plural_forms_html => <<'EOT',
        ISO   English name   Plurals header
        <td class="col0"> ar </td>
        <td class="col1"> Arabic <a href="http://wiki.arabeyes.org/Plural_Forms" class="urlextern" title="http://wiki.arabeyes.org/Plural_Forms">notes</a></td>
        <td class="col2 leftalign"> nplurals=6; plural= n==0 ? 0 : n==1 ? 1 : n==2 ? 2 : n%100&gt;=3 &amp;&amp; n%100&lt;=10 ? 3 : n%100&gt;=11 ? 4 : 5;  </td>
        <td class="col0"> de </td>
        <td class="col1"> German </td>
        <td class="col2"> nplurals=2; plural=(n != 1) </td>
        <td class="col0"> ru </td>
        <td class="col1"> Russian </td>
        <td class="col2"> nplurals=3; plural=(n%10==1 &amp;&amp; n%100!=11 ? 0 : n%10&gt;=2 &amp;&amp; n%10&lt;=4 &amp;&amp; (n%100&lt;10 || n%100&gt;=20) ? 1 : 2) </td>
EOT
);

is_deeply(
    $obj->all_plural_forms,
    {
        ar => {
            english_name => 'Arabic',
            plural_forms => 'nplurals=6; plural= n==0 ? 0 : n==1 ? 1 : n==2 ? 2 : n%100>=3 && n%100<=10 ? 3 : n%100>=11 ? 4 : 5;',
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
