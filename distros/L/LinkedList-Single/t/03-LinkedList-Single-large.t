
use v5.12;

use Test::More;

use Scalar::Util    qw( blessed refaddr reftype weaken );

my $class   = 'LinkedList::Single';

# yes, this is abusive: it is intended to be.

my @passes  = ( 1 .. 16 );

plan tests => 1 + 2 * @passes;

use_ok $class;

my $handler = $class->can( 'DESTROY' );

for( @passes )
{
    my $size    = 2 ** $_;

    my $tmp     = $class->new( 1 .. $size );

    pass "Create: $_ ($size)";

    undef $tmp;

    pass "Destroy: $_ ($size)";
}

# this is not a module

0

__END__
