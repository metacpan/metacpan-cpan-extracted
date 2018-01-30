use strict;
use warnings;

# hide Cpanel::JSON::XS, JSON::XS, JSON::PP
use lib map {
    my $m = $_;
    sub { return unless $_[1] eq $m; die "Can't locate $m in \@INC (hidden).\n" };
} qw{Cpanel/JSON/XS.pm JSON/XS.pm JSON/PP.pm};

use Test::More 0.88;

ok(!eval { require JSON::MaybeXS; 1 }, 'Class failed to load');

like(
  $@, qr{Can't locate Cpanel/JSON/XS\.pm.*Can't locate JSON/XS\.pm.*Can't locate JSON/PP\.pm}s,
  'All errors reported'
);

done_testing;
