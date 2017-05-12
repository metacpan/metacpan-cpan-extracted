
use strict;
use Test;

plan tests => 4 + 8 + 8 + 4 + 4 + 8 + 604 + 2;

use Games::RolePlay::MapGen::Tools qw(choice roll random irange range str_eval _group _tile);

# choice 4 {{{
my %h = ( 1=>1, 2=>2, 3=>3, 4=>4 );
#alarm 3; # in case it loops, which it shouldn't
while( my @k = keys %h ) {
    my $e = choice(@k);

    die "ran out of elements or something" if @k and not $e;

    ok($e, $h{$e});
    delete $h{$e};
}
# }}}
# roll 8 {{{
%h = ();
#alarm 3; # in case it loops, which it shouldn't
while( not( $h{1} and $h{2} and $h{3} and $h{4} and $h{5} and $h{6} and $h{7} and $h{8} ) ) {
    my $roll = roll(1, 8);

    redo if $h{$roll};

    $h{$roll} = 1;
    ok(1);
}
# }}}
# str_eval 8 + 4 + 4 + (2) {{{
%h = ();
#alarm 3; # in case it loops, which it shouldn't
while( not( $h{1} and $h{2} and $h{3} and $h{4} and $h{5} and $h{6} and $h{7} and $h{8} ) ) {
    my $roll = &str_eval("1d8");

    die "holy crap that's not defined!!" unless defined $roll;

    redo if $h{$roll};

    $h{$roll} = 1;
    ok(1);
}
%h = ();
#alarm 3; # in case it loops, which it shouldn't
while( not( $h{2} and $h{3} and $h{4} and $h{5} ) ) {
    my $roll = &str_eval("1d4+1");

    die "holy crap that's not defined!!" unless defined $roll;

    redo if $h{$roll};

    $h{$roll} = 1;
    ok(1);
}
%h = ();
#alarm 3; # in case it loops, which it shouldn't
while( not( $h{0} and $h{1} and $h{2} and $h{3} ) ) {
    my $roll = &str_eval("1d4-1");

    die "holy crap that's not defined!!" unless defined $roll;

    redo if $h{$roll};

    $h{$roll} = 1;
    ok(1);
}
ok( &str_eval("test failed"), undef );
ok( &str_eval(1073), 1073 );
# }}}
# random 8 {{{
%h = ();
#alarm 3; # in case it loops, which it shouldn't
while( not( $h{0} and $h{1} and $h{2} and $h{3} and $h{4} and $h{5} and $h{6} and $h{7} ) ) {
    my $roll = random( 8 );

    redo if $h{$roll};

    $h{$roll} = 1;
    ok(1);
}
# }}}
# range 604 {{{

#alarm 30; # this is far more than should be needed.
1 while sprintf('%0.4f', range(0, 7)) != "0.0"; ok( 1 );
1 while sprintf('%0.4f', range(0, 7)) != "7.0"; ok( 1 );

for(1..200) {
    my $num = range(37, 99);
    my $cor = range(370, 990, 1);
    my $neg = range(37, 99, -1);

    ok( $num >= 37 and $num <= 99 );
    ok( sprintf('%0.4f', $cor/10), sprintf('%0.4f', $num) );
    ok( sprintf('%0.4f', $neg),    sprintf('%0.4f', 99 - ($num-37)) );
}
# }}}

ok( ref(&_group) =~ m/::_group$/ );
ok( ref(&_tile)  =~ m/::_tile$/  );
