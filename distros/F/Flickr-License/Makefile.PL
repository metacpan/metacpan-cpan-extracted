use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Flickr::License',
    VERSION_FROM      => 'lib/Flickr/License.pm', # finds $VERSION
    PREREQ_PM         => {  Class::Singleton=>1.03,
                            Flickr::API=>0.08,
                            Flickr::API::Utils=>0.01
                        }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Flickr/License.pm', # retrieve abstract from module
       AUTHOR         => 'Billy Abbott <billy@cowfish.org.uk>') : ()),
);
