#! /usr/bin/perl

# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use Test::More ( 'tests' => 5 );

use strict;
use warnings;

use IPC::Pipeline;

eval { pipeline(); };
like( $@ => qr/^Not enough arguments/, 'pipeline() fails when no arguments are passed' );

eval { pipeline(undef); };
like( $@ => qr/^Not enough arguments/, 'pipeline() fails when only one argument is passed' );

eval { pipeline( undef, undef ); };
like( $@ => qr/^Not enough arguments/, 'pipeline() fails when only two arguments are passed' );

eval { pipeline( undef, undef, undef ); };
like( $@ => qr/^Not enough arguments/, 'pipeline() fails when only three arguments are passed' );

eval { pipeline( my ( $in, $out, $err ), 'foo' ); };
like( $@ => qr/^Filter passed is not a/, 'pipeline() fails when filter is not CODE or ARRAY' );
