use Forks::Super ':test';
use Test::More tests => 5;
use strict;
use warnings;

my $job = fork {
    sub => sub {
        $|=1;
	while (my $x = <STDIN>) {

	    # child doesn't really have a way of knowing when the
	    # parent has stopped writing input to "STDIN", so we
	    # must use a "convention" about when the input stream
	    # has run dry.
	    last if $x eq "EOF\n";

	    print $x*$x+3,"\n";
	}
    },
    child_fh => 'in,out,block'
};

sleep 5;
my $z = $job->write_stdin("14\n");
ok($z, 'write to child STDIN');

my $y = $job->read_stdout();
ok($y eq "199\n", 'child STDIN read after delay');

$z = $job->write_stdin("10\n");
ok($z, '2nd write to child STDIN');

$y = $job->read_stdout();
ok($y eq "103\n", '2nd child STDIN read after delay');

$job->write_stdin("EOF\n");
$job->close_fh('stdin');
$y = $job->read_stdout();
ok(!$y, 'no output after passing EOF');



