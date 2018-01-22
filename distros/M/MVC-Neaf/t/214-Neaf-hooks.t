#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf;

# generate subs that append given constant to $trace
my $trace = '';
sub gen ($) { ## no critic # yes need proto in this helper sub
    my $id = shift;
    return sub {
        $_[0]->isa( "MVC::Neaf::Request" ) or die "No request in hook";
        $trace .= "$id,";
    };
};

# test route
MVC::Neaf->route( '/foo/bar/baz' => sub { +{} }, -view => 'JS' );

MVC::Neaf->add_hook( pre_route => gen 0.1 );
MVC::Neaf->add_hook( pre_route => gen 0.2, prepend => 1 );

# hooks which we're testing
MVC::Neaf->add_hook( pre_logic => gen 1.1 );
MVC::Neaf->add_hook( pre_logic => gen 1.2, path => '/foo' );
MVC::Neaf->add_hook( pre_logic => gen 1.3, path => '/foo' );
MVC::Neaf->add_hook( pre_logic => gen 1.4, path => '/foo', method => 'POST' );
MVC::Neaf->add_hook( pre_logic => gen 1.5, path => '/foo', exclude => '/foo/bar' );

MVC::Neaf->add_hook( pre_content => gen 2.1, path => '/foo/bar/baz' );

MVC::Neaf->add_hook( pre_render => gen 3.1 );
MVC::Neaf->add_hook( pre_render => gen 3.2, path => '/foo' );
MVC::Neaf->add_hook( pre_render => gen 3.3, path => '/foo', prepend => 1 );

MVC::Neaf->add_hook( pre_reply => gen 4.1, path => '/foo/bar////' );
MVC::Neaf->add_hook( pre_reply => gen 4.2, path => '/foo' );
MVC::Neaf->add_hook( pre_reply => gen 4.3, path => '/foo' );

MVC::Neaf->add_hook( pre_cleanup => gen 5.1, path => '/' );
MVC::Neaf->add_hook( pre_cleanup => gen 5.2, path => '/' );

# run it!
my ($status, $head, $content) = MVC::Neaf->run_test(
    { REQUEST_URI => '/foo/bar/baz' } );

is ($status, 200, "http ok");
is ($content, '{}', "content ok");

my $order = '0.2,0.1,1.1,1.2,1.3,2.1,3.1,3.3,3.2,4.1,4.3,4.2,5.2,5.1,';
is ($trace, $order, "Hooks come in order" );

$trace = '';
MVC::Neaf->run_test( { REQUEST_URI => '/foo/bar/baz' } );
is ($trace, $order, "Hooks not reinstalled" );

my $data = MVC::Neaf->get_routes;
note explain [values %$data]->[0]{GET};

done_testing;
