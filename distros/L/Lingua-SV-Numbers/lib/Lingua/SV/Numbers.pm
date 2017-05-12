package Lingua::SV::Numbers;

use Exporter 5.57 'import';
@EXPORT_OK = qw/num2sv num2sv_cardinal num2sv_ordinal/;

use warnings;
use strict;
use Carp;

use constant {
	ORDINAL => 1,	# flag passed to _translate()
};



#--------------

# According to SAOL:
#   biljon: en miljon miljoner
#   triljon: en miljon biljoner
#   kvadriljon: en miljon triljoner
my %bases;
@bases{0..20,30,40,50,60,70,80,90,100,1_000,10**6,10**9,10**12,10**18} = qw/
	noll ett två tre fyra fem sex sju åtta nio tio
	elva tolv tretton fjorton femton sexton sjutton arton nitton
	tjugo trettio fyrtio femtio sextio sjuttio åttio nittio
	hundra tusen miljon miljard biljon triljon
/;
my %ordinalBases;
@ordinalBases{sort {$a<=>$b} keys %bases} = qw/
	nollte första andra tredje fjärde femte sjätte sjunde åttonde nionde tionde
	elfte tolfte trettonde fjortonde femtonde sextonde sjuttonde artonde nittonde
	tjugonde trettionde fyrtionde femtionde sextionde sjuttionde åttionde nittionde
	hundrade tusende miljonte miljardte biljonte triljonte
/;



#--------------


*num2sv = \&num2sv_cardinal;
sub num2sv_cardinal {
	_num2sv( 0, @_ );
}
sub num2sv_ordinal {
	_num2sv( ORDINAL, @_ );
}
sub _num2sv {
	my $flags = shift;
	carp "not exactly one argument given" if ( @_ != 1 );
	my $x = shift;
	if ( $x =~ m/^-?\d+$/ ) {
		return _translate( $flags, _reduce( $x ) );
	} else {
		carp "not an integer";
		return $x;
	}
}

#--------------

# Translates an array of reduced components.
sub _translate {
	my $flags = shift;
	my $str = '';
	if ( $_[0] eq '-' ) {
		$str = 'minus ';
		shift;
	}
	my $prev;
	while ( @_ ) {
		my $cur = shift;
		my $next = $_[0];

		if ( $prev && $prev > $cur && _precedingOne( $cur ) ) {
			$str .= ( _tWord( $cur ) ? 'ett' : 'en' );
		}

		if ( ! $next && $flags & ORDINAL ) {
			if ( $cur > 10**6 ) {
				carp( "There is no word for ordinal $cur in Swedish" );
			}
			$str .= $ordinalBases{$cur};
		} elsif ( $cur == 1 && $next ) {
			if ( _precedingOne( $next ) ) {
				$str .= _tWord( $next ) ? 'ett' : 'en';
			}
		} elsif (
			$prev && 1 < $prev && $prev < $cur &&
			! _degeneratePlural( $cur )
		) {
			$str .= $bases{$cur} . 'er';
		} else {
			$str .= $bases{$cur};
		}
		$prev = $cur;
	}
	$str =~ s/(.)\1{2,}/$1$1/g;
	return $str;
}

# Returns true if the gender of the base word is t (ett).
sub _tWord {
	my $num = shift;
	warn "not a base word: $num" unless exists $bases{$num};
	return $num <= 1000;
}
sub _nWord {
	return not _tWord( shift );
}
# returns true if the base word should be preceded by en/ett in singular
sub _precedingOne {
	return ( shift() >= 100 );
}
# returns true if the base word does not change in plural
sub _degeneratePlural {
	return ( shift() <= 1000 );
}

# Reduces a number. Returns array of reduced components.
sub _reduce {
	my $x = shift;

	return ('-', -$x ) if $x < 0;
	return $x if ( exists $bases{$x} );
	for my $num ( sort {$b<=>$a} keys %bases ) {
		next if ( $num > $x );
		my $factor = int( $x / $num );
		my $remainder = $x - $factor * $num;
		#printf "splitting %.0f into %d * %.0f + %d\n", $x, $factor, $num, $x-$factor*$num;
		return $remainder
			? ( _reduce( $factor ), $num, _reduce( $x - $factor*$num ) )
			: ( _reduce( $factor ), $num );
	}

	warn "no reduction found for $x";
	return undef;
}

=head1 NAME

Lingua::SV::Numbers - Convert numbers into Swedish words.

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.04';


=head1 SYNOPSIS

    use Lingua::SV::Numbers qw/num2sv num2sv_ordinal/;
    print num2sv( 99 ) . " luftballonger\n"; #-> nittionio luftballonger
    print num2sv_ordinal( 13 ) . " timmen\n"; #-> trettonde timmen

=head1 FUNCTIONS

These functions are provided but not exported by default.

=over 4

=item num2sv EXPR

Alias for C<num2sv_cardinal>.

=item num2sv_cardinal EXPR

Returns a Swedish string of the cardinal number corresponding to EXPR. Only
integers (positive and negative) are supported. E.g. 3 => "tre"

=item num2sv_ordinal EXPR

Returns a Swedish string of the ordinal number corresponding to EXPR. Only
integers (positive and negative) are supported. E.g. 3 => "tredje"

=back

=head1 TODO

=over 4

=item * support fractions

=item * support scientific notation

=item * support thousand-dividing commas

=back

=head1 AUTHOR

Tim Nordenfur, C<< <tim at gurka.se> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lingua-sv-numbers at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-SV-Numbers>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::SV::Numbers


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-SV-Numbers>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-SV-Numbers>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-SV-Numbers>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-SV-Numbers/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Tim Nordenfur.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lingua::SV::Numbers
