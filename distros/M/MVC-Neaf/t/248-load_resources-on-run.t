#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Warn;

use MVC::Neaf;

subtest "without magic" => sub {
    my $app = MVC::Neaf->new->magic(0);
    my $psgi = $app->run;
    my @known = sort keys %{ $app->get_routes };
    is_deeply \@known, [ ], "routes NOT loaded via resources"
        or diag "Found routes: @known";
};

subtest "with magic" => sub {
    my $app = MVC::Neaf->new;
    $app->add_route( '/' => sub {
        return { -template => 'index.html', -view => 'TT' };
    } );
    $app->load_view('TT', 'TT');
    my $psgi = $app->run;

    # load_resources works only once & closes DATA, so
    # run more subtests inside this one

    subtest "static content" => sub {
        my @known = sort keys %{ $app->get_routes };
        is_deeply \@known, [ '', '/js/foobar' ], "route loaded via resources"
            or diag "Found routes: @known";

        lives_ok {
            my $nonvoid = $app->run;
        } "reload doesn't die";
    };

    subtest "template" => sub {
        my @ret;

        warnings_like {
            @ret = $app->run_test( '/' );
        } [], "no warnings";

        is $ret[0], 200, 'request ok';
        like $ret[2], qr(<html></html>), 'template processed';
    };
};

done_testing;

__END__

@@ /js/foobar
let foo = "bar";

@@ index.html view=TT
<html></html>
