#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase 0.029

use Test::Spelling 0.12;
use Pod::Wordlist;

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
