=head1 NAME

75_bare_scalar_ref_data_value_dies.t - HAC-096: a bare (not xBOOLEAN-wrapped)
SCALAR ref used as a data value - typically the result of forgetting to call
xBOOLEAN() around a live variable - fell through kvp2str_each's final
fallback ("return $v") unchecked, silently stringifying to
"a=SCALAR%280x...%29" with no error or warning: the exact silent-corruption
failure class HAC-020 (nested hash) and HAC-093 (xBOOLEAN's own non-scalar-ref
guard) already established this project must never do. kvp2json_each's
equivalent fallback did technically die (JSON::XS itself refuses to encode
an arbitrary scalar ref), but with a confusing low-level message that never
mentions this module's own vocabulary (xBOOLEAN) at all. Both encoders now
die with the same clear, actionable message before reaching that point.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;

{
    my $x = "hello";

    eval { $api->kvp2str( data => { a => \$x } ) };
    my $error = $@;

    ok $error, "kvp2str: a bare SCALAR ref dies instead of silently stringifying to SCALAR(0x...)";
    like $error, qr/xBOOLEAN/, "the error points at xBOOLEAN() as the fix";
}

{
    my $x = "hello";

    eval { $api->kvp2json( data => { a => \$x } ) };
    my $error = $@;

    ok $error, "kvp2json: a bare SCALAR ref dies with this module's own clear message";
    like $error, qr/xBOOLEAN/, "the error points at xBOOLEAN() as the fix, not a raw JSON::XS internal error";
}

{
    # A bare CODE ref is already executed as a callback upstream of these
    # fallbacks (see _execute_callbacks / the CODE branch at the top of each
    # *_each sub) - only confirm the fallback guard doesn't regress that.
    is $api->kvp2str( data => { a => sub { "computed" } } ), 'a=computed',
        "a CODE ref value is still executed as a callback, unaffected by this fix";
    is $api->kvp2json( data => { a => sub { "computed" } } ), '{"a":"computed"}',
        "a CODE ref value is still executed as a callback, unaffected by this fix";
}

done_testing;
