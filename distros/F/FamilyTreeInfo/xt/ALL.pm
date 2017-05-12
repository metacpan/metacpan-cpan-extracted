use Test::More;
eval "use Test::Synopsis";
plan skip_all => "Test::Synopsis required" if $@;
all_synopsis_ok();
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
all_pod_files_ok();
use strict;
use Test::More;
eval q{ use Test::Perl::Critic };
plan skip_all => "Test::Perl::Critic is not installed." if $@;
all_critic_ok("lib");
use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(<DATA>);
set_spell_cmd(
    "sp_ch () {(cat $1|aspell --lang=ru-yo list|aspell --lang=en list); };sp_ch"
);
all_pod_files_spelling_ok('lib');
use strict;
use warnings;
use Test::More;

eval "use Test::Portability::Files; 1" or do {
    plan skip_all => 'Test::Portability::Files is not installed.';
};

run_tests();
use strict;
use warnings;
use Test::More;

eval "use Test::Pod::Coverage 1.00; 1" or do {
    plan skip_all => 'Test::Pod::Coverage 1.00 is not installed.';
};

all_pod_coverage_ok();
use strict;
use warnings;
use Test::More;

eval { require Test::Kwalitee; Test::Kwalitee->import(); 1 } or do {
    plan skip_all => 'Test::Kwalitee not installed; skipping';
};
use strict;
use warnings;
use Test::More;

eval "use Test::Vars; 1" or do {
    plan skip_all => 'Test::Vars is not installed.';
};

all_vars_ok();
use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(<DATA>);
set_spell_cmd(
    "sp_ch () {(cat $1|aspell --lang=ru-yo list|aspell --lang=en list); };sp_ch"
);
all_pod_files_spelling_ok('lib/POD2/RU/perlunitut.pod');

