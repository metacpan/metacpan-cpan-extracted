use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'IChing::Hexagram::Illuminatus',
    'VERSION_FROM'	=> 'Illuminatus.pm', # finds $VERSION
    'PREREQ_PM'		=> { LWP::UserAgent    => '2.00',
			     HTTP::Request     => '1.3',
			     HTML::Summary     => '0.01',
			     HTML::TreeBuilder => '2.03',
}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Illuminatus.pm', # retrieve abstract from module
       AUTHOR     => 'Stray Toaster <coder@stray-toaster.co.uk>') : ()),
);
