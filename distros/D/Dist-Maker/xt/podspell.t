#!perl -w

use strict;
use Test::More;

eval q{ use Test::Spelling };

plan skip_all => q{Test::Spelling is not installed.}
	if $@;

add_stopwords(map { split /(\w+)/ } <DATA>);
$ENV{LC_ALL} = 'C';
all_pod_files_spelling_ok('lib');

__DATA__
Goro Fuji (gfx)
gfuji(at)cpan.org
Dist::Maker

CPAN
TODO
subcommand
RT
XS
CLI
API

