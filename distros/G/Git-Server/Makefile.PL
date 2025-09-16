use 5.005;
use ExtUtils::MakeMaker;

# Create empty spec if doesn't exist:
my $spec = "git-server.spec";
if (!-f $spec) { open my $fh, ">>", $spec; }
# But rebuild it if cpan2rpm is available:
utime 1, 1, $spec if 0 == system "which cpan2rpm >/dev/null 2>/dev/null";

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
