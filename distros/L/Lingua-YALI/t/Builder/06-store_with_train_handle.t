use strict;
use warnings;

use Test::More tests => 22;
use Test::Exception;
use File::Basename;
use Carp;

# http://od-eon.com/blogs/calvin/zcat-bug-mac-osx/
my $zcat_cmd = "zcat ";
if ( $^O eq "darwin" ) {
    $zcat_cmd = "gzcat ";
}

my $rm_cmd ="rm -f " . dirname(__FILE__) . "/tmp.*";
`$rm_cmd`;

BEGIN { use_ok('Lingua::YALI::Builder') };
my $builder = Lingua::YALI::Builder->new(ngrams=>[2,3,4]);

open(my $fh_a, "<:bytes", dirname(__FILE__) . "/../Identifier/aaa01.txt") or croak $!;

is($builder->train_handle($fh_a), 332, "training on input");

# =======

my $file1W20 = dirname(__FILE__) . "/tmp.1.20.txt.gz";
dies_ok { $builder->store($file1W20, 1, 20) } "asdadasd";
ok(! -f $file1W20, "file $file1W20 was created");

my $file1W2 = dirname(__FILE__) . "/tmp.1.2.txt.gz";
dies_ok { $builder->store($file1W2, 1, 2) } "asdadasd";
ok(! -f $file1W2, "file $file1W2 was created");

# =======

my $file2W20 = dirname(__FILE__) . "/tmp.2.20.txt.gz";
my $file2E20 = dirname(__FILE__) . "/sol.2.20.txt.gz";
$builder->store($file2W20, 2, 20);
ok(-f $file2W20, "file $file2W20 was not created");

my $cmd_diff220 = "bash -c 'diff <(" . $zcat_cmd . " $file2W20) <(" . $zcat_cmd . " $file2E20) | wc -l'";
my $line220 = int(`$cmd_diff220`);
is ( $line220, 0, "Created file $file2W20 is different from $file2E20");

my $file2W2 = dirname(__FILE__) . "/tmp.2.2.txt.gz";
my $file2E2 = dirname(__FILE__) . "/sol.2.2.txt.gz";
$builder->store($file2W2, 2, 2);
ok(-f $file2W2, "file $file2W2 was not created");

my $cmd_diff22 = "bash -c 'diff <(" . $zcat_cmd . " $file2W2) <(" . $zcat_cmd . " $file2E2) | wc -l'";
my $line22 = int(`$cmd_diff22`);
is ( $line22, 0, "Created file $file2W2 is different from $file2E2");

# ========

my $file3W20 = dirname(__FILE__) . "/tmp.3.20.txt.gz";
my $file3E20 = dirname(__FILE__) . "/sol.3.20.txt.gz";
$builder->store($file3W20, 3, 20);
ok(-f $file3W20, "file $file3W20 was not created");

my $cmd_diff320 = "bash -c 'diff <(" . $zcat_cmd . " $file3W20) <(" . $zcat_cmd . " $file3E20) | wc -l'";
my $line320 = int(`$cmd_diff320`);
is ( $line320, 0, "Created file $file3W20 is different from $file3E20");

my $file3W2 = dirname(__FILE__) . "/tmp.3.2.txt.gz";
my $file3E2 = dirname(__FILE__) . "/sol.3.2.txt.gz";
$builder->store($file3W2, 3, 2);
ok(-f $file3W2, "file $file3W2 was not created");

my $cmd_diff32 = "bash -c 'diff <(" . $zcat_cmd . " $file3W2) <(" . $zcat_cmd . " $file3E2) | wc -l'";
my $line32 = int(`$cmd_diff32`);
is ( $line32, 0, "Created file $file3W2 is different from $file3E2");

# ========

my $file4W20 = dirname(__FILE__) . "/tmp.4.20.txt.gz";
my $file4E20 = dirname(__FILE__) . "/sol.4.20.txt.gz";
$builder->store($file4W20, 4, 20);
ok(-f $file4W20, "file $file4W20 was not created");

my $cmd_diff420 = "bash -c 'diff <(" . $zcat_cmd . " $file4W20) <(" . $zcat_cmd . " $file4E20) | wc -l'";
my $line420 = int(`$cmd_diff420`);
is ( $line420, 0, "Created file $file4W20 is different from $file4E20");

my $file4W2 = dirname(__FILE__) . "/tmp.4.2.txt.gz";
my $file4E2 = dirname(__FILE__) . "/sol.4.2.txt.gz";
$builder->store($file4W2, 4, 2);
ok(-f $file4W2, "file $file4W2 was not created");

my $cmd_diff42 = "bash -c 'diff <(" . $zcat_cmd . " $file4W2) <(" . $zcat_cmd . " $file4E2) | wc -l'";
my $line42 = int(`$cmd_diff42`);
is ( $line42, 0, "Created file $file4W2 is different from $file4E2");

# =========

my $file5W20 = dirname(__FILE__) . "/tmp.5.20.txt.gz";
dies_ok { $builder->store($file5W20, 5, 20) } "asdadasd";
ok(! -f $file5W20, "file $file5W20 was created");

my $file5W2 = dirname(__FILE__) . "/tmp.5.2.txt.gz";
dies_ok { $builder->store($file5W2, 5, 2) } "asdadasd";
ok(! -f $file5W2, "file $file5W2 was created");

`$rm_cmd`;