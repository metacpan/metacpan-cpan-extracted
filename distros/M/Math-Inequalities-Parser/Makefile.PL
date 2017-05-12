use strict;
use warnings;
use inc::Module::Install 0.91;
use Module::Install::AuthorRequires;
use Module::Install::AuthorTests;

name 'Math-Inequalities-Parser';
all_from 'lib/Math/Inequalities/Parser.pm';

build_requires 'Test::More' => '0.88';

author_requires 'Test::Pod::Coverage' => '1.04';
author_requires 'Test::Pod' => '1.14';

author_tests 't/author';

resources repository => 'git://github.com/bobtfish/Math-Inequalities-Parser.git';

if ($Module::Install::AUTHOR) {
    system("pod2text lib/Math/Inequalities/Parser.pm > README")
        and die $!;
}

WriteAll();
