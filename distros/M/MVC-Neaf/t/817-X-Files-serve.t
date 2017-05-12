#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Basename;

use MVC::Neaf qw(:sugar);
use MVC::Neaf::X::Files;

my $xfiles = MVC::Neaf::X::Files->new( root => dirname(__FILE__) );

get '/foo' => sub { $xfiles->serve_file( basename(__FILE__) ) };

my ($status, $head, $content) = neaf->run_test( '/foo' );

is $status, 200, "File found";
like $content, qr(^#!/usr/bin/env perl\n)s, "File really there";

done_testing;
