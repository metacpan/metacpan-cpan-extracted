use strict;
use warnings;
use utf8;
use Test::More;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my @fragments = (
    [
'<p lang="no">ukeskortene attende betre</p>',
'<p lang="no">ukes­kort­ene atten­de betre</p>',
'<p lang="no">ukes­kort­ene attende betre</p>',
        'Norwegian'
    ],
    [
'<p lang="no">ukeskortene attende betre <span>            </span></p>',
'<p lang="no">ukes­kort­ene atten­de betre <span>            </span></p>',
'<p lang="no">ukes­kort­ene attende betre <span>            </span></p>',
        'Norwegian redundant spaces'
    ],
    [
'<p lang="nn">ukeskortene attende betre</p>',
'<p lang="nn">ukes­kort­ene att­en­de bet­re</p>',
'<p lang="nn">ukes­kort­ene attende betre</p>',
        'Norwegian Nynorsk'
    ],
    [
'<p lang="nb">ukeskortene attende betre</p>',
'<p lang="nb">ukes­kort­ene at­ten­de be­tre</p>',
'<p lang="nb">ukes­kort­ene attende betre</p>',
        'Norwegian Bokmål'
    ],
    [
'<p lang="no">ukeskortene attende betre</p><p lang="nn">ukeskortene attende betre</p>',
'<p lang="no">ukes­kort­ene atten­de betre</p><p lang="nn">ukes­kort­ene att­en­de bet­re</p>',
'<p lang="no">ukes­kort­ene attende betre</p><p lang="nn">ukes­kort­ene attende betre</p>',
        'Norwegian and Nynorsk adjacent'
    ],
    [
'<p lang="no">ukeskortene <span lang="nn">attende</span> <span lang="nb">betre</span> attende</p>',
'<p lang="no">ukes­kort­ene <span lang="nn">att­en­de</span> <span lang="nb">be­tre</span> atten­de</p>',
'<p lang="no">ukes­kort­ene <span lang="nn">attende</span> <span lang="nb">betre</span> attende</p>',
        'Nynorsk and Bokmål nested and surrounded in Norwegian'
    ],
    [
'<p xml:lang="no">ukeskortene <span xml:lang="nn">attende</span> <span xml:lang="nb">betre</span> attende</p>',
'<p xml:lang="no">ukes­kort­ene <span xml:lang="nn">att­en­de</span> <span xml:lang="nb">be­tre</span> atten­de</p>',
'<p xml:lang="no">ukes­kort­ene <span xml:lang="nn">attende</span> <span xml:lang="nb">betre</span> attende</p>',
        'Nynorsk and Bokmål nested and surrounded in Norwegian xml:lang'
    ],
    [
'<p lang="no">ukeskortene <span>attende</span> <span lang="nb" title="betre">betre</span> attende</p>',
'<p lang="no">ukes­kort­ene <span>atten­de</span> <span lang="nb" title="be­tre">be­tre</span> atten­de</p>',
'<p lang="no">ukes­kort­ene <span>attende</span> <span lang="nb" title="betre">betre</span> attende</p>',
        'Bokmål nested and surrounded in Norwegian lang'
    ],
    [
'<p xml:lang="no">ukeskortene <span>attende</span> <span xml:lang="nb">betre</span> attende</p>',
'<p xml:lang="no">ukes­kort­ene <span>atten­de</span> <span xml:lang="nb">be­tre</span> atten­de</p>',
'<p xml:lang="no">ukes­kort­ene <span>attende</span> <span xml:lang="nb">betre</span> attende</p>',
        'Bokmål nested and surrounded in Norwegian xml:lang'
    ],
    [
'<p>ukeskortene <span>attende</span> <span title="betre">betre</span> attende</p>',
'<p>ukesko­rtene <span>at­tende</span> <span title="be­tre">be­tre</span> at­tende</p>',
'<p>ukesko­rtene <span>attende</span> <span title="betre">betre</span> attende</p>',
        'Default nested and surrounded'
    ],
);

plan tests => (2 * ( 0 + @fragments ) ) + 1;

use HTML::Hyphenate;
my $h = HTML::Hyphenate->new();
$h->min_length(2);
foreach my $frag (@fragments) {
    $h->min_length(2);
	is( $h->hyphenated( @{$frag}[0] ), @{$frag}[1], @{$frag}[3] );
    $h->min_length(10);
	is( $h->hyphenated( @{$frag}[0] ), @{$frag}[2], @{$frag}[3] );
}

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
if ($ENV{AUTHOR_TESTING}) {
	Test::NoWarnings::had_no_warnings();
}
