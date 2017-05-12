package JE::Object::Date;

our $VERSION = '0.066';


use strict;
use warnings; no warnings 'utf8';

use JE::Code 'add_line_number';
#use Memoize;
use POSIX 'floor';
use Scalar::Util 1.1 qw'blessed weaken looks_like_number';
use Time::Local 'timegm_nocheck';
use Time::Zone 'tz_local_offset';

our @ISA = 'JE::Object';

##require JE::Number;
require JE::Object;
require JE::Object::Error::TypeError;
require JE::Object::Function;
require JE::String;

use constant EPOCH_OFFSET => timegm_nocheck(0,0,0,1,0,1970);

=head1 NAME

JE::Object::Date - JavaScript Date object class

=head1 SYNOPSIS

  use JE;

  $j = new JE;

  $js_date = new JE::Object::Date $j;

  $js_date->value; # 1174886940.466
  "$js_date";      # Sun Mar 25 22:29:00 2007 -0700

=head1 DESCRIPTION

This class implements JavaScript Date objects for JE.

=head1 METHODS

See L<JE::Types> and L<JE::Object> for descriptions of most of the methods. 
Only what
is specific to JE::Object::Date is explained here.

=over

=cut

my %mon_numbers = qw/ Jan 0 Feb 1 Mar 2 Apr 3 May 4 Jun 5 Jul 6 Aug 7 Sep 8
                      Oct 9 Nov 10 Dec 11 /;

sub new {
	my($class, $global) = (shift, shift);
	my $self = $class->SUPER::new($global, {
		prototype => $global->prototype_for('Date')
		          || $global->prop('Date')->prop('prototype')
	});

	if (@_ >= 2) {
		my($year,$month,$date,$hours,$minutes,$seconds,$ms) = @_;
		for($year,$month) {
			defined()
			? defined blessed $_ && $_->can('to_number') &&
			  ($_ = $_->to_number->value)
			: ($_ = sin 9**9**9);
		}
		defined $date
		? defined blessed $date && $date->can('to_number') &&
		  ($date = $date->to_number->value)
		: ($date = 1);
		for($hours,$minutes,$seconds,$ms) {
			no warnings 'uninitialized'; # undef --> 0
			$_ = defined blessed $_ && (can $_ 'to_number')
			?	$_->to_number->value
			:	0+$_;
		}
		$year >= 0 and int($year) <= 99 and $year += 1900;
		$$$self{value} = _time_clip(_local2gm(_make_date(
			_make_day($year,$month,$date),
			_make_time($hours,$minutes,$seconds,$ms),
		)));
		
	}
	elsif (@_ and
            defined blessed $_[0]
	    ? (my $prim = $_[0]->to_primitive)->isa('JE::String')
	    : !looks_like_number $_[0]) {
		$$$self{value} = _parse_date("$_[0]");
			
	} elsif(@_) {
		$$$self{value} = _time_clip (
			defined $_[0]
			? defined blessed $_[0]
			  && $_[0]->can('to_number')
				? $_[0]->to_number->value
				: 0+$_[0]
			: 0
		);
	} else {
		require Time::HiRes;
		$$$self{value} =
		 int +(Time::HiRes::time() - EPOCH_OFFSET) * 1000;
	}
	$self;
}




=item value

Returns the date as the number of seconds since the epoch, with up to three
decimal places.

=cut

sub value { $${$_[0]}{value}/1000 + EPOCH_OFFSET }



=item class

Returns the string 'Date'.

=cut

sub class { 'Date' }



sub to_primitive { SUPER::to_primitive{shift}@_?@_:'string' }


=back

=head1 SEE ALSO

L<JE>, L<JE::Types>, L<JE::Object>

=cut


# Most of these functions were copied directly from ECMA-262. Those were
# not optimised for speed,  but apparently either for clarity or obfusca-
# tion--I’ve yet to ascertain which. These need to be optimized, and many
# completely rewritten.

# ~~~ Are these useful enough to export them?
sub MS_PER_DAY() { 86400000 }
use constant LOCAL_TZA => do {
 # ~~~ I need to test this by subtracting 6 mumps -- but how?
	my $time = time;
	1000 * (tz_local_offset($time) - (localtime $time)[8] * 3600)
};

# ~~~ I still need to figure which of these (if any) actually benefit from
#     memoisation.

# This stuff was is based on code from Time::Local 1.11, with various
# changes (particularly the removal of stuff we don’t need).
my @MonthDays = (31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
my %Cheat;
sub _daygm {
    $_[3] + ($Cheat{(),@_[4,5]} ||= do {
        my $month = ($_[4] + 10) % 12;
        my $year = $_[5] - int $month/10;
        365*$year + floor($year/4) - floor($year/100) + floor($year/400) +
            int(($month*306 + 5)/10) - 719469
    });
}
sub _timegm {
	my ($sec,$min,$hour,$mday,$month,$year) = @_;

	my $days = _daygm(undef, undef, undef, $mday, $month, $year);
	my $xsec = $sec + 60*$min + 3600*$hour;

	$xsec + 86400 * $days;	
}


sub _day($) { floor $_[0] / MS_PER_DAY }
sub _time_within_day($) { $_[0] % MS_PER_DAY }
sub _days_in_year($) {
	365 + not $_[0] % 4 || !($_[0] % 100) && $_[0] % 400
}
sub _day_from_year($) {
	my $y = shift;
	365 * ($y - 1970) + floor(($y - 1969) / 4) -
		floor(($y - 1901) / 100) + floor(($y - 1601) / 400)
}
sub _time_from_year($) { MS_PER_DAY * &_day_from_year }
sub _div($$) {
    my $mod = $_[0] % $_[1];
    return +($_[0] - $mod) / $_[1], $mod;
}
sub _year_from_time($) {
	# This line adjusts the  time  so  that  1/Mar/2000  is  0,  and
	# 29/Feb/2400, the extra leap day in the quadricentennium, is the
	# last day therein.  (So a qcm is  4 centuries  +  1  leap  day.)
	my $time = $_[0] - 951868800_000;

	(my $prec, $time) = _div $time, MS_PER_DAY * (400 * 365 + 97);
	$prec *= 400; # number of years preceding the current quadri-
	                  # centennium

	# Divide by a century and we have centuries preceding the current
	# century and the time within the century, unless $tmp == 4, ...
	(my $tmp, $time) = _div $time, MS_PER_DAY * (100 * 365 + 24);
	if($tmp == 4) { # ... in which case we already know the year, since
	                # this is the last day of a qcm
		return $prec + 400 + 2000;
	}
	$prec += $tmp * 100; # preceding the current century
	
	# A century is 24 quadrennia followed by four non-leap years, or,
	# since we are starting with March,  25 quadrennia with one day 
	# knocked off the end.  So no special casing is  needed  here.
	($tmp, $time) = _div $time, MS_PER_DAY * (4 * 365 + 1);
	$prec += $tmp * 4; # preceding the current quadrennium
	
	($tmp, $time) = _div $time, MS_PER_DAY * 365;
	# Same special case we encountered when dividing qcms, since there
	# is an extra day on the end.
	if($tmp == 4) {
		return $prec + 4 + 2000;
	}
	$prec + 2000 + $tmp +    # Add 1 if we are past Dec.:
		($time >= (31+30+31+30+31+31+30+31+30+31) * MS_PER_DAY);
		           # days from Mar 1 to Jan 1
}
sub _in_leap_year($) { _days_in_year &_year_from_time == 366 }
sub _day_within_year($) { &_day - _day_from_year &_year_from_time }
sub _month_from_time($) {
	my $dwy = &_day_within_year;
	my $ily = &_in_leap_year;
	return 0 if $dwy < 31;
	my $counter = 1;
	for (qw/59 90 120 151 181 212 243 273 304 334 365/) {
		return $counter if $dwy < $_ + $ily;
		++$counter;
	}
}
sub _date_from_time($) {
	my $dwy = &_day_within_year;
	my $mft = &_month_from_time;
	return $dwy+1 unless $mft;
	return $dwy-30 if $mft == 1;
	return $dwy - qw/0 0 58 89 119 150 180 211 242 272 303 333/[$mft]
		- &_in_leap_year;
}
sub _week_day($) { (&_day + 4) % 7 }

# $_dumdeedum[0] will contain the nearest non-leap-year that begins on Sun-
# day, $_dumdeedum[1] the nearest beginning on Monday, etc.
# @_dumdeedum[7..15] are for leap years.
# For the life of me I can't think of a name for this array!
{
	my @_dumdeedum; 

	my $this_year = (gmtime(my $time = time))[5]+1900;
	$_dumdeedum[_week_day(_time_from_year _year_from_time $time*1000) +
		7 * (_days_in_year($this_year)==366) ] = $this_year;

	my $next_past = my $next_future = $this_year;
	my $count = 1; my $index;
	while ($count < 14) {
		$index = (_day_from_year(--$next_past) + 4) % 7 +
			7 * (_days_in_year($next_past)==366);
		unless (defined $_dumdeedum[$index]) {
			$_dumdeedum[$index] = $next_past;
			++$count;
		}
		$index = (_day_from_year(++$next_future) + 4) % 7 +
			7 * (_days_in_year($next_future)==366);
		unless (defined $_dumdeedum[$index]) {
			$_dumdeedum[$index] = $next_future;
			++$count;
		}
	}
# The spec requires that the same formula for daylight savings be used for
# all years.  An ECMAScript implementation is not  allowed  to  take  into
# account that the formula might have changed in the past. That's what the
# @_dumdeedum array is for. The spec basically allows for fourteen differ-
# ent possibilities for the dates for daylight savings time  change.  The
# code above collects the 'nearest' fourteen years that are not equivalent
# to each other.

	sub _ds_time_adjust($) {
		my $year = _year_from_time(my $time = $_[0]);
		my $ddd_index = (_day_from_year($year) + 4) % 7 +
				7 * (_days_in_year $year == 366);
		my $time_within_year = $time - _time_from_year $year;
		(localtime
		  +(
		    $time_within_year +
		    _time_from_year $_dumdeedum[$ddd_index]
		  ) / 1000 # convert to seconds
		  + EPOCH_OFFSET
		)[8] * 3600_000
	}
}

sub _gm2local($) {
	# shortcut for nan & inf to avoid localtime(nan) warning
	return $_[0] unless $_[0] == $_[0] and $_[0]+1 != $_[0];

	$_[0] + LOCAL_TZA + &_ds_time_adjust
}

sub _local2gm($) {
	# shortcut for nan & inf to avoid localtime(nan) warning
	return $_[0] unless $_[0] == $_[0] and $_[0]+1 != $_[0];

	$_[0] - LOCAL_TZA - _ds_time_adjust $_[0] - LOCAL_TZA
}

sub _hours_from_time($) { floor($_[0] / 3600_000) % 24 }
sub _min_from_time($) { floor($_[0] / 60_000) % 60 }
sub _sec_from_time($) { floor($_[0] / 1000) % 60 }
sub _ms_from_time($) { $_[0] % 1000 }

sub _make_time($$$$) {
	my ($hour, $min, $sec, $ms) = @_;
	for(\($hour, $min, $sec, $ms)) {
		$$_ + 1 == $$_ or $$_ != $$_ and return sin 9**9**9;
		$$_ = int $$_; # ~~~ Is this necessary? Is it sufficient?
	}
	$hour * 3600_000 +
	$min  *   60_000 +
	$sec  *     1000 +
	$ms;
}

sub _make_day($$$) {
	my ($year, $month, $date) = @_;
	for(\($year, $month, $date)) {
		$$_ + 1 == $$_ or $$_ != $$_ and return sin 9**9**9;
		$$_ = int $$_; # ~~~ Is it sufficient?
	}
	$year += floor($month/12);
	$month %= 12;
	_timegm(0,0,0,$date,$month,$year)
		/
	(MS_PER_DAY/1000)
}

sub _make_date($$) {
	my ($day, $time) = @_;
	for(\($day, $time)) {
		$$_ + 1 == $$_ or $$_ != $$_ and return sin 9**9**9;
	}
	$day * MS_PER_DAY + $time
}

sub _time_clip($) {
	my ($time) = @_;
	$time + 1 == $time or $time != $time and return sin 9**9**9;
	abs($time) > 8.64e15 and return sin 9**9**9;
	int $time
}

sub _parse_date($) {
	# If the date matches the format output by
	# to(GMT|UTC|Locale)?String, we need to parse it ourselves.
	# Otherwise, we pass it on to Date::Parse, and live with
	# the latter’s limited range.
	# ~~~ (Maybe I should change this to use
	#      DateTime::Format::Natural.)

	my $str = shift;
	my $time;
	if($str =~ /^(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat)[ ]
            (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[ ]
            ([ \d]\d)\ (\d\d):(\d\d):(\d\d)\ (\d{4,})
            [ ]([+-]\d{2})(\d{2})
          \z/x) {
		$time = _timegm($5,$4,$3,$2,$mon_numbers{$1},$6)
			+ $7*-3600 + $8*60;
	} elsif($str =~ /^(?:Sun|Mon|Tue|Wed|Thu|Fri|Sat),[ ]
            (\d\d?)[ ]
            (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)[ ]
	    (\d{4,})\ (\d\d):(\d\d):(\d\d)\ GMT 
          \z/x) {
		$time = _timegm($6,$5,$4,$1,$mon_numbers{$2},$3);
	} else {
		require Date::Parse;
		if(defined($time = Date::Parse::str2time($str))) {
			$time -= EPOCH_OFFSET
		}
	}
	defined $time ? $time * 1000 :
		sin 9**9**9;
}

my @days = qw/ Sun Mon Tue Wed Thu Fri Sat Sun /;
my @mon  = qw/ Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec /;
sub _new_constructor {
	() = (@days, @mon); # work-around for perl bug #16302
	my $global = shift;
	my $f = JE::Object::Function->new({
		name            => 'Date',
		scope            => $global,
		argnames         => [qw/year    month date hours minutes
		                        seconds ms/],
		function         => sub {
			my $time = time;
			my $offset = tz_local_offset($time);
			my $sign = qw/- +/[$offset >= 0];
			return JE::String->_new($global,
				localtime($time) . " $sign" .
				sprintf '%02d%02d',
					_div abs($offset)/60, 60
			);
		},
		function_args    => [],
		constructor      => sub {
			unshift @_, __PACKAGE__;
			goto &new;
		},
		constructor_args => ['scope','args'],
	});

	$f->prop({
		name  => 'parse',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'parse',
			argnames => ['string'],
			no_proto => 1,
			function_args => ['args'],
			function => sub {
				my $str = shift;
				JE::Number->new($global, 
				    defined $str
				    ? _parse_date $str->to_string->value
				    : 'nan'
				);
			},
		}),
		dontenum => 1,
	});

	$f->prop({
	  name  => 'UTC',
	  value => JE::Object::Function->new({
	    scope  => $global,
	    name    => 'UTC',
	    argnames => [qw 'year month date hours minutes
	                     seconds ms' ],
	    no_proto => 1,
	    function_args => ['args'],
	    function => sub {
	      my($year,$month,$date,$hours,$minutes,$seconds,$ms) = @_;
	      for($year,$month) {
	        $_ = defined() ? $_->to_number->value : sin 9**9**9
	      }
	      $date = defined $date ? $date->to_number->value : 1;
	      for($hours,$minutes,$seconds,$ms) {
	        $_ = defined $_ ? $_->to_number->value : 0;
	      }
	      $year >= 0 and int($year) <= 99 and $year += 1900;
	      JE::Number->new($global, 
	        _time_clip(_make_date(
	          _make_day($year,$month,$date),
	          _make_time($hours,$minutes,$seconds,$ms),
	        ))
	      );
	    },
	  }),
	  dontenum => 1,
	});

	my $proto = bless $f->prop({
		name    => 'prototype',
		dontenum => 1,
		readonly => 1,
	}), __PACKAGE__;
	$global->prototype_for('Date'=>$proto);

	$$$proto{value} = sin 9**9**9;

	$proto->prop({
		name  => 'toString',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'toString',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number
			      "Arg to toString ($_[0]) is not a date")
			    unless $_[0]->isa('JE::Object::Date');
			  # Can’t use localtime because of its lim-
			  # ited range.
			  my $v = $${+shift}{value};
			  my $time = _gm2local $v;
			  my $offset = ($time - $v) / 60_000;
			  my $sign = qw/- +/[$offset >= 0];
			  return JE::String->_new($global,
			    sprintf
			      '%s %s %2d %02d:%02d:%02d %04d %s%02d%02d',
			      $days[_week_day $time],       # Mon
			      $mon[_month_from_time $time], # Dec
			      _date_from_time $time,        # 31
			      _hours_from_time $time,       # 11:42:40
			      _min_from_time $time,         
			      _sec_from_time $time,
			      _year_from_time $time,        # 2007
			      $sign,                        # -
			      _div abs($offset), 60         # 0800
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'toDateString',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'toString',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number
			      "Arg to toDateString ($_[0]) is not a date")
			    unless $_[0]->isa('JE::Object::Date');
			  my $time = _gm2local $${+shift}{value};
			  return JE::String->_new($global,
			    sprintf
			      '%s %s %d %04d',
			      $days[_week_day $time],       # Mon
			      $mon[_month_from_time $time], # Dec
			      _date_from_time $time,        # 31
			      _year_from_time $time,        # 2007
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'toTimeString',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'toTimeString',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number
			      "Arg to toTimeString ($_[0]) is not a date")
			    unless $_[0]->isa('JE::Object::Date');
			  my $time = _gm2local $${+shift}{value};
			  return JE::String->_new($global,
			    sprintf
			      '%02d:%02d:%02d',
			      _hours_from_time $time, 
			      _min_from_time $time,         
			      _sec_from_time $time,
			  );
			},
		}),
		dontenum => 1,
	});

	# ~~~ How exactly should I make these three behave? Should I leave
	#     them as they is?
	$proto->prop({
		name => 'toLocaleString',
		value => $proto->prop('toString'),
		dontenum => 1,
	});
	$proto->prop({
		name => 'toLocaleDateString',
		value => $proto->prop('toDateString'),
		dontenum => 1,
	});
	$proto->prop({
		name => 'toLocaleTimeString',
		value => $proto->prop('toTimeString'),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'valueOf',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'valueOf',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number
			      "Arg to valueOf ($_[0]) is not a date")
			    unless $_[0]->isa('JE::Object::Date');
				JE::Number->new(
					$global,$${+shift}{value}
				);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'getTime',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getTime',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
				$_[0]->class eq 'Date' or die
					JE'Object'Error'TypeError->new(
						$global,
						"getTime cannot be called".
						" on an object of type " .
						shift->class
					);
				JE::Number->new(
					$global,$${+shift}{value}
				);
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'getYear',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getYear',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number
			      "Arg to getYear ($_[0]) is not a date")
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  $v == $v or return JE::Number->new($global,$v);
			  JE::Number->new( $global,
			    _year_from_time(_gm2local $v) - 1900
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'getFullYear',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getFullYear',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number
			      "Arg to getFullYear ($_[0]) is not a date")
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  $v == $v or return JE::Number->new($global,$v);
			  JE::Number->new( $global,
			    _year_from_time(_gm2local $v)
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'getUTCFullYear',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getUTCFullYear',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "getUTCFullYear cannot be " .
			     "called on an object of type " . $_[0]->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  $v == $v or return JE::Number->new($global,$v);
			  JE::Number->new( $global,
			    _year_from_time( $v)
			  );
			},
		}),
		dontenum => 1,
	});


	$proto->prop({
		name  => 'getMonth',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getMonth',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number
			      "Arg to getMonth ($_[0]) is not a date")
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  $v == $v or return JE::Number->new($global,$v);
			  JE::Number->new( $global,
			    _month_from_time(_gm2local $v)
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'getUTCMonth',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getUTCMonth',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "getUTCMonth cannot be called".
			      " on an object of type " . $_[0]->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  $v == $v or return JE::Number->new($global,$v);
			  JE::Number->new( $global,
			    _month_from_time($v)
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'getDate',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getDate',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number
			    "getDate cannot be called on an object of type"
			    . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  $v == $v or return JE::Number->new($global,$v);
			  JE::Number->new( $global,
			    _date_from_time(_gm2local $v)
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'getUTCDate',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getUTCDate',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "getUTCDate cannot be called ".
			    "on an object of type"
			    . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  $v == $v or return JE::Number->new($global,$v);
			  JE::Number->new( $global,
			    _date_from_time($v)
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'getDay',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getDay',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number
			    "getDay cannot be called on an object of type"
			    . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  $v == $v or return JE::Number->new($global,$v);
			  JE::Number->new( $global,
			    _week_day(_gm2local $v)
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'getUTCDay',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getUTCDay',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "getUTCDay cannot be called ".
			    "on an object of type"
			    . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  $v == $v or return JE::Number->new($global,$v);
			  JE::Number->new( $global,
			    _week_day($v)
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'getHours',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getHours',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number
			   "getHours cannot be called on an object of type"
			    . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  $v == $v or return JE::Number->new($global,$v);
			  JE::Number->new( $global,
			    _hours_from_time(_gm2local $v)
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'getUTCHours',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getUTCHours',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "getUTCHours cannot be called".
			    " on an object of type"
			    . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  $v == $v or return JE::Number->new($global,$v);
			  JE::Number->new( $global,
			    _hours_from_time($v)
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'getMinutes',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getMinutes',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "getMinutes cannot be called" .
			      " on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  $v == $v or return JE::Number->new($global,$v);
			  JE::Number->new( $global,
			    _min_from_time(_gm2local $v)
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'getUTCMinutes',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getUTCMinutes',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "getUTCMinutes cannot be " .
			      "called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  $v == $v or return JE::Number->new($global,$v);
			  JE::Number->new( $global,
			    _min_from_time($v)
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'getSeconds',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getSeconds',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "getSeconds cannot be called" .
			      " on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  $v == $v or return JE::Number->new($global,$v);
			  JE::Number->new( $global,
			    _sec_from_time(_gm2local $v)
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name => 'getUTCSeconds',
		value => $proto->prop('getSeconds'),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'getMilliseconds',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getMilliseconds',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "getMilliseconds cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  $v == $v or return JE::Number->new($global,$v);
			  JE::Number->new( $global,
			    _ms_from_time(_gm2local $v)
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name => 'getUTCMilliseconds',
		value => $proto->prop('getMilliseconds'),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'getTimezoneOffset',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'getTimezoneOffset',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "getTimezoneOffset cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  $v == $v or return JE::Number->new($global,$v);
			  JE::Number->new( $global,
			    ($v - _gm2local $v) / 60_000
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'setTime',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'setTime',
			argnames => ['time'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "setTime cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  JE::Number->new( $global, $${$_[0]}{value} = 
			    _time_clip(
			      defined $_[1] ? $_[1]->to_number->value :
			        sin 9**9**9
			    )
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'setMilliseconds',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'setMilliseconds',
			argnames => ['ms'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "setMilliseconds cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${$_[0]}{value};
			  JE::Number->new( $global, $${$_[0]}{value} = 
			    _time_clip _make_date
			      _day $v,
			      _make_time
			        _hours_from_time $v,
			        _min_from_time $v,
			        _sec_from_time $v,
			        defined $_[1] ? $_[1]->to_number->value :
			          sin 9**9**9
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name => 'setUTCMilliseconds',
		value => $proto->prop('setMilliseconds'),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'setSeconds',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'setSeconds',
			argnames => ['sec','ms'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "setSeconds cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $s = defined $_[1] ? $_[1]->to_number->value
			    : sin 9**9**9;
			  if($s != $s) {
			   $_[0]{value} = sin 9**9**9;
			   return JE::Number->new($global,sin 9**9**9);
			  }
			  my $v = $${$_[0]}{value};
			  my $ms =
			   defined $_[2]
			   ? $_[2]->to_number->value
			   : _ms_from_time $v;
			  if($ms!=$ms) {
			   $_[0]{value} = sin 9**9**9;
			   return JE::Number->new(sin 9**9**9);
			  }
			  JE::Number->new( $global, $${$_[0]}{value} = 
			    _time_clip _make_date
			      _day $v,
			      _make_time
			        _hours_from_time $v,
			        _min_from_time $v,
			         $s,
			         $ms,
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name => 'setUTCSeconds',
		value => $proto->prop('setSeconds'),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'setMinutes',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'setMinutes',
			argnames => ['min','sec','ms'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "setMinutes cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $m = defined $_[1] ? $_[1]->to_number->value
			    : sin 9**9**9;
			  if($m != $m) {
			   $_[0]{value} = sin 9**9**9;
			   return JE::Number->new($global,sin 9**9**9);
			  }
			  my $v = _gm2local $${$_[0]}{value};
			  my $s =
			   defined $_[2]
			   ? $_[2]->to_number->value
			   : _sec_from_time $v;
			  my $ms =
			   defined $_[3]
			   ? $_[3]->to_number->value
			   : _ms_from_time $v;
			  if($s!=$s || $ms!=$ms) {
			   $_[0]{value} = sin 9**9**9;
			   return JE::Number->new(sin 9**9**9);
			  }
			  JE::Number->new( $global, $${$_[0]}{value} = 
			    _time_clip _local2gm _make_date
			      _day $v,
			      _make_time _hours_from_time $v, $m, $s, $ms
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'setUTCMinutes',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'setUTCMinutes',
			argnames => ['min','sec','ms'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "setUTCMinutes cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $m = defined $_[1] ? $_[1]->to_number->value
			    : sin 9**9**9;
			  if($m != $m) {
			   $_[0]{value} = sin 9**9**9;
			   return JE::Number->new($global,sin 9**9**9);
			  }
			  my $v = $${$_[0]}{value};
			  my $s =
			   defined $_[2]
			   ? $_[2]->to_number->value
			   : _sec_from_time $v;
			  my $ms =
			   defined $_[3]
			   ? $_[3]->to_number->value
			   : _ms_from_time $v;
			  if($s!=$s || $ms!=$ms) {
			   $_[0]{value} = sin 9**9**9;
			   return JE::Number->new(sin 9**9**9);
			  }
			  JE::Number->new( $global, $${$_[0]}{value} = 
			    _time_clip _make_date
			      _day $v,
			      _make_time _hours_from_time $v, $m, $s, $ms
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'setHours',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'setHours',
			argnames => ['hour','min','sec','ms'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "setHours cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $h = defined $_[1] ? $_[1]->to_number->value
			    : sin 9**9**9;
			  if($h != $h) {
			   $_[0]{value} = sin 9**9**9;
			   return JE::Number->new($global,sin 9**9**9);
			  }
			  my $v = _gm2local $${$_[0]}{value};
			  my $m =
			   defined $_[2]
			   ? $_[2]->to_number->value
			   : _min_from_time $v;
			  my $s =
			   defined $_[3]
			   ? $_[3]->to_number->value
			   : _sec_from_time $v;
			  my $ms =
			   defined $_[4]
			   ? $_[4]->to_number->value
			   : _ms_from_time $v;
			  if($m!=$m || $s!=$s || $ms!=$ms) {
			   $_[0]{value} = sin 9**9**9;
			   return JE::Number->new(sin 9**9**9);
			  }
			  JE::Number->new( $global, $${$_[0]}{value} = 
			    _time_clip _local2gm _make_date
			      _day $v,
			      _make_time $h, $m, $s, $ms
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'setUTCHours',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'setUTCHours',
			argnames => ['hour','min','sec','ms'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "setUTCHours cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $h = defined $_[1] ? $_[1]->to_number->value
			    : sin 9**9**9;
			  if($h != $h) {
			   $_[0]{value} = sin 9**9**9;
			   return JE::Number->new($global,sin 9**9**9);
			  }
			  my $v = $${$_[0]}{value};
			  my $m =
			   defined $_[2]
			   ? $_[2]->to_number->value
			   : _min_from_time $v;
			  my $s =
			   defined $_[3]
			   ? $_[3]->to_number->value
			   : _sec_from_time $v;
			  my $ms =
			   defined $_[4]
			   ? $_[4]->to_number->value
			   : _ms_from_time $v;
			  if($m!=$m || $s!=$s || $ms!=$ms) {
			   $_[0]{value} = sin 9**9**9;
			   return JE::Number->new(sin 9**9**9);
			  }
			  JE::Number->new( $global, $${$_[0]}{value} = 
			    _time_clip _make_date
			      _day $v,
			      _make_time $h, $m, $s, $ms
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'setDate',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'setDate',
			argnames => ['date'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "setDate cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $d = defined $_[1] ? $_[1]->to_number->value
			    : sin 9**9**9;
			  if($d != $d) {
			   $_[0]{value} = $d;
			   return JE::Number->new($global,$d)
			  }
			  my $v = _gm2local $${$_[0]}{value};
			  JE::Number->new( $global, $${$_[0]}{value} = 
			    _time_clip _local2gm _make_date
			      _make_day(
			        _year_from_time $v,
			        _month_from_time $v,
			        $d
			      ),
			      _time_within_day $v
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'setUTCDate',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'setUTCDate',
			argnames => ['date'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "setUTCDate cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $d = defined $_[1] ? $_[1]->to_number->value
			    : sin 9**9**9;
			  if($d != $d) {
			   $_[0]{value} = $d;
			   return JE::Number->new($global,$d)
			  }
			  my $v = $${$_[0]}{value};
			  JE::Number->new( $global, $${$_[0]}{value} = 
			    _time_clip _make_date
			      _make_day(
			        _year_from_time $v,
			        _month_from_time $v,
			        $d
			      ),
			      _time_within_day $v
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'setMonth',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'setMonth',
			argnames => ['month','date'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "setMonth cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $m = defined $_[1] ? $_[1]->to_number->value
			    : sin 9**9**9;
			  if($m != $m) {
			   $_[0]{value} = sin 9**9**9;
			   return JE::Number->new($global,sin 9**9**9)
			  }
			  my $v = _gm2local $${$_[0]}{value};
			  my $d =
			   defined $_[2]
			   ? $_[2]->to_number->value
			   : _date_from_time $v;
			  JE::Number->new( $global, $${$_[0]}{value} = 
			    _time_clip _local2gm _make_date
			      _make_day(
			        _year_from_time $v,
			        $m,
			        $d
			      ),
			      _time_within_day $v
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'setUTCMonth',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'setUTCMonth',
			argnames => ['month','date'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "setUTCMonth cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $m = defined $_[1] ? $_[1]->to_number->value
			    : sin 9**9**9;
			  if($m != $m) {
			   $_[0]{value} = sin 9**9**9;
			   return JE::Number->new($global,sin 9**9**9)
			  }
			  my $v = $${$_[0]}{value};
			  my $d =
			   defined $_[2]
			   ? $_[2]->to_number->value
			   : _date_from_time $v;
			  JE::Number->new( $global, $${$_[0]}{value} = 
			    _time_clip _make_date
			      _make_day(
			        _year_from_time $v,
			        $m,
			        $d
			      ),
			      _time_within_day $v
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'setYear',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'setMilliseconds',
			argnames => ['ms'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "setYear cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $y = defined $_[1] ? $_[1]->to_number->value
			    : sin 9**9**9;
			  if($y != $y) {
			   $_[0]{value} = $y; return JE::Number->new($y)
			  }
			  my $inty = int $y;
			  $inty >= 0 && $inty <= 99 and $y = $inty+1900;
			  my $v = _gm2local $${$_[0]}{value};
			  $v == $v or $v = 0;
			  JE::Number->new( $global, $${$_[0]}{value} = 
			    _time_clip _local2gm _make_date
			      _make_day(
			        $y,
			        _month_from_time $v,
			        _date_from_time $v
			      ),
			      _time_within_day $v
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'setFullYear',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'setFullYear',
			argnames => ['year','month','date'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "setFullYear cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $y = defined $_[1] ? $_[1]->to_number->value
			    : sin 9**9**9;
			  if($y != $y) {
			   $_[0]{value} = sin 9**9**9;
			   return JE::Number->new($global,sin 9**9**9)
			  }
			  my $v = _gm2local $${$_[0]}{value};
			  my $m =
			   defined $_[2]
			   ? $_[2]->to_number->value
			   : _month_from_time $v;
			  my $d =
			   defined $_[3]
			   ? $_[3]->to_number->value
			   : _date_from_time $v;
			  JE::Number->new( $global, $${$_[0]}{value} = 
			    _time_clip _local2gm _make_date
			      _make_day(
			        $y,
			        $m,
			        $d
			      ),
			      _time_within_day $v
			  );
			},
		}),
		dontenum => 1,
	});

	$proto->prop({
		name  => 'setUTCFullYear',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'setUTCFullYear',
			argnames => ['year','month','date'],
			no_proto => 1,
			function_args => ['this','args'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "setUTCFullYear cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $y = defined $_[1] ? $_[1]->to_number->value
			    : sin 9**9**9;
			  if($y != $y) {
			   $_[0]{value} = sin 9**9**9;
			   return JE::Number->new($global,sin 9**9**9)
			  }
			  my $v = $${$_[0]}{value};
			  my $m =
			   defined $_[2]
			   ? $_[2]->to_number->value
			   : _month_from_time $v;
			  my $d =
			   defined $_[3]
			   ? $_[3]->to_number->value
			   : _date_from_time $v;
			  JE::Number->new( $global, $${$_[0]}{value} = 
			    _time_clip _make_date
			      _make_day(
			        $y,
			        $m,
			        $d
			      ),
			      _time_within_day $v
			  );
			},
		}),
		dontenum => 1,
	});

	my $tgs = $proto->prop({
		name  => 'toGMTString',
		value => JE::Object::Function->new({
			scope  => $global,
			name    => 'toGMTString',
			no_proto => 1,
			function_args => ['this'],
			function => sub {
			  die JE::Object::Error::TypeError->new($global,
			    add_line_number "toGMTString cannot be" .
			      " called on an object of type"
			      . shift->class)
			    unless $_[0]->isa('JE::Object::Date');
			  my $v = $${+shift}{value};
			  JE::String->_new( $global,
			    sprintf "%s, %02d %s %04d %02d:%02d:%02d GMT",
			      $days[_week_day $v], _date_from_time $v,
			      $mon[_month_from_time $v],
			      _year_from_time $v, _hours_from_time $v,
			      _min_from_time $v, _sec_from_time $v
			  );
			},
		}),
		dontenum => 1,
	});
	$proto->prop(
		{name => toUTCString => value => $tgs => dontenum => 1}
	);

	weaken $global;
	$f;
}



return "a true value";
