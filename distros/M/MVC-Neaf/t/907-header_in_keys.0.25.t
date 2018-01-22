#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;

use MVC::Neaf::Request::PSGI;

my $req = MVC::Neaf::Request::PSGI->new( env => {
    HTTP_REFERER    => 'http://foo.com',
    HTTP_USER_AGENT => 'lwp',
#    HTTP_COOKIE     => 'jar',  ## Removed - was causing trouble with
                                ## Plack < 1.043
});

warnings_like {
    is_deeply( [sort $req->header_in_keys], [sort qw[ Referer User-Agent ]]
        , "header_in_keys (who needs it anyway?)" );
}[{carped => qr/DEPRECATED.*header_field_names/}]
    , "Deprecated, alternative suggested";

done_testing;
