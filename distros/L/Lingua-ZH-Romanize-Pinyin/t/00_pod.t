use strict;
use Test::More;

my $FILES = [qw(
    lib/Lingua/ZH/Romanize/Pinyin.pm
    lib/Lingua/ZH/Romanize/DictZH.pm
    lib/Lingua/ZH/Romanize/Cantonese.pm
)];
local $@;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok( @$FILES );
;1;
