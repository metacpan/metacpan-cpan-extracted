#!/usr/bin/perl -w

use strict;
use Test::More;
eval "use Test::Spelling";
plan skip_all => "Test::Spelling required for testing POD spelling" if $@;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__DATA__
gettext
textdomain
ShareDir
localizable
parseable
Perlers
colour
workover
UTF
subdirectory
Poedit
