=head1 NAME

70_xboolean_live_undef_json.t - HAC-091: kvp2json_each crashed on a live
xBOOLEAN(\$var) reference holding undef - a regression introduced by
HAC-084/HAC-090 combining. $$inner was compared directly against '0'/'1'
with eq (warning on undef) and, since undef eq neither, the undef value
was passed straight into _json_validate_utf8()/_numify_if_lossless()
unguarded, which then tried to Encode::decode(utf8 => undef, ...) and
died with a confusing "value is not valid UTF-8" error instead of
producing a sensible result. kvp2json_each now defaults the live value
to '' before the 0/1 comparison, matching kvp2str_each's own undef
handling (HAC-082) and the top-level scalar branch's own
undef-becomes-empty-string convention.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

my $api = HTTP::API::Client->new;
my $var;

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $json = $api->kvp2json( data => { flag => xBOOLEAN( \$var ) }, events => {} );

    is $json, '{"flag":""}',
        "a live xBOOLEAN(\\\$var) holding undef encodes as an empty JSON string, not a crash";
    ok !( grep { /uninitialized|not valid UTF-8/ } @warnings ),
        "no uninitialized-value warning and no invalid-UTF-8 die for a live BOOL ref holding undef";
}

done_testing;
