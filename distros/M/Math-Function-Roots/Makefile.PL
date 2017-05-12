use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Math::Function::Roots',
    AUTHOR              => 'Spencer Ogden <spencer@spencerogden.com>',
    VERSION_FROM        => 'lib/Math/Function/Roots.pm',
    ABSTRACT_FROM       => 'lib/Math/Function/Roots.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Math-Function-Roots-*' },
);

sub MY::postamble {
    return <<'EOF'
testcover:
	cover -delete
	HARNESS_PERL_SWITCHES=-MDevel::Cover make test
EOF
}
