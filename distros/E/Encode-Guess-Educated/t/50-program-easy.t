
use strict;
use warnings;
use Test::More 0.94;

BEGIN {
    chdir '..' unless -d 't';
}

use Encode qw(:fallbacks encode decode);

my @data_files = glob("t/data/demos/*.*");

cmp_ok(scalar @data_files, ">", 0, "glob demo files")
    || BAIL_OUT("can't find any demo files");

my $perl = "perl -Iblib/lib";
my $prog = "blib/script/gank";

for my $file (@data_files) {
    my($ext) = $file =~ / \. ([^.]+) $/x;
    my $answer = `$perl $prog $file`;
    is($?, 0, "text exit status running $prog $file");
    chomp $answer;
    is($answer, $ext, "detected $file is in $ext");
}

done_testing();
