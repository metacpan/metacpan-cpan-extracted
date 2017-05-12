use ExtUtils::MakeMaker;
WriteMakefile(
              NAME => "MTDB",
              DISTNAME => "MTDB",
	($] >= 5.005 ?    
     	 (ABSTRACT_FROM => 'lib/MTDB.pm',
       	AUTHOR     =>' Mark Ralf Thomson <Mark-Thomson@gmx.net>') : ()),
              VERSION_FROM => 'lib/MTDB.pm',
	      PREREQ_PM => { Data::Dumper => '2.08', Crypt::Blowfish =>'2.09', Crypt::CBC => '2.02' },
              'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'}
             );
