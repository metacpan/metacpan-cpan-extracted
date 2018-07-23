use strict;
use warnings;
use utf8;
use Test::More;
$ENV{AUTHOR_TESTING} && eval { require Test::NoWarnings };
use Test::Warn;

my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";

my @fragments = (
    [
'<p>Supercalifragilisticexpialidocious</p>',
'<p>Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious</p>',
        'no language'
    ],
    [
'<p lang="en">Supercalifragilisticexpialidocious</p>',
'<p lang="en">Su­per­cal­i­fra­gil­istic­ex­pi­al­ido­cious</p>',
        'lang en'
    ],
    [
'<p lang="de-DE">Supercalifragilisticexpialidocious</p>',
'<p lang="de-DE">Su­per­ca­lifra­gi­li­sti­c­ex­pia­li­do­cious</p>',
        'lang de-DE'
    ],
    [
'<p lang="af-za">Supercalifragilisticexpialidocious</p>',
'<p lang="af-za">Su­per­ca­lifra­gi­listi­cexpi­a­li­do­ci­ous</p>',
        'lang af-za'
    ],
    [
'<p lang="ca">Supercalifragilisticexpialidocious</p>',
'<p lang="ca">Su­per­ca­li­fra­gi­lis­ti­c­ex­pi­a­li­do­ci­ous</p>',
        'lang ca'
    ],
    [
'<p lang="cs">Supercalifragilisticexpialidocious</p>',
'<p lang="cs">Su­per­ca­lif­ragi­lis­ti­cex­pi­a­li­do­ci­ous</p>',
        'lang cs'
    ],
    [
'<p lang="cy">Supercalifragilisticexpialidocious</p>',
'<p lang="cy">Superc­a­l­if­ra­gil­istic­exp­ial­idoc­ious</p>',
        'lang cy'
    ],
    [
'<p lang="da">Supercalifragilisticexpialidocious</p>',
'<p lang="da">Su­perca­lif­ragi­li­sti­ce­xpi­a­li­do­cious</p>',
        'lang da'
    ],
    [
'<p lang="da-DK">Supercalifragilisticexpialidocious</p>',
'<p lang="da-DK">Su­perca­lif­ragi­li­sti­ce­xpi­a­li­do­cious</p>',
        'lang da-DK'
    ],
    [
'<p lang="en-gb">Supercalifragilisticexpialidocious</p>',
'<p lang="en-gb">Su­per­cal­i­fra­gil­istic­ex­pi­al­ido­cious</p>',
        'lang en-gb'
    ],
    [
'<p lang="en-us">Supercalifragilisticexpialidocious</p>',
'<p lang="en-us">Su­per­cal­ifrag­ilis­tic­ex­pi­ali­do­cious</p>',
        'lang en-us'
    ],
    [
'<p lang="es">Supercalifragilisticexpialidocious</p>',
'<p lang="es">Su­per­ca­li­fra­gi­lis­ti­cex­pia­li­do­cious</p>',
        'lang es'
    ],
    [
'<p lang="et">Supercalifragilisticexpialidocious</p>',
'<p lang="et">Su­pe­rca­lif­ra­gi­lis­ticex­pia­li­docious</p>',
        'lang et'
    ],
    [
'<p lang="et-ee">Supercalifragilisticexpialidocious</p>',
'<p lang="et-ee">Su­pe­rca­lif­ra­gi­lis­ticex­pia­li­docious</p>',
        'lang et-ee'
    ],
    [
'<p lang="eu">Supercalifragilisticexpialidocious</p>',
'<p lang="eu">Su­per­ca­li­fra­gi­lis­ti­cex­pia­li­do­cious</p>',
        'lang eu'
    ],
    [
'<p lang="fi">Supercalifragilisticexpialidocious</p>',
'<p lang="fi">Su­perca­li­fra­gi­lis­ticex­pia­li­docious</p>',
        'lang fi'
    ],
    [
'<p lang="fr">Supercalifragilisticexpialidocious</p>',
'<p lang="fr">Su­per­ca­li­fra­gi­lis­ti­cex­pia­li­do­cious</p>',
        'lang fr'
    ],
    [
'<p lang="fr-fr">Supercalifragilisticexpialidocious</p>',
'<p lang="fr-fr">Su­per­ca­li­fra­gi­lis­ti­cex­pia­li­do­cious</p>',
        'lang fr-fr'
    ],
    [
'<p lang="ga">Supercalifragilisticexpialidocious</p>',
'<p lang="ga">Sup­er­c­al­i­fragil­is­tic­expial­idocious</p>',
        'lang ga'
    ],
    [
'<p lang="gl">Supercalifragilisticexpialidocious</p>',
'<p lang="gl">Su­per­ca­li­fra­gi­lis­ti­cex­pia­li­do­cious</p>',
        'lang gl'
    ],
    [
'<p lang="hr">Supercalifragilisticexpialidocious</p>',
'<p lang="hr">Su­per­ca­li­fra­gi­lis­ti­cexpi­ali­do­ci­ous</p>',
        'lang hr'
    ],
    [
'<p lang="hsb">Supercalifragilisticexpialidocious</p>',
'<p lang="hsb">Su­per­ca­li­fra­gi­li­sti­cexpia­li­docious</p>',
        'lang hsb'
    ],
    [
'<p lang="ia">Supercalifragilisticexpialidocious</p>',
'<p lang="ia">Su­per­ca­li­fra­gi­lis­ti­cex­pi­a­li­do­ci­o­us</p>',
        'lang ia'
    ],
    [
'<p lang="id">Supercalifragilisticexpialidocious</p>',
'<p lang="id">Su­per­ca­li­fra­gi­lis­ti­ce­xpi­a­li­do­ci­o­us</p>',
        'lang id'
    ],
    [
'<p lang="it">Supercalifragilisticexpialidocious</p>',
'<p lang="it">Su­per­ca­li­fra­gi­li­sti­cex­pia­li­do­cious</p>',
        'lang it'
    ],
    [
'<p lang="it-it">Supercalifragilisticexpialidocious</p>',
'<p lang="it-it">Su­per­ca­li­fra­gi­li­sti­cex­pia­li­do­cious</p>',
        'lang it-it'
    ],
    [
'<p lang="kmr">Supercalifragilisticexpialidocious</p>',
'<p lang="kmr">Su­per­ca­li­f­ra­gi­lis­ti­ce­x­pi­a­li­do­cious</p>',
        'lang kmr'
    ],
    [
'<p lang="la">Supercalifragilisticexpialidocious</p>',
'<p lang="la">Su­per­ca­li­fra­gi­li­sti­ce­x­pia­li­do­cious</p>',
        'lang la'
    ],
    [
'<p lang="lt">Supercalifragilisticexpialidocious</p>',
'<p lang="lt">Su­per­ca­lif­ra­gi­lis­ti­ce­xpia­li­do­cious</p>',
        'lang lt'
    ],
    [
'<p lang="lt-lt">Supercalifragilisticexpialidocious</p>',
'<p lang="lt-lt">Su­per­ca­lif­ra­gi­lis­ti­ce­xpia­li­do­cious</p>',
        'lang lt-lt'
    ],
    [
'<p lang="lv">Supercalifragilisticexpialidocious</p>',
'<p lang="lv">Su­perca­lif­ra­gi­lis­ti­cexpia­li­do­cious</p>',
        'lang lv'
    ],
    [
'<p lang="nb">Supercalifragilisticexpialidocious</p>',
'<p lang="nb">Su­per­ca­li­fra­gi­li­s­ticex­pia­li­docious</p>',
        'lang nb'
    ],
    [
'<p lang="nl">Supercalifragilisticexpialidocious</p>',
'<p lang="nl">Su­per­ca­lifra­gi­lis­ti­c­ex­pi­a­li­do­cious</p>',
        'lang nl'
    ],
    [
'<p lang="nl-nl">Supercalifragilisticexpialidocious</p>',
'<p lang="nl-nl">Su­per­ca­lifra­gi­lis­ti­c­ex­pi­a­li­do­cious</p>',
        'lang nl-nl'
    ],
    [
'<p lang="nn">Supercalifragilisticexpialidocious</p>',
'<p lang="nn">Su­per­ca­li­fra­gi­li­s­ticex­pia­li­docious</p>',
        'lang nn'
    ],
    [
'<p lang="no">Supercalifragilisticexpialidocious</p>',
'<p lang="no">Su­per­ca­li­fra­gi­li­s­ticex­pia­li­docious</p>',
        'lang no'
    ],
    [
'<p lang="pl">Supercalifragilisticexpialidocious</p>',
'<p lang="pl">Su­per­ca­li­fra­gi­li­sti­ce­xpia­li­do­cio­us</p>',
        'lang pl'
    ],
    [
'<p lang="pl-pl">Supercalifragilisticexpialidocious</p>',
'<p lang="pl-pl">Su­per­ca­li­fra­gi­li­sti­ce­xpia­li­do­cio­us</p>',
        'lang pl-pl'
    ],
    [
'<p lang="pt">Supercalifragilisticexpialidocious</p>',
'<p lang="pt">Su­per­ca­li­fra­gi­lis­ti­cex­pi­a­li­do­ci­ous</p>',
        'lang pt'
    ],
    [
'<p lang="pt-br">Supercalifragilisticexpialidocious</p>',
'<p lang="pt-br">Su­per­ca­li­fra­gi­lis­ti­cex­pia­li­do­cious</p>',
        'lang pt-br'
    ],
    [
'<p lang="ro">Supercalifragilisticexpialidocious</p>',
'<p lang="ro">Su­per­ca­li­fra­gi­lis­ti­cex­pi­a­li­do­cio­us</p>',
        'lang ro'
    ],
    [
'<p lang="sh">Supercalifragilisticexpialidocious</p>',
'<p lang="sh">Su­per­ca­li­fra­gi­li­sti­ce­xpi­a­li­do­ci­o­us</p>',
        'lang sh'
    ],
    [
'<p lang="sh-latn">Supercalifragilisticexpialidocious</p>',
'<p lang="sh-latn">Su­per­ca­li­fra­gi­li­sti­ce­xpi­a­li­do­ci­o­us</p>',
        'lang sh-latn'
    ],
    [
'<p lang="sk">Supercalifragilisticexpialidocious</p>',
'<p lang="sk">Su­per­ca­lif­ra­gi­lis­ti­ce­xpia­li­do­ci­ous</p>',
        'lang sk'
    ],
    [
'<p lang="sl">Supercalifragilisticexpialidocious</p>',
'<p lang="sl">Su­per­ca­li­fra­gi­li­sti­cexpi­a­li­do­ci­o­us</p>',
        'lang sl'
    ],
    [
'<p lang="sl-si">Supercalifragilisticexpialidocious</p>',
'<p lang="sl-si">Su­per­ca­li­fra­gi­li­sti­cexpi­a­li­do­ci­o­us</p>',
        'lang sl-si'
    ],
    [
'<p lang="sv">Supercalifragilisticexpialidocious</p>',
'<p lang="sv">Su­per­ca­li­fra­gi­listi­cex­pi­a­li­do­cious</p>',
        'lang sv'
    ],
    [
'<p lang="tr">Supercalifragilisticexpialidocious</p>',
'<p lang="tr">Su­per­ca­lif­ra­gi­lis­ti­ce­x­pi­ali­do­ci­o­us</p>',
        'lang tr'
    ],
    [
'<p lang="zh-latn">Supercalifragilisticexpialidocious</p>',
'<p lang="zh-latn">Su­per­ca­li­f­ra­gi­li­sti­ce­xpia­li­do­cious</p>',
        'lang zh-latn'
    ],
    [
'<p lang="zu-za">Supercalifragilisticexpialidocious</p>',
'<p lang="zu-za">Su­pe­rca­li­fra­gi­li­sti­ce­xpia­li­do­cious</p>',
        'lang zu-za'
    ],
);

my @utf8_fragments = (
    [
'<p lang="is">Upplýsingatæknifyrirtæki</p>',
'<p lang="is">Upp­lýs­inga­tæknifyr­ir­tæki</p>',
        'lang is'
    ],
    [
'<p lang="grc">ὀφειλήματα οφειλήματα</p>',
'<p lang="grc">ὀφει­λή­μα­τα οφει­λή­μα­τα</p>',
        'lang grc'
    ],
    [
'<p lang="bg">Supercalifragilisticexpialidocious</p>',
'<p lang="bg">Supercalifragilisticexpialidocious</p>',
        'lang bg'
    ],
    [
'<p lang="sr-cyrl">Реализовали</p>',
'<p lang="sr-cyrl">Ре­а­ли­зо­ва­ли</p>',
        'lang sr-cyrl'
    ],
    [
'<p lang="sr">Реализовали</p>',
'<p lang="sr">Ре­а­ли­зо­ва­ли</p>',
        'lang sr'
    ],
    [
'<p lang="sh-cyrl">уламжлалаа</p>',
'<p lang="sh-cyrl">улам­жла­лаа</p>',
        'lang sh-cyrl'
    ],
    [
'<p lang="sa">देवनागरीदेवनागरी</p>',
'<p lang="sa">दे­व­ना­ग­री­दे­व­ना­ग­री</p>',
        'lang sa'
    ],
    [
'<p lang="ru">уламжлалаа</p>',
'<p lang="ru">уламж­ла­лаа</p>',
        'lang ru'
    ],
    [
'<p lang="ru-ru">уламжлалаа</p>',
'<p lang="ru-ru">улам­ж­ла­лаа</p>',
        'lang ru-ru'
    ],
    [
'<p lang="mn-cyrl">уламжлалаа</p>',
'<p lang="mn-cyrl">уламж­ла­лаа</p>',
        'lang mn-cyrl'
    ],
    [
'<p lang="mn-cyrl-x-2a">уламжлалаа</p>',
'<p lang="mn-cyrl-x-2a">уламж­ла­лаа</p>',
        'lang mn-cyrl-x-2a'
    ],
    [
'<p lang="uk">уламжлалаа</p>',
'<p lang="uk">улам­жла­лаа</p>',
        'lang uk'
    ],
    [
'<p lang="el-monoton">ὀφειλήματα οφειλήματα</p>',
'<p lang="el-monoton">ὀφει­λή­μα­τα οφει­λή­μα­τα</p>',
        'lang el-monoton'
    ],
    [
'<p lang="el-polyton">ὀφειλήματα οφειλήματα</p>',
'<p lang="el-polyton">ὀφει­λή­μα­τα οφει­λή­μα­τα</p>',
        'lang el-polyton'
    ],
);
# 50 fragments + 14 utf8 fragments
plan tests => ( 0 + @fragments + (@utf8_fragments << 1)) + 1;

use HTML::Hyphenate;
my $h = HTML::Hyphenate->new();
foreach my $frag (@fragments) {
	is( $h->hyphenated( @{$frag}[0] ), @{$frag}[1], @{$frag}[2] );
}

TODO: {
	local $TODO = q{utf8 patterns not yet supported by TeX::Hyphen};
	foreach my $frag (@utf8_fragments) {
		warnings_like {
			is( $h->hyphenated( @{$frag}[0] ), @{$frag}[1], @{$frag}[2] );
		} [
			qr/Use of uninitialized value within %CARON_MAP in substitution iterator.*/,
		], 'Warned about uninitialized value within %CARON_MAP';
	}
};

my $msg = 'Author test. Set $ENV{AUTHOR_TESTING} to a true value to run.';
SKIP: {
    skip $msg, 1 unless $ENV{AUTHOR_TESTING};
}
if ($ENV{AUTHOR_TESTING}) {
	Test::NoWarnings::had_no_warnings();
}
