=head1 NAME

54_bool_nested_in_csv.t - HAC-071: kvp2str_each's BOOL branch ignores
%o's no_key flag entirely and always prefixes "$k=" onto its output,
unlike the scalar and ARRAY branches which respect it. A BOOL-marked
value (xTRUE/xFALSE) nested inside an xCSV(...) list is recursed into
with no_key => 1 (same as any other CSV element), but the BOOL branch's
"$k=" prefix leaks into the comma-joined string instead of being
suppressed - xCSV(6, 7, xTRUE(), 15) encoded to "e=6,7,e=1,15" (a bogus
embedded "e=" in the middle) instead of "e=6,7,1,15".

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new( content_type => "application/x-www-form-urlencoded" );

{
    my $str = $api->kvp2str( data => { e => xCSV( 6, 7, xTRUE(), 15 ) }, events => {} );
    is $str, 'e=6,7,1,15', "a BOOL marker nested inside xCSV joins as a plain value, not 'e=6,7,e=1,15'";
}

{
    my $str = $api->kvp2str( data => { e => xCSV( xFALSE(), 2 ) }, events => {} );
    is $str, 'e=0,2', "xFALSE nested inside xCSV also joins as a plain value";
}

{
    my $str = $api->kvp2str( data => { flag => xTRUE() }, events => {} );
    is $str, 'flag=1', "a top-level (non-CSV) BOOL marker is unaffected - still key=value";
}

done_testing;
