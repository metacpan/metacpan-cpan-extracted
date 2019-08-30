use strict;
use warnings;
use Test::More;

# exercise some corner cases around our choice of the end-of-line
# character sequence

use_ok('Forks::Queue::File');

unlink 't/q10';
ok(-d 't', 'queue directory exists');
ok(! -f 't/q10', 'queue file does not exist yet');

########

my $q = Forks::Queue::File->new( file => 't/q10', style => 'fifo' );

ok($q, 'got queue object');
ok(ref($q) eq 'Forks::Queue::File', 'has correct object type');
ok(-f 't/q10', 'queue file created');
ok(-s 't/q10' > 1024, 'queue header section created');

my $EOL = Forks::Queue::File::EOL();

$q->put( $EOL . "abc" );
$q->put($EOL);
$q->put( "def" . $EOL );
ok($q->get eq $EOL . "abc");
ok($q->get eq $EOL);
ok($q->get eq "def" . $EOL);

#####

done_testing;
