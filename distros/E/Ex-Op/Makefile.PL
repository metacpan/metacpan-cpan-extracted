use 5.010;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %WriteMakefileArgs = (
    NAME             => 'Ex::Op',
    AUTHOR           => ['LNATION <email@lnation.org>'],
    VERSION_FROM     => 'lib/Ex/Op.pm',
    ABSTRACT_FROM    => 'lib/Ex/Op.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.010',
    INC              => '-Iinclude',
    DEFINE           => $ENV{EX_OP_CHECK_WRAP} ? '-DEO_FORCE_CHECK_WRAP -DEO_TEST_HOOKS' : '',
    XS               => { 'Op.xs' => 'Op.c' },
    OBJECT           => 'Op$(OBJ_EXT)',
    macro => { TARFLAGS => "--format=ustar -c -v -f" },
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '0',
    },
    TEST_REQUIRES => {
        'Test::More' => '0',
    },
    PREREQ_PM => {
    },
    depend => {
        'Op$(OBJ_EXT)' => 'include/ex_op.h include/ex_op_reg.h include/ex_op_call.h include/ex_op_kw.h include/ex_op_compat.h include/xop_compat.h',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Ex-Op-* Op.c Op$(OBJ_EXT)' },
);

unless (eval { ExtUtils::MakeMaker->VERSION('6.64'); 1 }) {
    my $test_requires = delete $WriteMakefileArgs{TEST_REQUIRES} || {};
    @{$WriteMakefileArgs{PREREQ_PM}}{keys %$test_requires} = values %$test_requires;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    unless eval { ExtUtils::MakeMaker->VERSION('6.52'); 1 };
delete $WriteMakefileArgs{MIN_PERL_VERSION}
    unless eval { ExtUtils::MakeMaker->VERSION('6.48'); 1 };
delete $WriteMakefileArgs{LICENSE}
    unless eval { ExtUtils::MakeMaker->VERSION('6.31'); 1 };

WriteMakefile(%WriteMakefileArgs);
