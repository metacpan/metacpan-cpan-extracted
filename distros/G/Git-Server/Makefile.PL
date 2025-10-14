use 5.005;
use ExtUtils::MakeMaker;

WriteMakefile
    NAME          => 'Git::Server',
    AUTHOR        => 'Rob Brown <bbb@cpan.org>',
    VERSION_FROM  => 'lib/Git/Server.pm',
    ABSTRACT_FROM  => 'lib/Git/Server.pm',
    PREREQ_PM     => {
        Cwd => 0,
    },
    dist => {
        COMPRESS => "gzip -9 -vf",
    },
    EXE_FILES => [ `cat MANIFEST` =~ /^(git-.{6})$/gm ],
    PM => {
        map ( ( "lib/$_" => "\$(INST_LIB)/$_" ), `cat MANIFEST` =~ m{^lib/(.+\.pm)$}gm ),
        map ( ( $_ => "\$(INST_SCRIPT)/$_" ), `cat MANIFEST` =~ /^(git-.{6}|hooks.*)$/gm ),
    },
    ;
