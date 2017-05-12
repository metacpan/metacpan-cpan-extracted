use strict;
use ExtUtils::MakeMaker;

if ($] >= 5.006) {
    warn "This distribution is only for perl 5.00503\n";
    exit 0;
}

# this tips via Jcode module http://search.cpan.org/dist/Jcode/
my @EXTRA = (
    'NORECURS' => 1,
    'PL_FILES' => {
    },
    'PM' => {
        'Fake/Encode.pm' => '$(INST_LIB)/Fake/Encode.pm',
    },
);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'             => 'Fake::Encode',
    'VERSION_FROM'     => 'Fake/Encode.pm', # finds $VERSION
    ($] >= 5.005 ?                          # Add these new keywords supported since 5.005
      ('PREREQ_PM'     => {},               # e.g., Module::Name => 1.1
       'ABSTRACT_FROM' => 'Fake/Encode.pm', # retrieve abstract from module
       'AUTHOR'        => 'ina <ina@cpan.org> in a CPAN',
      )
      :
      ()
    ),
    @EXTRA,
);

__END__
