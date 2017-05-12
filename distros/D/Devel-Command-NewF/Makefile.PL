use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Devel::Command::NewF',
    AUTHOR              => 'Joe McMahon <mcmahon@cpan.org>',
    VERSION_FROM        => 'lib/Devel/Command/NewF.pm',
    ABSTRACT_FROM       => 'lib/Devel/Command/NewF.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    # Add your required modules here.
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Devel-Command-NewF-*' },
);

sub MY::postamble {
  return <<'MAKE_FRAG';
yman: *.3
	cd build && pod2man ../lib/Devel/Command/NewF.pm > "../man/man3/Devel::Command::NewF.3"

yicf_check: *.yicf
	cd build && check_yicf_ypan *.yicf

yinst: *.yicf
	cd build && yinst_create -t release *.yicf

ydist: yman yinst *.tgz
	cd build && dist_install *.tgz

MAKE_FRAG
    }
