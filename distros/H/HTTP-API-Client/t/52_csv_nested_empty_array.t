=head1 NAME

52_csv_nested_empty_array.t - HAC-069: an empty ARRAY nested inside an
xCSV(...) list produced a stray blank CSV segment instead of being
omitted entirely - xCSV(6, 7, [], 15) encoded to "e=6,7,,15" (a double
comma) rather than "e=6,7,15". kvp2str_each's ARRAY branch already
returns '' for an empty array (the same string a genuine empty-string
scalar element also produces), so the CSV branch's loop couldn't tell
"this element contributed nothing" from "this element really is an
empty string" and pushed both into the comma-joined list the same way.
HAC-065 already established that an empty array should be omitted
entirely at the top level of kvp2str - this extends the same treatment
to an empty array nested inside xCSV.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

{
    my $str = $api->kvp2str( data => { e => xCSV( 6, 7, [], 15 ) }, events => {} );
    is $str, 'e=6,7,15', "an empty array nested inside xCSV is omitted, not left as a blank comma segment";
}

{
    my $str = $api->kvp2str( data => { e => xCSV( 6, '', 15 ) }, events => {} );
    is $str, 'e=6,,15', "a genuine empty-string scalar element is still preserved as a blank segment, unchanged";
}

done_testing;
