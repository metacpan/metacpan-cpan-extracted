package Sample::Cache;

use strict;
use warnings;

our $VERSION = '0.01';

sub new {
	my ($class, %opts) = @_;
	return bless {
		store    => {},
		max_size => $opts{max_size} || 1000,
		ttl      => $opts{ttl} || 3600,
		hits     => 0,
		misses   => 0,
		order    => [],
		on_evict => $opts{on_evict} || sub {},
	}, $class;
}

sub get {
	my ($self, $key) = @_;

	if (exists $self->{store}{$key}) {
		my $entry = $self->{store}{$key};
		if (time() - $entry->{ts} > $self->{ttl}) {
			$self->_evict($key);
			$self->{misses}++;
			return undef;
		}
		$self->{hits}++;
		# Move to end of LRU
		$self->{order} = [
			grep { $_ ne $key } @{$self->{order}}
		];
		push @{$self->{order}}, $key;
		return $entry->{value};
	}

	$self->{misses}++;
	return undef;
}

sub set {
	my ($self, $key, $value) = @_;

	# Evict oldest if at capacity
	while (scalar @{$self->{order}} >= $self->{max_size}) {
		my $oldest = shift @{$self->{order}};
		$self->_evict($oldest) if defined $oldest;
	}

	$self->{store}{$key} = {
		value => $value,
		ts    => time(),
	};

	# Remove existing position and append
	$self->{order} = [
		grep { $_ ne $key } @{$self->{order}}
	];
	push @{$self->{order}}, $key;

	return $value;
}

sub delete {
	my ($self, $key) = @_;
	$self->_evict($key);
	return 1;
}

sub stats {
	my ($self) = @_;
	my $total = $self->{hits} + $self->{misses};
	return {
		hits      => $self->{hits},
		misses    => $self->{misses},
		hit_rate  => $total > 0 ? $self->{hits} / $total : 0,
		size      => scalar keys %{$self->{store}},
		max_size  => $self->{max_size},
	};
}

sub clear {
	my ($self) = @_;
	for my $key (keys %{$self->{store}}) {
		$self->{on_evict}->($key, $self->{store}{$key}{value});
	}
	$self->{store} = {};
	$self->{order} = [];
	$self->{hits}  = 0;
	$self->{misses} = 0;
	return 1;
}

sub _evict {
	my ($self, $key) = @_;
	return unless exists $self->{store}{$key};
	my $entry = delete $self->{store}{$key};
	$self->{order} = [
		grep { $_ ne $key } @{$self->{order}}
	];
	$self->{on_evict}->($key, $entry->{value});
}

sub compute {
	my ($self, $key, $generator) = @_;
	my $cached = $self->get($key);
	return $cached if defined $cached;

	my $value = $generator->();
	$self->set($key, $value);
	return $value;
}

my @VALID_OPTS = qw(max_size ttl on_evict serializer);

sub _validate_opts {
	my ($class, %opts) = @_;
	for my $k (keys %opts) {
		unless (grep { $_ eq $k } @VALID_OPTS) {
			warn "Unknown option: $k\n";
		}
	}
	return 1;
}

1;
