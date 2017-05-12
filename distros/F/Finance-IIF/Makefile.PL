use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Finance::IIF',
    'VERSION_FROM' => 'lib/Finance/IIF.pm',
    'PREREQ_PM'    => {},                     # e.g., Module::Name => 1.1
    (
        $] >= 5.005
        ?                                     ## keywords supported since 5.005
          (
            ABSTRACT_FROM => 'lib/Finance/IIF.pm',
            AUTHOR        => 'Matthew McGillis <matthew@mcgillis.org>'
              . ' and Phil Lobbes <phil@perkpartners.com>'
          )
        : ()
    ),
);
