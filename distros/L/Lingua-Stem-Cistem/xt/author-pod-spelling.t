#!perl

use strict;
use warnings;
use utf8;

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    require Test::More;
    Test::More::plan(skip_all => 'these tests are for author testing');
  }
}

use Test::More;

eval "use Test::Spelling";
if ( $@ ) {
  plan skip_all => 'Test::Spelling required for testing POD';
}
else {
  add_stopwords(qw(
     Helmut
     Wollmersdorfer
     CISTEM
     Cistem
     Leonie
     NFD
     Stemmer
     Weissweiler
     Weißweiler
     ge
     goldstandard
     graphemes
     roundtrip
     specifiying
     stemmer
     stemmers
     subsitutions
     tokenized
  ));
  all_pod_files_spelling_ok();
}


