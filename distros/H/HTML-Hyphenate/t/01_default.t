use strict;
use warnings;
use utf8;

use Test::More;
use Test::Warn;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

use version;

my @fragments = (
    [
        'Supercalifragilisticexpialidocious',
'Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious',
        'plain word'
    ],
    [
        'Supercalifragilisticexpialidocious Supercalifragilisticexpialidocious',
'Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious',
        'plain words'
    ],
    [
        'Supercalifragilisticexpialidocious &eacute;',
'Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious é',
        'plain word and é'
    ],
    [
        'Supercalifragilisticexpialidocious é',
'Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious é',
        'plain word and é'
    ],
    [
        'Supercalifragilisticexpialidocious &lt; &gt; &amp;',
		'Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious &lt; &gt; &amp;',
        'plain word, HTML encoded less than sign, greater than sign and ampersand'
    ],
    [
        'semi-in­de­pen­dent supercalifragilisticexpialidocious',
'semi-in­de­pen­dent su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious',
        'plain words including hyphen and soft hyphen'
    ],
    [
        'semi-independent supercalifragilisticexpialidocious',
'semi-in­de­pen­dent su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious',
        'plain words including hyphen'
    ],
    [
        '<p>Supercalifragilisticexpialidocious</p>',
'<p>Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious</p>',
        'single word pararaph'
    ],
    [
        '<pre>Supercalifragilisticexpialidocious</pre>',
        '<pre>Supercalifragilisticexpialidocious</pre>',
        'single word pre'
    ],
    [
        '<p><nobr>Supercalifragilisticexpialidocious</nobr></p>',
        '<p><nobr>Supercalifragilisticexpialidocious</nobr></p>',
        'single word pararaph with nobr'
    ],
    [
        '<p style="white-space: nowrap">Supercalifragilisticexpialidocious</p>',
        '<p style="white-space: nowrap">Supercalifragilisticexpialidocious</p>',
        'single word pararaph with nowrap inline style'
    ],
    [
'<p class="supercalifragilisticexpialidocious">Supercalifragilisticexpialidocious</p>',
'<p class="supercalifragilisticexpialidocious">Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious</p>',
        'single word pararaph with class attribute'
    ],
    [
'<table><tr><th abbr="Supercalifragilisticexpialidocious">Supercalifragilisticexpialidocious</th></tr></table>',
'<table><tr><th abbr="Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious">Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious</th></tr></table>',
        'single word table head with abbr attribute'
    ],
    [
'<table><tr><th nowrap>Supercalifragilisticexpialidocious</th></tr></table>',
'<table><tr><th nowrap>Supercalifragilisticexpialidocious</th></tr></table>',
        'single word table head with nowrap attribute'
    ],
    [
'<img alt="Supercalifragilisticexpialidocious"/>',
'<img alt="Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious">',
        'image with alt attribute'
    ],
    [
'<select><option label="Supercalifragilisticexpialidocious">Supercalifragilisticexpialidocious</option></select>',
'<select><option label="Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious">Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious</option></select>',
        'single word option with label attribute'
    ],
    [
'<div><object standby="Supercalifragilisticexpialidocious">Supercalifragilisticexpialidocious</object></div>',
'<div><object standby="Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious">Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious</object></div>',
        'object with standby attribute'
    ],
    [
'<table summary="Supercalifragilisticexpialidocious"><tr><td>Supercalifragilisticexpialidocious</td></tr></table>',
'<table summary="Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious"><tr><td>Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious</td></tr></table>',
        'single word table with summary attribute'
    ],
    [
'<p title="Supercalifragilisticexpialidocious">Supercalifragilisticexpialidocious</p>',
'<p title="Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious">Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious</p>',
        'single word pararaph with title attribute'
    ],
);

plan tests => ( 0 + @fragments ) + 1 + 1;

warnings_like {
	require HTML::Hyphenate;
} [
], 'Warned out unescaped left brace in TeX::Hyphen';

my $h = HTML::Hyphenate->new();
foreach my $frag (@fragments) {
    is( $h->hyphenated( @{$frag}[0] ), @{$frag}[1], @{$frag}[2] );
}

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
$ENV{AUTHOR_TESTING} && Test::NoWarnings::had_no_warnings();
