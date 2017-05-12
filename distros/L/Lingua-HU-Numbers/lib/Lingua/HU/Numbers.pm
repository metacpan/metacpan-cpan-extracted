package Lingua::HU::Numbers;

use 5.006;

use warnings;
use strict;

use Carp;
use utf8;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = qw(num2hu num2hu_ordinal);

our $VERSION = '0.07';

my %dig;

@dig{ 0..30,40,50,60,70,80,90 } = qw( nulla egy kettő három négy öt hat hét
nyolc kilenc tíz tizenegy tizenkettő tizenhárom tizennégy tizenöt tizenhat
tizenhét tizennyolc tizenkilenc húsz huszonegy huszonkettő huszonhárom
huszonnégy huszonöt huszonhat huszonhét huszonnyolc huszonkilenc harminc
negyven ötven hatvan hetven nyolcvan kilencven );

my %ord;

my @tenord = qw ( egyedik kettedik harmadik negyedik ötödik hatodik hetedik
nyolcadik kilencedik);

my %tenord; @tenord{ 1..9 } = @tenord;

my $empty = q{};
my $minus = q{-};
my $space = q{ };

my @desc = ($empty,qw(ezer millió milliárd billió billiárd trillió trilliárd 
kvadrillió kvadrilliárd kvintillió kvintilliárd szextillió szextilliárd
szeptillió szeptilliárd oktillió oktilliárd nonillió nonilliárd
decillió decilliárd));

my @frac = ($empty,qw( ezred milliomod milliárdod billiomod billiárdod
trilliomod trilliárdod kvadrilliomod kvadrilliárdod kvintilliomod
kvintilliárdod szextilliomod szextilliárdod szeptilliomod szeptilliárdod
oktilliomod oktilliárdod nonilliomod nonilliárdod decilliomod 
decilliárdod ));
	
@ord{ 0..10,11..19,20,21..29,30,40,50,60,70,80,90,100 } = (qw(nulladik első 
második), @tenord[2..8], 'tizedik',(map { "tizen$_" } @tenord), 'huszadik', 
(map { "huszon$_" } @tenord), qw( harmincadik negyvenedik ötvenedik hatvanadik
hetvenedik nyolcvanadik kilencvenedik századik));

sub num2hu {
	my $num = $_[0];
	return $dig{'0'} if ($num =~ m/^[+-]0+$/sx);
	return unless defined $num && length $num;
	croak('Number is not properly formatted!')
		if ($num !~ m/^[+-]?\d+(\.\d+)?$/sx);
	my ($int,$frac) = $num =~ m/^[+-]?(\d+)(?:\.(\d+))?$/x;
	croak('The number is too large, the module can\'t handle it!')
		if ($int && length($int) > 66 || $frac && length($frac) > 66);
	my $plusmin = $empty;
	$num =~ s/^([+-])/$plusmin = $1;$empty/esx;
	$plusmin = ($plusmin eq $minus) ? 'mínusz ':$empty;
	if ($num =~ m/(\d+)\.(\d+)/x) {
		if (_frac2hu($2)) { return $plusmin._int2hu($1).' egész '._frac2hu($2)
		} else { return $plusmin._int2hu($1); }
	} else {
		return $plusmin._int2hu($num);
	}
}

sub num2hu_ordinal {
	my $num = $_[0];
	return unless defined $num && length($num);
	croak('You need to specify a positive integer for this function!')
		if ($num !~ m/^\d+$/sx);
	croak('The number is too large, the module can\'t handle it!')
		if (length($num) > 66);
	return $ord{'0'} if ($num =~ m/^0+$/sx);
	return _ord2hu($num);
}

sub _int2hu {
	my $num = $_[0];
	my $recur = $_[1];
	return $dig{$num} if ($dig{$num});
	my ($hun,$end,$pre);
	if ($num =~ m/^(\d)(\d)$/x) {
		return $dig{$1.'0'} . $dig{$2}
	} elsif ($num =~ m/^(\d)(\d\d)$/x) {
		($hun,$end) = ($1,$2);
		$hun = ($hun eq '1' && !$recur)? 'száz':"$dig{$hun}száz";
		return $hun if ($end eq '00');
		return $hun._int2hu($2 + 0);
	} elsif ($num <= 2000 && $num =~ m/^1(\d\d\d)$/x) {
		return 'ezer' if ($1 eq '000');
		return 'ezer'._int2hu($1 + 0,1);
	} elsif ($num =~ m/^(\d{1,3})((?:000){1,2})$/x) {
		($pre,$end) = ($1,(length($2) == 3)? $desc[1]:$desc[2]);
		return _int2hu($pre + 0).$end;
	} else {
		return _bigint2hu($num);
	}

}

sub _bigint2hu {
	my $num = $_[0];
	my @parts;
	my $count = 0;
	my $part;
	if ($num =~ m/001(\d{3})$/x) {
		$num =~ s/00(1\d{3})$//x;
		$part = $1;
		unshift @parts, [ $part, $count ];
		$count += 2;
	}
	while ($num =~ s/(\d{1,3})$//x) {
		$part = $1 + 0;
		unshift @parts, [ $part, $count ] if ($part);
		$count++;
	}
	my @out;
	for (0..$#parts) {
		push @out, _int2hu($parts[$_]->[0],$_).
		(($parts[$_]->[1] > 8)? $space:$empty).
		$desc[$parts[$_]->[1]];
	}
	return join($minus,@out);
	
}

sub _frac2hu {
	my $num = $_[0];
	$num =~ s/0+$//x;
	my $place = length($num);
	$num =~ s/^0+//x;
	return if ($num eq $empty);
	if ($place < 3) { 
		$place = ($place == 1) ? 'tized':'század';
		return _int2hu($num).$space.$place;
	} else {
		my $rest = $empty;
		$rest = _int2hu('1'.('0' x ($place % 3))) if ($place % 3);
		$place = int( $place / 3 );
		return _int2hu($num).$space.$rest.$frac[$place];
	}


}

sub _ord2hu {
	my $num = $_[0];
	$num =~ s/^0+//x;
	return $ord{$num} if $ord{$num};
	if ($num =~ m/^(\d)(\d)$/x) {
		return _int2hu($1.'0').$tenord{$2};
	} elsif ($num =~ m/^(\d)(\d\d)$/x) {
		if ($2 eq '00') { return _int2hu($1.'00').'adik' }
		else { return _int2hu($1.'00')._ord2hu($2); }
	} elsif ($num =~ m/^(\d+?)((?:000)+)$/x) {
		if ($1 eq '1' && $2 eq '000') { return 'ezredik' } 
		else { return _int2hu($1).$frac[(length($2) / 3)].'ik'; }
	} elsif ($num =~ m/^1(\d\d\d)$/x) {
		return 'ezer'._ord2hu($1);
	} elsif ($num =~ m/^(\d+)(\d\d\d)$/x) {
		return _int2hu($1.'000').$minus._ord2hu($2);
	}
	
}
1;
__END__
=head1 NAME

Lingua::HU::Numbers - converts numbers into Hungarian language text form

=head1 SYNOPSIS


    use Lingua::HU::Numbers qw/num2hu num2hu_ordinal/;

    my $number = "42";
    my $foo = num2hu($number);
    print $foo;

prints

    negyvenkettő

=head1 DESCRIPTION

Lingua::HU::Numbers is a module converting numbers (like "42") into their
Hungarian language representation ("negyvenkettő").

The module provides two optionally exported functions that can be exported:
C<num2hu> and C<num2hu_ordinal>.

Please see the README file for details of Hungarian grammar.

=head1 FUNCTIONS

=over

=item * num2hu

It takes a scalar value which currently must be a real number smaller
than -+10**66. The return value is a scalar expressing the Hungarian text
version of the given number.

=cut

=item * num2hu_ordinal

This function takes a scalar value which must be a positive integer smaller
than 10**66. The return value is a scalar expressing the Hungarian ordinal
text form of the specified number.

=cut

=back

=head1 LIMITATIONS

The module cannot handle numbers larger than -+10**66
at the moment.

=head1 FUTURE PLANS

Exponential notation, fraction support will be added in the
next few releases. Patches (and accompanying tests) are welcome.

The module aims to remain similar in structure to L<Lingua::EN::Numbers>,
so that those familiar with that module can use this one easily.

=head1 AUTHOR

Bálint Szilakszi, C<< <szbalint at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-lingua-hu-numbers at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lingua-HU-Numbers>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SEE ALSO

L<Lingua::EN::Numbers>
L<Lingua::Num2Word>

=head1 ACKNOWLEDGEMENTS

Sean M. Burke for writing Lingua::EN::Numbers, which this module is modelled
from.

=head1 LICENSE

Copyright 2006-2008 Bálint Szilakszi.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
