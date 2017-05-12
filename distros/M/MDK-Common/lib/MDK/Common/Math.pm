package MDK::Common::Math;

=head1 NAME

MDK::Common::Math - miscellaneous math functions

=head1 SYNOPSIS

    use MDK::Common::Math qw(:all);

=head1 EXPORTS

=over

=item $PI

the well-known constant 

=item even(INT)

=item odd(INT)

is the number even or odd?

=item sqr(FLOAT)

C<sqr(3)> gives C<9>

=item sign(FLOAT)

returns a value in { -1, 0, 1 }

=item round(FLOAT)

C<round(1.2)> gives C<1>, C<round(1.6)> gives C<2>

=item round_up(FLOAT, INT)

returns the number rounded up to the modulo:
C<round_up(11,10)> gives C<20>

=item round_down(FLOAT, INT)

returns the number rounded down to the modulo:
C<round_down(11,10)> gives C<10>

=item divide(INT, INT)

integer division (which is lacking in perl). In array context, also returns the remainder:
C<($a, $b) = divide(10,3)> gives C<$a is 3> and C<$b is 1>

=item min(LIST)

=item max(LIST)

returns the minimum/maximum number in the list

=item or_(LIST)

is there a true value in the list?

=item and_(LIST)

are all values true in the list?

=item sum(LIST)

=item product(LIST)

returns the sum/product of all the element in the list

=item factorial(INT)

C<factorial(4)> gives C<24> (4*3*2)

=back

=head1 OTHER

the following functions are provided, but not exported:

=over

=item factorize(INT)

C<factorize(40)> gives C<([2,3], [5,1])> as S<40 = 2^3 + 5^1>

=item decimal2fraction(FLOAT)

C<decimal2fraction(1.3333333333)> gives C<(4, 3)> 
($PRECISION is used to decide which precision to use)

=item poly2(a,b,c)

Solves the a*x2+b*x+c=0 polynomial:
C<poly2(1,0,-1)> gives C<(1, -1)>

=item permutations(n,p)

A(n,p)

=item combinaisons(n,p)

C(n,p)

=back

=head1 SEE ALSO

L<MDK::Common>

=cut


use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw($PI even odd sqr sign round round_up round_down divide min max or_ and_ sum product factorial);
our %EXPORT_TAGS = (all => [ @EXPORT_OK ]);


our $PRECISION = 10;
our $PI = 3.1415926535897932384626433832795028841972;

sub even { $_[0] % 2 == 0 }
sub odd  { $_[0] % 2 == 1 }
sub sqr  { $_[0] * $_[0] }
sub sign { $_[0] <=> 0 }
sub round { int($_[0] + 0.5) }
sub round_up { my ($i, $r) = @_; $r ||= 1; $i = int $i; $i += $r - ($i + $r - 1) % $r - 1 }
sub round_down { my ($i, $r) = @_; $r ||= 1; $i = int $i; $i -= $i % $r }
sub divide { my $d = int $_[0] / $_[1]; wantarray() ? ($d, $_[0] % $_[1]) : $d }
sub min  { my $n = shift; $_ < $n and $n = $_ foreach @_; $n }
sub max  { my $n = shift; $_ > $n and $n = $_ foreach @_; $n }
sub or_  { my $n = 0; $n ||= $_ foreach @_; $n }
sub and_ { my $n = 1; $n &&= $_ foreach @_; $n }
sub sum  { my $n = 0; $n  += $_ foreach @_; $n }
sub product { my $n = 1; $n  *= $_ foreach @_; $n }


sub factorize {
    my ($n) = @_;
    my @r;

    $n == 1 and return [ 1, 1 ];
    for (my $k = 2; sqr($k) <= $n; $k++) {
	my $i = 0;
	for ($i = 0; $n % $k == 0; $i++) { $n /= $k }
	$i and push @r, [ $k, $i ];
    }
    $n > 1 and push @r, [ $n, 1 ];
    @r;
}

sub decimal2fraction { # ex: 1.33333333 -> (4, 3)
    my $n0 = shift;
    my $precision = 10 ** -(shift || $PRECISION);
    my ($a, $b) = (int $n0, 1);
    my ($c, $d) = (1, 0);
    my $n = $n0 - int $n0;
    my $k;
    until (abs($n0 - $a / $c) < $precision) {
	$n = 1 / $n;
	$k = int $n;
	($a, $b) = ($a * $k + $b, $a);
	($c, $d) = ($c * $k + $d, $c);
	$n -= $k;
    }
    ($a, $c);
}

sub poly2 {
    my ($a, $b, $c) = @_;
    my $d = ($b**2 - 4 * $a * $c) ** 0.5;  
    (-$b + $d) / 2 / $a, (-$b - $d) / 2 / $a;
}

# A(n,p)
sub permutations {
    my ($n, $p) = @_;
    my ($r, $i);
    for ($r = 1, $i = 0; $i < $p; $i++) {
	$r *= $n - $i;
    }
    $r;
}

# C(n,p)
sub combinaisons {
    my ($n, $p) = @_;

    permutations($n, $p) / factorial($p);
}

sub factorial { permutations($_[0], $_[0]) }


1;
