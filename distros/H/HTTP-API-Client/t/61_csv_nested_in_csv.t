=head1 NAME

61_csv_nested_in_csv.t - HAC-078: kvp2str_each's CSV branch always
prefixed "$k=" regardless of %options' no_key flag, unlike the scalar/
BOOL/ARRAY branches which all respect it. An xCSV value nested inside
another xCSV is recursed into with no_key => 1 (the same mechanism
HAC-071 fixed for a BOOL nested in CSV), but the CSV branch ignored it -
xCSV(6, 7, xCSV(13, 14), 15) encoded to "e=6,7,e=13,14,15" (a bogus
embedded "e=") instead of "e=6,7,13,14,15". Same failure family as
HAC-069 (empty ARRAY nested in CSV) and HAC-071 (BOOL nested in CSV) -
CSV nested in CSV was the one combination those didn't cover.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

{
    my $str = $api->kvp2str(
        data   => { e => xCSV( 6, 7, xCSV( 13, 14 ), 15 ) },
        events => {},
    );
    is $str, 'e=6,7,13,14,15',
        "a CSV nested inside a CSV joins as a bare comma-separated value, no embedded key=";
}

{
    # top-level (non-nested) CSV usage is unaffected
    my $str = $api->kvp2str( data => { e => xCSV( 1, 2, 3 ) }, events => {} );
    is $str, 'e=1,2,3', "top-level xCSV usage is unaffected";
}

done_testing;
