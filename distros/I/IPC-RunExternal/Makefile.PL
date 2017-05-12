use lib inc; use Devel::AssertOS qw(Unix);

use 5.006002;
use strict;
use warnings;
use ExtUtils::MakeMaker;

use lib 'inc';
use Devel::AssertOS qw(Unix);

WriteMakefile(
    NAME                => 'IPC::RunExternal',
    AUTHOR              => q{Mikko Koivunalho <mikko.koivunalho@iki.fi>},
    VERSION_FROM        => 'lib/IPC/RunExternal.pm',
    ABSTRACT_FROM       => 'lib/IPC/RunExternal.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.47
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'IPC-RunExternal-*' },
    MIN_PERL_VERSION => '5.006002',
);
