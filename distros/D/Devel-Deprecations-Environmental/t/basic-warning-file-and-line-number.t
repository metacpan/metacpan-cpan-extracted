use warnings;
use strict;

use Test::More;

use lib 't/lib';

sub _warning_string {
    sprintf("Deprecation warning! In %s on line %d: %s\n", @_);
}

my @warnings;
BEGIN { $SIG{__WARN__} = sub { @warnings = @_ }; }

# make sure it works all proper-like at compile-time

# line 37 "at-compile-time"
use Devel::Deprecations::Environmental 'Internal::Always';
BEGIN {
    is(
        $warnings[0],
        _warning_string("at-compile-time", 37, "always deprecated"),
        _warning_string("at-compile-time", 37, "always deprecated"),
    );
}

# ... and at run-time, just cos that makes testing easier

@warnings = ();
# line 73 "at-run-time"
Devel::Deprecations::Environmental->import('Internal::Always');
is(
    $warnings[0],
    _warning_string("at-run-time", 73, "always deprecated"),
    _warning_string("at-run-time", 73, "always deprecated"),
);

@warnings = ();
Devel::Deprecations::Environmental->import('Internal::Never');
is(
    scalar(@warnings),
    0,
    'no deprecation warning emitted'
);

done_testing;
