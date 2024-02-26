use strict;
use warnings;

use Expect;
my $e = Expect->new;

$e->spawn($^X, "examples/calc.pl") or die;

$e->log_stdout(0);
$e->raw_pty(1);
$e->send("19+23\n");
$e->expect(1, "19+23");
print 'Match: <', $e->match, ">\n";
print 'Before: <', $e->before, ">\n";
print 'After: <', $e->after, ">\n";
$e->clear_accum;

$e->expect(1, '-re' => qr/'\d+'/);
print 'Match: <', $e->match, ">\n";
print 'Before: <', $e->before, ">\n";
print 'After: <', $e->after, ">\n";
$e->close;

