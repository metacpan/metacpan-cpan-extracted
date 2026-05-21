use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw::Separated;
use File::Raw qw(slurp);

# Explicit TSV plugin on a .tsv path.
my $rows = File::Raw::slurp('t/data/simple.tsv', plugin => 'tsv');
is_deeply($rows, [['a','b','c'], ['d','e','f']],
    "slurp(\$p, plugin => 'tsv') returns AoA");

# The plugin doesn't care about the path's extension.
# A .tab file parses identically.
my ($fh1, $tab) = tempfile(SUFFIX => '.tab', UNLINK => 1);
print $fh1 "p\tq\tr\n";
close $fh1;
is_deeply(File::Raw::slurp($tab, plugin => 'tsv'),
    [['p','q','r']],
    'tsv plugin works on a .tab path');

# A .txt file with tab content also parses - the plugin name selects
# the parser, not the extension.
my ($fh2, $txt) = tempfile(SUFFIX => '.txt', UNLINK => 1);
print $fh2 "x\ty\nz\tw\n";
close $fh2;
is_deeply(File::Raw::slurp($txt, plugin => 'tsv'),
    [['x','y'], ['z','w']],
    'tsv plugin works on a .txt path');

# An extensionless path also works.
my ($fh3, $bare) = tempfile(UNLINK => 1);
print $fh3 "1\t2\t3\n";
close $fh3;
is_deeply(File::Raw::slurp($bare, plugin => 'tsv'),
    [['1','2','3']],
    'tsv plugin works on a path with no extension');

# Without plugin =>, the .tsv file returns raw bytes.
my $bytes = File::Raw::slurp('t/data/simple.tsv');
ok(!ref($bytes),
    "slurp('foo.tsv') without plugin => is plain bytes (not AoA)");

done_testing;
