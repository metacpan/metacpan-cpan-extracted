
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile (
    NAME         => 'HTML::Normalize',
    VERSION_FROM => 'lib/HTML/Normalize.pm',               # finds \$VERSION
    AUTHOR       => 'Peter Jaquiery (grandpa@cpan.org)',
    ABSTRACT     => 'HTML light weight cleanup',
    PREREQ_PM    => {
        'Test::Simple'      => 0.44,
        'HTML::Entities'    => 1.35,
        'HTML::TreeBuilder' => 3.23,
        'HTML::Tagset'      => 3.10,
    },
);
