use strict;
use warnings;
use Test::More;
use File::Raw::Separated;        # registers the 'csv' + 'tsv' plugins
use File::Raw qw(slurp);

# Explicit plugin dispatch returns AoA.
my $rows = File::Raw::slurp('t/data/simple.csv', plugin => 'csv');
is_deeply($rows, [['a','b','c'], ['d','e','f']],
    "slurp(\$p, plugin => 'csv') returns AoA");

# Quoted CSV with embedded comma + doubled-quote.
my $quoted = File::Raw::slurp('t/data/quoted.csv', plugin => 'csv');
is_deeply($quoted, [['a,b', 'c"d', 'e']],
    'RFC 4180 quoted-comma + doubled-quote');

# Multiline quoted field.
my $ml = File::Raw::slurp('t/data/multiline.csv', plugin => 'csv');
is_deeply($ml, [["line1\nline2", 'x']],
    'embedded newline preserved inside quoted field');

# Crucial contract: WITHOUT plugin =>, slurp returns raw bytes regardless
# of the file extension. The old auto-by-extension hook is gone.
my $no_plugin = File::Raw::slurp('t/data/simple.csv');
ok(!ref($no_plugin),
    "slurp('foo.csv') without plugin => is plain bytes (not AoA)");
like($no_plugin, qr/\Aa,b,c\nd,e,f\n\z/,
    'bytes are exactly the file contents');

# Same for .txt.
my $txt = File::Raw::slurp('t/data/plain.txt');
ok(!ref($txt), '.txt path returns bytes');
like($txt, qr/just text/, '.txt content unchanged');

done_testing;
