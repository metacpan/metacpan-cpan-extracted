use strict;
use warnings;
use utf8;

use Test::More;
use File::Slurper qw(read_text);

require_ok('HTML::Inspect');

my $html      = read_text "t/data/collectMeta.html";
my $inspector = HTML::Inspect->new(
    location => 'http://example.com/doc',
    html_ref => \$html
);

# Should capital letters be acepted in name attributes content? Not
# in standart metadata names, otherwise why not.
# See https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meta/name
# 'Author'      => "Ванчо Панчев",
# but here capitalised name="Values" are OK
my $expectedMetaNames = {
    'empty'       => '',
    'Author'      => "Ванчо Панчев",
    'Алабала'     => 'ница',
    'description' => 'The Open Graph protocol enables...',
    'generator'   => "Хей, гиди Ванчо",
    'referrer'    => 'no-referrer'
};

my $collectedMetaNames = $inspector->collectMetaNames();    # cached already
is_deeply($collectedMetaNames => $expectedMetaNames, 'collectMetaNames() returns  HIM_names');
note explain $collectedMetaNames;

my $expectedAllMeta = [
    {'charset' => 'UTF-8'},
    {'content' => 'Open Graph protocol',     'property' => 'og:title'},
    {'content' => 'website',                 'property' => 'OG:TYPE'},
    {'content' => 'https://ogp.me/',         'property' => 'og:url'},
    {'content' => 'https://ogp.me/logo.png', 'property' => 'og:image'},
    {'content' => '115190258555800',         'prefix'   => 'fb: https://ogp.me/ns/fb#', 'property' => 'fb:app_id'},
    {},
    {'content'    => "ница", 'name' => "Алабала"},
    {'content'    => '',     'name' => 'empty'},
    {'name'       => 'undefined'},
    {'content'    => 'no-referrer',                        'name'       => 'referrer'},
    {'content'    => 'The Open Graph protocol enables...', 'name'       => 'description'},
    {'content'    => "Ванчо Панчев",                       'name'       => 'Author'},
    {'content'    => "Хей, гиди Ванчо",                    'name'       => 'generator'},
    {'content'    => '3;url=https://www.mozilla.org',      'http-equiv' => 'refresh'},
    {'content'    => 'text/html',                          'http-equiv' => 'Content-type'},
    {'content'    => 'text/html;charset=utf-8',            'http-equiv' => 'Content-Type'},
    {'content'    => '',                                   'http-equiv' => 'Content-Disposition'},
    {'http-equiv' => 'Keep-Alive'}
];
my $collectedAllMeta = $inspector->collectMeta();
is_deeply($expectedAllMeta => $collectedAllMeta, 'HIM_all, parsed ok');
note explain $collectedAllMeta;

done_testing;

