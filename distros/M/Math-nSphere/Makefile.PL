
use ExtUtils::MakeMaker;

WriteMakefile( NAME              => 'Math::nSphere',
               VERSION_FROM      => 'lib/Math/nSphere.pm', # finds $VERSION
               PREREQ_PM         => {}, # e.g., Module::Name => 1.1
               ABSTRACT_FROM  => 'lib/Math/nSphere.pm', # retrieve abstract from module
               AUTHOR         => 'Salvador Fandino <sfandino@yahoo.com>'
             );
