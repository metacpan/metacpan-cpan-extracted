use 5.008008;
use ExtUtils::MakeMaker;

unless ($^O eq 'linux') {
    warn "This is Linux only software\n";
    exit 0;
}

exit 0
    if ($ENV{AUTOMATED_TESTING} and
	system q{echo -e '#include <sys/types.h>\n#include <attr/xattr.h>' |
                 gcc -xc -E - >/dev/null 2>&1});

WriteMakefile(
    NAME           => 'Linux::UserXAttr',
    VERSION_FROM   => 'lib/Linux/UserXAttr.pm',
    PREREQ_PM      => {},
    ABSTRACT_FROM  => 'lib/Linux/UserXAttr.pm',
    AUTHOR         => 'Torsten Förtsch <torsten.foertsch@gmx.net>',
    dist           => {
		       COMPRESS => 'gzip -9f',
		       PREOP    => './mk_README.sh',
 		      },
    LIBS           => [''],
    DEFINE         => '',
    INC            => '-I.',
);
