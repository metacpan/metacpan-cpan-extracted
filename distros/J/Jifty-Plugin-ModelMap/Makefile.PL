use inc::Module::Install;
name ('Jifty-Plugin-ModelMap');
license ('perl');
version_from('lib/Jifty/Plugin/ModelMap.pm');
requires('Jifty');
requires('GraphViz');
requires('HTML::Entities');
requires('Memoize');
build_requires('Test::More');
auto_install();
&WriteAll;
#use strict;
#use warnings;
#use ExtUtils::MakeMaker;
#
#WriteMakefile(
#    NAME                => 'Jifty::Plugin::ModelMap',
#    AUTHOR              => 'bokutin <bokutin@cpan.org>',
#    VERSION_FROM        => 'lib/Jifty/Plugin/ModelMap.pm',
#    ABSTRACT_FROM       => 'lib/Jifty/Plugin/ModelMap.pm',
#    PL_FILES            => {},
#    PREREQ_PM => {
#        'Test::More' => 0,
#    },
#    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
#    clean               => { FILES => 'Jifty-Plugin-ModelMap-*' },
#);
