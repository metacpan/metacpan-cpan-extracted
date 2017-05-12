use strict;
use warnings;

use Test::More tests => 291;
use Linux::Prctl qw(:constants);

use POSIX qw(setlocale LC_ALL);
setlocale(LC_ALL, 'C');

my %new_caps = ("syslog" => 1, "wake_alarm" => 1);

is(defined(tied %Linux::Prctl::cap_permitted), 1, "Have a tied cap_permitted object");
is(defined(tied %Linux::Prctl::cap_effective), 1, "Have a tied cap_effective object");
is(defined(tied %Linux::Prctl::cap_inheritable), 1, "Have a tied cap_inheritable object");
my $R = $< ? 0 : 1;
for(@{$Linux::Prctl::EXPORT_TAGS{capabilities}}) {
    SKIP: {
        s/^CAP_//;
        $_ = lc($_);
        eval {
            my $ign = $Linux::Prctl::cap_permitted{$_};
            1;
        } or do {
            if($@ =~ /Invalid argument|has not defined/ && exists($new_caps{$_})) {
                skip("$_ not defined", 8);
            }
        };
        is($Linux::Prctl::cap_permitted{$_}, $R, "Checking whether $_ is set in cap_permitted");
        is($Linux::Prctl::cap_effective{$_}, $R, "Checking whether $_ is set in cap_effective");
        is($Linux::Prctl::cap_inheritable{$_}, 0, "Checking whether $_ is set in cap_inheritable");

        $Linux::Prctl::cap_inheritable{$_} = 1;
        is($Linux::Prctl::cap_inheritable{$_}, $R, "Checking whether $_ is set to $R in cap_inheritable");

        $Linux::Prctl::cap_effective{$_} = 0;
        is($Linux::Prctl::cap_effective{$_}, 0, "Checking whether $_ is set to 0 in cap_effective");
        $Linux::Prctl::cap_effective{$_} = 1;
        is($Linux::Prctl::cap_effective{$_}, $R, "Checking whether $_ is set to $R in cap_effective");

        $Linux::Prctl::cap_permitted{$_} = 0;
        is($Linux::Prctl::cap_permitted{$_}, $R, "Checking whether $_ is set to $R in cap_permitted");
        $Linux::Prctl::cap_permitted{$_} = 1;
        is($Linux::Prctl::cap_permitted{$_}, $R, "Checking whether $_ is set to $R in cap_permitted");
    }
}
