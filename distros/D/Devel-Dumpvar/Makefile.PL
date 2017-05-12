use inc::Module::Install::DSL 0.91;

all_from      lib/Devel/Dumpvar.pm
requires_from lib/Devel/Dumpvar.pm
test_requires File::Spec 0.80
test_requires Test::More 0.42
