use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   NAME         => 'Math::PartialOrder',
   VERSION_FROM => 'lib/Math/PartialOrder.pm', # finds $VERSION
   AUTHOR       => 'Bryan Jurish <jurish@ling.uni-potsdam.de>',
   ABSTRACT     => 'Classes for rooted finite partial orders (especially semilattices)',
   PREREQ_PM    => {
		    # for Math::PartialOrder - none
		    # -> for Math::PartialOrder::Std - none
		    'Set::Hashed' => 0.07,
		    # --> for Math::PartialOrder::Caching - none
		    # --> for Math::PartialOrder::LRUCaching
		    'Tie::Cache' => 0.15,
		    # -> for Math::PartialOrder::Masked|Enum|CEnum|CMasked
		    'Bit::Vector' => 6.0,
		    # -> for Math::PartialOrder::Loader
		    'Storable' => 0.611,
		    'GraphViz' => 1.3,
		    'File::Temp' => 0.12
		   },
  );
