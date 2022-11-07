use warnings;
use strict;

use Test::More;
use Test::Exception;
use Test::Time;

use Devel::Deprecations::Environmental ();
use DateTime;

use lib 't/lib';

my $now = time();
# we only need to do both object- and string- comparisons for warn-time
# objects, as the comparison logic is the same for the others
my $warn_time_object        = DateTime->from_epoch(epoch => $now + 1);
my $warn_time_string        = $warn_time_object->iso8601();
my $unsupported_time_object = DateTime->from_epoch(epoch => $now + 3);
my $fatal_time_object       = DateTime->from_epoch(epoch => $now + 5);

sub _warning_string {
    sprintf("Deprecation warning! In %s on line %d: %s\n", @_);
}

my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };

subtest "no warn-times specified" => sub {
    @warnings = ();
    Devel::Deprecations::Environmental->import('Internal::Always');
    like(
        $warnings[0],
        qr/^Deprecation warning! In/,
        $warnings[0],
    );
};

subtest "not yet reached warn-time" => sub {
    Test::Time->import(time => $now);

    @warnings = ();
    Devel::Deprecations::Environmental->import(
        'Internal::Always' => { warn_from => $warn_time_object }
    );
    is(scalar(@warnings), 0, "not yet reached warn-time (as an object)");
    Devel::Deprecations::Environmental->import(
        'Internal::Always' => { warn_from => $warn_time_string }
    );
    is(scalar(@warnings), 0, "not yet reached warn-time (as a string)");
};

subtest "reached warn-time, no unsupported/fatal specified" => sub {
    Test::Time->import(time => $now);
    sleep 2;

    @warnings = ();
    Devel::Deprecations::Environmental->import(
        'Internal::Always' => { warn_from => $warn_time_object }
    );
    is(scalar(@warnings), 1, "got one warning (time passed as object)");
    Devel::Deprecations::Environmental->import(
        'Internal::Always' => { warn_from => $warn_time_string }
    );
    is(scalar(@warnings), 2, "got one more warning (time passed as string)");
    like(
        $warnings[0],
        qr/^Deprecation warning! In/,
        $warnings[0],
    );
    like(
        $warnings[1],
        qr/^Deprecation warning! In/,
        $warnings[1],
    );
};

subtest "reached warn-time but not unsupported/fatal-time" => sub {
    Test::Time->import(time => $now);
    sleep 2;

    @warnings = ();
    Devel::Deprecations::Environmental->import(
        'Internal::Always' => {
            warn_from        => $warn_time_object,
            unsupported_from => $unsupported_time_object,
            fatal_from       => $fatal_time_object
        }
    );
    is(scalar(@warnings), 1, "got one warning"),
    my $unsupported_time_string = $unsupported_time_object->iso8601();
    like(
        $warnings[0],
        qr/^Deprecation warning! From $unsupported_time_string: In/,
        $warnings[0],
    );
};

subtest "reached warn-time and unsupported-time but not fatal-time" => sub {
    Test::Time->import(time => $now);
    sleep 4;

    @warnings = ();
    Devel::Deprecations::Environmental->import(
        'Internal::Always' => {
            warn_from        => $warn_time_object,
            unsupported_from => $unsupported_time_object,
            fatal_from       => $fatal_time_object
        }
    );
    is(scalar(@warnings), 1, "got one warning");
    like(
        $warnings[0],
        qr/^Unsupported! In/,
        $warnings[0],
    );
};

subtest "reached unsupported-time but not fatal-time (no warn-time)" => sub {
    Test::Time->import(time => $now);
    sleep 4;

    @warnings = ();
    Devel::Deprecations::Environmental->import(
        'Internal::Always' => {
            unsupported_from => $unsupported_time_object,
            fatal_from       => $fatal_time_object
        }
    );
    is(scalar(@warnings), 1, "got one warning");
    like(
        $warnings[0],
        qr/^Unsupported! In/,
        $warnings[0],
    );
};

subtest "reached warn-time and unsupported-time and fatal-time" => sub {
    Test::Time->import(time => $now);
    sleep 6;

    @warnings = ();
    dies_ok {
        Devel::Deprecations::Environmental->import(
            'Internal::Always' => {
                warn_from        => $warn_time_object,
                unsupported_from => $unsupported_time_object,
                fatal_from       => $fatal_time_object
            }
        );
    } "died";
    like(
        $@,
        qr/^Unsupported! In/,
        $@
    );
    is(scalar(@warnings), 0, "got no warning");
};

subtest "reached fatal-time (no warn/unsupported-time)" => sub {
    Test::Time->import(time => $now);
    sleep 6;

    @warnings = ();
    dies_ok {
        Devel::Deprecations::Environmental->import(
            'Internal::Always' => {
                fatal_from       => $fatal_time_object
            }
        );
    } "died";
    like(
        $@,
        qr/^Unsupported! In/,
        $@
    );
    is(scalar(@warnings), 0, "got no warning");
};

subtest "times out of order" => sub {
    Test::Time->import(time => $now);

    throws_ok {
        Devel::Deprecations::Environmental->import(
            'Internal::Always' => {
                warn_from        => $warn_time_object,
                unsupported_from => $warn_time_object,
                fatal_from       => $fatal_time_object
            }
        );
    } qr/warn_from must be before unsupported_from/, 'warn < unsupported';

    throws_ok {
        Devel::Deprecations::Environmental->import(
            'Internal::Always' => {
                warn_from        => $fatal_time_object,
                fatal_from       => $warn_time_object
            }
        );
    } qr/warn_from must be before fatal_from/, 'warn < fatal';

    throws_ok {
        Devel::Deprecations::Environmental->import(
            'Internal::Always' => {
                unsupported_from => $fatal_time_object,
                fatal_from       => $unsupported_time_object
            }
        );
    } qr/unsupported_from must be before fatal_from/, 'unsupported < fatal';
};

done_testing;
