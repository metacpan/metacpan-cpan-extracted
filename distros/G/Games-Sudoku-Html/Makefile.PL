use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Games::Sudoku::Html',
    VERSION_FROM      => 'lib/Games/Sudoku/Html.pm',
    AUTHOR            => 'Steffen Heinrich <she@cpan.org>',
    LICENSE           => 'perl_5',
    MIN_PERL_VERSION  => '5.06.0',
    PREREQ_PM         => {
      HTML::Template    => 0,
    },
    EXE_FILES => [
      'scripts/sudoku2html.pl',
    ],
    dist              => {
    	# all the files on my external NTFS disk have all permissions set, 
    	# have tar to remove world writables
    	# https://unix.stackexchange.com/questions/755403/specify-different-mode-values-using-gnu-tar 
#      TARFLAGS => "--mode='o=rX' -cvf",
    	# ptar option -C:   CPAN mode - drop 022 from permissions
    	# mode flags for 'ptar' (in Strawberry perls bin/)
      TARFLAGS => '-Ccvf',
      TAR      => 'ptar',
    },
);
