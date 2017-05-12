    use ExtUtils::MakeMaker;
    WriteMakefile
      ('DISTNAME' => 'Mail-Thread-Chronological',
       'VERSION' => '1.22',
       'PL_FILES' => {},
       'PREREQ_PM' => {
			'Test::More' => '0',
			'List::Util' => '0',
			'Date::Parse' => '0',
			'Mail::Thread' => '0',

		      },
      );
