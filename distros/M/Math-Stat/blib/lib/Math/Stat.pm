package Math::Stat;

use strict;
use warnings;
use vars qw( @ISA @EXPORT_OK );

require Exporter;
use AutoLoader qw(AUTOLOAD);

our @ISA = qw( Exporter );

our $VERSION = '0.01';

=pod

=head1 NAME

Math::Stat - Perform Sample Statistics on Arrays

=head1 SYNOPSYS

=over 4

use Math::Stat;

my $stat = Math::Stat->new(\@data, { Autoclean => 1 });

$stat->median();	# returns median of data points in data

$stat->average();

$stat->stddev();

$stat->skewness();

$stat->kurtosis();

$stat->moment($N);

=back

=cut

sub new {
 	my($self, $data_ref) = @_;
	my $class = ref($self) || $self;
	my %struct;
	my $nobj = bless \%struct, $class;
	$nobj->{'Data'} = $data_ref;
	$nobj->{'DataCT'} = scalar(@{$data_ref});
	$nobj;
}

sub average {
	my $self = shift;
	return 0 unless $self->{'DataCT'};
	my $sum = 0;
	for my $el (@{$self->{'Data'}}) {
		$sum += $el;
	}
	return $sum/$self->{'DataCT'};
}

sub median {
	my $self = shift;
	my @sorted = sort {$a <=> $b} @{$self->{'Data'}};
	return 0 unless scalar(@sorted);
	return $sorted[int(scalar(@sorted)/2)];
}

sub variance {
	my $self = shift;
	return $self->moment(2);
}

sub stddev {
	my $self = shift;
	return sqrt($self->variance());
}

sub skewness {
	my $self = shift;
	return $self->moment(3)/($self->moment(2)**1.5);
}

sub kurtosis {
	my $self = shift;
	return $self->moment(4)/($self->moment(2)**2) - 3;
}

sub moment {
	my $self = shift;
	my $moment = shift;
	my @array = @_;
        return 0 unless $self->{'DataCT'} > ($moment - 1);
	my $avg = $self->average();
	my $l3 = 0;
	for my $e (@{$self->{'Data'}}) {
		$l3 += ($e - $avg) ** $moment;
	}
	return $l3/(scalar(@{$self->{'Data'}}) - 1);
}

sub _min {
	my ($a, $b) = @_;
	return ($a < $b)?$a:$b;
}

sub _max {
	my ($a, $b) = @_;
        return ($a > $b)?$a:$b;
}

sub min {
	my $self = shift;
	my $min;
	my $seen = 0; 
	foreach my $el (@{$self->{'Data'}}) {
		if($seen) {
			$min  = _min($min, $el);
		}
		else {
			$min = $el;
			$seen = 1;
		}
	}
	return $min;
}
		
sub max {
	my $self = shift;
	my $max;
	my $seen = 0; 
	foreach my $el (@{$self->{'Data'}}) {
		print "$el\n";
		if($seen) {
			$max  = _max($max, $el);
		}
		else {
			$max = $el;
			$seen = 1;
		}
		print "$max\n";
	}
	return $max;
}
1;

=pod

=head1 AUTHOR

George Schlossnagle <george@omniti.com>

=cut

__END__
