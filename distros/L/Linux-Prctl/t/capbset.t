use strict;
use warnings;

use Test::More tests => 73;
use Linux::Prctl qw(:constants);

my %new_caps = ("syslog" => 1, "wake_alarm" => 1);

SKIP: {
    skip "capbset_drop not available", 37 unless Linux::Prctl->can('capbset_drop');
    is(defined(tied %Linux::Prctl::capbset), 1, "Have a tied capbset object");
    for(@{$Linux::Prctl::EXPORT_TAGS{capabilities}}) {
        s/^CAP_//;
        $_ = lc($_);
        eval {
            is($Linux::Prctl::capbset{$_}, 1, "Checking whether $_ is in the bounding set");
            1;
        } or do {
            if($@ =~ /has not defined/ && exists($new_caps{$_})) {
                skip "$_ not available", 1;
            }
        }
    }
}

SKIP: {
    skip "capbset_drop not available", 36 unless Linux::Prctl->can('capbset_drop');
    skip "Drop tests only makes sense when run as root", 36 unless $< == 0;
    for(@{$Linux::Prctl::EXPORT_TAGS{capabilities}}) {
        s/^CAP_//;
        $_ = lc($_);
        eval {
            $Linux::Prctl::capbset{$_} = 0;
            is($Linux::Prctl::capbset{$_}, 0, "Checking whether $_ is no longer in the bounding set");
            1;
        } or do {
            if($@ =~ /has not defined/ && exists($new_caps{$_})) {
                skip "$_ not available", 2;
            }
        }
    }
}
