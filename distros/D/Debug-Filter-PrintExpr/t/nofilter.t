#!perl -T
use strict;
use warnings;
no warnings qw(void numeric);
use utf8;

use Debug::Filter::PrintExpr {nofilter => 1};
use Test2::V0;
use IO::String;
use Scalar::Util qw/dualvar/;

# get the filehandle ref into our namespace and close it
our $handle;
*handle = *Debug::Filter::PrintExpr::handle;
close $handle;


# capture debug output into $result
my $result = '';
$handle = IO::String->new($result);
#${custom:}
is $result, '', 'filter disabled';

done_testing;
