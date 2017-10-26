use ExtUtils::MakeMaker;

my %opts = (
     'NAME'          => 'Games::Sudoku::CLI',
     'VERSION_FROM'  => 'lib/Games/Sudoku/CLI.pm',
     'PREREQ_PM' => {
          'Test::More'                           => 0.47,
          'Games::Sudoku::Component::Controller' => '0.02',
     },
	 ABSTRACT_FROM => 'lib/Games/Sudoku/CLI.pm',
    EXE_FILES    => ['bin/sudoku.pl'],
);

if (eval { ExtUtils::MakeMaker->VERSION(6.3002) }) {
	$opts{LICENSE} = 'perl';
}

if (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
	$opts{META_MERGE} = {
		'meta-spec' => { version => 2 },
		resources => {
			repository => {
				type => 'git',
				url  => 'http://github.com/szabgab/perl5-Games-Sudoku-CLI.git',
				web  => 'http://github.com/szabgab/perl5-Games-Sudoku-CLI',
			}
		}
	};
}


WriteMakefile( %opts );
