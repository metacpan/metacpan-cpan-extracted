use 5.010;
use strict;
use warnings;

use utf8;
binmode STDOUT,':utf8';
binmode STDERR,':utf8';

use Test::More;
use Test::More::UTF8;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();

# BEGIN { use_ok('Lingua::RU::Numeral') };

