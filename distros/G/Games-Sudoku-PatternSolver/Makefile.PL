use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => "Games::Sudoku::PatternSolver",
    VERSION_FROM      => "lib/Games/Sudoku/PatternSolver.pm",
    AUTHOR            => "Steffen Heinrich <she@cpan.org>",
    LICENSE           => "perl_5",
    MIN_PERL_VERSION  => "5.10.0",
    PREREQ_PM         => {
    	Bit::Vector       => 0,
    	List::Util        => 0,
    	Algorithm::Combinatorics  => 0,
    	Time::HiRes       => 0,
      HTML::Template    => 0,
    },
    dist              => {
    	# all the files on my external NTFS disk have all permissions set, 
    	# have tar to remove world writables
    	# https://unix.stackexchange.com/questions/755403/specify-different-mode-values-using-gnu-tar 
    	TARFLAGS          => "--mode='o=rX' -cvf",
    },
);
