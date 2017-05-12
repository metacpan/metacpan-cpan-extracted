use inc::Module::Install::DSL 1.06;

all_from      lib/GitHub/Extract.pm
requires_from lib/GitHub/Extract.pm
test_requires Test::More   0.42
test_requires HTTP::Online 0.02
test_requires File::Remove 1.51
