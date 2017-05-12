use strict;
use Test::More;
use Test::Exception;
use IO::Slice;
use File::Basename qw< dirname >;
my $dirname = dirname(__FILE__);
my @specs = map { $_->{filename} = "$dirname/$_->{filename}"; $_ }
   @{ do "$dirname/testfile.specs" };

my $spec = $specs[0];
my $sfh = IO::Slice->new($spec);

my $expected = substr $spec->{contents}, 0, 3;
my $got = join '', map { getc $sfh } 1 .. 3;
is $got, $expected, 'some characters got from the input file';

my $object = tied *$sfh;
$object->ungetc() for 1 .. 3;
$got = join '', map { getc $sfh } 1 .. 3;
is $got, $expected, 'some characters got from the input file, after ungetc';

done_testing();
