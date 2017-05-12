use inc::Module::Install::DSL 0.91;

all_from       lib/JSAN/Shell.pm
requires       Term::ReadLine       1.01
requires       Term::ReadLine::Perl 1.0302
requires       Getopt::Long         2.34
requires       File::HomeDir        0.80
requires       File::ShareDir       1.00
requires       File::UserConfig     0.06
requires       LWP::Online          1.05
requires       Mirror::JSON         0.01
requires       JSAN::Client         0.29
test_requires  File::Spec           0.80
test_requires  Test::More           0.47
test_requires  Test::Script         1.05
install_script jsan
install_share
