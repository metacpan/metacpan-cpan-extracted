package Mock::Cache::Memcached;

use strict;
use warnings;

my %CACHE;

sub new {
	return bless {}, $_[0];
}

sub get {
	my ($self, $key) = @_;
	my $cached = $CACHE{$key};
	if ($cached && $cached->{timeout} >= time) {
		return $cached->{value};
	}
	delete $CACHE{$key};
	return;
}

sub set {
	my ($self, $key, $value, $timeout) = @_;
	$CACHE{$key} = {
		timeout => time + $timeout,
		value   => $value,
	};
	return $value;
}

sub delete {
	my ($self, $key) = @_;
	delete $CACHE{$key};
	return;
}

sub flush_all {
	%CACHE = ();
	return;
}

1;
__END__
