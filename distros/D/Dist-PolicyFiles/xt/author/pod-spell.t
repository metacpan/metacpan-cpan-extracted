use strict;
use warnings;

use Test::More;
use Test::Spelling;
use Pod::Wordlist;

$ENV{LANG} = 'en_US';

add_stopwords(<DATA>);
set_pod_file_filter(sub { return $_[0] !~ /~$/; });
all_pod_files_spelling_ok( qw(lib script ) );


__DATA__

md
policyfiles
Rindfrey

