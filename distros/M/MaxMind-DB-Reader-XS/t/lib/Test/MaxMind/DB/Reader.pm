package Test::MaxMind::DB::Reader;

use strict;
use warnings;

use MaxMind::DB::Reader::XS;

## no critic (Variables::RequireLocalizedPunctuationVars)
$ENV{MAXMIND_DB_READER_IMPLEMENTATION} = 'XS';

## use critic

require MaxMind::DB::Reader;

1;
