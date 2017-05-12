use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Linux::ACL',
    AUTHOR              => q{Yuriy Nazarov <nazarov@cpan.org>},
    VERSION_FROM        => 'lib/Linux/ACL.pm',
    ABSTRACT_FROM       => 'lib/Linux/ACL.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Linux-ACL-*' },
    LIBS                => ['-lacl'],
    DEFINE              => '',
    INC                 => '',
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
    'meta-spec' => { version => 2 },
     resources => {
         repository => {
             type => 'git',
             url  => 'https://github.com/nazarov-yuriy/Linux--ACL.git',
             web  => 'https://github.com/nazarov-yuriy/Linux--ACL',
         },
     }})
     : ()
    ),
);
