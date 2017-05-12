#!perl -w

use strict;
use Test::More;

eval q{ use Test::Spelling };

plan skip_all => q{Test::Spelling is not installed.}
	if $@;

add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');

__DATA__
Goro Fuji (gfx)
gfx
gfuji(at)cpan.org
File::Spec::Memoized
canonpath
catpath
devnull
splitdir
splitpath
tmpdir