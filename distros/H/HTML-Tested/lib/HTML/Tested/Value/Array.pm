use strict;
use warnings FATAL => 'all';

package HTML::Tested::Value::Array;
use base 'HTML::Tested::Value';
use Carp;

sub new {
	my $self = shift()->SUPER::new(@_);
	my $opts = $self->options;
	while (my ($n, $v) = each %$opts) {
		next unless ref($v) eq 'HASH';
		my $dto = $v->{is_datetime} or next;
		$self->setup_datetime_option($dto, $v);
	}
	return $self;
}

sub transform_value {
	my ($self, $caller, $val, $n) = @_;
	confess "Invalid non-array value: seal_value"
		unless $val && ref($val) eq 'ARRAY';
	my $opts = $self->options;
	my @res;
	for (my $i = 0; $i < @$val; $i++) {
		my $nopts = $opts->{$i};
		$self->{_options} = $nopts if $nopts;
		my $v = $val->[$i];
		my $dtfs = $caller->ht_get_widget_option($n, "is_datetime");
		$v = $dtfs->format_datetime($v) if ($v && $dtfs);
		$v = $self->seal_value($v, $caller)
			if $caller->ht_get_widget_option($n, "is_sealed");
		$v = $self->encode_value($v, $caller)
			if !($caller->ht_get_widget_option($n, "is_trusted"));
		push @res, $v;
		$self->{_options} = $opts if $nopts;
	}
	return \@res;
}

sub seal_value {
	my ($self, $val, $caller) = @_;
	return $self->options->{isnt_sealed} ? $val
			: $self->SUPER::seal_value($val, $caller);
}

1;
