# This code is part of Perl distribution Math-Formula version 0.18.
# The POD got stripped from this file by OODoc version 3.03.
# For contributors see file ChangeLog.

# This software is copyright (c) 2023-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

#oodist: *** DO NOT USE THIS VERSION FOR PRODUCTION ***
#oodist: This file contains OODoc-style documentation which will get stripped
#oodist: during its release in the distribution.  You can use this file for
#oodist: testing, however the code of this development version may be broken!

use warnings;
use strict;
use v5.16;  # fc

package Math::Formula::Type;{
our $VERSION = '0.18';
}

use base 'Math::Formula::Token';

#!!! The declarations of all other packages in this file are indented to avoid
#!!! indexing by CPAN.

use Log::Report 'math-formula',
	import => [ qw/warning error __x/ ];

# Object is an ARRAY. The first element is the token, as read from the formula
# or constructed from a computed value.  The second is a value, which can be
# used in computation.  More elements are type specific.

#--------------------

#--------------------

sub cast($)
{	my ($self, $to, $context) = @_;

	return MF::STRING->new(undef, $self->token)
		if $to eq 'MF::STRING';

	undef;
}


# token() is implemented in de base-class ::Token, but documented here

# Returns a value as result of a calculation.
# Nothing to compute for most types: simply itself.
sub compute { $_[0] }


sub value  { my $self = shift; $self->[1] //= $self->_value($self->[0], @_) }
sub _value { $_[1] }


sub collapsed($) { $_[0]->token =~ s/\s+/ /gr =~ s/^ //r =~ s/ $//r }

sub prefix()
{	my ($self, $op, $context) = @_;
	error __x"cannot find prefx operator '{op}' on a {child}", op => $op, child => ref $self;
}

sub attribute {
	warning __x"cannot find attribute '{attr}' for {class} '{token}'", attr => $_[1], class => ref $_[0], token => $_[0]->token;
	undef;
}

sub infix(@)
{	my $self = shift;
	my ($op, $right, $context) = @_;

	if($right->isa('MF::NAME'))
	{	my $token = $right->token;
		if($op eq '.')
		{	if(my $attr = $self->attribute($token))
			{	return ref $attr eq 'CODE' ? $attr->($self, @_) : $attr;
			}
		}
		else
		{	defined $context->formula($token)
				or error __x"rvalue name '{name}' for operator '{op}' is not a formula", name => $token, op => $op;

			my $value = $context->evaluate($token);
			return $self->infix($op, $value, $context);
		}
	}

	# object used as string
	return $self->cast('MF::STRING', $context)->infix(@_)
		if $op eq '~';

	error __x"cannot match infix operator '{op}' for ({left} -> {right})",
		op => $op, left => ref $self, right => ref $right;
}

#--------------------

package
	MF::BOOLEAN;

use base 'Math::Formula::Type';

# $class->new($token, $value, %options)
# When the value is derived from an expression, this should result in 1 or 0
sub new($$@)
{	my ($class, $token, $value) = (shift, shift, shift);
	defined $token or $value = $value ? 1 : 0;
	$class->SUPER::new($token, $value, @_);
}

sub prefix($)
{	my ($self, $op, $context) = @_;
	if($op eq 'not')
	{	return MF::BOOLEAN->new(undef, ! $self->value);
	}
	$self->SUPER::prefix($op, $context);
}

sub infix(@)
{	my $self = shift;
	my ($op, $right, $context) = @_;

	if(my $r = $right->isa('MF::BOOLEAN') ? $right : $right->cast('MF::BOOLEAN', $context))
	{	# boolean values are 0 or 1, never undef
		my $v
		  = $op eq 'and' ? ($self->value and $r->value)
		  : $op eq  'or' ? ($self->value  or $r->value)
		  : $op eq 'xor' ? ($self->value xor $r->value)
		  : undef;

		return MF::BOOLEAN->new(undef, $v) if defined $v;
	}
	elsif($op eq '->')
	{	$self->value or return undef;   # case false
		my $result = $right->compute($context);
		$context->setCaptures([]);      # do not leak captures
		return $result;
	}

	$self->SUPER::infix(@_);
}

sub _token($) { $_[1] ? 'true' : 'false' }
sub _value($) { $_[1] eq 'true' }

#--------------------

package
	MF::STRING;

use base 'Math::Formula::Type';

use Unicode::Collate ();
my $collate = Unicode::Collate->new;  #XXX which options do we need?

sub new($$@)
{	my ($class, $token, $value) = (shift, shift, shift);
	($token, $value) = (undef, $$token) if ref $token eq 'SCALAR';
	$class->SUPER::new($token, $value, @_);
}

sub _token($) { '"' . ($_[1] =~ s/[\"]/\\$1/gr) . '"' }

sub _value($)
{	my $token = $_[1] // '';

	  substr($token, 0, 1) eq '"' ? $token =~ s/^"//r =~ s/"$//r =~ s/\\([\\"])/$1/gr
	: substr($token, 0, 1) eq "'" ? $token =~ s/^'//r =~ s/'$//r =~ s/\\([\\'])/$1/gr
	:    $token;  # from code
}

sub cast($)
{	my ($self, $to) = @_;

	  ref $self eq __PACKAGE__ && $to eq 'MF::REGEXP'  ? MF::REGEXP->_from_string($self)
	: ref $self eq __PACKAGE__ && $to eq 'MF::PATTERN' ? MF::PATTERN->_from_string($self)
	: $self->SUPER::cast($to);
}

sub infix(@)
{	my $self = shift;
	my ($op, $right, $context) = @_;

	if($op eq '~')
	{	my $r = $right->isa('MF::STRING') ? $right : $right->cast('MF::STRING', $context);
		return MF::STRING->new(undef, $self->value . $r->value) if $r;
	}
	elsif($op eq '=~')
	{	if(my $r = $right->isa('MF::REGEXP') ? $right : $right->cast('MF::REGEXP', $context))
		{	if(my @captures = $self->value =~ $r->regexp)
			{	$context->setCaptures(\@captures);
				return MF::BOOLEAN->new(undef, 1);
			}
			return MF::BOOLEAN->new(undef, 0);
		}
	}
	elsif($op eq '!~')
	{	my $r = $right->isa('MF::REGEXP') ? $right : $right->cast('MF::REGEXP', $context);
		return MF::BOOLEAN->new(undef, $self->value !~ $r->regexp) if $r;
	}
	elsif($op eq 'like' || $op eq 'unlike')
	{	# When expr is CODE, it may produce a qr// instead of a pattern.
		my $r = $right->isa('MF::PATTERN') || $right->isa('MF::REGEXP') ? $right : $right->cast('MF::PATTERN', $context);
		my $v
		  = ! $r ? undef
		  : $op eq 'like' ? $self->value =~ $r->regexp
		  :   $self->value !~ $r->regexp;
		return MF::BOOLEAN->new(undef, $v) if $r;
	}
	elsif($op eq 'cmp')
	{	my $r = $right->isa('MF::STRING') ? $right : $right->cast('MF::STRING', $context);
		return MF::INTEGER->new(undef, $collate->cmp($self->value, $right->value));
	}

	$self->SUPER::infix(@_);
}

my %string_attrs = (
	length   => sub { MF::INTEGER->new(undef, length($_[0]->value))  },
	is_empty => sub { MF::BOOLEAN->new(undef, $_[0]->value !~ m/\P{Whitespace}/) },
	lower    => sub { MF::STRING->new(undef, fc($_[0]->value)) },
);

sub attribute($) { $string_attrs{$_[1]} || $_[0]->SUPER::attribute($_[1]) }

#--------------------

package
	MF::INTEGER;

use base 'Math::Formula::Type';
use Log::Report 'math-formula', import => [ qw/error __x/ ];

sub cast($)
{	my ($self, $to) = @_;
	  $to eq 'MF::BOOLEAN' ? MF::BOOLEAN->new(undef, $_[0]->value == 0 ? 0 : 1)
	: $to eq 'MF::FLOAT'   ? MF::FLOAT->new(undef, $_[0]->value)
	: $self->SUPER::cast($to);
}

sub prefix($)
{	my ($self, $op, $context) = @_;
	  $op eq '+' ? $self
	: $op eq '-' ? MF::INTEGER->new(undef, - $self->value)
	: $self->SUPER::prefix($op, $context);
}

sub infix(@)
{	my $self = shift;
	my ($op, $right, $context) = @_;

	return $self->cast('MF::BOOLEAN', $context)->infix(@_)
		if $op eq 'and' || $op eq 'or' || $op eq 'xor';

	$right->cast('MF::INTEGER')
		if $right->isa('MF::TIMEZONE');  # mis-parse

	if($right->isa('MF::INTEGER') || $right->isa('MF::FLOAT'))
	{	my $v
		  = $op eq '+' ? $self->value + $right->value
		  : $op eq '-' ? $self->value - $right->value
		  : $op eq '*' ? $self->value * $right->value
		  : $op eq '%' ? $self->value % $right->value
		  : undef;
		return ref($right)->new(undef, $v) if defined $v;

		return MF::INTEGER->new(undef, $self->value <=> $right->value)
			if $op eq '<=>';

		return MF::FLOAT->new(undef, $self->value / $right->value)
			if $op eq '/';
	}

	return $right->infix($op, $self, @_[2..$#_])
		if $op eq '*' && $right->isa('MF::DURATION');

	$self->SUPER::infix(@_);
}

my $gibi        = 1024 * 1024 * 1024;

my $multipliers = '[kMGTEZ](?:ibi)?\b';
sub _match { "[0-9][0-9_]* (?:$multipliers)?" }

my %multipliers = (
	k => 1000, M => 1000_000, G => 1000_000_000, T => 1000_000_000_000, E => 1e15, Z => 1e18,
	kibi => 1024, Mibi => 1024*1024, Gibi => $gibi, Tibi => 1024*$gibi, Eibi => 1024*1024*$gibi,
	Zibi => $gibi*$gibi,
);

sub _value($)
{	my ($v, $m) = $_[1] =~ m/^ ( [0-9]+ (?: _[0-9][0-9][0-9] )* ) ($multipliers)? $/x
		or error __x"illegal number format for '{string}'", string => $_[1];

	($1 =~ s/_//gr) * ($2 ? $multipliers{$2} : 1);
}

my %int_attrs = (
	abs => sub { $_[0]->value < 0 ? MF::INTEGER->new(undef, - $_[0]->value) : $_[0] },
);
sub attribute($) { $int_attrs{$_[1]} || $_[0]->SUPER::attribute($_[1]) }

#--------------------

package
	MF::FLOAT;

use base 'Math::Formula::Type';
use POSIX  qw/floor/;

sub _match  { '[0-9]+ (?: \.[0-9]+ (?: e [+-][0-9]+ )? | e [+-][0-9]+ )' }
sub _value($) { $_[1] + 0.0 }
sub _token($) { my $t = sprintf '%g', $_[1]; $t =~ /[e.]/ ?  $t : "$t.0" }

sub cast($)
{	my ($self, $to) = @_;
	  $to eq 'MF::INTEGER' ? MF::INTEGER->new(undef, floor($_[0]->value))
	: $self->SUPER::cast($to);
}

sub prefix($$)
{	my ($self, $op, $context) = @_;
	  $op eq '+' ? $self
	: $op eq '-' ? MF::FLOAT->new(undef, - $self->value)
	: $self->SUPER::prefix($op, $context)
}

sub infix(@)
{	my $self = shift;
	my ($op, $right, $context) = @_;

	return $self->cast('MF::BOOLEAN', $context)->infix(@_)
		if $op eq 'and' || $op eq 'or' || $op eq 'xor';

	$right->cast('MF::INTEGER')
		if $right->isa('MF::TIMEZONE');  # mis-parse

	if($right->isa('MF::FLOAT') || $right->isa('MF::INTEGER'))
	{	# Perl will upgrade the integers
		my $v
		  = $op eq '+' ? $self->value + $right->value
		  : $op eq '-' ? $self->value - $right->value
		  : $op eq '*' ? $self->value * $right->value
		  : $op eq '%' ? $self->value % $right->value
		  : $op eq '/' ? $self->value / $right->value
		  : undef;
		return MF::FLOAT->new(undef, $v) if defined $v;

		return MF::INTEGER->new(undef, $self->value <=> $right->value)
			if $op eq '<=>';
	}
	$self->SUPER::infix(@_);
}

# I really do not want a math library in here!  Use formulas with CODE expr
# my %float_attrs;
#sub attribute($) { $float_attrs{$_[1]} || $_[0]->SUPER::attribute($_[1]) }


#--------------------

package
	MF::DATETIME;

use base 'Math::Formula::Type';
use DateTime ();

sub _match {
	  '[12][0-9]{3} \- (?:0[1-9]|1[012]) \- (?:0[1-9]|[12][0-9]|3[01]) T '
	. '(?:[01][0-9]|2[0-3]) \: [0-5][0-9] \: (?:[0-5][0-9]) (?:\.[0-9]+)?'
	. '(?:[+-][0-9]{4})?';
}

sub _token($) { $_[1]->datetime . ($_[1]->time_zone->name =~ s/UTC$/+0000/r) }

sub _value($)
{	my ($self, $token) = @_;
	$token =~ m/^
		([12][0-9]{3}) \- (0[1-9]|1[012]) \- (0[1-9]|[12][0-9]|3[01]) T
		([01][0-9]|2[0-3]) \: ([0-5][0-9]) \: ([0-5][0-9]|6[01]) (?:(\.[0-9]+))?
		([+-] [0-9]{4})?
	$ /x or return;

	my $tz_offset = $8 // '+0000';  # careful with named matches :-(
	my @args = (year => $1, month => $2, day => $3, hour => $4, minute => $5, second => $6, nanosecond => ($7 // 0) * 1_000_000_000);
	my $tz = DateTime::TimeZone::OffsetOnly->new(offset => $tz_offset);

	DateTime->new(@args, time_zone => $tz);
}

sub _to_time($)
{	+{ hour => $_[0]->hour, minute => $_[0]->minute, second => $_[0]->second, ns => $_[0]->nanosecond };
}

sub cast($)
{	my ($self, $to) = @_;
	  $to eq 'MF::TIME' ? MF::TIME->new(undef, _to_time($_[0]->value))
	: $to eq 'MF::DATE' ? MF::DATE->new(undef, $_[0]->value->clone)
	: $self->SUPER::cast($to);
}

sub infix(@)
{	my $self = shift;
	my ($op, $right, $context) = @_;

	if($op eq '+' || $op eq '-')
	{	my $dt = $self->value->clone;
		if($right->isa('MF::DURATION'))
		{	my $v = $op eq '+' ?  $dt->add_duration($right->value) : $dt->subtract_duration($right->value);
			return MF::DATETIME->new(undef, $v);
		}
		if($op eq '-')
		{	my $r = $right->isa('MF::DATETIME') ? $right : $right->cast('MF::DATETIME', $context);
			return MF::DURATION->new(undef, $dt->subtract_datetime($right->value));
		}
	}

	if($op eq '<=>')
	{	return MF::INTEGER->new(undef, DateTime->compare($self->value, $right->value))
			if $right->isa('MF::DATETIME');

		if($right->isa('MF::DATE'))
		{	# Many timezone problems solved by DateTime
			my $date  = $right->token;
			my $begin = $self->_value($date =~ /\+/ ? $date =~ s/\+/T00:00:00+/r : $date.'T00:00:00');
			return MF::INTEGER->new(undef, -1) if DateTime->compare($begin, $self->value) > 0;

			my $end   = $self->_value($date =~ /\+/ ? $date =~ s/\+/T23:59:59+/r : $date.'T23:59:59');
			return MF::INTEGER->new(undef, DateTime->compare($self->value, $end) > 0 ? 1 : 0);
		}
	}

	$self->SUPER::infix(@_);
}

my %dt_attrs = (
	'time'  => sub { MF::TIME->new(undef, _to_time($_[0]->value)) },
	date    => sub { MF::DATE->new(undef, $_[0]->value) },  # dt's are immutable
	hour    => sub { MF::INTEGER->new(undef, $_[0]->value->hour)  },
	minute  => sub { MF::INTEGER->new(undef, $_[0]->value->minute) },
	second  => sub { MF::INTEGER->new(undef, $_[0]->value->second) },
	fracsec => sub { MF::FLOAT  ->new(undef, $_[0]->value->fractional_second) },
);

sub attribute($)
{	$dt_attrs{$_[1]} || $MF::DATE::date_attrs{$_[1]} || $_[0]->SUPER::attribute($_[1]);
}

#--------------------

package
	MF::DATE;

use base 'Math::Formula::Type';

use Log::Report 'math-formula', import => [ qw/error warning __x/ ];

use DateTime::TimeZone  ();
use DateTime::TimeZone::OffsetOnly ();

sub _match { '[12][0-9]{3} \- (?:0[1-9]|1[012]) \- (?:0[1-9]|[12][0-9]|3[01]) (?:[+-][0-9]{4})?' }

sub _token($) { $_[1]->ymd . ($_[1]->time_zone->name =~ s/UTC$/+0000/r) }

sub _value($)
{	my ($self, $token) = @_;
	$token =~ m/^
		([12][0-9]{3}) \- (0[1-9]|1[012]) \- (0[1-9]|[12][0-9]|3[01])
		([+-] [0-9]{4})?
	$ /x or return;

	my $tz_offset = $4 // '+0000';  # careful with named matches :-(
	my @args = ( year => $1, month => $2, day => $3);
	my $tz = DateTime::TimeZone::OffsetOnly->new(offset => $tz_offset);

	DateTime->new(@args, time_zone => $tz);
}

sub cast($)
{	my ($self, $to) = @_;
	if($to eq 'MF::INTEGER')
	{	# In really exceptional cases, an integer expression can be mis-detected as DATE
		bless $self, 'MF::INTEGER';
		$self->[0] = $self->[1] = eval "$self->[0]";
		return $self;
	}

	if($to eq 'MF::DATETIME')
	{	my $t  = $self->token;
		my $dt = $t =~ /\+/ ? $t =~ s/\+/T00:00:00+/r : $t . 'T00:00:00';
		return MF::DATETIME->new($dt);
	}

	$self->SUPER::cast($to);
}

sub infix(@)
{	my $self = shift;
	my ($op, $right, $context) = @_;

	if($op eq '+' && $right->isa('MF::TIME'))
	{	my $l = $self->value;
		my $r = $right->value;
		my $v = DateTime->new(year => $l->year, month => $l->month, day => $l->day,
			hour => $r->{hour}, minute => $r->{minute}, second => $r->{second},
			nanosecond => $r->{ns}, time_zone => $l->time_zone);

		return MF::DATETIME->new(undef, $v);
	}

	if($op eq '-' && $right->isa('MF::DATE'))
	{	return MF::DURATION->new(undef, $self->value->clone->subtract_datetime($right->value));
	}

	if($op eq '+' || $op eq '-')
	{	my $r = $right->isa('MF::DURATION') ? $right : $right->cast('MF::DURATION', $context);
		! $r || $r->token !~ m/T.*[1-9]/
			or error __x"only duration with full days with DATE, found '{value}'", value => $r->token;

		my $dt = $self->value->clone;
		my $v = $op eq '+' ? $dt->add_duration($right->value) : $dt->subtract_duration($right->value);
		return MF::DATE->new(undef, $v);
	}

	if($op eq '<=>')
	{	my $r   = $right->isa('MF::DATE') ? $right : $right->cast('MF::DATE', $context);
		my ($ld, $ltz) = $self->token =~ m/(.{10})(.*)/;
		my ($rd, $rtz) =    $r->token =~ m/(.{10})(.*)/;

		# It is probably a configuration issue when you configure this.
		$ld ne $rd || ($ltz //'') eq ($rtz //'')
			or warning __x"dates '{first}' and '{second}' do not match on timezone", first => $self->token, second => $r->token;

		return MF::INTEGER->new(undef, $ld cmp $rd);
	}

	$self->SUPER::infix(@_);
}

our %date_attrs = (
	year     => sub { MF::INTEGER->new(undef, $_[0]->value->year)  },
	month    => sub { MF::INTEGER->new(undef, $_[0]->value->month) },
	day      => sub { MF::INTEGER->new(undef, $_[0]->value->day) },
	timezone => sub { MF::TIMEZONE->new($_[0]->value->time_zone->name) },
);
sub attribute($) { $date_attrs{$_[1]} || $_[0]->SUPER::attribute($_[1]) }

#--------------------

package
	MF::TIME;
use base 'Math::Formula::Type';

use constant GIGA => 1_000_000_000;

sub _match { '(?:[01][0-9]|2[0-3]) \: [0-5][0-9] \: (?:[0-5][0-9]) (?:\.[0-9]+)?' }

sub _token($)
{	my $time = $_[1];
	my $ns   = $time->{ns};
	my $frac = $ns ? sprintf(".%09d", $ns) =~ s/0+$//r : '';
	sprintf "%02d:%02d:%02d%s", $time->{hour}, $time->{minute}, $time->{second}, $frac;
}

sub _value($)
{	my ($self, $token) = @_;
	$token =~ m/^ ([01][0-9]|2[0-3]) \: ([0-5][0-9]) \: ([0-5][0-9]) (?:(\.[0-9]+))? $/x
		or return;

	+{ hour => $1+0, minute => $2+0, second => $3+0, ns => ($4 //0) * GIGA };
}

our %time_attrs = (
	hour     => sub { MF::INTEGER->new(undef, $_[0]->value->{hour})  },
	minute   => sub { MF::INTEGER->new(undef, $_[0]->value->{minute}) },
	second   => sub { MF::INTEGER->new(undef, $_[0]->value->{second}) },
	fracsec  => sub { my $t = $_[0]->value; MF::FLOAT->new(undef, $t->{second} + $t->{ns}/GIGA) },
);

sub attribute($) { $time_attrs{$_[1]} || $_[0]->SUPER::attribute($_[1]) }

sub _sec_diff($$)
{	my ($self, $diff, $ns) = @_;
	if($ns < 0)       { $ns += GIGA; $diff -= 1 }
	elsif($ns > GIGA) { $ns -= GIGA; $diff += 1 }

	my $sec = $diff % 60;  $diff /= 60;
	my $min = $diff % 60;
	my $hrs = ($diff / 60) % 24;
	+{ hour => $hrs, minute => $min, second => $sec, nanosecond => $ns};
}

sub infix(@)
{	my $self = shift;
	my ($op, $right, $context) = @_;

	if($op eq '+' || $op eq '-')
	{	# normalization is a pain, so bluntly convert to seconds
		my $time = $self->value;
		my $was  = $time->{hour} * 3600 + $time->{minute} * 60 + $time->{second};

		if(my $r = $right->isa('MF::TIME') ? $right : $right->cast('MF::TIME', $context))
		{	my $v    = $r->value;
			my $min  = $v->{hour} * 3600 + $v->{minute} * 60 + $v->{second};
			my $diff = $self->_sec_diff($was - $min, $time->{ns} - $v->{ns});
			my $frac = $diff->{nanosecond} ? sprintf(".%09d", $diff->{nanosecond}) =~ s/0+$//r : '';
			return MF::DURATION->new(sprintf "PT%dH%dM%d%sS", $diff->{hour}, $diff->{minute},
				$diff->{second}, $frac);
		}

		if(my $r = $right->isa('MF::DURATION') ? $right : $right->cast('MF::DURATION', $context))
		{	my (undef, $hours, $mins, $secs, $ns) =
				$r->value->in_units(qw/days hours minutes seconds nanoseconds/);

			my $dur  = $hours * 3600 + $mins * 60 + $secs;
			my $diff = $op eq '+' ? $was + $dur       : $was - $dur;
			my $nns  = $op eq '+' ? $time->{ns} + $ns : $time->{ns} - $ns;
			return MF::TIME->new(undef, $self->_sec_diff($diff, $ns));
		}
	}

	$self->SUPER::infix(@_);
}

#--------------------

package
	MF::TIMEZONE;
use base 'Math::Formula::Type';
use POSIX  'floor';

sub _match { '[+-] (?: 0[0-9]|1[012] ) [0-5][0-9]' }

sub _token($)
{	my $count = $_[1];
	my $sign = '+';
	($sign, $count) = ('-', -$count) if $count < 0;
	my $hours = floor($count / 60 + 0.0001);
	my $mins  = $count % 60;
	sprintf "%s%02d%02d", $sign, $hours, $mins;
}

# The value is stored in minutes

sub _value($)
{	my ($self, $token) = @_;
	$token =~ m/^ ([+-]) (0[0-9]|1[012]) ([0-5][0-9]) $/x
		or return;

	($1 eq '-' ? -1 : 1) * ( $2 * 60 + $3 );
}

sub cast($)
{	my ($self, $to) = @_;
	if($to->isa('MF::INTEGER') || $to->isa('MF::FLOAT'))
	{	# Oops, we mis-parsed and integer when 1[0-2][0-5][0-9]
		$self->[1] = $self->[0] + 0;
		$self->[0] = undef;
		return bless $self, $to;
	}
	$self->SUPER::cast($to);
}

our %tz_attrs = (
	in_seconds => sub { MF::INTEGER->new(undef, $_[0]->value * 60)  },
	in_minutes => sub { MF::INTEGER->new(undef, $_[0]->value) },
);

sub attribute($) { $tz_attrs{$_[1]} || $_[0]->SUPER::attribute($_[1]) }

sub prefix($$)
{	my ($self, $op, $context) = @_;
	  $op eq '+' ? $self
	: $op eq '-' ? MF::TIMEZONE->new(undef, - $self->value)
	: $self->SUPER::prefix($op, $context);
}

sub infix(@)
{	my $self = shift;
	my ($op, $right, $context) = @_;

	if($op eq '+' || $op eq '-')
	{	if(my $d = $right->isa('MF::DURATION') ? $right : $right->cast('MF::DURATION'))
		{	return MF::TIMEZONE->new(undef, $self->value +
				($op eq '-' ? -1 : 1) * floor($d->inSeconds / 60 + 0.000001));
		}
	}

	$self->SUPER::infix(@_);
}

#--------------------

package
	MF::DURATION;
use base 'Math::Formula::Type';

use DateTime::Duration ();
use POSIX  qw/floor/;

sub _match { '[+-]? P (?:[0-9]+Y)? (?:[0-9]+M)? (?:[0-9]+D)? '
	. ' (?:T (?:[0-9]+H)? (?:[0-9]+M)? (?:[0-9]+(?:\.[0-9]+)?S)? )? \b';
}

use DateTime::Format::Duration::ISO8601 ();
my $dur_format = DateTime::Format::Duration::ISO8601->new;
# Implementation dus not like negatives, but DateTime::Duration does.

sub _token($) { ($_[1]->is_negative ? '-' : '') . $dur_format->format_duration($_[1]) }

sub _value($)
{	my $value    = $_[1];
	my $negative = $value =~ s/^-//;
	my $duration = $dur_format->parse_duration($value);
	$negative ? $duration->multiply(-1) : $duration;
}

sub prefix($$)
{	my ($self, $op, $context) = @_;
	  $op eq '+' ? $self
	: $op eq '-' ? MF::DURATION->new('-' . $self->token)
	:   $self->SUPER::prefix($op, $context);
}

sub infix(@)
{	my $self = shift;
	my ($op, $right, $context) = @_;

	if($op eq '+' || $op eq '-')
	{	my $r  = $right->isa('MF::DURATION') ? $right : $right->cast('MF::DURATION', $context);
		my $v  = $self->value->clone;
		my $dt = ! $r ? undef : $op eq '+' ? $v->add_duration($r->value) : $v->subtract_duration($r->value);
		return MF::DURATION->new(undef, $dt) if $r;
	}
	elsif($op eq '*')
	{	my $r  = $right->isa('MF::INTEGER') ? $right : $right->cast('MF::INTEGER', $context);
		return MF::DURATION->new(undef, $self->value->clone->multiply($r->value)) if $r;
	}
	elsif($op eq '<=>')
	{	my $r  = $right->isa('MF::DURATION') ? $right : $right->cast('MF::DURATION', $context);
		return MF::INTEGER->new(undef, DateTime::Duration->compare($self->value, $r->value)) if $r;
	}

	$self->SUPER::infix(@_);
}


sub inSeconds()
{	my $d = $_[0]->value;
	($d->years + $d->months/12) * 365.256 + $d->days * 86400 + $d->hours * 3600 + $d->minutes * 60 + $d->seconds;
}

my %dur_attrs = (
	in_days    => sub { MF::INTEGER->new(undef, floor($_[0]->inSeconds / 86400 +0.00001)) },
	in_seconds => sub { MF::INTEGER->new(undef, $_[0]->inSeconds) },
);

sub attribute($) { $dur_attrs{$_[1]} || $_[0]->SUPER::attribute($_[1]) }

#--------------------

package
	MF::NAME;
use base 'Math::Formula::Type';

use Log::Report 'math-formula', import => [ qw/error __x/ ];

my $pattern = '[_\p{Alpha}][_\p{AlNum}]*';
sub _match() { $pattern }


sub value() { error __x"name '{name}' cannot be used as value.", name => $_[0]->token }


sub validated($$)
{	my ($class, $name, $where) = @_;

	$name =~ qr/^$pattern$/o
		or error __x"Illegal name '{name}' in '{where}'", name => $name =~ s/[^_\p{AlNum}]/ϴ/gr, where => $where;

	$class->new($name);
}

sub cast(@)
{	my ($self, $type, $context) = @_;

	if($type->isa('MF::FRAGMENT'))
	{	my $frag = $self->token eq '' ? $context : $context->fragment($self->token);
		return MF::FRAGMENT->new($frag->name, $frag) if $frag;
	}

	$context->evaluate($self->token, expect => $type);
}

sub prefix($$)
{	my ($self, $op, $context) = @_;

	return MF::BOOLEAN->new(undef, defined $context->formula($self->token))
		if $op eq 'exists';

	$self->SUPER::prefix($op, $context);
}

sub infix(@)
{	my $self = shift;
	my ($op, $right, $context) = @_;
	my $name = $self->token;

	if($op eq '.')
	{	my $left = $name eq '' ? MF::FRAGMENT->new($context->name, $context) : $context->evaluate($name);
		return $left->infix(@_) if $left;
	}

	if($op eq '#')
	{	my $left = $name eq '' ? MF::FRAGMENT->new($context->name, $context) : $context->fragment($name);
		return $left->infix(@_) if $left;
	}

	if($op eq '//')
	{	return defined $context->formula($name) ? $context->evaluate($name) : $right->compute($context);
	}

	my $left = $context->evaluate($name);
	$left ? $left->infix($op, $right, $context): undef;
}


#--------------------

package
	MF::PATTERN;
use base 'MF::STRING';

use Log::Report 'math-formula', import => [ qw/warning __x/ ];


sub _token($) {
	warning __x"cannot convert qr back to pattern, do {regexp}", regexp => $_[1];
	"pattern meaning $_[1]";
}

sub _from_string($)
{	my ($class, $string) = @_;
	$string->token;        # be sure the pattern is kept as token: cannot be recovered
	bless $string, $class;
}

sub _to_regexp($)
{	my @chars  = $_[0] =~ m/( \\. | . )/gxu;
	my (@regexp, $in_alts, $in_range);

	foreach my $char (@chars)
	{	if(length $char==2) { push @regexp, $char; next }
		if($char !~ /^[\[\]*?{},!]$/) { push @regexp, $in_range ? $char : quotemeta $char }
		elsif($char eq '*') { push @regexp, '.*' }
		elsif($char eq '?') { push @regexp, '.' }
		elsif($char eq '[') { push @regexp, '['; $in_range++ }
		elsif($char eq ']') { push @regexp, ']'; $in_range=0 }
		elsif($char eq '!') { push @regexp, $in_range && $regexp[-1] eq '[' ? '^' : '\!' }
		elsif($char eq '{') { push @regexp, $in_range ? '{' : '(?:'; $in_range or $in_alts++ }
		elsif($char eq '}') { push @regexp, $in_range ? '}' : ')';   $in_range or $in_alts=0 }
		elsif($char eq ',') { push @regexp, $in_alts ? '|' : '\,' }
		else {die}
	}
	my $regexp = join '', @regexp;
	qr/^${regexp}$/u;
}


sub regexp() { $_[0][2] //= _to_regexp($_[0]->value) }

#--------------------

package
	MF::REGEXP;
use base 'MF::STRING';

sub _from_string($)
{	my ($class, $string) = @_;
	bless $string, $class;
}


sub regexp
{	my $self = shift;
	return $self->[2] if defined $self->[2];
	my $value  = $self->value =~ s!/!\\/!gr;
	$self->[2] = qr/$value/xu;
}

#--------------------

package
	MF::FRAGMENT;
use base 'Math::Formula::Type';

use Log::Report 'math-formula', import => [ qw/panic error __x/ ];

sub name    { $_[0][0] }
sub context { $_[0][1] }

sub infix(@)
{	my $self = shift;
	my ($op, $right, $context) = @_;
	my $name = $right->token;

	if($op eq '#' && $right->isa('MF::NAME'))
	{	my $fragment = $self->context->fragment($name)
			or error __x"cannot find fragment '{name}' in '{context}'", name => $name, context => $context->name;

		return $fragment;
	}

	if($op eq '.' && $right->isa('MF::NAME'))
	{	my $result = $self->context->evaluate($name);
		return $result if $result;
	}

	$self->SUPER::infix(@_);
}

1;
