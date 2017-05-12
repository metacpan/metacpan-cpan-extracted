use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'EZDBI',
    VERSION_FROM => 'lib/EZDBI.pm', # finds $VERSION
    AUTHOR       => 'Mark Jason Dominus (mjd-perl-ezdbi+@plover.com)',
    ABSTRACT     => 'Easy interface to SQL databases',
    PREREQ_PM    => {DBI => 0},
          PM     => {'lib/EZDBI.pm' => '$(INST_LIBDIR)/EZDBI.pm'},
);
