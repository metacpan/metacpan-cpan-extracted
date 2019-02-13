use strict;
use warnings;
use Test::More;
use Devel::Probe;
use Devel::Leak;

my $impossible_probe_line = 999;
my @probe = (__FILE__, $impossible_probe_line, Devel::Probe::ONCE);
sub probe_cb { }

leak_test(sub {
        Devel::Probe::install();
        Devel::Probe::remove();
    }, 10000, "no memory leak in install/remove cycle"
);

leak_test(sub {
        Devel::Probe::install();
        Devel::Probe::enable();
        Devel::Probe::disable();
        Devel::Probe::remove();
    }, 10000,  "no memory leak in install/enable/disable/remove cycle"
);

leak_test(sub {
        Devel::Probe::install();
        Devel::Probe::add_probe(@probe);
        Devel::Probe::remove();
    }, 10000,  "no memory leak in install/add_probe/remove cycle"
);

leak_test(sub {
        Devel::Probe::install();
        Devel::Probe::add_probe(__FILE__, $impossible_probe_line, Devel::Probe::ONCE, ["foo"]);
        Devel::Probe::remove();
    }, 10000,  "no memory leak in install/add_probe + arg/remove cycle"
);

leak_test(sub {
        Devel::Probe::install();
        Devel::Probe::trigger(\&probe_cb);
        Devel::Probe::remove();
    }, 10000, "no memory leak in install/trigger/remove cycle"
);

leak_test(sub {
        Devel::Probe::install();
        Devel::Probe::enable();
        # this is a real probe line; we want to fire the probe a lot
        Devel::Probe::add_probe(__FILE__, 60, Devel::Probe::PERMANENT, ["foo"]);
        my $trigger_target = 1000;
        my $trigger_count = 0;
        Devel::Probe::trigger(sub {
            my ($line, $file, $arg) = @_;
            $trigger_count++;
        });
        my $foo = 0;
        for (1 .. $trigger_target) {
            my $bar = $_ + 1;
            $foo += $bar; # probe fires here
        }
        if ($trigger_count != $trigger_target) {
            die "probe did not fire correct number of times. can't use Test::More methods here because they break the memory leak detection";
        }
        Devel::Probe::remove();
    }, 1000,  "no memory leak in install/add_probe + arg/frequent trigger/remove cycle"
);

sub leak_test {
    my ($test_cb, $size, $desc) = @_;
    my $handle;
    my $i = 0;
    my $start_objects = Devel::Leak::NoteSV($handle);
    while($i < $size) {
        $test_cb->();
        $i++;
    }
    # note, never call 'NoteSV' with the $handle again; it will segfault.
    my $end_objects = Devel::Leak::NoteSV($handle);

    is($end_objects, $start_objects, $desc);
}

done_testing;
