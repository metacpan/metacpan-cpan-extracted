#!/run/bin/perl

use lib qw{
	      lib
	   ../lib
	../../lib
};

use Devel::Comments;
use Test::More 'no_plan';

close *STDERR;
my $STDERR = q{};
open *STDERR, '>', \$STDERR;

my $count = 0;

LABEL:

while ($count < 100) {    ### while:===[%]   done (%)
    $count++;
}

use Data::Dumper 'Dumper';
warn Dumper [ $STDERR ];

like $STDERR, qr/while:\[0\]                  done \(0\)\r/
                                            => 'First iteration';

like $STDERR, qr/while:=\[2\]                 done \(2\)\r/ 
                                            => 'Second iteration';

like $STDERR, qr/while:==\[4\]                done \(4\)\r/ 
                                            => 'Third iteration';

like $STDERR, qr/while:===\[6\]               done \(6\)\r/ 
                                            => 'Fourth iteration';

like $STDERR, qr/while:====\[9\]              done \(9\)\r/ 
                                            => 'Fifth iteration';

like $STDERR, qr/while:=====\[14\]           done \(14\)\r/ 
                                            => 'Sixth iteration';
