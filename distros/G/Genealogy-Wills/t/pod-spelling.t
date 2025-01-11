#!perl

use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::Spelling';

Test::Spelling->import();

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__END__
CPANTS
GPL
Gedcom
MetaCPAN
RT
sql
