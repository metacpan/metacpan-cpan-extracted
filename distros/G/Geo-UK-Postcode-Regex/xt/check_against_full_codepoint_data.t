use strict;
use warnings;

use Test::Most;

use Geo::UK::Postcode::CodePointOpen;

plan skip_all => "CODEPOINT_PATH environment variable not set - skipping"
    unless $ENV{CODEPOINT_PATH};

ok my $code_point_open
    = Geo::UK::Postcode::CodePointOpen->new( path => $ENV{CODEPOINT_PATH} ),
    "got CodePointOpen object";

note "getting regexes";
ok my $lax_re    = Geo::UK::Postcode::Regex->regex;
ok my $strict_re = Geo::UK::Postcode::Regex->strict_regex;
ok my $valid_re  = Geo::UK::Postcode::Regex->valid_regex;

sub tester {
    my $regex = shift;
    return sub {
        my $iterator = $code_point_open->read_iterator();
        while ( my $pc = $iterator->() ) {
            my $postcode = $pc->{Postcode};
            ok $postcode =~ $regex, "$postcode ok";
        }
    };
}

subtest lax    => tester($lax_re);
subtest strict => tester($strict_re);
subtest valid  => tester($valid_re);

done_testing;

