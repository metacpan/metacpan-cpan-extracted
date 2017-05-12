package Lingua::AF::Numbers;

$VERSION = '1.2';

use strict;

my $numbers = {
	0	=>	'nul',
	1	=>	'een',
	2	=>	'twee',
	3	=>	'drie',
	4	=>	'vier',
	5	=>	'vyf',
	6	=>	'ses',
	7	=>	'sewe',
	8	=>	'agt',
	9	=>	'nege',
	10	=>	'tien',
	11	=>	'elf',
	12	=>	'twaalf',
	13	=>	'dertien',
	14	=>	'viertien',
	15	=>	'vyftien',
	16	=>	'sestien',
	17	=>	'sewentien',
	18	=>	'agtien',
	19	=>	'negentien',
	20	=>	'twintig',
	30	=>	'dertig',
	40	=>	'viertig',
	50	=>	'vyftig',
	60	=>	'sestig',
	70	=>	'sewentig',
	80	=>	'tagtig',
	90	=>	'negentig',
};

sub new
{
	my $class = shift;
	my $number = shift || '';

	my $self = {};
	bless $self, $class;

	if( $number =~ /\d+/ ) {
		return( $self->parse($number) );
	};

	return( $self );
};


sub parse 
{
	my $self = shift;
	my $number = shift;

	my $digits;
	my $ret = '';

	if( defined($numbers->{$number}) ) {
		$ret = $numbers->{$number};
	}
	else {
		my $ret_array = [];

		@{$digits} = reverse( split('', $number) );

		# tens of billions
		if( defined($digits->[10]) && ($digits->[10] != 0) ) {
			my $temp = $self->_formatTens( $digits->[9], $digits->[10] );
			unshift @{$ret_array}, "$temp biljoen";
		}
		elsif( defined($digits->[9]) && ($digits->[9] != 0) ) {
			unshift @{$ret_array}, $self->_formatLarge( $digits->[9], 'biljoen' );
		};

		# hundreds of millions
		if( defined($digits->[8]) && ($digits->[8] != 0) ) {
			if( ($digits->[7] == 0) && ($digits->[6] == 0) ) {
				unshift @{$ret_array}, $self->_formatLarge( $digits->[8], 'honderd miljoen' );
			}
			else {
				unshift @{$ret_array}, $self->_formatLarge( $digits->[8], 'honderd' );
			};
		};

		# tens of millions
		if( defined($digits->[7]) && ($digits->[7] != 0) ) {
			my $temp = $self->_formatTens( $digits->[6], $digits->[7] );
			unshift @{$ret_array}, "$temp miljoen";
		}
		elsif( defined($digits->[6]) && ($digits->[6] != 0) ) {
			unshift @{$ret_array}, $self->_formatLarge( $digits->[6], 'miljoen' );
		};

		# hundreds of thousands
		if( defined($digits->[5]) && ($digits->[5] != 0) ) {
			if( ($digits->[4] == 0) && ($digits->[3] == 0) ) {
				unshift @{$ret_array}, $self->_formatLarge( $digits->[5], 'honderd duisend' );
			}
			else {
				unshift @{$ret_array}, $self->_formatLarge( $digits->[5], 'honderd' );
			};
		};

		# tens of thousands
		if( defined($digits->[4]) && ($digits->[4] != 0) ) {
			my $temp = $self->_formatTens( $digits->[3], $digits->[4] );
			unshift @{$ret_array}, "$temp duisend";
		}
		elsif( defined($digits->[3]) && ($digits->[3] != 0) ) {
			unshift @{$ret_array}, $self->_formatLarge( $digits->[3], 'duisend' );
		};

		# hundreds
		if( defined($digits->[2]) && ($digits->[2] != 0) ) {
			unshift @{$ret_array}, $self->_formatLarge( $digits->[2], 'honderd' );
		};

		# tens
		unshift @{$ret_array}, $self->_formatTens( $digits->[0], $digits->[1] );

		$ret = $self->_sortReturn( $ret_array, $digits );

	};

	return( $ret );
};


sub _sortReturn
{
	my $self = shift;
	my $ret_array = shift;
	my $digits = shift;

	my $large_nums = 0;
	my $ret = '';

	my $size = @{$ret_array};

	if( $size == 1 ) {
		return( $ret_array->[0] );
	}
	elsif( $size > 1 ) {
		$large_nums = 1;
	};

	for( my $i = $size; $i > 0; $i-- ) {
		if( defined($ret_array->[$i]) ) {
			if( $ret_array->[$i] =~ /(miljoen|duisend)/ ) {
				$ret .= $ret_array->[$i] .', ';
			}
			else {
				$ret .= $ret_array->[$i] .' ';
			};
		};
	};

	if( ($digits->[0] == 0) && ($digits->[1] == 0) ) {
		# do nothing
	}
	elsif( ($digits->[0] == 0) || ($digits->[1] == 0) || ($digits->[1] == 1) ) {
		if( $large_nums ) {
			$ret .= ' en ';
		};
		$ret .= $ret_array->[0];
	}
	else {
		$ret .= ' '. $ret_array->[0];
	};

	$ret =~ s/(^ |\s{2,}| $)/ /g;

	return( $ret );
};


sub _formatTens
{
	my $self = shift;
	my $units = shift;
	my $tens = shift;

	# Both digits are zero
	unless( $units || $tens ) {
		return;
	};

	if( $tens == 0 ) {
		return( $numbers->{$units} );
	}
	elsif( ($tens == 1) || ($units == 0) ) {
		my $temp = $tens . $units;
		return( $numbers->{$temp} );
	};

	my $temp = $tens . 0;
	return( "$numbers->{$units} en $numbers->{$temp}" );
};


sub _formatLarge
{
	my $self = shift;
	my $digit = shift;
	my $word = shift;

	my $ret = "$numbers->{$digit} $word";

	return( $ret );
};




1;

=pod

=head1 NAME

Lingua::AF::Numbers - Perl module for converting numeric values into their Afrikaans equivalents

    
=head1 DESCRIPTION

Initial release, documentation and updates will follow.

=head1 SYNOPSIS

  use Lingua::AF::Numbers;
    
  my $numbers = Lingua::AF::Numbers->new;

  my $text = $numbers->parse( 123 );

  # prints 'een honderd, drie en twintig'
  print $text;


=head1 KNOWN BUGS

None, but that does not mean there are not any.

=head1 AUTHOR

Alistair Francis, http://search.cpan.org/~friffin/

=cut

