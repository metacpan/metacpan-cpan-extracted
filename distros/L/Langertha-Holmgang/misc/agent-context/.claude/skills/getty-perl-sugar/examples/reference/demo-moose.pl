use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use JSON::PP ();
use Example::Flow::Check;
my $check = Example::Flow::Check->new(url=>'https://example.invalid', deep=>1);
print JSON::PP->new->canonical->pretty->encode($check->run);
