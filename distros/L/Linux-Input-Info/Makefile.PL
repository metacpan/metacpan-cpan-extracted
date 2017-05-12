use ExtUtils::MakeMaker;

#unless ( $ENV{LINUX_INPUT_INFO_FORCE_BUILD} || ( -d '/dev/input' && -f '/dev/input/event0' ) ) {
#	print STDERR "You don't seem to have a /dev/input directory with any event devices in.\n";
#	exit(-1);
#}


WriteMakefile(
    NAME         => 'Linux::Input::Info',
    VERSION_FROM => 'Info.pm',
    EXE_FILES    => [ 'bin/lsdevinput', 'bin/finddevinput'   ],
);


