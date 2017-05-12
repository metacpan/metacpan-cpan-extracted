#!perl

use strict;
use warnings;

use Test::More;

use File::Temp;
use autodie;

require_ok( 'Enbld::Logger' );

my $temp = File::Temp->newdir;

Enbld::Logger->rotate( $temp );
Enbld::Logger->write( 'first message to logger' );

open my $fh_first, '<', Enbld::Logger->logfile();
my $log_first = ( <$fh_first> );
close $fh_first;

is( $log_first, 'first message to logger', 'write first tracelog' );

Enbld::Logger->rotate( $temp );
Enbld::Logger->write( 'second message to logger' );

open my $fh_second, '<', Enbld::Logger->logfile();
my $log_second = ( <$fh_second> );
close $fh_second;

is( $log_second, 'second message to logger', 'write second tracelog' );

done_testing();
