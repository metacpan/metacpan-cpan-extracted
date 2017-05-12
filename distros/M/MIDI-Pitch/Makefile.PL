use 5.00503;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MIDI::Pitch',
    VERSION_FROM      => 'lib/MIDI/Pitch.pm',
    PREREQ_PM         => { Test::More => 0},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MIDI/Pitch.pm', # retrieve abstract from module
       AUTHOR         => 'Christian <crenz@web42.com>') : ()),
);

package MY;

use Config;

sub test {
    my $inherited = shift->SUPER::test(@_);
    unless ($ENV{TEST_COVERAGE}) {
	print "Set TEST_COVERAGE=1 in your environment to test coverage using Devel::Cover.\n";
	return $inherited;
    }
    eval { require Devel::Cover; };

    if ($@) {
        print "Devel::Cover not installed, will not collect test coverage statistics.\n";
        return $inherited;
    }

    if ($^O !~ /^(darwin|linux|.*bsd)/i) {
        print "Devel::Cover installed, but will not collect test coverage statistics on this platform.\n";
        return $inherited;
    }

    print "Devel::Cover found, will collect test coverage statistics.\n";

    $inherited =~ s|^test(\s+::?)|test_old$1|m;
   $inherited .= <<EOT;

test$1
\tcover -delete
\tHARNESS_PERL_SWITCHES=-MDevel::Cover $Config{'make'} test_old
\tcover

EOT

    return $inherited;
}
