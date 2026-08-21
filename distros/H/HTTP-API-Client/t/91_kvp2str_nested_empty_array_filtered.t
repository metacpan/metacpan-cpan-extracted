=head1 NAME

91_kvp2str_nested_empty_array_filtered.t - HAC-125: kvp2str_each's plain-ARRAY
branch (not xCSV) has 'push @parts, $part if length $part;' to filter out
empty entries - the only way a non-CSV array element produces an empty
$part is a nested empty arrayref (the recursive call on [] returns '').
No test exercised this before - Devel::Cover's branch report showed the
filtered/empty arm of that if-guard untested. Live-verified before this
test existed: the behavior is already correct, this closes a coverage
gap, not a defect.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new;

    is $api->kvp2str( data => { tags => [ [], "a", "b" ] }, events => {} ),
        "tags=a&tags=b",
        "a nested empty arrayref inside a plain ARRAY value is silently filtered out, not emitted as a stray empty entry";
}

done_testing;
