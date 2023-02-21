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
my $this_perl   = sprintf("%d.%d.%d", @parts);
my $future_perl = sprintf("%d.%d.%d", $parts[0], $parts[1] + 2, 0);

subtest "ridiculous invocations" => sub {
    throws_ok {
        Devel::Deprecations::Environmental->import('OldPerl')
    } qr/parameter is mandatory/, "dies with no args";
    throws_ok {
        Devel::Deprecations::Environmental->import(OldPerl => { older_than => "a lemon" })
    } qr/plausible perl version/, "dies with implausible version";
};

subtest "this perl ($this_perl) is OK" => sub {
    @warnings = ();
    Devel::Deprecations::Environmental->import(OldPerl => { older_than => $this_perl });
    is(scalar(@warnings), 0, "no warnings");
};

subtest "this perl is too old (need $future_perl)" => sub {
    @warnings = ();
    Devel::Deprecations::Environmental->import(OldPerl => { older_than => $future_perl });
    is(scalar(@warnings), 1, "got a warning");
    like(
        $warnings[0],
        qr/Deprecation warning!.*: Perl too old \(got $this_perl, need $future_perl\)\n/,
        $warnings[0],
    );
};

done_testing;
