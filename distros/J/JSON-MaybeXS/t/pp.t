use strict;
use warnings;

# hide Cpanel::JSON::XS, JSON::XS
use lib map {
    my $m = $_;
    sub { return unless $_[1] eq $m; die "Can't locate $m in \@INC (hidden).\n" };
} qw{Cpanel/JSON/XS.pm JSON/XS.pm};

use if !eval { require JSON::PP; 1; }, 'Test::More', skip_all => 'No JSON::PP';
use Test::More 0.88;
use JSON::MaybeXS;

diag 'Using JSON::PP ', JSON::PP->VERSION;

is(JSON, 'JSON::PP', 'Correct JSON class');

is(
  \&encode_json, \&JSON::PP::encode_json,
  'Correct encode_json function'
);

is(
  \&decode_json, \&JSON::PP::decode_json,
  'Correct encode_json function'
);

require './t/lib/is_bool.pm';

done_testing;
