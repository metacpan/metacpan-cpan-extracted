package Lingua::NL::Numbers;

$VERSION = '1.3';

use strict;

my $numbers = {
	0	=>	'nul',
	1	=>	'een',
	2	=>	'twee',
	3	=>	'drie',
	4	=>	'vier',
	5	=>	'vijf',
	6	=>	'zes',
	7	=>	'zeven',
	8	=>	'acht',
	9	=>	'negen',
	10	=>	'tien',
	11	=>	'elf',
	12	=>	'twaalf',
	13	=>	'dertien',
	14	=>	'veertien',
	15	=>	'vijftien',
	16	=>	'zestien',
	17	=>	'zeventien',
	18	=>	'achtien',
	19	=>	'negentien',
	20	=>	'twintig',
	30	=>	'dertig',
	40	=>	'veertig',
	50	=>	'vijftig',
	60	=>	'zestig',
	70	=>	'zeventig',
	80	=>	'tachtig',
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
			unshift @{$ret_array}, $self->_formatLarge( $digits->[9], ' biljoen' );
		};

		# hundreds of millions
		if( defined($digits->[8]) && ($digits->[8] != 0) ) {
			if( ($digits->[7] == 0) && ($digits->[6] == 0) ) {
				unshift @{$ret_array}, $self->_formatLarge( $digits->[8], ' honderd miljard' );
			}
			else {
				unshift @{$ret_array}, $self->_formatLarge( $digits->[8], ' honderd' );
			};
		};

		# tens of millions
		if( defined($digits->[7]) && ($digits->[7] != 0) ) {
			my $temp = $self->_formatTens( $digits->[6], $digits->[7] );
			unshift @{$ret_array}, "$temp miljard";
		}
		elsif( defined($digits->[6]) && ($digits->[6] != 0) ) {
			unshift @{$ret_array}, $self->_formatLarge( $digits->[6], ' miljard' );
		};

		# hundreds of thousands
		if( defined($digits->[5]) && ($digits->[5] != 0) ) {
			if( ($digits->[4] == 0) && ($digits->[3] == 0) ) {
				unshift @{$ret_array}, $self->_formatLarge( $digits->[5], ' honderd duizend' );
			}
			else {
				unshift @{$ret_array}, $self->_formatLarge( $digits->[5], ' honderd' );
			};
		};

		# tens of thousands
		if( defined($digits->[4]) && ($digits->[4] != 0) ) {
			my $temp = $self->_formatTens( $digits->[3], $digits->[4] );
			unshift @{$ret_array}, "$temp duizend";
		}
		elsif( defined($digits->[3]) && ($digits->[3] == 1) ) {
			unshift @{$ret_array}, ' duizend';
		}
		elsif( defined($digits->[3]) && ($digits->[3] != 0) ) {
			unshift @{$ret_array}, $self->_formatLarge( $digits->[3], ' duizend' );
		};

		# hundreds
		if( defined($digits->[2]) && ($digits->[2] == 1) ) {
			unshift @{$ret_array}, 'honderd';
		}
		elsif( defined($digits->[2]) && ($digits->[2] != 0) ) {
			unshift @{$ret_array}, $self->_formatLarge( $digits->[2], 'honderd' );
		};

		# tens
		unshift @{$ret_array}, $self->_formatTens( $digits->[0], $digits->[1], 'en' );

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
			if( $ret_array->[$i] =~ /(miljard|duizend)/ ) {
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
	my $en = shift || ' en ';

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
	return( $numbers->{$units} . $en . $numbers->{$temp} );
};


sub _formatLarge
{
	my $self = shift;
	my $digit = shift;
	my $word = shift;

	my $ret = "$numbers->{$digit}$word";

	return( $ret );
};




1;

=pod

=head1 NAME

Lingua::NL::Numbers - Perl module for converting numeric values into their Dutch equivalents

    
=head1 DESCRIPTION

Initial release, documentation and updates will follow.

=head1 SYNOPSIS

  use Lingua::NL::Numbers;
    
  my $numbers = Lingua::NL::Numbers->new;

  my $text = $numbers->parse( 123 );

  # prints 'een honderd, drie en twintig'
  print $text;


=head1 KNOWN BUGS

None, but that does not mean there are not any.

=head1 AUTHOR

Alistair Francis, http://search.cpan.org/~friffin/

=cut

