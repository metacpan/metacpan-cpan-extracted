use strict;
use ExtUtils::MakeMaker;
use 5.006;


WriteMakefile(
    NAME         => 'IPC::Lite',
    PMLIBDIRS    => ['Games'],
    VERSION_FROM => 'IPC/Lite.pm',
    AUTHOR       => 'Erik Aronesty <earonesty@cpan.org>',
    ABSTRACT     => 'IPC shared variables using SQLite',
    PREREQ_PM    => {
                     'DBI' => 1.21,
                     'DBD::SQLite' => 0,
                     'Test::Simple' => 0,
                    },
    PM           => {'IPC/Lite.pm'=>'$(INST_LIBDIR)/Lite.pm'},
    dist	 => {
		     PREOP=>'pod2text IPC/Lite.pm > README'
		    },
);
