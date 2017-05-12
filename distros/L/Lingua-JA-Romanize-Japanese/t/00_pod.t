use strict;
use Test::More;

my $FILES = [qw(
    lib/Lingua/JA/Romanize/DictJA.pm
    lib/Lingua/JA/Romanize/Kana.pm
    lib/Lingua/JA/Romanize/Japanese.pm
    lib/Lingua/JA/Romanize/MeCab.pm
    lib/Lingua/JA/Romanize/Juman.pm
    lib/Lingua/JA/Romanize/Base.pm
    lib/Lingua/JA/Romanize/Kana/Hepburn.pm
)];
local $@;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok( @$FILES );
;1;
