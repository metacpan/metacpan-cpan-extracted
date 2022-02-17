use utf8;
use ExtUtils::MakeMaker;
use Config;
use Alien::SWIProlog;
use Alien::SWIProlog::Util;

print "retrieving SWI-Prolog configuration:\n";

$ENV{PL} = Alien::SWIProlog->runtime_prop->{'swipl-bin'};
my $plvars = Alien::SWIProlog::Util::get_plvars( $ENV{PL} );

print "\ncreating plconfig.c\n";
unless (open (PLC, ">plconfig.c")) {
    print "unable to open 'plconfig.c' to store SWI-Prolog configuration\n";
    exit(1);
}

print PLC <<EOC;
char *PL_base="$plvar{PLBASE}";
char *PL_arch="$plvar{PLARCH}";
char *PL_exe="$plvar{PLEXE}";
char *PL_path="$plvar{PLPATH}";
EOC

unless (close (PLC)) {
    print "unable to write 'plconfig.c' to store SWI-Prolog configuration\n";
    exit(1);
}

WriteMakefile( 'NAME' => 'Language::Prolog::Yaswi::Low',
               'VERSION_FROM' => 'Low.pm',
               'PREREQ_PM' => {},
               'ABSTRACT_FROM' => 'Low.pm',
               'AUTHOR' => 'Salvador Fandiño <sfandino@yahoo.com>',
               'LIBS' => [ Alien::SWIProlog->libs ],
               'DEFINE' => '',
               'INC' => Alien::SWIProlog->cflags,
               'OBJECT' => ( '$(BASEEXT)$(OBJ_EXT) callback$(OBJ_EXT) callperl$(OBJ_EXT)'.
                             ' hook$(OBJ_EXT) perl2swi$(OBJ_EXT) swi2perl$(OBJ_EXT)'.
                             ' plconfig$(OBJ_EXT) argv$(OBJ_EXT)'.
                             ' query$(OBJ_EXT) vars$(OBJ_EXT) context$(OBJ_EXT)'.
                             ' engines$(OBJ_EXT) opaque$(OBJ_EXT)' ),
               # 'OPTIMIZE' => '-g -O0'
             );

