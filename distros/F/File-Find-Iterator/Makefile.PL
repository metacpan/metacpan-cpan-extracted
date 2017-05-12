use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
              'NAME'            => 'File::Find::Iterator',
              'VERSION_FROM'    => 'Iterator.pm', # finds $VERSION
              'PREREQ_PM'       => {Storable => 2.04, Class::Iterator => 0.1}, # e.g., Module::Name => 1.1
	      ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
	       (AUTHOR     => 'Robert Silve <robert@silve.net>') : ()),
);
