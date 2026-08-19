=head1 NAME

62_xboolean_live_nonbinary_json.t - HAC-081: kvp2json_each's BOOL branch
returned $v->[0] unconditionally, which is correct only for xTRUE()/
xFALSE() (a scalar ref to exactly 1/0 - JSON::XS's own convention for a
native boolean). xBOOLEAN(\$flag) is documented (DataTypeMarker.pm POD)
as a general live-tracking mechanism, not restricted to 0/1 - but for
any other live value, kvp2json_each handed JSON::XS a raw, non-blessed
scalar ref, which JSON::XS cannot encode at all ("cannot encode
reference to scalar ... unless the scalar is 0 or 1"), crashing
kvp2json() outright. kvp2str_each already dereferenced correctly for
this exact case (see its BOOL branch) - kvp2json_each now matches it:
still yields a native JSON boolean for a live 0/1 value, but dereferences
and encodes the actual value for anything else.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

{
    my $status = "active";
    my $json = eval {
        $api->kvp2json( data => { state => xBOOLEAN( \$status ) }, events => {} );
    };
    is $@, '', "xBOOLEAN(\\\$flag) with a non-0/1 live value no longer crashes kvp2json";
    is $json, '{"state":"active"}',
        "...and encodes the live value's actual current contents, matching kvp2str's behavior";
}

{
    my $status = "active";
    my $str = $api->kvp2str( data => { state => xBOOLEAN( \$status ) }, events => {} );
    is $str, 'state=active', "kvp2str's existing correct live-dereference behavior is unchanged";
}

{
    # xTRUE/xFALSE (a live ref to exactly 1/0) must still hit JSON::XS's
    # native boolean encoding, unchanged by this fix.
    my $json_true  = $api->kvp2json( data => { ok => xTRUE() },  events => {} );
    my $json_false = $api->kvp2json( data => { ok => xFALSE() }, events => {} );
    is $json_true,  '{"ok":true}',  "xTRUE still encodes as a native JSON boolean";
    is $json_false, '{"ok":false}', "xFALSE still encodes as a native JSON boolean";
}

{
    # A live scalar ref that currently holds exactly 1 or 0 (not via
    # xTRUE/xFALSE) should also still get native boolean treatment.
    my $flag = 1;
    my $json = $api->kvp2json( data => { ok => xBOOLEAN( \$flag ) }, events => {} );
    is $json, '{"ok":true}', "a live ref currently holding 1 still encodes as a native JSON boolean";
}

done_testing;
