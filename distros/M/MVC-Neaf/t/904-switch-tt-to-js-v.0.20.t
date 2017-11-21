#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
sub warns_like(&@); ## no critic

use MVC::Neaf;

{
    my $n = MVC::Neaf->new;
    $n->route( '/' => sub { +{ -template => \"Foo=[% foo %]", foo => 42 } } );

    warns_like {
        is $n->run_test('/'), "Foo=42", "content rendered";
    } qr/deprecated/i;
};

warns_like {
    my $n = MVC::Neaf->new;
    $n->route( '/' => sub { +{ foo => 42 } } );
    is $n->run_test('/'), '{"foo":42}', "content rendered as js";
}; # and no warnings


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

