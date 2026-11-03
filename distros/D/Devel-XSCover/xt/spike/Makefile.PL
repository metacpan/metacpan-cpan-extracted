use strict;
use warnings;
use Config;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Spike',
    VERSION_FROM => 'lib/Spike.pm',
    INC          => '-Iinclude',
    OPTIMIZE     => '-O2 -DSPIKE_OPT',
    CCFLAGS      => "$Config{ccflags} -DSPIKE_CC",
    XS           => { 'Spike.xs' => 'Spike.c' },
    OBJECT       => 'Spike$(OBJ_EXT) src/helper$(OBJ_EXT)',
    depend       => {
        'Spike.c'            => 'xs/more.xs',
        'Spike$(OBJ_EXT)'    => 'include/spike.h',
        'src/helper$(OBJ_EXT)' => 'include/spike.h',
    },
    clean => { FILES => 'Spike.c *.gcda *.gcno *.gcov src/*.gcda src/*.gcno' },
);

sub MY::postamble {
    return "src/helper\$(OBJ_EXT): src/helper.c include/spike.h\n"
         . "\t\$(CCCMD) \$(CCCDLFLAGS) \"-I\$(PERL_INC)\" \$(PASTHRU_DEFINE) \$(DEFINE) src/helper.c -o src/helper\$(OBJ_EXT)\n";
}
