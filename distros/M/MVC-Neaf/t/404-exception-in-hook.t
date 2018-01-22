#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Warn;
use MVC::Neaf::Util qw(JSON encode_json decode_json);

use MVC::Neaf qw(:sugar);

my $file = __FILE__;
get '/foo' => sub { +{ foo => 'bar' } }; my $line = __LINE__;

neaf pre_render => sub { $_[0]->param( pre_render => 1 ) and die "RANDR" };
neaf pre_reply  => sub { $_[0]->param( pre_reply  => 1 ) and die "ORLY" };

my $content;
warnings_like {
    $content = neaf->run_test( '/foo?pre_render=1' );
} [qr/RANDR/], "Warning about pre-render";

my $ref = decode_json( $content );
is $ref->{error}, 500, "pre_render => error 500";

warnings_like {
    $content = neaf->run_test( '/foo?pre_reply=1' );
} [qr/ORLY/], "Warning about pre_reply";

is $content, '{"foo":"bar"}', "rendered anyway";

done_testing;
