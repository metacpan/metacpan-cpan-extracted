package MyFunc;
use v5.20;
use warnings;

use ExtUtils::Constant ();

sub write_constants {
    ExtUtils::Constant::WriteConstants(
        NAME => 'File::Copy::clonefile',
        NAMES => [qw(CLONE_NOFOLLOW CLONE_NOOWNERCOPY CLONE_ACL)],
        PROXYSUBS => { autoload => 1 },
        C_FILE => 'lib/File/Copy/const-c.inc',
        XS_FILE => 'lib/File/Copy/const-xs.inc',
    );
}

1;
