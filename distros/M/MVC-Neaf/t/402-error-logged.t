#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

sub warnextract(&) { ## no critic
    my $code = shift;

    my @warn;
    local $SIG{__WARN__} = sub { push @warn, shift };
    $code->();

    note "Got warning: ".$_ for @warn;
    return @warn;
};

use MVC::Neaf;

my @warn;

neaf pre_route => sub {
    my $req = shift;
    $req->param( pre => 1 )
        and die "preamble";
};
get '/kaboom' => sub {
    my $req = shift;

    die "foobared!"
        unless $req->param( tpl => 1 );

    return { -view => 'TT', -template => \'[% IF kaboom %]' };
};

subtest "expection in handler" => sub {
    my @ret;
    my @warn = warnextract {
        @ret = neaf->run_test('/kaboom');
    };

    is $ret[0], 500, "tpl error = status 500";

    my ($req_id) = $ret[2] =~ qr{<b>([-\w]+)</b>};
    like $req_id, qr/[-\w]{8}/, "reasonably long request id";

    is scalar @warn, 1, "exactly 1 warning";
    like $warn[0], qr/ERROR.*\Q$req_id\E.*foobared/, "req_id and original error retained";
};

subtest "expection in template" => sub {
    my @ret;
    my @warn = warnextract {
        @ret = neaf->run_test('/kaboom?tpl=1');
    };

    is $ret[0], 500, "tpl error = status 500";

    my ($req_id) = $ret[2] =~ qr{<b>([-\w]+)</b>};
    like $req_id, qr/[-\w]{8}/, "reasonably long request id";

    is scalar @warn, 1, "exactly 1 warning";
    like $warn[0], qr/ERROR.*\Q$req_id\E.*rendering/, "req_id retained";
};

done_testing;
