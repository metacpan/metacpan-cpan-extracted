use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output, ":encoding(utf8)";
binmode $builder->failure_output, ":encoding(utf8)";
binmode $builder->todo_output, ":encoding(utf8)";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Gzip::Libdeflate;
use File::Compare;

my $o = Gzip::Libdeflate->new ();
my $file = "$Bin/index.html";
my $out = $o->decompress_file (in => "$file.gz");
ok ($out);
if (-f $file) {
    unlink $file or die $!;
}
my $start = $o->decompress_file (in => "$file.gz", out => $file);
ok (-f $file);
my $rt = "$Bin/round-trip.gz";
$o->compress_file (in => $file, out => $rt);
ok (-f $rt, "Round trip file created");
unlink $file or die $!;
my $finish = $o->decompress_file (in => $rt);
unlink $rt or die $!;
is ($start, $finish, "Got the right thing");

done_testing ();
