use ExtUtils::MakeMaker;
WriteMakefile(
	NAME => 'Mail::Queue::DB',
	VERSION_FROM => 'lib/Mail/Queue/DB.pm',
	PREREQ_PM => {
		DB_File::Lock => 0,
	},
	EXE_FILES => [qw(
		scripts/mqdb-sendmail
		scripts/mqdb-flush
		scripts/mqdb-list
		scripts/mqdb-rm
	)],
);
