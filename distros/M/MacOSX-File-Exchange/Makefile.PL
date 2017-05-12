use 5.008006;
use ExtUtils::MakeMaker;

$^O eq "darwin"
    or die "Sorry, this module is for Darwin/Mac OS X only.\n";

WriteMakefile(
    NAME              => 'MacOSX::File::Exchange',
    VERSION_FROM      => 'lib/MacOSX/File/Exchange.pm',
    ABSTRACT_FROM     => 'lib/MacOSX/File/Exchange.pm',
    AUTHOR            => 'Bo Lindbergh <blgl@stacken.kth.se>',
);
