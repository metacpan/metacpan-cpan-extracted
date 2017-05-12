use strict;
use warnings;
use inc::Module::Install;

name     'Geography-JapanesePrefectures-Walker';
all_from 'lib/Geography/JapanesePrefectures/Walker.pm';

requires 'Scalar::Util';
requires 'Test::More';
requires 'Test::Class';
requires 'Geography::JapanesePrefectures';
requires 'Encode';
requires 'List::MoreUtils';
requires 'Data::Visitor::Callback';

use_test_base;
auto_install;
WriteAll;

