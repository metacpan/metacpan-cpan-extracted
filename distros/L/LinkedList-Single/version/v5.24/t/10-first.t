
use v5.20;

use Test::More;
use Test::Deep;

my $class   = 'LinkedList::Single';

my @valz    = ( ( 0 ) x 255 , ( 1 ) x 3 );

use_ok $class;

my $listh   = $class->new( @valz );

if( $listh->head->first )
{
    pass "Located true value";
    note "Remaining struct:\n", explain $$listh;
}
else
{
    fail "First does not find the true value";
}

for( 1 .. 2 )
{
    ok $listh->first, "Found true value";
    note "Remaining struct:\n", explain $$listh;
}

ok ! defined $listh->first, "Found end of list";

done_testing;

# this is not a module

0

__END__
