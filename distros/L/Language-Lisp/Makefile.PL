use Config;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $dynalib = '';

if ($^O eq 'linux') {
    # only ms-win32 do this correctly;
    #$dynalib = "$Config{installarchlib}/auto/DynaLoader/DynaLoader.a";
    $dynalib = "$Config{installarchlib}/auto/DynaLoader/DynaLoader.a";
}

WriteMakefile(
    NAME              => 'Language::Lisp',
    VERSION_FROM      => 'lib/Language/Lisp.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM  => 'lib/Language/Lisp.pm', # retrieve abstract from module
    AUTHOR         => 'Vadim Konovalov vkon@cpan.org',
    LIBS              => [], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    INC               => '', # e.g., '-I/usr/include/other'
	# Un-comment this if you add C files to link with later:
    OBJECT            => "\$(O_FILES) $dynalib ", # link all the C files too
);
