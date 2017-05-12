use strict;
use warnings;

use Test::More tests => 5;
use Test::Exception;
use File::Basename;


BEGIN { use_ok('Lingua::YALI::Builder') };
my $builder = Lingua::YALI::Builder->new(ngrams=>[2,3,4]);

open(my $fh_a, "<:bytes", dirname(__FILE__) . "/../Identifier/aaa01.txt") or croak $!;
is($builder->train_handle($fh_a), 332, "training on input");
close($fh_a);

is($builder->train_handle(undef), undef, "undef file handler");

dies_ok { $builder->train_handle("aaaaaaaaaaaa") } "not file handler";

#TODO: zjistit, jak kontrolovat filehandle otevreny pro zapis, kdyz z neho chci cist.
my $file = dirname(__FILE__) . "/write.txt";
open(my $fh_w, ">:bytes", $file) or croak $!;
is($builder->train_handle($fh_w), 0, "training on file handle opened for writing");
#dies_ok { $builder->train_handle($fh_w) } "training on file handle opened for writing";
close($fh_w);
`rm $file`;
