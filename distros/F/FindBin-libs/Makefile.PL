# even the old version is guaranteed not to work 
# with anything earlier than 5.008.

use 5.008;
use strict;

use ExtUtils::MakeMaker;

my $dest    = 'lib/FindBin/libs.pm';

my $from 
= ref $^V && v5.14 le $^V 
? 'libs_curr_pm'
: 'libs_old_pm'
;

-e $dest && unlink $dest;
-e $dest && die "Failed unlink: '$dest' ($!)"; 

link $from => $dest;

[ -e $dest ] || die "Failed link: '$dest' ($!)";

print STDOUT "Installing: '$from' ($dest)\n";

our $VERSION = '2.15';
$VERSION = eval $VERSION;

WriteMakefile
(
    NAME            => 'FindBin::libs',
    VERSION         => $VERSION,
    ABSTRACT_FROM   => $dest,
    PREREQ_PM       =>
    {
        # standard distro, particular versions 
        # are unlikely to cause pain.

		qw
        (
            strict          0

            Carp            0
            Cwd             0
            FindBin         0
            Symbol          0
            File::Spec      0
            File::Temp      0
            List::Util      0
            Test::More      0
        )
    },
);

__END__
