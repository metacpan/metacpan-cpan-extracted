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

is $des->tempfile(), undef, "uninitialized tempfile() returns undef with no params";

is
    ref $des->tempfile(File::Edit::Portable->new()->tempfile),
    'File::Temp',
    "with File::Edit::Portable::tempfile object sent in returns ok";

is
    ref $des->tempfile(),
    'File::Temp',
    "after File::Edit::Portable::tempfile object in place with no params returns ok";

done_testing;


