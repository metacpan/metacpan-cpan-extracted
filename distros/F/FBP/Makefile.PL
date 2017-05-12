use inc::Module::Install::DSL 1.04;

all_from      lib/FBP.pm
requires_from lib/FBP.pm
requires      IO::File         1.14
requires      XML::SAX         0.96
test_requires File::Spec       0.80
test_requires Test::More       0.47
test_requires Test::NoWarnings 0.084
