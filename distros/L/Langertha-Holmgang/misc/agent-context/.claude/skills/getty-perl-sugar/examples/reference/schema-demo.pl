use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use JSON::PP ();
use Example::Sugar::Schema qw(str int_ bool arr obj nullable enum_);
my $schema = obj({
  name => str(min=>1, max=>60),
  count => int_(min=>1, max=>10),
  note => nullable(str(max=>80)),
  mode => nullable(enum_(qw(fast thorough))),
  tags => arr(str(max=>20), max=>5),
  enabled => bool(),
}, required=>[qw(name count mode)]);
print JSON::PP->new->canonical->pretty->encode($schema);
