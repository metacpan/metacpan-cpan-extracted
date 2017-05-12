use inc::Module::Install::DSL 0.91;

all_from       lib/File/LocalizeNewlines.pm
requires_from  lib/File/LocalizeNewlines.pm
requires       Getopt::Long 0
test_requires  Test::More   0.42
test_requires  Test::Script 1.02
test_requires  File::Remove 1.42
install_script localizenewlines
