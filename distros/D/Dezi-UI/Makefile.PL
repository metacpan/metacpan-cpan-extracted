use strict;
use warnings;
use inc::Module::Install;
use 5.008003;

name 'Dezi-UI';
all_from 'lib/Dezi/UI.pm';
requires 'Test::More' => 0;
requires 'Dezi'       => 0.001004;
requires 'Plack'      => 0;
requires 'Data::Dump' => 0;

perl_version '5.8.3';
license 'http://dev.perl.org/licenses/';
homepage 'https://github.com/karpet/Dezi-UI';
bugtracker 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-UI';
repository 'git://github.com/karpet/Dezi-UI.git';

WriteMakefile(
    PL_FILES => {},
    dist     => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Dezi-* dezi.index' },
);
