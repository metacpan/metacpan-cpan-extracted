use 5.008000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Devel::GDB::Reflect',
    VERSION_FROM      => 'lib/Devel/GDB/Reflect.pm', # finds $VERSION
    PREREQ_PM         => {
                            'Parse::Yapp' => 0,
                            'Devel::GDB' => 0,
                            'Data::Dumper' => 0,
                            'Term::ReadLine' => 0,
                            'String::ShellQuote' => 0,
                         }, # e.g., Module::Name => 1.1
    EXE_FILES         => [ 'bin/gdb++' ],
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Devel/GDB/Reflect.pm', # retrieve abstract from module
       AUTHOR         => 'Antal Novak <afn@cpan.org>') : ()),
);

sub MY::postamble
{
<<_____
\$(INST_LIBDIR)/Reflect/GDBGrammar.pm: yp/GDBGrammar.yp
	yapp -m Devel::GDB::Reflect::GDBGrammar -o \$@ \$<

pure_all :: \$(INST_LIBDIR)/Reflect/GDBGrammar.pm
_____
}
