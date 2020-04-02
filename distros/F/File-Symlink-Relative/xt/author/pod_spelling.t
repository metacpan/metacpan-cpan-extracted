package main;

use strict;
use warnings;

use Test2::Tools::LoadModule;

load_module_or_skip_all 'Test::Spelling';

add_stopwords( <DATA> );

all_pod_files_spelling_ok();

1;
__DATA__
merchantability
Wyant
