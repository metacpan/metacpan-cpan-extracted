#!/usr/bin/perl --

package Lingua::NL::Numbers::GroeneBoekje;

# Numbers in words, according to the dutch "Groene Boekje".
# http://woordenlijst.org/leidraad/6/9/

=head1 NAME

Lingua::NL::Numbers::GroeneBoekje - Convert numeric values into their Dutch equivalents

=head1 SYNOPSIS

    use Lingua::NL::Numbers::GroeneBoekje;

    my $converter = Lingua::NL::Numbers::GroeneBoekje->new;

    my $text = $converter->parse(124);

    # prints 'honderdvierentwintig'
    print $text;

=head1 DESCRIPTION

Lingua::NL::Numbers::GroeneBoekje converts numeric values to their
Dutch written equivalent, according to the guidelines as defined in
the "Groene Boekje". For example:

    twee
    twintig
    tweeëntwintig
    tweehonderd
    tweehonderdtweeëntwintig
    tweeëntwintighonderd
    tweeduizend tweehonderdtwintig
    twee miljoen tweehonderdtwintigduizend tweehonderdtweeëntwintig

=head1 KNOWN BUGS

Estimated upper bound is 10**18 - 1, but this is not checked.

When "twee" is glued to "en" it will get a dieraesis on the "e" of "en".
The result will be a Perl Unicode string.

When "drie" is glued to "en" it will get a dieraesis on the "e" of "en".
The result will be a Perl Unicode string.

=head1 AUTHOR

Johan Vromans E<lt>jvromans@squirrel.nlE<gt>.

=head1 SEE ALSO

L<Lingua::NL::Numbers>

http://woordenlijst.org/leidraad/6/9/

=cut

$VERSION = "0.10";

use strict;
use warnings;

sub new {
    my ($pkg) = @_;
    $pkg = ref($pkg) || $pkg;
    bless \(my $o), $pkg;
}

sub parse {
    my ($self, $n) = @_;
    _num_($n);
}

use constant HOUNDRED  => "honderd";
use constant THOUSAND  => "duizend";
use constant TEN6TH    => "miljoen";
use constant TEN9TH    => "miljard";

my @units =
  ( qw(nul een twee drie vier
       vijf zes zeven acht negen),
    qw(tien elf twaalf dertien veertien
       vijftien zestien zeventien achttien negentien) );
my @tens =
  ( qw(nul tien twintig dertig veertig
       vijftig zestig zeventig tachtig negentig) );

# Regel 6.N
# We schrijven een getal in één woord, tot en met het woord duizend.

sub _num_ {
    my ($n) = @_;

    # Prefab numbers.
    return $units[$n] if $n < @units;

    # Small numbers, up to 99.
    if ( $n < 100 ) {
	my $t = int($n / 10);
	my $res = "";
	if ( my $r = $n % 10 ) {
	    $res = $units[$r] . "en";
	    $res =~ s/([ie])ee/$1."eë"/e;
	}
	return $res.$tens[$t];
    }

    # Up to 1_999.
    if ( $n < 1999 ) {
	my $t = int($n / 100);
	my $r = $n % 100;
	my $res;
	if ( $t % 10 == 0 ) {
	    $res = ($t > 10 ? _num_($t/10) : "") . THOUSAND;
	    # Regel 6.N (vervolg)
	    # Na het woord duizend volgt een spatie.
	    $res .= " " if $r;
	}
	else {
	    $res = ($t > 1 ? _num_($t) : "") . HOUNDRED;
	}
	$res .= _num_($r) if $r;
	return $res;
    }

    # Up to 999_999.
    if ( $n < 1000000 ) {
	my $t = int($n / 1000);
	my $r = $n % 1000;
	my $res = ($t > 1 ? _num_($t) : "") . THOUSAND;
	# Regel 6.N (vervolg)
	# Na het woord duizend volgt een spatie.
	$res .= " " . _num_($r) if $r;
	return $res;
    }

    # THe higher ones.
    return _very_high($n,    1000000, TEN6TH) if $n < 1000000000;
    return _very_high($n, 1000000000, TEN9TH);
    "ontzettend veel";
}

# Regel 6.N (vervolg)
# De woorden miljoen, miljard, biljoen enz. schrijven we los.

sub _very_high {
    my ($n, $m, $w) = @_;
    my $t = int($n / $m);
    my $r = $n % $m;
    my $res = _num_($t) . " " . $w;
    $res .= " " . _num_($r) if $r;
    return $res;
}

unless ( caller ) {
    package main;
    foreach ( @ARGV ) {
	printf("%8d: %s\n",
	       $_, Lingua::NL::Numbers::GroeneBoekje->new->parse($_));
    }
}
