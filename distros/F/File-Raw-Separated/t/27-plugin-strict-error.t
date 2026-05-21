use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw::Separated;
use File::Raw qw(slurp);

# Malformed CSV: a stray quote mid-field. Lenient mode preserves it as
# data; strict mode croaks with byte-offset diagnostics.
my ($fh, $bad) = tempfile(SUFFIX => '.csv', UNLINK => 1);
print $fh qq(a"b,c\n);
close $fh;

# Default (lenient) - stray quote becomes part of the field.
my $lenient = File::Raw::slurp($bad, plugin => 'csv');
is_deeply($lenient, [['a"b', 'c']],
    'lenient mode: stray quote preserved as data');

# strict => 1 per call, no module-wide state to set.
my $rc = eval { File::Raw::slurp($bad, plugin => 'csv', strict => 1); 1 };
ok(!$rc, "strict => 1 croaks on malformed .csv");
like($@, qr/quot/i,        'error mentions quoting');
like($@, qr/byte offset/i, 'error includes byte offset');

# Each call is independent: a follow-up call without strict still parses.
my $again = File::Raw::slurp($bad, plugin => 'csv');
is_deeply($again, [['a"b', 'c']],
    'next call without strict parses leniently (no sticky state)');

done_testing;
