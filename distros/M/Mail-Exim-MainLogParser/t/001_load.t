# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'Mail::Exim::MainLogParser' ); }

my $object = Mail::Exim::MainLogParser->new ();
isa_ok ($object, 'Mail::Exim::MainLogParser');


