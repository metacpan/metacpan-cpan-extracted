use strict;
use warnings;

use Test::More tests => 3;
use Test::Exception;
use File::Basename;


BEGIN { use_ok('Lingua::YALI::Builder') };
my $builder = Lingua::YALI::Builder->new(ngrams=>[2,3,4]);

open(my $fh_a, "<:bytes", dirname(__FILE__) . "/../Identifier/aaa01.txt") or croak $!;
my $a_string = "";
while ( <$fh_a> ) {
    $a_string .= $_;
}
is($builder->train_string($a_string), 332, "training on input");

is($builder->train_string(undef), undef, "training on undef");
