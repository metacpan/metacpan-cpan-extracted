package Math::Calc::Euro;
use strict;
use Carp;

use vars '$VERSION';
$VERSION = 0.02;

my %rates = qw(	LUF 40.3399	ATS 13.76	BEF 40.3399
		NLG 2.20371	FIM 5.94574	FRF 6.55957
		DEM 1.94483	GRD 340.75	IEP 0.787564
		ITL 1936.27	PTE 200.482	ESP 166.386 );

sub new {
    my ($proto, $currency) = @_;
    my $rate = defined $currency && (
		   $rates{uc $currency} || 0 + $currency
	       ) ||
	       ( ref $proto eq __PACKAGE__ ?
	           $$proto
	       :
	           croak("Invalid currency")
	       );
    return bless \$rate, ref($proto) || $proto;
}

sub to_euro {
    my ($self, $amount) = @_;
    return $amount / $$self;
}

sub to_national {
    my ($self, $amount) = @_;
    return $amount * $$self;
}

sub from_euro { goto &to_national }
sub from_national { goto &to_euro }
sub clone { goto &new }
1;

__END__

=head1 NAME

Math::Calc::Euro - convert between EUR and the old currencies

=head1 SYNOPSIS

    my $guildercalc = Math::Calc::Euro->new('NLG')
    print $guildercalc->to_euro(1), "\n"; # 0.45378...
    print $guildercalc->from_national(1), "\n"; # same
    print $guildercalc->to_national(1), "\n"; # 2.20371
    print $guildercalc->from_euro(1), "\n"; # same

=head1 DESCRIPTION

The Math::Calc::Euro module provides for an object oriented
interface for converting to/from EUR.

=over 10

=item new / clone

Takes one argument: the currency. Either one of these:
LUF ATS BEF NLG FIM FRF DEM GRD IEP ITL PTE ESP
or a number indicating how much the national currency is worth
in euro's.
When used as an object method, it defaults to the object's rate.

=item to_euro / from_national

Returns the value in euro's.
Takes one argument: the amount of money.

=item to_national / from_euro

Returns the value in the old currency.
Takes one argument: the amount of euro's.

=back

=head1 KNOWN BUGS

None yet

=head1 AUTHOR

Juerd <juerd@juerd.nl>

=cut