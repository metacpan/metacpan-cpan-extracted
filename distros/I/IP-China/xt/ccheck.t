use warnings;
use strict;
use utf8;
use FindBin '$Bin';
use Test::More;
use Deploy 'do_system';
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";
use Path::Tiny;
for my $cfile (qw/block-china-data.c ip-tools.c/) {
my $tempfile = Path::Tiny->tempfile ();
do_system ("ccheck $Bin/../$cfile > $tempfile 2>&1");
my @lines = $tempfile->lines ({chomp => 1});
ok (scalar (@lines) == 0, "no errors from ccheck");
if (@lines) {
for (@lines) {
note ($_);
}
}
$tempfile->remove ();
}
done_testing ();
