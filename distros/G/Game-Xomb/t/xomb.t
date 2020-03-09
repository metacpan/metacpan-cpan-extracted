#!perl
#
# test that `xomb` is at least not hopelessly buggy

use 5.24.0;
use warnings;
use Test::Most;
use Test::UnixCmdWrap;

plan tests => 9;

# shebag in xomb will be fixed by module install for the perl being
# installed to but here don't know that so use whatever is running
# the tests
my $xomb = Test::UnixCmdWrap->new(cmd => "$^X ./bin/xomb");

$xomb->run(args => '--help', status => 64, stderr => qr/Usage: xomb/);
$xomb->run(args => '--version', status => 1, stdout => qr/\d/a);
$xomb->run(
    args   => '--thpppt',          # Ack
    status => 64,
    stderr => qr/Unknown option/
);
