use strict;
use warnings;

use Test2::V0; no warnings 'void';
use lib 't/lib';
use TestHelper qw(ok_location db_continue do_test);

$DB::single = 1; 8;
foo();
sub foo {
    $DB::single = 1; 11;
    Bar::bar();
}
sub Bar::bar {
    $DB::single = 1; 15;
    Bar::baz();
}
package Bar;
sub baz {
    $DB::single = 1; 20;
}
my $subref; BEGIN { $subref = sub {
    $DB::single=1;
    24;
}; }
$subref->();

package main;
sub __tests__ {
    plan tests => 10;

    ok_location filename => __FILE__, line => 8, package => 'main', subroutine => 'MAIN', subref => undef;

    db_continue;
    ok_location filename => __FILE__, line => 11, package => 'main', subroutine => 'main::foo', subref => undef;

    db_continue;
    ok_location filename => __FILE__, line => 15, package => 'main', subroutine => 'Bar::bar', subref => undef;

    db_continue;
    ok_location filename => __FILE__, line => 20, package => 'Bar', subroutine => 'Bar::baz', subref => undef;

    do_test {
        my $loc = TestHelper->current_location;
        is($loc->filename, __FILE__, 'current location filename');
        is($loc->line, 20, 'current location line');
        is($loc->package, 'Bar', 'current location package');
        is($loc->subroutine, 'Bar::baz', 'current location subroutine');
        is($loc->subref, undef, 'subref is undef');
    };
    db_continue;

    ok_location filename => __FILE__, line => 24, package => 'Bar', subroutine => sprintf('Bar::__ANON__[%s:25]',__FILE__),
                subref => $subref;
}

