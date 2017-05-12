use 5.008000;
use inc::Module::Install;

all_from 'lib/Math/Random/Xorshift.pm';

requires 'Exporter::Lite' => '0.02';

test_requires 'Test::More' => '0.88';
test_requires 'Test::UseAllModules' => '0.12';
test_requires 'Test::Exception' => '0.29';

author_requires 'Test::Requires' => '0.05';
author_tests qw/xt/;

cc_inc_paths qw/./;
ppport;

makemaker_args(OBJECT  => '$(O_FILES)');

WriteAll;
