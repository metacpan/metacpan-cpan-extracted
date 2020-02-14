use Test::Most;
use Test::Warnings;

use Hash::Util::Merge qw/ mergemap /;

my %a = ( a => 10, b => 15 );
my %b = ( a => 1,  b => 5 );
my %c = ( b => 4 );

{
    my $c = mergemap { $a + $b } \%a, \%b;
    is_deeply $c, { a => 11, b => 20 }, 'mergemap';
}

{
    my $c = mergemap { $a - $b } \%a, \%b;
    is_deeply $c, { a => 9, b => 10 }, 'mergemap';
}

{
    my $c = mergemap { $a + ($b // 1) } \%a, \%c;
    is_deeply $c, { a => 11, b => 19 }, 'mergemap (undef)';
}

{
    my $c = mergemap { $a // $b } \%c, \%a;
    is_deeply $c, { a => $a{a}, b => $c{b} }, 'mergemap (undef)';
}

done_testing;

