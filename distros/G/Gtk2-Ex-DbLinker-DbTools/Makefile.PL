

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Gtk2::Ex::DbLinker::DbTools',
    VERSION_FROM => 'lib/Gtk2/Ex/DbLinker/DbTools.pm', # finds \$VERSION
    AUTHOR       => 'FranE<ccedil>ois Rappaz (rappazf@gmail.com)',
    ABSTRACT_FROM => 'lib/Gtk2/Ex/DbLinker/DbTools.pm', 
    PREREQ_PM    => {
                     'Test::More' => 1,
		      'interface' => 0.03,
		      'Try::Tiny' => 0.22,
		      'DBI' => 1.631,
		      'Carp' => 1.17,
		      'Log::Any' => 1.049,
		     'Data::Dumper' => 2.154,
             'Scalar::Util' => 1.45, 
             'Class::InsideOut' => 1.13,
                    },
     META_MERGE => {
        resources => {
            repository => 'https://sourceforge.net/projects/gtk2-ex-dblinker-dbtools/',
        },
    },
TAR => 'ptar', 
TARFLAGS => '-c -C -f',
COMPRESS => q{perl -MIO::Compress::Gzip=gzip,:constants -e"my $$in = $$ARGV[0]; gzip($$in => qq($$in.gz), q(Level) => Z_BEST_COMPRESSION, q(BinModeIn) => 1) or die q(gzip failed); unlink $$in;"},
);
