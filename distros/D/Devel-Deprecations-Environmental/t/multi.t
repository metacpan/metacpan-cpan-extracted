use warnings;
use strict;

use Test::More;
use Test::Exception;

use Config;
use Devel::Deprecations::Environmental ();

use lib 't/lib';

my @warnings;
$SIG{__WARN__} = sub { push @warnings, @_ };

my @parts = split(/\./, $Config{version});
my $future_perl = sprintf("%d.%d.%d", $parts[0], $parts[1] + 2, 0);

@warnings = ();
Devel::Deprecations::Environmental->import(
    # these two always warn
    ((~0 != 4294967295) ? 'Internal::Int64' : 'Int32'),
    OldPerl => { older_than => $future_perl },
    # this one never warns
    ((~0 == 4294967295) ? 'Internal::Int64' : 'Int32'),
);
is(scalar(@warnings), 2, "got 2 warnings");
like(
    $warnings[0],
    qr/Deprecation warning!.*bit integer/,
    $warnings[0],
);
like(
    $warnings[1],
    qr/Deprecation warning!.*Perl too old/,
    $warnings[1],
);

done_testing;
