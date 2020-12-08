use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::More;
use File::Copy qw(copy);

BEGIN {
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new();

is $des->rw(), undef, "Uninitialized rw() returns undef with no params";

is
    ref $des->rw(File::Edit::Portable->new),
    'File::Edit::Portable',
    "rw() with File::Edit::Portable object sent in returns ok";

is
    ref $des->rw(),
    'File::Edit::Portable',
    "rw() after File::Edit::Portable object in place with no params returns ok";

done_testing;


