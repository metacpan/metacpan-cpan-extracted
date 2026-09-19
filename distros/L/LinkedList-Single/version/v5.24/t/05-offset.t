
use v5.12;

use Test::More;

my $class   = 'LinkedList::Single';

my @valz    = ( 1 .. 10 );

my @offsetz = ( 0, 3, 2, 4 );

plan tests => 1 + @offsetz;

use_ok $class;

my $listh   = $class->new( @valz );

my @found
= map
{
    $listh  += $_;

    $listh->node_data;
}
@offsetz;

print join "\n\t", "\nFound:", @found, "\n";

my $j   = 0;

for my $i ( 0 .. $#offsetz )
{
    $j  += $offsetz[$i];

    my $found   = $found[$i];
    my $expect  = $valz[$j];

    ok $expect == $found, "Found $i: $found ($expect)";
}

# this is not a module

0

__END__
