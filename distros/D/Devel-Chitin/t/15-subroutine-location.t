use strict;
use warnings;

use Test2::V0;  no warnings 'void';
use lib 't/lib';
use TestHelper qw(do_test ok_subroutine_location);

sub foo {
    9;
}
sub Bar::bar {
    12;
}
package Bar;
sub baz {
    16;
}
eval qq(
    sub sub_in_eval {
        20;
    }
);
$DB::single=1;

package main;
sub __tests__ {
    plan tests => 5;

    do_test {
        is(TestHelper->subroutine_location('not::there'),
            undef,
            'subroutine_location() with non-existant sub returns undef');
    };
    ok_subroutine_location 'main::foo',
            package => 'main',
            subroutine => 'foo',
            filename => __FILE__,
            source => __FILE__,
            line => 8,
            source_line => 8,
            end => 10,
            code => \&main::foo;

    ok_subroutine_location 'Bar::bar',
            package => 'Bar',
            subroutine => 'bar',
            filename => __FILE__,
            source => __FILE__,
            line => 11,
            source_line => 11,
            end => 13,
            code => \&Bar::bar;

    ok_subroutine_location 'Bar::baz',
            package => 'Bar',
            subroutine => 'baz',
            filename => __FILE__,
            source => __FILE__,
            line => 15,
            source_line => 15,
            end => 17,
            code => \&Bar::baz;

    my $this_file = __FILE__;
    ok_subroutine_location 'Bar::sub_in_eval',
            package => 'Bar',
            subroutine => 'sub_in_eval',
            filename => qr{^\(eval \d+\)\[\Q$this_file\E:18\]$},
            source => __FILE__,
            line => 2,
            source_line => 18,
            end => 4,
            code => \&Bar::sub_in_eval;
}

