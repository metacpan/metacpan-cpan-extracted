=head1 NAME

58_kvp_response_empty_segment.t - HAC-075: kvp_response() produced a
bogus '' => undef entry plus two uninitialized-value warnings whenever
the response body had an empty &-separated segment (leading, trailing,
or doubled ampersand) - split /&/, "a=1&&a=2" yields ("a=1", "", "a=2"),
and split /=/, "", 2 on that empty segment returns an empty list, so
$k/$v both end up undef. Same failure signature already fixed on the
encode side by HAC-060/061/065, now on the decode side too. An empty
segment is now skipped entirely, matching how an empty array/value is
already omitted rather than represented on the encode side.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;
use HTTP::Response;

my $api = HTTP::API::Client->new;

for my $case (
    [ "doubled ampersand",  "a=1&&a=2",  { a => [ 1, 2 ] } ],
    [ "leading ampersand",  "&a=1",      { a => 1 } ],
    [ "trailing ampersand", "a=1&",      { a => 1 } ],
) {
    my ( $name, $content, $expected ) = @$case;

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $r = HTTP::Response->new(200);
    $r->content($content);
    $api->last_response($r);

    is_deeply $api->kvp_response, $expected, "$name: no bogus '' key, real data preserved";
    ok !(grep { /uninitialized/ } @warnings), "$name: no uninitialized-value warning";
}

done_testing;
