use inc::Module::Install::DSL 1.00;

all_from      lib/File/Find/Rule/PPI.pm
requires_from lib/File/Find/Rule/PPI.pm
test_requires File::Spec 0.80
test_requires Test::More 0.47
