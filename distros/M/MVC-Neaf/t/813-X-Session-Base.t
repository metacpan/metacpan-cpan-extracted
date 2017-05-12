#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

my %data;
{
    package My::Session;
    use parent qw(MVC::Neaf::X::Session::Base);
    use Carp;

    sub store {
        $data{$_[1]} = $_[2];
        return { id => $_[1] };
    };
    sub fetch {
        return { strfy => $data{$_[1]} };
    };
}

my $app = MVC::Neaf->new;

$app->set_session_handler( engine => My::Session->new,  );

$app->route( store => sub {
    my $req = shift;
    $req->save_session( { exist => 1, name => $req->param(name => '.+') } );
    return { -content => 'ok' };
});

$app->route( fetch => sub {
    my $req = shift;

    die 418 unless $req->session->{exist};
    die 403 unless $req->session->{name};
    return { -content => $req->session->{name} };
});

my  ($ret, $head, $content) = $app->run_test( '/fetch' );
is ($ret, 418, "Request w/o session at all = no go" );

    ($ret, $head, $content) = $app->run_test( '/store' );
is ($ret, 200, "Request /store worked" );
like $head->header('set-cookie'), qr/session=\S/, "cookie there";

    ($ret, $head, $content) = $app->run_test( '/fetch'
        , override => { HTTP_COOKIE => $head->header('set-cookie') } );
is ($ret, 403, "Session ok, but no name = no go" );

    ($ret, $head, $content) = $app->run_test( '/store?name=KHEDIN' );
is ($ret, 200, "Request /store worked" );
like $head->header('set-cookie'), qr/session=\S/, "cookie there";

    ($ret, $head, $content) = $app->run_test( '/fetch'
        , override => { HTTP_COOKIE => $head->header('set-cookie') } );
is ($ret, 200, "Name is given now" );
is ($content, "KHEDIN", "Data round trip" );

note "Data was: ", explain \%data;

done_testing;
