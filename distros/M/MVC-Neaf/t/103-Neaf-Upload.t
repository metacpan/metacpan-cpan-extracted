#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

use MVC::Neaf::Upload;

my $up = MVC::Neaf::Upload->new( id => "foo", tempfile => __FILE__ );

like( $up->content, qr(^#!/usr/bin), "Content loaded" );
cmp_ok( $up->size, ">", 0, "Size positive" );

done_testing;
