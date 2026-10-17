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
AnnoCPAN
CPAN
GPL
GPL2
MaxMind
POSTing
RT
attr
geocoder
lat
licence
lng
tz
