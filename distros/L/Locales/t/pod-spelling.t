#!perl

use Test::More;
plan skip_all => 'POD tests are only run in RELEASE_TESTING mode.' unless $ENV{'RELEASE_TESTING'};

eval 'use Test::Spelling 0.19';
plan skip_all => 'Test::Spelling v0.19 required for testing POD' if $@;

use Locales;
my $loc = Locales->new;

add_stopwords( $loc->get_language_codes(), map { split /[\s\:\-]/ } readline(*DATA) );
$ENV{LANG} = 'C';
all_pod_files_spelling_ok();

__DATA__
MERCHANTABILITY
Muey

CLDR
LICENCE
IETF
fallback
v0
v1
v2
javascript
utf
UTF
MX
TODO
latin
latin1
misformatted
arg
