

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Math::Palindrome',
    VERSION_FROM => 'lib/Math/Palindrome.pm', # finds \$VERSION
    AUTHOR       => 'Aureliano C. P. Guedes (guedes.aureliano@gmail.com)',
    ABSTRACT     => 'Tool to manipulate palindromes numbers.',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
