use strict;
use warnings;

# hide Cpanel::JSON::XS, JSON::XS, JSON::PP
use lib map {
    my ( $m, $c ) = ( $_, qq{die "Can't locate $_ (hidden)\n"} );
    sub { return unless $_[1] eq $m; open my $fh, "<", \$c; return $fh }
} qw{Cpanel/JSON/XS.pm JSON/XS.pm JSON/PP.pm};

use Test::More 0.88;

ok(!eval { require JSON::MaybeXS; 1 }, 'Class failed to load');

like(
  $@, qr{Can't locate Cpanel/JSON/XS\.pm.*Can't locate JSON/XS\.pm.*Can't locate JSON/PP\.pm}s,
  'All errors reported'
);

done_testing;
