use strict;
use warnings;
use Test::More tests => 2;
use Env::Sanctify;

my $save = scalar keys %ENV;

my $sanctify = Env::Sanctify->sanctify(
		sanctify => [ '.*' ],
);

ok( scalar keys %ENV == 0, 'There is nothing in the %ENV' );
$sanctify->restore();
ok( scalar keys %ENV == $save, 'Okay there is stuff again in the %ENV' );
