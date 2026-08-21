=head1 NAME

93_tune_utf8_non_matching_error_swallowed.t - HAC-128: _tune_utf8()'s catch
block only re-encodes when the caught error matches /content must be bytes/
- any OTHER error from $req->content($content) is silently swallowed and
$content is returned unchanged. t/26_tune_utf8.t only exercises the
matching-error (wide-char) and no-error (plain ascii) cases, never a
non-matching error. Tested here via a monkeypatch of HTTP::Request::content,
the same white-box-private-function-testing approach t/26 itself already
established, since no realistic caller path throws a different error here.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;
use HTTP::Request;

{
    no warnings qw( redefine once );
    local *HTTP::Request::content = sub { die "some unrelated error\n" };

    my $original = "original content, unrelated to encoding";
    my $out = HTTP::API::Client::_tune_utf8($original);

    is $out, $original,
        "an error unrelated to UTF-8 encoding is silently swallowed - content passes through unchanged, not crashed or corrupted";
}

done_testing;
