use strict;
$^W = 1;

use Test::More;
END { done_testing }

use Devel::CheckOS;

my @families = ();
foreach my $platform (Devel::CheckOS::list_platforms()) {
    if(grep { $_ } Devel::CheckOS::list_family_members($platform)) {
        ok(eval "Devel::AssertOS::$platform->can('expn') && Devel::AssertOS::${platform}::expn()",
            "$platform family has an expn()");
    } elsif(grep { $_ eq $platform } qw(
        Cygwin Linux::v2_6 MachTen MacOSX::v10_4 MSWin32 OS390
        OSF QNX::Neutrino QNX::v4 RISCOS MacOSX::v10_5
    )) {
        ok(eval "Devel::AssertOS::$platform->can('expn') && Devel::AssertOS::${platform}::expn()",
            "non-obvious platform '$platform' has an expn()");
    }
}

