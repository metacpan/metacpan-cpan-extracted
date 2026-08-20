=head1 NAME

85_marker_namespace_no_collision.t - HAC-108: xBOOLEAN()/xCSV() blessed
into bare, unqualified package names 'BOOL'/'CSV' - a real Perl namespace
collision risk, since kvp2json_each/kvp2str_each identify this module's
own markers purely by 'ref($v) eq "BOOL"'/'"CSV"' string checks, with no
other verification of origin. Verified live before this fix: a trivial
unrelated package that does 'bless {value=>1}, "BOOL"' (nothing to do with
this module) passed as a data value crashed kvp2json with a confusing
'Not an ARRAY reference' error - a namespace collision, not a data
problem. xBOOLEAN()/xCSV() now bless into HTTP::API::DataTypeMarker::BOOL/
::CSV, eliminating the collision risk entirely.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    package Unrelated::BOOL::User;
    sub new { return bless { value => 1 }, 'BOOL' }
}

{
    my $api  = HTTP::API::Client->new;
    my $fake = Unrelated::BOOL::User::new();

    my $out = eval { $api->kvp2json( data => { a => $fake } ) };
    my $error = $@;

    ok !$error, "an unrelated object blessed into bare 'BOOL' no longer collides with this module's marker (error: "
        . ( $error // '' ) . ")";
}

{
    # The module's own markers still work correctly under their new
    # namespaced classes.
    is $HTTP::API::DataTypeMarker::EXPORT[0], 'xCSV', "sanity: DataTypeMarker still exports as expected";

    my $api = HTTP::API::Client->new;
    is $api->kvp2json( data => { t => xTRUE() } ), '{"t":true}',
        "xTRUE() still encodes as a native JSON boolean under the namespaced BOOL class";
    is $api->kvp2str( data => { tags => xCSV( 1, 2, 3 ) } ), 'tags=1,2,3',
        "xCSV() still comma-joins under the namespaced CSV class";
    is ref( xBOOLEAN(1) ), 'HTTP::API::DataTypeMarker::BOOL',
        "xBOOLEAN() now blesses into the namespaced class";
    is ref( xCSV(1) ), 'HTTP::API::DataTypeMarker::CSV',
        "xCSV() now blesses into the namespaced class";
}

done_testing;
