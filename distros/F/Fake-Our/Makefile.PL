use strict;
use ExtUtils::MakeMaker;

# remove here to PASS test of ActiveState Code. (this software no longer contains warnings.pm)
# http://code.activestate.com/ppm/Fake-Our/
# # Bug #97866 for Modern-Open: Prevent from installing on newer perls
# # https://rt.cpan.org/Public/Bug/Display.html?id=97866
# if ($] >= 5.006) {
#     warn "This distribution is only for perl 5.005.\n";
#     exit 0;
# }

# this tips via Jcode module http://search.cpan.org/dist/Jcode/
my @EXTRA = (
    'NORECURS' => 1,
    'PL_FILES' => {
    },
    'PM' => {
        'Fake/Our.pm' => '$(INST_LIB)/Fake/Our.pm',
    },
);

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'             => 'Fake::Our',
    'VERSION_FROM'     => 'Fake/Our.pm', # finds $VERSION
    ($] >= 5.005 ?                       # Add these new keywords supported since 5.005
      ('PREREQ_PM'     => {},            # e.g., Module::Name => 1.1
       'ABSTRACT_FROM' => 'Fake/Our.pm', # retrieve abstract from module
       'AUTHOR'        => 'ina <ina@cpan.org> in a CPAN',
      )
      :
      ()
    ),
    @EXTRA,
);

__END__
