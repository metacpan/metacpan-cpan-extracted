use strict;
use warnings;
use Test::More tests => 1;
use File::Spec;

our $logfile;
BEGIN {
    $logfile = File::Spec->catfile( "t", "log.out" );
    $ENV{DEBUG}      = 1;
    $ENV{STDERR2LOG} = $logfile;
}

use Debug::STDERR;

for ( 1 .. 100 ) {
    if ( $_ % 2 ) {
        debug( "hello" => { data => $_ } );
    }
}

my $test = 0;
open(LOG, $logfile);
while(<LOG>){
    if ($_ =~ /'data' => (\d\d)/){
        $test += $1;
    }
}
close(LOG);

is($test, 2475, "dubug() and redirect STDERR OK");

unlink $logfile;