# $Id: 01_default.t 321 2010-10-30 18:06:08Z roland $
# $Revision: 321 $
# $HeadURL: svn+ssh://ipenburg.xs4all.nl/srv/svnroot/elaine/trunk/HTML-Hyphenate/t/01_default.t $
# $Date: 2010-10-30 20:06:08 +0200 (Sat, 30 Oct 2010) $

use strict;
use warnings;
use utf8;

use Test::More;
$ENV{TEST_AUTHOR} && eval { require Test::NoWarnings };

use HTML::Tree;
use version;

my $tree = version->parse($HTML::Tree::VERSION);
my $broken = version->parse('4.0');

diag(q{Using HTML::Tree version } . $tree);
if ($tree == $broken) {
	BAIL_OUT(q{HTML::Tree version 4.0 is not supported, use 3.23 or earlier or 4.1 or later to avoid issues as reported in RT #61809 <https://rt.cpan.org/Ticket/Display.html?id=61809>});
}

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
		$tree < $broken
			? 'Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious &#60; &#62; &#38;'
			: 'Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious &lt; &gt; &amp;',
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
'<table><tr><th nowrap="nowrap">Supercalifragilisticexpialidocious</th></tr></table>',
        'single word table head with nowrap attribute'
    ],
    [
        '<img alt="Supercalifragilisticexpialidocious"/>',
'<img alt="Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious" />',
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

plan tests => ( 0 + @fragments ) + 1;

use HTML::Hyphenate;
my $h = HTML::Hyphenate->new();
foreach my $frag (@fragments) {
    is( $h->hyphenated( @{$frag}[0] ), @{$frag}[1], @{$frag}[2] );
}

my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{TEST_AUTHOR};
}
$ENV{TEST_AUTHOR} && Test::NoWarnings::had_no_warnings();
