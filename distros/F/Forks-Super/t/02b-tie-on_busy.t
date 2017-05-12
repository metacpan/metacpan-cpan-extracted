use Forks::Super ':test', ON_BUSY => 'bogus';
use Test::More tests => 6;
use strict;
use warnings;

#
# the value $Forks::Super::ON_BUSY is a tied scalar
# that can only be assigned the (case insensitive) values:
#
#     block  fail  queue
#

for my $valid (qw(Block block FAIL Queue)) {
    $Forks::Super::ON_BUSY = $valid;
    ok($Forks::Super::ON_BUSY eq lc $valid);
}

my $current = $Forks::Super::ON_BUSY;

$Forks::Super::ON_BUSY = "Bogus";
ok($Forks::Super::ON_BUSY eq 'queue' && $Forks::Super::ON_BUSY eq $current);

$Forks::Super::ON_BUSY =~ s/queue/Block/;
ok($Forks::Super::ON_BUSY eq "block");
