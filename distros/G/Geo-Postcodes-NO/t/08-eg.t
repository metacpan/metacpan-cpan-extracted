use strict;
use warnings;

use Test::More;
use FindBin qw($Bin);
use File::Spec;

my $root = File::Spec->rel2abs(File::Spec->catdir($Bin, '..'));
my $lib  = File::Spec->catdir($root, 'lib');
my $eg   = File::Spec->catdir($root, 'eg');

sub run {
    my @cmd = @_;
    my $pid = open(my $fh, '-|', @cmd);
    die "cannot run @cmd: $!" unless defined $pid;
    my $out = do { local $/; <$fh> };
    close $fh;
    return ($out // '');
}

my $out = run($^X, '-I', $lib, File::Spec->catfile($eg, 'basic.pl'), '1178');
like($out, qr/Postcode\s+1178/, 'basic.pl prints the postcode');
like($out, qr/Location\s+OSLO/, 'basic.pl prints the location');
like($out, qr/Type\s+ST/, 'basic.pl prints the type');
like(run($^X, '-I', $lib, File::Spec->catfile($eg, 'basic.pl'), '9999'),
    qr/'9999' not in use/, 'basic.pl flags an unused postcode');
like(run($^X, '-I', $lib, File::Spec->catfile($eg, 'basic.pl'), 'ABBA'),
    qr/'ABBA'/, 'basic.pl flags an illegal postcode');
like(run($^X, '-I', $lib, File::Spec->catfile($eg, 'basic.pl')),
    qr/Usage: basic\.pl/, 'basic.pl prints usage with no arguments');

$out = run($^X, '-I', $lib, File::Spec->catfile($eg, 'selection.pl'), 'county', 'OSLO');
like($out, qr/Postcode\s+Location/, 'selection.pl prints a header');
like($out, qr/^0001\s+OSLO\s+OSLO/m, 'selection.pl lists matching postcodes');
like(run($^X, '-I', $lib, File::Spec->catfile($eg, 'selection.pl'), 'bogus', 'X'),
    qr/Not a legal field 'bogus'/, 'selection.pl rejects an illegal field');
like(run($^X, '-I', $lib, File::Spec->catfile($eg, 'selection.pl')),
    qr/Usage: selection\.pl/, 'selection.pl prints usage with the wrong argument count');

$out = run($^X, '-I', $lib, File::Spec->catfile($eg, 'multiselection.pl'),
    'county', 'OSLO', 'and not', 'type', 'BX');
like($out, qr/Postcode\s+Location/, 'multiselection.pl prints a header');
like($out, qr/^0010\s+OSLO/m, 'multiselection.pl lists matching postcodes');
like(run($^X, '-I', $lib, File::Spec->catfile($eg, 'multiselection.pl')),
    qr/Usage:/, 'multiselection.pl prints usage with no arguments');

$out = run($^X, '-I', $lib, File::Spec->catfile($eg, 'advanced.pl'));
like($out, qr/first two digits are repeated/, 'advanced.pl prints the regex heading');
like($out, qr/\b0101\b/, 'advanced.pl matches 0101');
like($out, qr/\b9595\b/, 'advanced.pl matches 9595');
like($out, qr/addition of a procedure/, 'advanced.pl prints the procedure heading');

done_testing;