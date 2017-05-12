use strict;
use warnings FATAL => 'all';

package HTML::Tested::Test::DateTime;
use DateTime::Duration;
use DateTime;
use Data::Dumper;
use POSIX ();

sub now {
	my $class = shift;
	my $res = DateTime->now;
	$res->set_time_zone(POSIX::strftime('%z', localtime));
	my $self = bless { _dt => $res, _interval => (shift || 1) }, $class;
	return $self;
}

sub strftime {
	my $self = shift;
	my @res;
	for (my $i = 0; $i < $self->{_interval}; $i++) {
		my $d = $self->{_dt} + DateTime::Duration->new(seconds => $i);
		push @res, $d->strftime(@_);
	}
	return Dumper(\@res);
}

sub clone { return shift(); }
sub set_locale {
	my $self = shift;
	$self->{_dt}->set_locale(@_);
	return $self;
}

1;
