#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use MVC::Neaf::Util qw(JSON encode_json decode_json);

use MVC::Neaf;

neaf pre_route => sub { $_[0]->log_error( "mark 1\n" ); };
neaf pre_route => sub { $_[0]->log_error( ); };

neaf pre_logic => sub { $_[0]->log_error( "mark 2" ); };

get '/foo/bar' => sub {
    my $req = shift;
    $req->log_error( "mark 3" );
    $req->log_error;

    die "Foobared";
};

# Cannot use warnings_like - we don't know what to expect before running
#     the code
{
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, shift };

    my $content = neaf->run_test( '/foo/bar' );

    my ($id) = $content =~ qr{<b>([-\w]+)</b>};
    like $id, qr/[-\w]{8}/, "some reasonably long identifier";
    note "req_id=$id";

    my $file = __FILE__;
    $file = qr/\Q$file\E/; # make sure \\ doesn't interfere with regex on windows

    is scalar @warn, 6, "6 warnings issued";
    like $warn[0], qr/req.*\Q$id\E.*pre_route.*mark 1\n$/, "pre_route, msg";
    like $warn[1], qr/req.*\Q$id\E.*pre_route.*$file line \d+\.?\n$/
        , "pre_route, unknown msg = attributed to caller";
    like $warn[2], qr/req.*\Q$id\E.*\/foo\/bar.*mark 2\n$/
        , "pre_logic: path defined";
    like $warn[3], qr/req.*\Q$id\E.*\/foo\/bar.*mark 3\n$/
        , "controller itself";
    like $warn[4], qr/req.*\Q$id\E.*\/foo\/bar.*$file line \d+\.?\n$/
        , "controller itself, attributed to caller";
    like $warn[5], qr/req.*\Q$id\E.*\/foo\/bar.*Foobared.*$file line \d+\.?\n$/
        , "Error message itself";

    note "WARN: $_" for @warn;
}

done_testing;
