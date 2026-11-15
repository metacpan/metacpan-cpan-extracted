use strict;
use warnings;
use Test::More;

use HTTP::API::Core;

open my $changes, '<', 'Changes' or die "cannot open Changes: $!";

# The first numbered entry is the newest published release. An Unreleased
# section may precede it while the next version is in development.
my ($latest_version, $latest_date);
while (my $line = <$changes>) {
    next if $line !~ /^([0-9]+\.[0-9]+)(?:\s+(\S+))?\s*$/;
    ($latest_version, $latest_date) = ($1, $2);
    last;
}
close $changes;

ok defined($latest_version), 'Changes includes a numbered release entry';
if (defined $latest_version) {
    like(
        defined($latest_date) ? $latest_date : '',
        qr/\A\d{4}-\d{2}-\d{2}\z/,
        'newest release entry in Changes has a YYYY-MM-DD date',
    );
    is(
        $HTTP::API::Core::VERSION,
        $latest_version,
        'module version matches the newest dated Changes release',
    );
}

done_testing;
