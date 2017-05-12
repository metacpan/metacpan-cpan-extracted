use ExtUtils::MakeMaker;

WriteMakefile(
	      NAME            => 'Mail::Qmail::Queue',
	      VERSION_FROM    => 'lib/Mail/Qmail/Queue/Message.pm',
              EXE_FILES       => [ qw(script/qqtest script/qqdump) ],
	      PREREQ_PM       => {
		  POSIX              => 0,
		  Exporter           => 0,
		  FileHandle         => 0,
  		  Getopt::Std        => 0,
                  Carp               => 0,
		  warnings           => 0,
		  constant           => 0,
		  Test::More         => 0,
	      }
	      );
