use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Finance::QIF',
    'VERSION_FROM' => 'lib/Finance/QIF.pm',
    'PREREQ_PM'    => { 'IO::File' => 1.11 },  # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?                                     ## keywords supported since 5.005
          (
            LICENSE       => 'perl',
            ABSTRACT_FROM => 'lib/Finance/QIF.pm',
            AUTHOR        => 'Matthew McGillis <matthew@mcgillis.org> & ' .
                             'Phil Lobbes <phil@perkpartners.com>'
          )
        : ()
    ),
);
