#!perl
use 5.006;
use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok( 'Devel::Trace::Subs' ) || print "Bail out!\n";
}

use Devel::Trace::Subs qw(trace);

# check/set env
{
    my $store = Devel::Trace::Subs::_store();
    is (ref $store, 'HASH', 'without data, _store() returns an href');
}
{
    my $store = Devel::Trace::Subs::_store({a => 1});
    my $file = "DTS_" . join('_', ($$ x 3)) . ".dat";
    is (-z $file, '', "with data, _store() stores the data in the file");
}
