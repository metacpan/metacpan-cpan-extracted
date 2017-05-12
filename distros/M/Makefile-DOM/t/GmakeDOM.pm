package t::GmakeDOM;

use lib 'inc';
use Test::Base -Base;

use MDOM::Document::Gmake;
use MDOM::Dumper;

our @EXPORT = qw( run_tests );

sub run_test ($) {
    my $block = shift;
    my $name = $block->name;
    my $src = $block->src;
    my $dom = MDOM::Document::Gmake->new( \$src );
    ok $dom, "$name - DOM defined";
    my $dumper = MDOM::Dumper->new($dom);
    my $got = $dumper->string;
    my $expected = $block->dom;

    # canonicalize the whitespace:
    $got =~ s/(?x) ^ ( \s* [\w:]+ ) [ \t]+/$1\t\t/gm;
    $expected =~  s/(?x) ^ ( \s* [\w:]+ ) [ \t]+/$1\t\t/gm;
    # process abbreviations:
    $expected =~ s/\bM::D::G\b/MDOM::Document::Gmake/gs;
    $expected =~ s/\bM::D\b/MDOM::Directive/gs;
    $expected =~ s/\bM::R::S\b/MDOM::Rule::Simple/gs;
    $expected =~ s/\bM::T::C\b/MDOM::Token::Comment/gs;
    $expected =~ s/\bM::T::W\b/MDOM::Token::Whitespace/gs;
    $expected =~ s/\bM::T::S\b/MDOM::Token::Separator/gs;
    $expected =~ s/\bM::T::B\b/MDOM::Token::Bare/gs;
    $expected =~ s/\bM::T::M\b/MDOM::Token::Modifier/gs;
    $expected =~ s/\bM::T::I\b/MDOM::Token::Interpolation/gs;
    $expected =~ s/\bM::C\b/MDOM::Command/gs;

    is $got, $expected, "$name - DOM structure ok";
    #warn $dumper->string if $name =~ /TEST 0/;
}

sub run_tests () {
    for my $block (blocks()) {
        run_test($block);
    }
}

1;

