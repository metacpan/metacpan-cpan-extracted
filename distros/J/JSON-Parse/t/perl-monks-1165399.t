# This is a test for the fix of the following bug:
# https://github.com/benkasminbullock/JSON-Parse/issues/34

# There is also a discussion here:
# http://perlmonks.org/?node_id=1165399

use FindBin '$Bin';
use lib "$Bin";
use JPT;

my $j = JSON::Parse->new();
# no complain, no effect:
$j->warn_only(1);

# legal json:
eval {
    my $pl = $j->run('{"k":"v"}');
};
ok (! $@);

# illegal json, the following statement dies:
my $warning;

$SIG{__WARN__} = sub { $warning = "@_" };
eval {
    my $pl = $j->run('illegal json');
};
ok (! $@, "No fatal error");
ok ($warning, "Got warning");

undef $SIG{__WARN__};

done_testing ();
