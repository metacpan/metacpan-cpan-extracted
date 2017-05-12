use ExtUtils::MakeMaker;

WriteMakefile(NAME => 'Fuse::TM',
	      VERSION    => '0.2',
	      ABSTRACT => "Accessing Topic Maps as Filesystem",
	      LICENSE=>"perl",
	      AUTHOR => 'Alexander Zangerl <alphazulu@cpan.org>',
	      PREREQ_PM => { 
		  "TM" => 1.43 ,
		  "Test::More"    => 0.47,
		  "Fuse" => 0.09,
		  "Data::Dumper" => 0,
	      },
	      EXE_FILES=>[qw(bin/tmfs)],
	      );
