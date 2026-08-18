=head1 NAME

35_get_no_path.t - HAC-041: send() defaulted $data/$headers/$events via
_defor() when omitted, but not $path - calling get()/post()/etc with no
path argument (a plausible pattern when base_url is meant to be the
whole target URL) left $path undef, producing a spurious "Use of
uninitialized value $path" warning.

=cut

use strict;
use warnings;
use Test::More;
use HTTP::API::Client;

{
    my $api = HTTP::API::Client->new( base_url => "http://example.com" );

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $req = $api->get( undef, {}, {}, { test_request_object => 1 } );

    ok !( grep { /uninitialized/ } @warnings ),
        "no uninitialized-value warning when \$path is undef";
    is $req->uri, "http://example.com", "the URL is just base_url";
}

{
    my $api = HTTP::API::Client->new;

    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };

    my $req = $api->get( "/search", {}, {}, { test_request_object => 1 } );

    ok !( grep { /uninitialized/ } @warnings ), "no warning when a path is given as usual";
    is $req->uri, "/search", "existing path behavior unchanged";
}

done_testing;
