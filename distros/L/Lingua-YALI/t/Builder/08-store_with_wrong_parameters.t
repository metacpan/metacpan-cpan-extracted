use strict;
use warnings;

use Test::More tests => 15;
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

is($builder->train_file(dirname(__FILE__) . "/../Identifier/aaa01.txt"), 332, "training on input");

# =======

my $file = dirname(__FILE__) . "/tmp.xxx.gz";
dies_ok { $builder->store() } "All parametes are missing";
ok(! -f $file, "file $file was created");

`$rm_cmd`;
dies_ok { $builder->store(undef, 2, 2) } "File name is missing";

`$rm_cmd`;
dies_ok { $builder->store($file, 2, -1) } "Invalid count";
ok(! -f $file, "file $file was created");

`$rm_cmd`;
dies_ok { $builder->store($file, 2, 0) } "Invalid count";
ok(! -f $file, "file $file was created");

`$rm_cmd`;
is($builder->store($file, 2), 3, "Store all of them if count is not specified.");
ok(-f $file, "file $file was created");

`$rm_cmd`;
dies_ok { $builder->store($file, undef, 2) } "Invalid n-gram size";
ok(! -f $file, "file $file was created");

#my $wrong_file1 = "/etc/passwd";
#dies_ok { $builder->store($wrong_file1, 2, 2) } "File is not writeable";
#
#my $wrong_file2 = "/tmp/";
#dies_ok { $builder->store($wrong_file2, 2, 2) } "File is not writeable";


my $builder2 = Lingua::YALI::Builder->new(ngrams=>[2,3,4]);
`$rm_cmd`;
dies_ok { $builder2->store($file, 2) } "Storing model without any training";
ok( ! -f $file, "file $file was created");

`$rm_cmd`;

`$rm_cmd`;