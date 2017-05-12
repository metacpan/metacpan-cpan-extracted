=encoding utf8

=cut

package Lingua::TH::Numbers;

use 5.008;
use strict;
use warnings;
use utf8;

use Carp;


=head1 NAME

Lingua::TH::Numbers - Convert and spell Thai numbers.


=head1 VERSION

Version 1.1.0

=cut

our $VERSION = '1.1.0';

# Digits from 1 to 9.
our $DIGITS =
{
	#      Thai   RTGS
	0 => [ "ศูนย์", 'sun',   ],
	1 => [ "หนึ่ง", 'nueng', ],
	2 => [ "สอง", 'song',  ],
	3 => [ "สาม", 'sam',   ],
	4 => [ "สี่",   'si',    ],
	5 => [ "ห้า",  'ha',    ],
	6 => [ "หก",  'hok',   ],
	7 => [ "เจ็ด", 'chet',  ],
	8 => [ "แปด", 'paet',  ],
	9 => [ "เก้า", 'kao',   ],
};

# Powers of 10, from 1 to 1 million. Numbers above one million are formed using
# numbers below one million as a multiplier for 'lan'.
our $POWERS_OF_TEN =
{
	#      Thai   RTGS
	0 => [ '',    ''      ], # 1
	1 => [ "สิบ",  'sip',  ], # 10
	2 => [ "ร้อย", 'roi',  ], # 100
	3 => [ "พัน",  'phan', ], # 1,000
	4 => [ "หมื่น", 'muen', ], # 10,000
	5 => [ "แสน", 'saen', ], # 100,000
	6 => [ "ล้าน", 'lan',  ], # 1,000,000
};

# Minus sign for negative numbers.
#                   Thai  RTGS
our $MINUS_SIGN = [ "ลบ", 'lop', ];

# The '20' part of numbers from 20 to 29 is an exception.
#                       Thai RTGS
our $TWO_FOR_TWENTY = [ "ยี่", 'yi', ];

# 11, 21, ..., 91 use 'et' instead of 'neung' for the trailing 1.
#                     Thai   RTGS
our $TRAILING_ONE = [ "เอ็ด", 'et', ];

# Decimal separator.
#                          Thai  RTGS
our $DECIMAL_SEPARATOR = [ "จุด", 'chut', ];

# Spelling output modes supported.
our $SPELLING_OUTPUT_MODES =
{
	# Name    Position in arrays of translations
	'thai' => 0,
	'rtgs' => 1,
};


=head1 SYNOPSIS

	use Lingua::TH::Numbers;

	# Input.
	my $ten = Lingua::TH::Numbers->new( '10' );
	my $sip = Lingua::TH::Numbers->new( '๑๐' );
	my $lop_sip = Lingua::TH::Numbers->new( '-๑๐' );
	my $three_point_one_four = Lingua::TH::Numbers->new( '3.14' );
	my $nueng_chut_sun_song = Lingua::TH::Numbers->new( '๑.๐๒' );

	# Output.
	print $ten->thai_numerals(), "\n";
	print $sip->arabic_numerals(), "\n";
	print $lop_sip->arabic_numerals(), "\n";
	print $three_point_one_four->thai_numerals(), "\n";
	print $nueng_chut_sun_song->arabic_numerals(), "\n";

	# Spell.
	print $three_point_one_four->spell(), "\n";
	print $three_point_one_four->spell( output_mode => 'thai' ), "\n";
	print $nueng_chut_sun_song->spell( output_mode => 'rtgs' ), "\n";
	print $nueng_chut_sun_song->spell( output_mode => 'rtgs', informal => 1 ), "\n";


=head1 METHODS

=head2 new()

Create a new Lingua::TH::Numbers object.

	my $ten = Lingua::TH::Numbers->new( '10' );
	my $sip = Lingua::TH::Numbers->new( '๑๐' );
	my $lop_sip = Lingua::TH::Numbers->new( '-๑๐' );
	my $three_point_one_four = Lingua::TH::Numbers->new( '3.14' );
	my $nueng_chut_sun_song = Lingua::TH::Numbers->new( '๑.๐๒' );

The input can use either Thai or Arabic numerals, but not both at the same time.

=cut

sub new
{
	my ( $class, $input ) = @_;

	# Required parameters.
	croak 'Input number is missing'
		unless defined( $input );

	# Find the type of the input.
	# Note: \d includes thai numbers with the utf8 pragma, so we can't use it here.
	my ( $arabic, $thai );
	if ( $input =~ m/^-?[0-9]+\.?[0-9]*$/ )
	{
		$arabic = $input;
	}
	elsif ( $input =~ m/^-?[\x{e50}-\x{e59}]+\.?[\x{e50}-\x{e59}]*$/ )
	{
		$thai = $input;
	}
	else
	{
		croak 'The input must use either Thai or Arabic numerals and be a number';
	}

	# Create the object.
	my $self = bless(
		{
			arabic => $arabic,
			thai   => $thai,
		},
		$class,
	);

	return $self;
}


=head2 thai_numerals()

Output the number stored in the object using thai numerals.

	my $ten = Lingua::TH::Numbers->new( '10' );
	print $ten->thai_numerals(), "\n";

=cut

sub thai_numerals
{
	my ( $self ) = @_;

	unless ( defined( $self->{'thai'} ) )
	{
		# Convert to Thai numerals.
		$self->{'thai'} = $self->{'arabic'};
		$self->{'thai'} =~ tr/0123456789/๐๑๒๓๔๕๖๗๘๙/;
	}

	return $self->{'thai'};
}


=head2 arabic_numerals()

Output the number stored in the object using arabic numerals.

	my $lop_sip = Lingua::TH::Numbers->new( '-๑๐' );
	print $lop_sip->arabic_numerals(), "\n";

=cut

sub arabic_numerals
{
	my ( $self ) = @_;

	unless ( defined( $self->{'arabic'} ) )
	{
		# Convert to Thai numerals.
		$self->{'arabic'} = $self->{'thai'};
		$self->{'arabic'} =~ tr/๐๑๒๓๔๕๖๗๘๙/0123456789/;
	}

	return $self->{'arabic'};
}


=head2 spell()

Spell the number stored in the object.

By default, spelling is done using Thai script, but the method also supports
the spelling of the Royal Thai General System with the parameter I<output_mode>
set to I<rtgs>.

This method also supports spelling shortcuts for informal language, using the
parameter I<informal>.

	# Spell using Thai script.
	print Lingua::TH::Numbers->new( '10' )->spell(), "\n";

	# Spell using the Royal Thai General System.
	print Lingua::TH::Numbers->new( '10' )->spell( output_mode => 'rtgs' ), "\n";

	# Spell using Thai script, with informal shortcuts.
	print Lingua::TH::Numbers->new( '10' )->spell( informal => 1 ), "\n";

	# Spell using the Royal Thai General System, with informal shortcuts.
	print Lingua::TH::Numbers->new( '10' )->spell( output_mode => 'rtgs', informal => 1 ), "\n";

=cut

sub spell
{
	my ( $self, %args ) = @_;
	my $informal = delete( $args{'informal'} );
	my $output_mode = delete( $args{'output_mode'} );

	# Check parameters.
	$output_mode = 'thai'
		unless defined( $output_mode );
	croak 'Output mode is not valid'
		unless defined( $SPELLING_OUTPUT_MODES->{ $output_mode } );
	$informal = 0
		unless defined( $informal );

	my $output_mode_index = $SPELLING_OUTPUT_MODES->{ $output_mode };

	# Parse the number.
	my $number = $self->arabic_numerals();
	my ( $sign, $integer, $decimals ) = $number =~ /^(-?)(\d+)\.?(\d*)$/;
	croak 'Can only spell numbers up to ( 10**13 - 1 )'
		if length( $integer ) > 13;

	# Put all the words in an array, as the word separator varies depending on the
	# output mode.
	my @spelling = ();

	# Convert the sign of the number.
	if ( defined( $sign ) && ( $sign eq '-' ) )
	{
		push( @spelling, $MINUS_SIGN->[ $output_mode_index ] );
	}

	# Convert the integer part of the number.
	if ( length( $integer ) > 7 )
	{
		my $millions;
		( $millions, $integer ) = $integer =~ /^(\d*)(\d{6})$/;

		push( @spelling, _spell_integer( $millions, $output_mode_index, $informal ) );
		push( @spelling, $POWERS_OF_TEN->{'6'}->[ $output_mode_index ] );
	}
	push( @spelling, _spell_integer( $integer, $output_mode_index, $informal ) );

	# Convert the decimal part of the number.
	if ( defined( $decimals ) && ( $decimals ne '' ) )
	{
		push( @spelling, $DECIMAL_SEPARATOR->[ $output_mode_index ] );
		foreach my $decimal ( split( //, $decimals ) )
		{
			push( @spelling, $DIGITS->{ $decimal }->[ $output_mode_index ] );
		}
	}

	# Join the words and return the final string.
	my $separator = $output_mode eq 'thai'
		? ''
		: ' ';
	return join( $separator, grep { $_ ne '' } @spelling );
}


=head1 INTERNAL FUNCTIONS

=head2 _spell_integer()

Spell the integer passed as parameter.

This internal function should not be used, as it is designed to handle a
sub-case of C<spell()> only in order to spell integers lesser than 10,000,000.

	my @spelling = Lingua::TH::Numbers::_spell_integer( 10, $output_mode_index, $is_informal );

=cut

sub _spell_integer
{
	my ( $integer, $output_mode_index, $is_informal ) = @_;
	my @spelling = ();

	croak 'Integer is too large for the internal function to spell'
		if length( $integer ) > 7;

	my @integer_digits  = reverse split( //, $integer );

	for ( my $power_of_ten = scalar( @integer_digits ) - 1; $power_of_ten >= 0; $power_of_ten-- )
	{
		my $digit = $integer_digits[ $power_of_ten ];

		# If there's no digit for this power of 10, skip it (except for 0 itself).
		next if $digit eq '0' && $integer ne '0';

		# 11, 21, ..., 91 use 'et' instead of 'neung' for the trailing 1.
		if ( $power_of_ten == 0 && $digit eq '1' && $integer ne '1' )
		{
			push( @spelling, $TRAILING_ONE->[ $output_mode_index ] );
			$power_of_ten = 0;
		}
		# 10 to 99 may have exceptions.
		elsif ( $power_of_ten == 1 )
		{
			if ( $digit eq '1' )
			{
				# Just 'sip', not 'neung sip'
			}
			elsif ( $digit eq '2' )
			{
				# 'yi' instead of 'song' of 20 to 29.
				push( @spelling, $TWO_FOR_TWENTY->[ $output_mode_index ] );
			}
			else
			{
				push( @spelling, $DIGITS->{ $digit }->[ $output_mode_index ] );
			}
			push( @spelling, $POWERS_OF_TEN->{ $power_of_ten }->[ $output_mode_index ] );
		}
		# For numbers >= 100, '1' is implicit.
		elsif ( $is_informal && $power_of_ten >= 2 && $digit eq '1' )
		{
			push( @spelling, $POWERS_OF_TEN->{ $power_of_ten }->[ $output_mode_index ] );
		}
		else
		# Normal rules apply.
		{
			push( @spelling, $DIGITS->{ $digit }->[ $output_mode_index ] );
			push( @spelling, $POWERS_OF_TEN->{ $power_of_ten }->[ $output_mode_index ] );
		}
	}

	return @spelling;
}


=head1 CAVEAT

There's too many Unicode issues in Perl 5.6 (in particular with tr/// which
this module uses) and Perl 5.6 is 10 year old at this point, so I decided to
make Perl 5.8 the minimum requirement for this module after a lot of time
spent jumping through pre-5.8 hoops.

If you really need this module and you are still using a version of Perl that
predates 5.8, please let me know although I would really encourage you to
upgrade.


=head1 BUGS

Please report any bugs or feature requests through the web interface at
L<https://github.com/guillaumeaubert/Lingua-TH-Numbers/issues/new>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc Lingua::TH::Numbers


You can also look for information at:

=over

=item * GitHub's request tracker

L<https://github.com/guillaumeaubert/Lingua-TH-Numbers/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/lingua-th-numbers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/lingua-th-numbers>

=item * MetaCPAN

L<https://metacpan.org/release/Lingua-TH-Numbers>

=back


=head1 AUTHOR

L<Guillaume Aubert|https://metacpan.org/author/AUBERTG>,
C<< <aubertg at cpan.org> >>.


=head1 COPYRIGHT & LICENSE

Copyright 2011-2017 Guillaume Aubert.

This code is free software; you can redistribute it and/or modify it under the
same terms as Perl 5 itself.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the LICENSE file for more details.

=cut

1;
