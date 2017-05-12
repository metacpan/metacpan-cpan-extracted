#!perl

use strict;
use warnings;

use Test::More;
use Test::Output;

use File::Temp;
use autodie;

require Enbld::Logger;

require_ok( 'Enbld::Message' );

stdout_is { Enbld::Message->notify( 'message' ) } '', 'quiet';

Enbld::Message->set_verbose;

my $dir = File::Temp->newdir;
Enbld::Logger->rotate( $dir );

stdout_is { Enbld::Message->notify( 'message' ) } "message\n", 'verbose';

open my $fh, '<', Enbld::Logger->logfile;
my $logfile = ( <$fh> );
close $fh;
is( $logfile, "message\n", 'logfile' );

stdout_is { Enbld::Message->notify( "message\n" ) } "message\n",
          'message with return code';

done_testing();

