use strict;
use warnings;

use Test2::V0;  no warnings 'void';
use lib 't/lib';
use File::Basename;
use TestHelper qw(db_continue);

require SampleCode;  # in t/lib
$DB::single=1;
11;

sub __tests__ {
    plan tests => 2;

    my $was_called = 0;
    TestHelper->postpone($INC{'Devel/Chitin.pm'},
                  sub { $was_called++ });
    is($was_called, 1, 'posponed() on an already loaded file fires immediately');

    my $pathname = File::Basename::dirname(__FILE__) . '/lib/SampleCode.pm';
    TestHelper->postpone($pathname,
                    sub {
                        my $got = shift;
                        is($got, $pathname, 'postponed() callback for SampleCode.pm');
                    });
    db_continue;
};
