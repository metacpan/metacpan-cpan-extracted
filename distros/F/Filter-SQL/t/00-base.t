#! /usr/bin/perl

use strict;
use warnings;

BEGIN {
    # disable automatic connect
    delete $ENV{FILTER_SQL_DBI}
        if defined $ENV{FILTER_SQL_DBI};
};

use Test::More tests => 8;

use_ok('Filter::SQL');

is(Filter::SQL->dbh, undef);
is(Filter::SQL->dbh(1234), undef);
is(Filter::SQL->dbh, 1234);

my $r = 1234;
is(Filter::SQL->dbh(sub { $r++ }), undef);
is($r, 1234);
is(Filter::SQL->dbh(), 1234);
is($r, 1235);
