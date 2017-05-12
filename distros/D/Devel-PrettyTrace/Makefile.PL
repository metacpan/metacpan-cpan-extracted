use strict;
use inc::Module::Install;

name 'Devel-PrettyTrace';
perl_version '5.006';

abstract_from 'lib/Devel/PrettyTrace.pod';
version_from 'lib/Devel/PrettyTrace.pm';
author 'Sergey Aleynikov <sergey.aleynikov@gmail.com>';
license 'bsd';

test_requires 'Test::More';
requires 'Data::Printer' => '0.19';
requires 'Exporter';
requires 'parent';
requires 'List::MoreUtils';

system 'pod2text lib/Devel/PrettyTrace.pod > README';

WriteAll;
