use strict;
use warnings;

# hide Cpanel::JSON::XS
use lib map {
    my $m = $_;
    sub { return unless $_[1] eq $m; die "Can't locate $m in \@INC (hidden).\n" };
} qw{Cpanel/JSON/XS.pm};

use Test::More 0.88;
use JSON::MaybeXS;

unless ( eval { require JSON::XS; 1 } ) {
    plan skip_all => 'No JSON::XS';
}

diag 'Using JSON::XS ', JSON::XS->VERSION;

is( JSON, 'JSON::XS', 'Correct JSON class' );

is( \&encode_json, \&JSON::XS::encode_json, 'Correct encode_json function' );
is( \&decode_json, \&JSON::XS::decode_json, 'Correct encode_json function' );

require './t/lib/is_bool.pm';

done_testing;
