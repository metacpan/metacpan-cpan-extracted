#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase 0.032

use Test::Spelling 0.12;
use Pod::Wordlist;

if ( exists $ENV{AUTOMATED_TESTING} ) {
    print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
    exit 0;
}

add_stopwords(<DATA>);

all_pod_files_spelling_ok( grep { -d } qw( bin lib t xt ) );
__DATA__
<sven.kirmess@kzone.ch>
AppVeyor
Kirmess
SKIRMESS
Sven
TravisCI
appveyor
dist
perlcriticrc
perltidy
perltidyrc
travis
