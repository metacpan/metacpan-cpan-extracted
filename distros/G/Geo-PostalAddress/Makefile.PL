# Makefile.PL for Geo::PostalAddress
# $Id: Makefile.PL,v 1.2 2005/04/28 21:14:23 michel Exp $
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $save_MM_version = $ExtUtils::MakeMaker::VERSION; # Save for CONFIGURE below
WriteMakefile(
    'NAME'         => 'Geo::PostalAddress',
    'VERSION_FROM' => 'PostalAddress.pm', # finds $VERSION
    'PREREQ_PM'    => {
        'Locale::Country' => '2.07',
        'Locale::SubCountry' => 0, # $VERSION not in the right package
    },
    # Undo what Locale::SubCountry did to ExtUtils::MakeMaker's namespace and
    # do what it should have done instead. (Used just because it gets run right
    # after the PREREQ_PM uses and version checks, which is the best time to
    # clean up Locale::SubCountry messes. Returns an empty hash ref.)
    'CONFIGURE'    => sub {
        if ($save_MM_version ne $ExtUtils::MakeMaker::VERSION) {
          $Locale::SubCountry::VERSION = $ExtUtils::MakeMaker::VERSION;
          $ExtUtils::MakeMaker::VERSION = $save_MM_version;
        }
        return {};
    }
);
