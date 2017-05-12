use strict;
use warnings;

use inc::Module::Install;

name 'Devel-Cover-Report-Phabricator';

all_from 'lib/Devel/Cover/Report/Phabricator.pm';

requires 'Getopt::Long' => 2.38;
requires 'Try::Tiny' => 0.12;
requires 'JSON' => 2.53;
requires 'List::MoreUtils' => 0.33;
requires 'Devel::Cover' => 0.99;
requires 'File::Slurp' => 9999.19;

test_requires 'Test::More' => 0.98;
test_requires 'Cwd' => 0;
test_requires 'File::Temp' => 0;
test_requires 'File::chdir' => 0;

tests 't/*.t';

repository 'http://github.com/mcartmell/Devel-Cover-Report-Phabricator';
bugtracker 'http://github.com/mcartmell/Devel-Cover-Report-Phabricator/issues';

WriteAll;
