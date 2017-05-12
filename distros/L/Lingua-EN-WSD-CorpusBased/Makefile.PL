use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lingua::EN::WSD::CorpusBased',
    VERSION_FROM      => 'lib/Lingua/EN/WSD/CorpusBased.pm', # finds $VERSION
    PREREQ_PM         => { 'WordNet::QueryData' => 1.40,
			   'WordNet::Similarity' => 1.03,
			   'String::Util' => 0.11 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
     (ABSTRACT_FROM  => 'lib/Lingua/EN/WSD/CorpusBased.pm', # retrieve abstract from module
      AUTHOR         => 'Nils Reiter <reiter@cpan.org>') : ()),
    );
