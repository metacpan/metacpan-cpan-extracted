# even the old version is guaranteed not to work 
# with anything earlier than 5.008.

use 5.008;

use Module::FromPerlVer;
use ExtUtils::MakeMaker;

our $VERSION = '2.016002';
$VERSION = eval $VERSION;

WriteMakefile
(
    qw
    (
        NAME            FindBin::libs
        ABSTRACT_FROM   lib/FindBin/libs.pm
        LICENSE         perl
    ),
	AUTHOR     	    => 'Steven Lembark <lembark@wrkhors.com>',
    VERSION         => $VERSION,
    PREREQ_PM       =>
    {
        # standard distro, particular versions 
        # are unlikely to cause pain.

		qw
        (
            strict              0

            Carp                0
            Cwd                 3.73
            FindBin             0
            Symbol              0
            File::Spec          0
            File::Temp          0
            List::Util          0
            Module::FromPerlVer 0.000005
            Test::More          0
        )
    },
);

__END__
