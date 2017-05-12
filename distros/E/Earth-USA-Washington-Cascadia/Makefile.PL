use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Earth::USA::Washington::Cascadia',
    AUTHOR        => q{C.J. Adams-Collier <cjac@colliertech.org>},
    VERSION_FROM  => 'lib/Earth/USA/Washington/Cascadia.pm',
    ABSTRACT_FROM => 'lib/Earth/USA/Washington/Cascadia.pm',
    EXE_FILES     => [ 'bin/redefine-marriage', ],
    ( !eval { ExtUtils::MakeMaker->VERSION(6.46) } )
    ? ( 'LICENSE' => 'f5 internal' )
    : ( ( META_ADD => { resources => {} } ) ),
    PL_FILES  => {},
    PREREQ_PM => { 'Test::More' => 0, 'WWW::Mechanize' => 0, },
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Earth-USA-Washington-Cascadia-*' },
);
