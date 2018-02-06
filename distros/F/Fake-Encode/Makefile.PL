use strict;
use ExtUtils::MakeMaker;

if ($] >= 5.006) {
    warn "This distribution is only for perl 5.00503\n";
    exit 0;
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'             => 'Fake::Encode',
    'VERSION_FROM'     => 'lib/Fake/Encode.pm', # finds $VERSION
    ($] >= 5.005 ?                              # Add these new keywords supported since 5.005
      ('PREREQ_PM'     => {},                   # e.g., Module::Name => 1.1
       'ABSTRACT_FROM' => 'lib/Fake/Encode.pm', # retrieve abstract from module
       'AUTHOR'        => 'ina <ina@cpan.org> in a CPAN',
      )
      :
      ()
    ),
);

__END__
