
use v5.24;

use Benchmark;
use Test::More;

use Scalar::Util    qw( blessed refaddr reftype weaken );

my $class   = 'LinkedList::Single';

# yes, this is abusive: it is intended to be.

my @passes  = ( 1 .. 20 );

plan tests => 1 + 2 * @passes;

use_ok $class;

my $handler = $class->can( 'DESTROY' );

for( @passes )
{
    my $size    = 2 ** $_;

    my $t0      = Benchmark->new;

    my $tmp     = eval { $class->new( 1 .. $size ) };

    my $t1      = Benchmark->new;

    $@
    ? fail "Create: $_ ($size), $$@"
    : pass "Create: $_ ($size)"
    ;

    eval { undef $tmp };

    my $t2      = Benchmark->new;

    $@
    ? fail "Destroy: $_ ($size), $$@"
    : pass "Destroy: $_ ($size)"
    ;

    note do
    {
        my $str0    = timestr timediff $t1, $t0;
        my $str1    = timestr timediff $t2, $t1;

        "Wallclock:\n Create:\t$str0\n Destroy:\t$str1.";
    };
}

# this is not a module

0

__END__
