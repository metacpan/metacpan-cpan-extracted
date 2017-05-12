package Lingua::AM::Abbreviate;
require 5.000;
require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(
			Contract
			Expand
			);
$VERSION = '0.01';


%AbbreviatedAmharic 	=	(
	'ት/ቤት'		=>	'ትምህርት ቤት',
	'ጽ/ቤት'		=>	'ጽህፈት ቤት',
	'ም/ቤት'		=>	'ምክር ቤት',
	'መ/ቤት'		=>	'መሥሪያ ቤት',
	'ፍ/ቤት'		=>	'ፍርድ ቤት',

	'ሠ/ፌዴሬሽን'		=>	'ሠራተኛ ፌዴሬሽን',

	'ቤ/ክ'		=>	'ቤተክርስትያን',
	'ቤ/መ'		=>	'ቤተመንግስት',
	'መ/ቅ'		=>	'መጸሐፍ ቅዱስ',

	'ም/'		=>	'ምክትል',
	'ገ/'		=>	'ገብረ',
	'ወ/'		=>	'ወልደ',
	'ተ/'		=>	'ተክለ',  # ወይም ተስፋ
	'ኃ/'		=>	'ኃይለ',

	'ኮ/ል'		=>	'ኮለኔል',
	'ጄ/ል'		=>	'ጄኔራል',
	'ሻ/'		=>	'ሻምበል',

	'ወ/ሮ'		=>	'ወይዘሮ',
	'ወ/ሪት'		=>	'ወይዘሪት',
	'ሚ/ር'		=>	'ሚስተር',
	'ሚ/ስ'		=>	'ሚስስ',
	'ፕ/ር'		=>	'ፕሮፌሰር',

	'ፕ/ት'		=>	'ፕሬዚዳንት',
	'ጠ/ሚ'		=>	'ጠቅላይ ሚኒስትር',
	'ጠ/ሚኒስትር'		=>	'ጠቅላይ ሚኒስትር',
	'ጠ/ሚ/ቢሮ'		=>	'ጠቅላይ ሚኒስትር ቢሮ',
	'ሚ/ሩ'		=>	'ሚኒስትሩ',

	'ዓ/ም'		=>	'ዓመተ ምህረት',
	'ዓ/ዓ'		=>	'ዓመተ ዓለም',
	'አ/አ'		=>	'አዲስ አባባ',

	'ዶ/ር'		=>	'ዶክተር',
	'ሆ/ል'		=>	'ሆስፒታል'
);


sub Expand
{
local ($term) = $_[0];

	if ( $AbbreviatedAmharic{$term} ) {
		return ( $AbbreviatedAmharic{$term} );
	} else {
		$prefix = $term =~ s/^([ለበከየ])//;
		if ( $AbbreviatedAmharic{$term} ) {
			return ( "$prefix$AbbreviatedAmharic{$term}" );
		} else {
			$term = $_[0];
			($prefix, $term) = split ( /\//, $term, 2 );
			$prefix .= "/";
			if ( $AbbreviatedAmharic{$prefix} ) {
				return ( "$AbbreviatedAmharic{$prefix}$term" );
			}
		}
	}

	
}

sub Contract
{
local ($term) = shift;

	foreach $key (keys %AbbreviatedAmharic) {
		return ( $key ) if ( $AbbreviatedAmharic{$key} eq $term );
 		# print "Contract: $AbbreviatedAmharic{$key} = $term\n";
		if ( $term =~ /^$AbbreviatedAmharic{$key}/ ) {
			$term =~ s/$AbbreviatedAmharic{$key}//;
			return ( "$key$term" );
		}
	}
}

#
# ma/bEt
# d/bEt
# me/`se/ma
# qe/ge/ma
# m/wana  as in "m/wana SeHefi"
#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################


__END__


=head1 NAME

AM::Abbreviate - Expand or Contract Amharic Abbreviations

=head1 SYNOPSIS

  use Lingua::AM::Abbreviate;

	while ( $string = <> ) {  # some UTF8 string
		if ( $contracted = Contract ( $string ) ) {
			print "$string => $contracted\n";
		} elsif ( $expanded = Expand ( $string ) ) {
			print "$string => $expanded\n";
		}
	}

=head1 DESCRIPTION

AM::Abbreviate provides two routines, "Expand" and "Contract", to assist
in Amharic translation or spell checking.  Each routine expects an Amharic
string in UTF8 encoding as an argument and returns an expansion or
contraction if found.


=head1 AUTHOR

Daniel Yacob,  L<LibEth@EthiopiaOnline.Net|mailto:LibEth@EthiopiaOnline.Net>

=head1 SEE ALSO

perl(1).  Ethiopic(3), L<http://libeth.netpedia.net|http://libeth.netpedia.net>

=cut
