package Language::FormulaEngine::Namespace::Default;
use parent 'Language::FormulaEngine::Namespace';
use strict;
use warnings FATAL => 'numeric', 'uninitialized';
use Try::Tiny;
use List::Util ();
use Math::Trig ();
use Scalar::Util ();
use POSIX ();
# POSIX::round isn't available everywhere
BEGIN { eval 'use POSIX "round"; 1;' or eval 'sub round { sprintf "%.*f", $_[1]||0, $_[0] }' }
use Language::FormulaEngine::Error ':all';
use DateTime;
use DateTime::Format::Flexible;
use namespace::clean;

# ABSTRACT: Default spreadsheet-like set of functions and behavior
our $VERSION = '0.06'; # VERSION

# No official versioned namespace yet, but this code is for when I publish one.

#sub _fake_require {
#	my $version= shift;
#	$INC{'Language/FormulaEngine/Namespace/Default/V'.$version.'.pm'}=
#		$INC{'Language/FormulaEngine/Namespace/Default.pm'};
#}
#
#sub _declare_versioned_namespace {
#	my ($from_ver, $to_ver, @list)= @_;
#	no strict 'refs';
#	my $from_stash= \%{ __PACKAGE__ . '::V' . $from_ver . '::' };
#	my $to_stash= \%{ __PACKAGE__ . '::V' . $to_ver . '::' };
#	if (@list) {
#		for (@list) {
#			defined $from_stash->{$_} or die "Version $from_ver does not contain method $_";
#			$to_stash->{$_}= $from_stash->{$_};
#		}
#	} else {
#		for (keys %$from_stash) {
#			$to_stash->{$_}= $from_stash->{$_}
#				if defined $from_stash->{$_}{CODE} && !defined $to_stash->{$_};
#		}
#	}
#	@{ __PACKAGE__ . '::V' . $to_ver . '::ISA' }= ( 'Language::FormulaEngine::Namespace' );
#}
#
#_fake_require 0;
#@Language::FormulaEngine::Namespace::Default::V0::ISA= ( __PACKAGE__ );


*fn_sum= *List::Util::sum0;
sub perlgen_sum {
	my ($self, $compiler, $node)= @_;
	my @arg_code= map $compiler->perlgen($_), @{$node->parameters};
	return '( '.join(' + ', @arg_code).' )';
}

sub fn_negative {
	@_ == 1 or die "Can only negate a single value, not a list\n";
	return -$_[0];
}
sub perlgen_negative {
	my ($self, $compiler, $node)= @_;
	my @arg_code= map $compiler->perlgen($_), @{$node->parameters};
	@arg_code == 1 or die "Can only negate a single value, not a list\n";
	return '(-('.$arg_code[0].'))';
}

*fn_mul= *List::Util::product;
sub perlgen_mul {
	my ($self, $compiler, $node)= @_;
	my @arg_code= map $compiler->perlgen($_), @{$node->parameters};
	return '( '.join(' * ', @arg_code).' )';
}

sub fn_div {
	@_ == 2 or die "div() takes exactly two arguments\n";
	$_[1] or die "division by zero\n";
	return $_[0] / $_[1];
}
sub perlgen_div {
	my ($self, $compiler, $node)= @_;
	my @arg_code= map $compiler->perlgen($_), @{$node->parameters};
	return '( '.join(' / ', @arg_code).' )';
}

sub nodeval_and { # customize nodeval_ to provide lazy evaluation of arguments
	my ($self, $node)= @_;
	$_->evaluate($self) or return 0
		for @{ $node->parameters };
	return 1;
}
sub perlgen_and {
	my ($self, $compiler, $node)= @_;
	my @arg_code= map $compiler->perlgen($_), @{$node->parameters};
	return '( ('.join(' and ', @arg_code).')? 1 : 0)';
}

sub nodeval_or {
	my ($self, $node)= @_;
	$_->evaluate($self) and return 1
		for @{ $node->parameters };
	return 0;
}
sub perlgen_or {
	my ($self, $compiler, $node)= @_;
	my @arg_code= map $compiler->perlgen($_), @{$node->parameters};
	return '( ('.join(' or ', @arg_code).')? 1 : 0)';
}

sub fn_not {
	@_ == 1 or die "Too many arguments to 'not'\n";
	return $_[0]? 0 : 1;
}
sub perlgen_not {
	my ($self, $compiler, $node)= @_;
	my @arg_code= map $compiler->perlgen($_), @{$node->parameters};
	@arg_code == 1 or die "Too many arguments to 'not'\n";
	return '('.$arg_code[0].'? 0 : 1)';
}

sub fn_compare {
	my $left= shift;
	while (@_) {
		my $op= shift;
		my $right= shift;
		my $numeric= Scalar::Util::looks_like_number($left) && Scalar::Util::looks_like_number($right);
		if ($op eq '==' or $op eq '!=') {
			return 0 unless ($numeric? ($left == $right) : ($left eq $right)) == ($op eq '==');
		}
		elsif ($op eq '>=' or $op eq '<') {
			return 0 unless ($numeric? ($left >= $right) : ($left ge $right)) == ($op eq '>=');
		}
		elsif ($op eq '<=' or $op eq '>') {
			return 0 unless ($numeric? ($left <= $right) : ($left le $right)) == ($op eq '<=');
		}
		else {
			die "Unhandled operator '$op' in compare()\n";
		}
		$left= $right;
	}
	return 1;
}


sub fn_choose {
	$_[0] > 0 and $_[0] < @_ or die "CHOSE() selector out of bounds ($_[0])";
	return $_[$_[0]];
}

sub nodeval_if { # customize nodeval_ to provide lazy evaluation of arguments
	my ($self, $node)= @_;
	@{$node->parameters} == 3 or die "IF(test, when_true, when_false) requires all 3 parameters\n";
	my $bool= $node->parameters->[0]->evaluate($self);
	return $node->parameters->[$bool? 1 : 2]->evaluate($self);
}
sub perlgen_if {
	my ($self, $compiler, $node)= @_;
	my @arg_code= map $compiler->perlgen($_), @{$node->parameters};
	@arg_code == 3 or die "IF(test, when_true, when_false) requires all 3 parameters\n";
	return '( '.$arg_code[0].'? '.$arg_code[1].' : '.$arg_code[2].' )';
}

sub nodeval_iferror {
	my ($self, $node)= @_;
	my $ret;
	try {
		$ret= $node->parameters->[0]->evaluate($self);
	} catch {
		my $err= $node->parameters->[1];
		$ret= defined $err? $err->evaluate($self) : '';
	};
	return $ret;
}
sub perlgen_iferror {
	my ($self, $compiler, $node)= @_;
	my @arg_code= map $compiler->perlgen($_), @{$node->parameters};
	return '(do { local $@; my $x; eval { $x=('.$arg_code[0].'); 1 }? $x : ('.$arg_code[1].') })';
}

sub nodeval_ifs {
	my ($self, $node)= @_;
	(my @todo= @{$node->parameters}) & 1
		and die "IFS(cond, val, ...) requires an even number of parameters\n";
	while (@todo) {
		my ($cond, $val)= splice @todo, 0, 2;
		return $val->evaluate($self) if $cond->evaluate($self);
	}
	die "IFS() had no true conditions\n";
}
sub perlgen_ifs {
	my ($self, $compiler, $node)= @_;
	(my @arg_code= map $compiler->perlgen($_), @{$node->parameters}) & 1
		and die "IFS(cond, val, ...) requires an even number of parameters\n";
	my $expr= '(';
	while (@arg_code) {
		my ($cond, $val)= splice @arg_code, 0, 2;
		$expr .= "($cond)? ($val) : ";
	}
	$expr .= 'die "IFS() had no true conditions\n")';
	return $expr;
}

sub fn_na {
	die ErrNA("NA");
}


*fn_abs= *CORE::abs;
*fn_acos= *Math::Trig::acos;
*fn_acot= *Math::Trig::acot;
*fn_asin= *Math::Trig::asin;
*fn_atan= *Math::Trig::atan;

sub fn_atan2 {
	# Perl differs in argument order from popular spreadsheet programs
	atan2($_[1], $_[0])
}

sub fn_average {
	List::Util::sum0(@_) / @_;
}

sub fn_base {
	my ($num, $radix, $min_length)= @_;
	my $digits= '';
	while ($num > 0) {
		use integer;
		($num, my $digit)= ($num / $radix, $num % $radix);
		$digits= chr(($digit < 10? 48 : 65) + $digit) . $digits;
	}
	my $pad= ($min_length||0) - length $digits;
	return $pad > 0? '0'x$pad . $digits : $digits;
}

*fn_cos= *CORE::cos;
*fn_degrees= *Math::Trig::rad2deg;
*fn_exp= *CORE::exp;
sub fn_fact {
	my $n= int($_[0]);
	return 1 unless $n;
	$n > 0 or die ErrNUM("Can't compute factorial of negative number '$n'");
	List::Util::product(1 .. $n);
}

*fn_min= *List::Util::min;
*fn_max= *List::Util::max;
sub fn_mod {
	my ($num, $modulo)= @_;
	$modulo+0 or die ErrNUM("MOD($num, $modulo): can't claculate modulus-0");
	$num % $modulo;
}

*fn_pi= *Math::Trig::pi;

sub fn_round {
	my ($num, $digits)= @_;
	my $scale= 0.1 ** ($_[1] || 0);
	return round($num / $scale) * $scale;
}

our $epsilon= 5e-14; # fudge factor for avoiding floating point rounding errors
sub fn_ceiling {
	my ($num, $step)= @_;
	$step= 1 unless defined $step;
	return POSIX::ceil($num / $step - $epsilon) * $step;
}
sub fn_floor {
	my ($num, $step)= @_;
	$step= 1 unless defined $step;
	return POSIX::floor($num / $step + $epsilon) * $step;
}
sub fn_roundup {
	fn_ceiling($_[0], 0.1 ** ($_[1] || 0));
}
sub fn_rounddown {
	fn_floor($_[0], 0.1 ** ($_[1] || 0));
}

sub fn_power {
	@_ == 2 or die ErrInval("POWER() takes 2 arguments");
	return $_[0] ** $_[1];
}

*fn_rand= *CORE::rand;
*fn_sin= *CORE::sin;
*fn_sqrt= *CORE::sqrt;
*fn_tan= *Math::Trig::tan;


*fn_char= *CORE::chr;
sub fn_clean {
	my $str= shift;
	$str =~ s/[[:^print:]]+//g;
	$str;
}
*fn_code= *CORE::ord;
*fn_upper= *CORE::uc;
*fn_lower= *CORE::lc;

sub fn_replace {
	@_ == 4 or die ErrInval("REPLACE() takes 4 arguments");
	my ($text, $ofs, $n, $newtext)= @_;
	substr($text, $ofs, $n)= $newtext;
	return $text;
}

*fn_substr= *CORE::substr;
*fn_len= *CORE::length;

sub fn_concatenate {
	join '', @_;
}
*fn_concat= *fn_concatenate;
*fn_join= *CORE::join;

sub fn_find {
	my ($needle, $haystack, $ofs)= @_;
	$ofs= 1 unless $ofs && $ofs > 0;
	return index($haystack, $needle, $ofs) + 1;
}

sub fn_fixed {
	my ($number, $places, $comma)= @_;
	$places= 2 unless defined $places;
	$comma= ',' unless defined $comma && (!$comma or $comma eq '.');
	$number= $places > 0? sprintf("%.*f", $places, $number) : fn_round($number, $places);
	if ($comma) {
		$number =~ s/\./,/ if $comma eq '.';
		my $tmp= reverse substr($number, 0, $places > 0? -($places+1) : length $number);
		$tmp =~ s/(\d\d\d)(?=\d)/$1$comma/g;
		substr($number, 0, $places > 0? -($places+1) : length $number)= reverse $tmp;
	}
	return $number;
}

sub fn_trim {
	my $str= shift;
	$str =~ s/\p{Space}+/ /g;
	$str =~ s/^ //;
	$str =~ s/ $//;
	$str;
}


sub fn_datevalue {
	my $date= shift;
	return $date if ref $date && ref($date)->isa('DateTime');
	try { DateTime::Format::Flexible->parse_datetime($date) }
	catch { die ErrInval("Not a date: '$date'") };
}
BEGIN { *_date= *fn_datevalue; } # for convenience
sub fn_date {
	my ($y, $m, $d)= @_;
	try { DateTime->new(year => $y, month => $m, day => $d) }
	catch { die ErrInval(ref $_ && $_->can("message")? $_->message : "$_") };
}

sub fn_datedif {
	my ($start, $end, $unit)= @_;
	$unit= uc($unit || '');
	if ($unit eq 'Y') { return _date($end)->delta_md(_date($start))->in_units('years') }
	if ($unit eq 'M') { return _date($end)->delta_md(_date($start))->in_units('months') }
	if ($unit eq 'D') { return _date($end)->delta_days(_date($start))->in_units('days') }
	die ErrInval "Unsupported datedif unit '$unit'";
}
sub fn_day {
	_date($_[0])->day
}
sub fn_days {
	my ($end, $start)= ( _date($_[0]), _date($_[1]) );
	my $n= $end->delta_days($start)->in_units('days');
	return $end > $start? $n : -$n;
}
sub fn_eomonth {
	my ($start, $m_ofs)= @_;
	$m_ofs= 0 unless @_ > 1;
	_date($start)->clone->add(months => $m_ofs+1)->truncate(to => 'month')->subtract(days => 1);
}
sub fn_hour {
	_date($_[0])->hour
}
sub fn_minute {
	_date($_[0])->minute
}
sub fn_month {
	_date($_[0])->month
}
sub fn_now {
	DateTime->now;
}
sub fn_second {
	_date($_[0])->second
}
sub fn_today {
	DateTime->now->truncate(to => 'day');
}
sub fn_weekday {
	my ($date, $standard)= @_;
	my $day_mon1= _date($date)->day_of_week;
	return $day_mon1 % 7 + 1 if !$standard or $standard == 1;
	return $day_mon1 if $standard == 2 or $standard == 11;
	return $day_mon1-1 if $standard == 3;
	return ($day_mon1 - ($standard - 10)) % 7 + 1 if $standard >= 12 && $standard <= 17;
	die ErrInval("No known weekday standard '$standard'");
}
sub fn_year {
	_date($_[0])->year
}

# Perl older than 5.16 can't actually reference the functions in CORE:: namespace.
# For example, perl -e 'my $sub= sub { CORE::ord(shift) }; print $sub->("A")' works but
# perl -e 'my $sub= sub { &CORE::ord }; print $sub->("A")' does not.  Neither does
# perl -e 'CORE->can("ord")->("A")', nor does *fn_foo= *CORE::foo used above.
# I could of course just wrap each core function with a function defined in this
# package, but it would be a needless performance hit for modern perl, and clutter
# the code above.
unless (CORE->can("abs")) {
	require Sub::Util;
	my $stash= \%Language::FormulaEngine::Namespace::Default::;
	for my $fn (grep /^fn_/, keys %$stash) {
		my $symname= "$stash->{$fn}";
		next unless $symname =~ s/^\*CORE/CORE/;
		#print "# Stash $fn is $symname\n";
		# prototypes make this annoying
		my $code= $symname eq 'CORE::substr'? "sub { substr(shift, \@_) }"
			: $symname eq 'CORE::join'? "sub { join(shift, \@_) }"
			: "sub { $symname(shift) }";
		my $sub= eval $code or die "$@";
		no strict 'refs'; no warnings 'redefine';
		# The name of the sub needs to remain as CORE::foo else test cases will fail
		*$fn= Sub::Util::set_subname($symname, $sub);
	}
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Language::FormulaEngine::Namespace::Default - Default spreadsheet-like set of functions and behavior

=head1 VERSION

version 0.06

=head1 DESCRIPTION

This is a L<namespace|Language::FormulaEngine::Namespace> containing many spreadsheet-like
functions.  It aims for spreadsheet similarity rather than compatibility; the goal to give
users of the FormulaEngine a familiar environmet rather than to try duplicating all features
and misfeatures Excel.

=head2 Core Grammar Functionality

These are the methods that implement the infix operators.

=over

=item C<< sum( num1, num2 ... ) >>

=item C<< negative( num1 ) >>

=item C<< mul( num1, num2, ... ) >>

=item C<< div( numerator, denominator ) >>

=item C<< and( bool1, bool2, ... ) >>

This applies perl-ish boolean semantics to each argument, and returns a numeric 0 or 1.
No arguments are evaluated after the first false value.

=item C<< or( bool1, bool2, ... ) >>

This applies perl-ish boolean semantics to each argument, and returns a numeric 0 or 1.
No arguments are evaluated after the first true value.

=item C<< not( bool1 ) >>

This applies perl-ish boolean semantics to the argument and returns numeric 1 or 0.

=item C<< compare( val1, op, val2, ...op, val ) >>

This compares two or more values against the 6 canonical operators
C<< "<", "<=", ">", ">=", "==", "!=" >> and returns 0 or 1.

It uses numeric comparison if both sides of an operator C<looks_like_number>, and uses string
comparison otherwise.

=back

=head2 Utility Functions

=over

=item C<< choose( offset, val1, val2, val3, ... ) >>

Given a 1-based offset, return the value of the Nth parameter.

=item C<< if( condition, val_if_true, val_if_false ) >>

If C<condition> is "true" (Perl interpretation) return C<val_if_true>, else C<val_if_false>.

=item C<< iferror( value_maybe_error, alternate_value ) >>

If C<value_maybe_error> does not throw an exception, return it, else return the
C<alternate_value>.

=item C<< ifs( condition1, value1, condition2, value2, ... ) >>

A simplified sequence of IF functions.  If C<condition1> is true, it returns C<value1>, else if
C<condition2> is true it returns C<value2>, and so on.  If no condition is true it dies.  (use
a final true condition and value to provide a default)

=item C<< na() >>

Throw an NA exception.

=back

=head2 Math Functions

=over

=item C<< abs( number ) >>

Return absolute value of number

=item C<< acos( ratio ) >>

Return angle in radians of the ratio adjacent/hypotenuse.

=item C<< acot( ratio ) >>

Return angle in radians of the ratio adjacent/opposite.

=item C<< asin( ratio ) >>

Return angle in radians of the ratio opposite/hypotenuse.

=item C<< atan( ratio ) >>

Return angle in radians of the ratio opposite/adjacent.

=item C<< atan2( x, y ) >>

Same as atan, but without division, so x=0 returns PI/2 instead of division error.

=item C<< average( num1, ... ) >>

Return sum of numbers divided by number of arguments

=item C<< base( num1, radix, min_length=0 ) >>

Return number converted to different base, with optional leading zeroes to reach min_length.

=item C<< ceiling( number, step=1 ) >>

Round a number up to the next multiple of C<step>.  If step is negative, this rounds away from
zero in the negative direction.

=item C<< cos( angle ) >>

Cosine of C<angle> in radians

=item C<< cot( ratio ) >>

Return the angle for the triangle ratio adjacent/opposite.

=item C<< degrees( angle_in_radians ) >>

Convert radians to degrees

=item C<< exp( power ) >>

Return base of the natural log raised to the specified power.

=item C<< fact( n ) >>

Compute factorial of C<n>.  (C<< 1 * 2 * 3 * ... n >>)

=item C<< floor( number, step=1 ) >>

Round a number down to the previous multiple of C<step>.  If step is negative, this rounds
toward zero in the positive direction.

=item C<< max( number, ... ) >>

Return largest value in list

=item C<< min( number, ... ) >>

Return smallest value in list

=item C<< mod( number, modulo ) >>

Returns true modulous of a number.  This uses Perl's (and math's) definition.  For the Excel-
compatible MOD function, see C<remainder>.

=item C<< pi() >>

Value of π

=item C<< radians( angle_in_degrees ) >>

Convert degrees to radians.

=item C<< rand( range=1 ) >>

Returns pseudo-random value greater or equal to 0 and less than C<range>.  This uses perl's
(C's) built-in C<< rand() >> function which is likely not as good as the generators used by
spreadsheet programs, but I didn't want to add a hefty dependency.

=item C<< remainder( number, divisor ) >>

Return the number after subtracting the biggest multiple of divisor that can be removed from it.
The remainder's sign will be the same as the sign of C<divisor> (unless remainder is zero).

=item C<< round( number, digits=0 ) >>

Round NUMBER to DIGITS decimal places of precision.  Uses the IEEE
5-round-to-even algorithm that C gives us.  DIGITS defaults to 0,
making it round to the nearest integer.

Dies if you attempt to round something that isn't a number.

=item C<< roundup( number, digits=0 ) >>

Like L</round>, but always round up.  See also L</ceiling>.

=item C<< rounddown( number, digits=0 ) >>

Like L</round>, but always round down.  See also L</floor>.

=item C<< sign( value ) >>

Return 1, 0, or -1 depending on the sign of C<value>.

=item C<< sin( angle ) >>

Returns ratio of opposite/adjacent for a given angle in radians.

=item C<< sqrt( number ) >>

Return square root of a number.

=item C<< tan( angle ) >>

Return ratio of opposite/adjacent for an angle.

=back

=head2 String Functions

=over

=item C<< char( codepoint_value ) >>

Return a unicode character.

=item C<< clean( string ) >>

Returns C<string> after removing all non-printable characters (defined as C<< [:^print:] >> )

=item C<< code( string ) >>

Opposite of L</char>, known as C<ord()> in other languages.  Returns the unicode codepoint
number of the first character of the string.

=item C<< concat, concatenate( string, ... ) >>

Returns all arguments concatenated as a string

=item C<< find( needle, haystack, from_offset=1 ) >>

Return the character offset of C<needle> from start of C<haystack>, beginning the search at
from_offset.  All offsets are 1-based.

=item C<< fixed( number, decimals=2, no_commas=false ) >>

Return the number formatted with a fixed number of decimal places.  By default, it gets commas
added in the USA notation, but this can be disabled.

=item C<< len( string ) >>

Return number of unicode characters in STRING.

=item C<< lower( string ) >>

Return lowercase version of STRING.

=item C<< replace( string, offset, length, new_text ) >>

Replace text in C<string> with C<new_text>, overwriting C<length> characters from C<offset>.

=item C<< substr( string, offset, length=max ) >>

Same as perl's builtin.

=item C<< trim( string ) >>

Remove all leading and trailing whitespace and replace runs of whitespace with a single space
character.

=item C<< upper( string ) >>

Return uppercase version of STRING.

=item C<< textjoin, join( separator, string, ... ) >>

Same as perl's builtin.

=back

=head2 DateTime Functions

Date math is implemented using the L<DateTime> module.  Strings are coerced into dates using
the L<DateTime::Format::Flexible> module for any parameter where a spreadsheet function would
normally expect a date value.  "Since 1900" date serial numbers are not used at all.

=over

=item C<< date( year, month, day ) >>

Convert a (year,month,day) triplet into a date.

=item C<< datedif( start_date, end_date, unit ) >>

Calculate difference bwteen two dates.  Unit can be one of: C<"Y"> (whole years), C<"M"> (whole
months), C<"D"> (whole days).  Dates can be parsed from any string resembling a date.

=item C<< datevalue( text ) >>

Parse a date, or die trying.

=item C<< day( date ) >>

Returns the day number of a date

=item C<< days( end_date, start_date ) >>

Returns number of days difference between start and end date.

=item C<< eomonth( start_date, months ) >>

Calculate the date of End-Of-Month at some offset from the start date.

=item C<< hour( date ) >>

Return the hour field of a date.

=item C<< minute( date ) >>

Return minute field of a date.

=item C<< month( date ) >>

Return month field of a date.

=item C<< year( date ) >>

Return the year field of a date.

=back

=head1 AUTHOR

Michael Conrad <mconrad@intellitree.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Michael Conrad, IntelliTree Solutions llc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
