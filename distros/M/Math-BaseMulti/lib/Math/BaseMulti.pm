package Math::BaseMulti;
# ABSTRACT: creating identifiers with a per digit base

use Moose;
our $VERSION = '1.01'; # VERSION

has 'digits' => (
	is => 'ro',
	traits => [ 'Array' ],
	isa => 'ArrayRef[ArrayRef[Str]]',
	required => 1,
	handles => {
		'_num_digits' => 'count',
	},
);

has '_reverse_digits' => (
	is => 'ro',
	isa => 'ArrayRef[HashRef]',
	lazy => 1,
	default => sub {
		my $self = shift;
		my @reverse;
		foreach my $digit ( @{$self->digits} ) {
			my %map;
			@map{@$digit} = (0..$#$digit);
			unshift(@reverse, \%map);
		}
		return(\@reverse);
	},
);

has '_base_list' => (
	is => 'ro',
	isa => 'ArrayRef[Int]',
	lazy => 1,
	default => sub {
		my $self = shift;
		my @b;
		foreach my $digits ( @{$self->digits} ) {
			push(@b, scalar(@$digits) );
		}
		return(\@b);
	},
);

has '_reverse_radix_list' => (
	is => 'ro',
	isa => 'ArrayRef[Int]',
	lazy => 1,
	default => sub {
		my $self = shift;
		my @r = reverse @{ $self->_radix_list };
		return( \@r );
	},
);

has '_radix_list' => (
	is => 'ro',
	isa => 'ArrayRef[Int]',
	traits => [ 'Array' ],
	lazy => 1,
	default => sub {
		my $self = shift;
		my @bases = @{$self->_base_list};
		my @r = (1);
		my $radix = 1;
		my $base;
		
		while( $base = pop(@bases) ) {
			$radix = $radix * $base;
			unshift(@r, $radix);
		}
		shift(@r);
		return( \@r );
	},
);

has 'leading_zero' => (
	is => 'rw',
	isa => 'Bool',
	default => 0,
);

sub to {
	my $self = shift;
	my $v = shift;
	my $str = '';
	my $left;
	my $cur;
	my $trailing = 0;

	for( my $i=0 ; $i < $self->_num_digits ; $i++ ) {
		my $r = $self->_radix_list->[$i];
		if( $v < $r ) {
			if( $trailing || $self->leading_zero ) {
				$str .= $self->digits->[$i]->[0];
			}
			next;
		}
		$trailing = 1;
		$cur = int( $v / $r );
		if( $cur > ($self->_base_list->[$i] - 1) ) {
			die('value is too big for conversion!');
		}
		$str .= $self->digits->[$i]->[$cur];
		$v = $v % $r;
	}

	return($str);
}

sub from {
	my $self = shift;
	my @str = reverse( split(//, shift) );
	my $int = 0;

	if( scalar(@str) > $self->_num_digits ) {
		die('string is too long for conversion!');
	}

	foreach my $i (0..$#str) {
		my $digit_value = $self->_reverse_digits->[$i]->{ $str[$i] };
		if( !defined $digit_value ) {
			die("character ".$str[$i]." is not a valid digit at position ".($i+1)." (from right)" );
		}
		$int += $self->_reverse_digits->[$i]->{ $str[$i] } * $self->_reverse_radix_list->[$i];
	}
	return($int);
}

1;

__END__

=pod

=head1 NAME

Math::BaseMulti - a perl module for creating identifiers with a per digit base

=head1 SYNOPSIS

  use Math::BaseMulti;

  $mbm = Math::BaseMulti->new(
    digits => [
      [ 0..9, 'A'..'Z' ],
      [ 0..9, 'A'..'Z' ],
      [ 0..9, 'A'..'Z' ],
      [ 0..9 ],
    ],
  );

  $mbm->to( 10 ); # will return "10"
  $mbm->to( 1000 ); # will return "2S0"
  $mbm->from( 'BA0' ); # will return 133310

  --

  $mbm = Math::BaseMulti->new(
    digits => [
      [ 'S' ],
      [ 'N' ],
      [ 0..9,'A'..'F','H','J','K','M','N','P','R'..'Z' ],
      [ 0..9,'A'..'F','H','J','K','M','N','P','R'..'Z' ],
      [ 0..9,'A'..'F','H','J','K','M','N','P','R'..'Z' ],
      [ 0..9,'A'..'F','H','J','K','M','N','P','R'..'Z' ],
      [ 0..9,'A'..'F','H','J','K','M','N','P','R'..'Z' ],
      [ 'A'..'Z' ],
    ],
	leading_zero => 1,
  );

  $mbm->to( 0 ); # will return "SN00000A"
  $mbm->to( 1 ); # will return "SN00000B"
  $mbm->to( 1000 ); # will return "SN00017M"

=head1 DESCRIPTION

Math::BaseMulti can be used to create identifiers with a base defined per digit.

The module provides conversion to/from such identifiers.

=head1 METHODS

=head2 new()

Creates an object instance.

Accepts parameters 'digits' and 'leading_zero'. For description see methods below.

=head2 from()

Expects a string in the format of defined by the parameter 'digits' and
converts it to an Int value.

=head2 to()

Expects an Int value and converts it to a string in the format defined by the
'digits' parameter.

=head2 digits()

Accepts an array of arrays.

Each element in the the first array repersents a digit. From high to low. (Little-Endian)
Each subarray contains a list of possible characters. The value will be the index of the
character in this array. first element => 0, second element => 1, ...

=head2 leading_zero()

Defines if to() should always add padding zeros values.

=head1 DEPENDENCIES

Math::BaseMulti requires Moose.

=head1 COPYRIGHT AND LICENSE

Copyright 2012-2013 by Markus Benning

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

