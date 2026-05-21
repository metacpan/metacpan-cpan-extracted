use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use File::Raw::Separated qw(import);
use File::Raw qw(slurp);

# Same data parsed two ways - in-memory via file_tsv_parse_buf, on-disk via
# the 'tsv' plugin - must produce identical AoA. Confirms the plugin's
# READ phase shares the same parser core as the in-memory entry point.

my $data = "h1\th2\nv1\tv2\n";

my ($fh, $path) = tempfile(SUFFIX => '.tsv', UNLINK => 1);
print $fh $data;
close $fh;

my $via_buf    = file_tsv_parse_buf($data);
my $via_plugin = File::Raw::slurp($path, plugin => 'tsv');

is_deeply($via_plugin, $via_buf,
    "slurp(\$p, plugin => 'tsv') == file_tsv_parse_buf(bytes)")
    or diag(explain({ plugin => $via_plugin, buf => $via_buf }));

done_testing;
