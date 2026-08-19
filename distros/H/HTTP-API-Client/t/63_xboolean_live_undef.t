=head1 NAME

63_xboolean_live_undef.t - HAC-082: kvp2str_each's BOOL branch produced
a spurious "Use of uninitialized value" warning when a live
xBOOLEAN(\$var) reference currently holds undef - _uri_escape_bytes_or_chars
was handed undef directly, and the result was interpolated into the
output string without ever being defaulted. kvp2json_each already
handled the identical input silently (encodes it as JSON null).
kvp2str_each now defaults an undef live value to '' before escaping,
matching the scalar branch's existing undef-handling convention.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;
use HTTP::API::DataTypeMarker qw(xBOOLEAN);

my $api = HTTP::API::Client->new;
my $var;

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $str = $api->kvp2str( data => { flag => xBOOLEAN( \$var ) }, events => {} );

    is $str, "flag=", "a live xBOOLEAN(\\\$var) holding undef encodes as an empty value";
    ok !( grep { /uninitialized/ } @warnings ),
        "no uninitialized-value warning for a live BOOL ref currently holding undef";
}

done_testing;
