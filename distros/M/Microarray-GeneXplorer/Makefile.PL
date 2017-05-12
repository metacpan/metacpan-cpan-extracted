use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
	      'NAME'		=> 'Microarray-GeneXplorer',
	      'VERSION_FROM'	=> 'VERSION', # finds $VERSION
	      'PREREQ_PM'	=> { GD           => 1.19,
				     Getopt::Long => 0}, # e.g., Module::Name => 1.1
	      'EXE_FILES'       => ['bin/makeMicroarrayDataset.pl', 'src/correlations'],
	      'DIR'             => ['src'],
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (ABSTRACT        => 'A collection of modules for creating a web browsable interface to gene expression data',
		AUTHOR          => 'Christian Rees <rees@genome.stanford.edu>, Janos Demeter <jdemeter@genome.stanford.edu>, John Matese <jcmatese@genomics.stanford.edu>, Gavin Sherlock <sherlock@genome.stanford.edu>') : ()
	       ),
	      );
