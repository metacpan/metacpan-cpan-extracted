use warnings;
use strict;

use Data::Dumper;
use Test::More;
use Test::More;
use File::Copy qw(copy);

BEGIN {
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

$ENV{ISSUE_31_TEST} = 1;

my $file = 't/test/sample.pm';

my $des = Devel::Examine::Subs->new();

$des->_read_file({file => $file});

is -f $des->tempfile()->filename, undef, "temp file unlinked ok";

done_testing;


