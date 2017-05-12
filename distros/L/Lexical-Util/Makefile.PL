use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Lexical::Util',
    VERSION_FROM      => 'lib/Lexical/Util.pm',
    PREREQ_PM         => {},
    ABSTRACT_FROM     => 'lib/Lexical/Util.pm',
    AUTHOR            => 'Kevin Michael Vail <kvail@cpan.org>',
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I.', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
);
