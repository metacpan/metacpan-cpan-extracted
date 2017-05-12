#    $Id: 01-basic.t,v 1.10 2007-09-01 17:39:36 adam Exp $

use strict;
use Test::More tests => 4;

BEGIN { use_ok( 'Log::Trivial' ); }

is( $Log::Trivial::VERSION, '0.40', 'Version Check' );

my $logger = Log::Trivial->new;
ok( defined $logger, 'Object is defined' );
isa_ok( $logger, 'Log::Trivial',  'Oject/Class Check' );

exit;
