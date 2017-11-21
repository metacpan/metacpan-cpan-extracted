#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
sub warns_like(&@); ## no critic

use MVC::Neaf::Request;

warns_like {
    my $req = MVC::Neaf::Request->new( path => '/foo/bar' );
    is $req->script_name, '/foo/bar', "script name defaulted to path";
} qr/NEAF.*script_name.*DEPRECATED/;

warns_like {
    my $req = MVC::Neaf::Request->new( path => '/foo/bar' );
    $req->set_full_path( "/foo", "/bar" );
    is $req->script_name, '/foo', "script name set correctly";
    is $req->path_info, 'bar', "path_info set correctly";
    is $req->path, '/foo/bar', "path preserved";
}qr/NEAF.*set_full_path.*DEPRECATED/, qr/NEAF.*script_name.*DEPRECATED/;

done_testing;

sub warns_like (&@) { ## no critic
    my ($code, @exp) = @_;

    my $n = scalar @exp;
    my @warn;
    local $SIG{__WARN__} = sub { push @warn, $_[0] };

    $code->();
    is scalar @warn, $n, "Exactly $n warnings issued";

    for (my $i = 0; $i < @exp; $i++) {
        like $warn[$i], $exp[$i], "Warning $i looks like $exp[$i]";
    };

    note "WARN: $_" for @warn;
};

