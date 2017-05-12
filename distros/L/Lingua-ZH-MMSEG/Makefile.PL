use strict;
use warnings;
use inc::Module::Install;

name 'Lingua-ZH-MMSEG';
all_from 'lib/Lingua/ZH/MMSEG.pm';
test_requires 'Test::More' => 0.42;
license 'lgpl';
perl_version '5.008006';
readme_markdown_from 'lib/Lingua/ZH/MMSEG.pm';

WriteAll;
