use strict;
use warnings;
use inc::Module::Install;
use 5.008003;

name 'LucyX-Suggester';
all_from 'lib/LucyX/Suggester.pm';

requires 'Test::More'    => 0;
requires 'Lucy'          => '0.003002';
requires 'Search::Tools' => '0.83';
requires 'Text::Aspell'  => 0;
requires 'Data::Dump'    => 0;

perl_version '5.8.3';
license 'http://dev.perl.org/licenses/';
homepage 'https://github.com/karpet/lucyx-suggester';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=LucyX-Suggester';
repository 'https://github.com/karpet/lucyx-suggester';

install_script 'bin/lucyx-suggest';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'LucyX-Suggester-* t/index.swish' },
);
