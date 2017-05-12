

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'IO::Socket::RedisPubSub',
    VERSION_FROM => 'lib/IO/Socket/RedisPubSub.pm', # finds \$VERSION
    AUTHOR       => 'Martin Redmond @mpr312',
    ABSTRACT     => 'Simple redis publish/subscribe client',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
