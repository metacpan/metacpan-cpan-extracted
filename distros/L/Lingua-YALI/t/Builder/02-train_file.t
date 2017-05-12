use strict;
use warnings;

use Test::More tests => 4;
use Test::Exception;
use File::Basename;


BEGIN { use_ok('Lingua::YALI::Builder') };
my $builder = Lingua::YALI::Builder->new(ngrams=>[2,3,4]);

is($builder->train_file(dirname(__FILE__) . "/../Identifier/aaa01.txt"), 332, "training on input");

is($builder->train_file(undef), undef, "undef file name");
dies_ok { $builder->train_file("___nonexisting_file___") } "training on unexisting file";


