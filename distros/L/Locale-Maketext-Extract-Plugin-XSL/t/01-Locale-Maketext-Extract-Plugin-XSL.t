#!/usr/bin/perl

use Test::More tests => 12;

BEGIN {
    use_ok( 'Locale::Maketext::Extract::Plugin::XSL' );
    use_ok( 'Locale::Maketext::Extract' );
}

use FindBin;

my @keys_to_match = (
 "Tell me...",
 "Where the '%1'",
 "do you find XSL hackers?",
 "...would it be <a href='#' onClick='%1'>here</a>?",
 'At a place with a lot of (nested (parentheses))',
 "...like <a href='%1'>lispland</a>?",
 "Mail me if you know one please!",
 "Thank you!",
);

my $ext = Locale::Maketext::Extract->new( plugins => {'Locale::Maketext::Extract::Plugin::XSL' => '*'} );
ok($ext->extract_file($FindBin::Bin.'/i18ntest.xsl'),'extracting from i18ntest.xsl');
$ext->compile();

is( scalar keys %{$ext->lexicon}, scalar @keys_to_match, 'lexicon has correct number of entries');

foreach my $key ( @keys_to_match ) {
    ok (exists $ext->lexicon->{$key}, "extracted key '$key' matches" );
}

