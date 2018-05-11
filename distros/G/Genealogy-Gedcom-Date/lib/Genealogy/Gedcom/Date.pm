package Genealogy::Gedcom::Date;

use strict;
use utf8;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Config;

use Data::Dumper::Concise; # For Dumper().

use Genealogy::Gedcom::Date::Actions;

use Log::Handler;

use Marpa::R2;

use Moo;

use Try::Tiny;

use Types::Standard qw/Any ArrayRef Bool Int HashRef Str/;

has bnf =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has _calendar =>
(
	default  => sub{return 'Gregorian'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has canonical =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has date =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has error =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has grammar =>
(
	default  => sub {return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has logger =>
(
	default  => sub{return undef},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has maxlevel =>
(
	default  => sub{return 'notice'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has minlevel =>
(
	default  => sub{return 'error'},
	is       => 'rw',
	isa      => Str,
	required => 0,
);

has recce =>
(
	default  => sub{return ''},
	is       => 'rw',
	isa      => Any,
	required => 0,
);

has result =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

our $VERSION = '2.10';

# ------------------------------------------------

sub BUILD
{
	my($self) = @_;

	if (! defined $self -> logger)
	{
		$self -> logger(Log::Handler -> new);
		$self -> logger -> add
		(
			screen =>
			{
				maxlevel       => $self -> maxlevel,
				message_layout => '%m',
				minlevel       => $self -> minlevel,
				utf8           => 1,
			}
		);
	}

	# Initialize the action class via global variables - Yuk!
	# The point is that we don't create an action instance.
	# Marpa creates one but we can't get our hands on it.

	$Genealogy::Gedcom::Date::Actions::calendar = $self -> clean_calendar;
	$Genealogy::Gedcom::Date::Actions::logger   = $self -> logger;

	$self -> bnf
	(
<<'END_OF_GRAMMAR'

:default				::= action => [values]

lexeme default			= latm => 1		# Longest Acceptable Token Match.

# Rules, in top-down order (more-or-less).

:start					::= gedcom_date

gedcom_date				::= date
							| lds_ord_date

date					::= calendar_escape calendar_date

calendar_escape			::=
calendar_escape			::= calendar_name 					action => calendar_name		# ($t1)
							| ('@#d') calendar_name ('@')	action => calendar_name		#   "
							| ('@#D') calendar_name ('@')	action => calendar_name		#   "

calendar_date			::= gregorian_date					action => gregorian_date	# ($t1)
							| julian_date					action => julian_date		# ($t1)
							| french_date					action => french_date		# ($t1)
							| german_date					action => german_date		# ($t1)
							| hebrew_date					action => hebrew_date		# ($t1)

gregorian_date			::= day gregorian_month gregorian_year
							| gregorian_month gregorian_year
							| gregorian_year_bce
							| gregorian_year

day						::= one_or_two_digits				action => ::first			# ($t1)

gregorian_month			::= gregorian_month_name			action => gregorian_month	# ($t1)

gregorian_year			::= number							action => year				# ($t1, $t2)
							| number ('/') two_digits		action => year				#     "

gregorian_year_bce		::= gregorian_year bce				action => gregorian_year_bce # ($t1, $t2)

julian_date				::= day gregorian_month_name year
							| gregorian_month_name year
							| julian_year_bce
							| year

julian_year_bce			::= year bce						action => julian_year_bce	# ($t1, $t2)

year					::= number							action => year				# ($t1, $t2)

french_date				::= day french_month_name year
							| french_month_name year
							| year bce
							| year

german_date				::= day dot german_month_name dot german_year
							| german_month_name dot german_year
							| german_year

german_year				::= year
							| year german_bce

hebrew_date				::= day hebrew_month_name year
							| hebrew_month_name year
							| year bce
							| year

lds_ord_date			::= date_value

date_value				::= date_period
							| date_range
							| approximated_date
							| interpreted_date				action => interpreted_date	# ($t1)
							| ('(') date_phrase (')')		action => date_phrase		# ($t1)

date_period				::= from_date to_date
							| from_date
							| to_date

from_date				::= from date						action => from_date			# ($t1, $t2)

to_date					::= to date			 				action => to_date			# ($t1, $t2)

date_range				::= before date						action => before_date		# ($t1, $t2)
							| after date					action => after_date		# ($t1, $t2)
							| between date and date			action => between_date		# ($t1, $t2, $t3, $t4)

approximated_date		::= about date						action => about_date		# ($t1, $t2)
							| calculated date				action => calculated_date	# ($t1, $t2)
							| estimated date				action => estimated_date	# ($t1, $t2)

interpreted_date		::= interpreted date ('(') date_phrase (')')

date_phrase				::= date_text

# Lexemes, in alphabetical order.

about					~ 'abt':i
							| 'about':i
							| 'circa':i

after					~ 'aft':i
							| 'after':i

and						~ 'and':i

bce						~ 'bc':i
							| 'b.c.':i
							| 'bce':i

before					~ 'bef':i
							| 'before':i

between					~ 'bet':i
							| 'between':i

calculated				~ 'cal':i
							| 'calculated':i

calendar_name			~ 'french r':i
							| 'frenchr':i
							| 'german':i
							| 'gregorian':i
							| 'hebrew':i
							| 'julian':i

date_text				~ [^)\x{0a}\x{0b}\x{0c}\x{0d}]+

digit					~ [0-9]

dot						~ '.'

estimated				~ 'est':i
							| 'estimated':i

french_month_name		~ 'vend':i | 'brum':i | 'frim':i | 'nivo':i | 'pluv':i | 'vent':i
							| 'germ':i | 'flor':i | 'prai':i | 'mess':i | 'ther':i
							| 'fruc':i | 'comp':i

from					~ 'from':i

german_bce				~ 'vc':i
							| 'v.c.':i
							| 'v.chr.':i
							| 'vchr':i
							| 'vuz':i
							| 'v.u.z.':i

german_month_name		~ 'jan':i | 'feb':i | 'mär':i | 'maer':i | 'mrz':i | 'apr':i | 'mai':i
							| 'jun':i | 'jul':i | 'aug':i | 'sep':i | 'sept':i | 'okt':i
							| 'nov':i | 'dez':i

gregorian_month_name	~ 'jan':i | 'feb':i | 'mar':i | 'apr':i | 'may':i | 'jun':i
							| 'jul':i | 'aug':i | 'sep':i | 'oct':i | 'nov':i | 'dec':i

hebrew_month_name		~ 'tsh':i | 'csh':i | 'ksl':i | 'tvt':i | 'shv':i | 'adr':i
							| 'ads':i | 'nsn':i | 'iyr':i | 'svn':i | 'tmz':i | 'aav':i | 'ell':i

interpreted				~ 'int':i
							| 'interpreted':i

number					~ digit+

one_or_two_digits		~ digit
							| digit digit

to						~ 'to':i

two_digits				~ digit digit

# Boilerplate.

:discard				~ whitespace
whitespace				~ [\s]+

END_OF_GRAMMAR
	);

	$self -> grammar
	(
		Marpa::R2::Scanless::G -> new
		({
			source => \$self -> bnf
		})
	);

} # End of BUILD.

# ------------------------------------------------

sub canonical_date
{
	my($self, $result) = @_;
	my($date) = '';

	my($separator);

	if ($$result{type} && ($$result{type} =~ /(?:French|Gregorian|Hebrew|Julian)/) )
	{
		$separator = ' ';
	}
	else # German.
	{
		$separator = '.';
	}

	if ($$result{type} && ($$result{type} =~ /(French r|German|Hebrew|Julian)/) )
	{
		$date = '@#d' . "\U$1" . '@';
	}

	$date .= defined($$result{day}) ? $date ? " $$result{day}" : $$result{day} : '';

	if ($$result{month})
	{
		if (defined $$result{day})
		{
			$date .= $date ? "$separator$$result{month}" : $$result{month};
		}
		else
		{
			$date .= $date ? " $$result{month}" : $$result{month};
		}

		$date .= $date ? "$separator$$result{year}" : $$result{year};
	}
	else
	{
		$date .= $date ? " $$result{year}" : $$result{year} if (defined $$result{year});
	}

	$date .= "/$$result{suffix}" if (defined $$result{suffix});
	$date .= " $$result{bce}"    if ($$result{bce});

	if (defined $$result{phrase})
	{
		$date .= $date ? " $$result{phrase}" : $$result{phrase};
	}

	return $date;

} # End of canonical_date.

# ------------------------------------------------

sub canonical_form
{
	my($self, $result) = @_;
	my(@date) = ('', '');

	my($separator);

	for my $i (0 .. $#$result)
	{
		$date[$i] = $self -> canonical_date($$result[$i]);
		$date[$i] = $$result[$i]{flag} ? $date[$i] ? "$$result[$i]{flag} $date[$i]" : $$result[$i]{flag} : $date[$i];
	}

	return $date[1] ? "$date[0] $date[1]" : $date[0];

} # End of canonical_form.

# ------------------------------------------------

sub clean_calendar
{
	my($self)     = @_;
	my($calendar) = $self -> _calendar;
	$calendar     =~ s/\@\#d(.+)\@/$1/; # Zap gobbledegook if present.
	$calendar     = ucfirst lc $calendar;

	return $self -> _calendar($calendar);

} # End of clean_calendar.

# --------------------------------------------------

sub compare
{
	my($self, $other)	= @_;
	my($result_1)		= $self -> result;
	my($date_1)			= $self -> normalize_date($#$result_1 < 0 ? {} : $$result_1[0]);
	my($result_2)		= $other -> result;
	my($date_2)			= $self -> normalize_date($#$result_2 < 0 ? {} : $$result_2[0]);

	# Return:
	# o 0 if the dates have different date escapes.
	# o 1 if $date_1 < $date_2.
	# o 2 if $date_1 = $date_2.
	# o 3 if $date_1 > $date_2.

	my($result);

	if ( ($$date_1{kind} ne $$date_2{kind}) || ($$date_1{type} ne $$date_2{type}) )
	{
		$result = 0;
	}
	elsif ($$date_1{bce} && ($$date_2{bce} eq '') )
	{
		# We don't care what the value of 'bce' is. We only care if it has been set or not.

		$result = 1;
	}
	elsif ( ($$date_1{bce} eq '') && $$date_2{bce})
	{
		$result = 3;
	}
	else
	{
		my($format)	= '%4d-%4s-%02d';
		my($form_1)	= sprintf($format, $$date_1{year}, $$date_1{month}, $$date_1{day});
		my($form_2)	= sprintf($format, $$date_2{year}, $$date_2{month}, $$date_2{day});

		if ($form_1 eq $form_2)
		{
			$result = 2;
		}
		elsif ($$date_1{bce})
		{
			# Ahhhggg. BCE! Reverse sense of test.

			if ($form_1 lt $form_2)
			{
				$result = 3;
			}
			else
			{
				$result = 1;
			}
		}
		elsif ($form_1 lt $form_2)
		{
			$result = 1;
		}
		else
		{
			$result = 3;
		}
	}

	return $result;

} # End of compare.

# ------------------------------------------------

sub decode_result
{
	my($self, $result) = @_;
	my(@worklist) = $result;

	my($obj);
	my($ref_type);
	my(@stack);

	do
	{
		$obj      = shift @worklist;
		$ref_type = ref $obj;

		if ($ref_type eq 'ARRAY')
		{
			unshift @worklist, @$obj;
		}
		elsif ($ref_type eq 'HASH')
		{
			push @stack, {%$obj};
		}
		elsif ($ref_type)
		{
			die "Unsupported object type $ref_type\n";
		}
		else
		{
			push @stack, $obj;
		}

	} while (@worklist);

	return [@stack];

} # End of decode_result.

# ------------------------------------------------

sub log
{
	my($self, $level, $s) = @_;

	$self -> logger -> log($level => $s) if ($self -> logger);

} # End of log.

# ------------------------------------------------

sub normalize_date
{
	my($self, $date)	= @_;
	$$date{bce}			= ''	if (! defined $$date{bce});
	$$date{day}			= 0		if (! defined $$date{day} || ($$date{day} !~ /^\d+$/) );
	$$date{kind}		= ''	if (! defined $$date{kind});
	$$date{month}		= ''	if (! defined $$date{month});
	$$date{type}		= ''	if (! defined $$date{type});
	$$date{year}		= 0		if (! defined $$date{year});
	my($index)			= index($$date{year}, '/');
	$$date{year}		= substr($$date{year}, 0, $index - 1) if ($index >= 0);

	return $date;

} # End of normalize_date.

# --------------------------------------------------

sub parse
{
	my($self, %args)	= @_;
	my($canonical)		= defined($args{canonical}) ? $args{canonical} : $self -> canonical;
	$canonical			= $canonical < 0 ? 0 : $canonical > 2 ? 2 : $canonical;
	my($date)			= defined($args{date}) ? $args{date} : $self -> date;
	$date				= '' if (! defined $date);

	# Now we have the date, zap any commas outside any ().

	my(@chars)    = split(//, $date);
	my($i)        = 0;
	my($finished) = $#chars < $i ? 1 : 0;

	while (! $finished)
	{
		if ( ($i > $#chars) || ($chars[$i] eq '(') )
		{
			$finished = 1;
		}
		else
		{
			$chars[$i] = ' ' if ($chars[$i] eq ',');

			$i++;
		}
	}

	$date = join('', @chars);

	$self -> canonical($canonical);
	$self -> date($date);
	$self -> error('');
	$self -> recce
	(
		Marpa::R2::Scanless::R -> new
		({
			grammar           => $self -> grammar,
			ranking_method    => 'high_rule_only',
			semantics_package => 'Genealogy::Gedcom::Date::Actions',
		})
	);

	my($result) = [];

	if (length($date) == 0)
	{
		$self -> error('Input is the empty string');

		return $result;
	}

	try
	{
		$self -> recce -> read(\$date);

		my($ambiguity_metric) = $self -> recce -> ambiguity_metric;

		if ($ambiguity_metric <= 0)
		{
			my($line, $column)	= $self -> recce -> line_column();
			my($whole_length)	= length $date;
			my($suffix)			= substr($date, ($whole_length - 100) );
			my($suffix_length)	= length $suffix;
			my($s)				= $suffix_length == 1 ? 'char' : "$suffix_length chars";
			my($message)		= "Call to ambiguity_metric() returned $ambiguity_metric (i.e. an error). \n"
				. "Marpa exited at (line, column) = ($line, $column) within the input string. \n"
				. "Input length: $whole_length. Last $s of input: '$suffix'";

			$self -> error($message);

			$self -> log(error => "Parse failed. $message");
		}
		elsif ($ambiguity_metric == 1)
		{
			$result = $self -> process_unambiguous();
		}
		else
		{
			$result = $self -> process_ambiguous();
		}
	}
	catch
	{
		my($error) = $_;

		$self -> error($error);
		$self -> log(debug => $self -> error);
	};

	for my $i (0 .. $#$result)
	{
		$$result[$i]{canonical} = $self -> canonical_date($$result[$i]);
	}

	if ($self -> canonical == 0)
	{
		$self -> log(debug => "Return value from parse(): \n" . Dumper($result) );
	}
	elsif ($self -> canonical == 1)
	{
		$self -> log(debug => $self -> canonical_form($result) );
	}
	else
	{
		$self -> log(debug => $self -> canonical_date($$result[$_]) ) for (0 .. $#$result);
	}

	$self -> error("Unable to parse '" . $self -> date . "'") if ( (! $self -> error) && $#$result < 0);
	$self -> result($result);

	return $result;

} # End of parse.

# --------------------------------------------------

sub process_ambiguous
{
	my($self)     = @_;
	my($calendar) = $self -> clean_calendar;
	my(%count)    =
	(
		AND  => 0,
		BET  => 0,
		FROM => 0,
		TO   => 0,
	);
	my($result) = [];

	my($item);

	while (my $value = $self -> recce -> value)
	{
		$value = $self -> decode_result($$value);

		for $item (@$value)
		{
			if ($$item{kind} eq 'Calendar')
			{
				$calendar = $$item{type};

				next;
			}

			if ($calendar eq $$item{type})
			{
				# We have to allow for the fact that when 'From .. To' or 'Between ... And'
				# are used, both dates are ambiguous, and we end up with double the number
				# of elements in the arrayref compared to what's expected.

				if (exists $$item{flag} && exists $count{$$item{flag} })
				{
					if ($count{$$item{flag} } == 0)
					{
						$count{$$item{flag} }++;

						push @$result, $item;
					}
				}
				else
				{
					push @$result, $item;
				}
			}

			# Sometimes we must reverse the array elements.

			if ($#$result == 1)
			{
				if ( ($$result[0]{flag} eq 'AND') && ($$result[1]{flag} eq 'BET') )
				{
					($$result[0], $$result[1]) = ($$result[1], $$result[0]);
				}
				elsif ( ($$result[0]{flag} eq 'TO') && ($$result[1]{flag} eq 'FROM') )
				{
					($$result[0], $$result[1]) = ($$result[1], $$result[0]);
				}
			}

			# Reset the calendar. Note: The 'next' above skips this statement.

			$calendar = $self -> clean_calendar;
		}
	}

	return $result;

} # End of process_ambiguous.

# --------------------------------------------------

sub process_unambiguous
{
	my($self)     = @_;
	my($calendar) = $self -> clean_calendar;
	my($result)   = [];
	my($value)    = $self -> recce -> value;
	$value        = $self -> decode_result($$value);

	if ($#$value == 0)
	{
		$value = $$value[0];

		if ($$value{type} =~ /^(?:$calendar|Phrase)$/)
		{
			$$result[0] = $value;
		}
		else
		{
			$result = [$value];
		}
	}
	elsif ($#$value == 2)
	{
		$result = [$$value[0], $$value[1] ];
	}
	elsif ($#$value == 3)
	{
		$result = [$$value[1], $$value[3] ];
	}
	elsif ($$value[0]{kind} eq 'Calendar')
	{
		$calendar = $$value[0]{type};

		if ($calendar eq $$value[1]{type})
		{
			$result = [$$value[1] ];
		}
	}
	elsif ( ($$value[0]{type} eq $calendar) && ($$value[1]{type} eq $calendar) )
	{
		$result = $value;
	}

	return $result;

} # End of process_unambiguous.

# --------------------------------------------------

1;

=pod

=encoding utf8

=head1 NAME

Genealogy::Gedcom::Date - Parse GEDCOM dates in French r/German/Gregorian/Hebrew/Julian

=head1 Synopsis

A script (scripts/synopsis.pl):

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use Genealogy::Gedcom::Date;

	# --------------------------

	sub process
	{
		my($count, $parser, $date) = @_;

		print "$count: $date: ";

		my($result) = $parser -> parse(date => $date);

		print "Canonical date @{[$_ + 1]}: ", $parser -> canonical_date($$result[$_]), ". \n" for (0 .. $#$result);
		print 'Canonical form: ', $parser -> canonical_form($result), ". \n";
		print "\n";

	} # End of process.

	# --------------------------

	my($parser) = Genealogy::Gedcom::Date -> new(maxlevel => 'debug');

	process(1, $parser, 'Julian 1950');
	process(2, $parser, '@#dJulian@ 1951');
	process(3, $parser, 'From @#dJulian@ 1952 to Gregorian 1953/54');
	process(4, $parser, 'From @#dFrench r@ 1955 to 1956');
	process(5, $parser, 'From @#dJulian@ 1957 to German 1.Dez.1958');

One-liners:

	perl scripts/parse.pl -max debug -d 'Between Gregorian 1701/02 And Julian 1703'

Output:

	Return value from parse():
	[
	  {
	    canonical => "1701/02",
	    flag => "BET",
	    kind => "Date",
	    suffix => "02",
	    type => "Gregorian",
	    year => 1701
	  },
	  {
	    canonical => "\@#dJULIAN\@ 1703",
	    flag => "AND",
	    kind => "Date",
	    type => "Julian",
	    year => 1703
	  }
	]

	perl scripts/parse.pl -max debug -d 'Int 10 Nov 1200 (Approx)'

Output:

	[
	  {
	    canonical => "10 Nov 1200 (Approx)",
	    day => 10,
	    flag => "INT",
	    kind => "Date",
	    month => "Nov",
	    phrase => "(Approx)",
	    type => "Gregorian",
	    year => 1200
	  }
	]

	perl scripts/parse.pl -max debug -d '(Unknown)'

Output:

	Return value from parse():
	[
	  {
	    canonical => "(Unknown)",
	    kind => "Phrase",
	    phrase => "(Unknown)",
	    type => "Phrase"
	  }
	]

See the L</FAQ> for the explanation of the output arrayrefs.

See also scripts/parse.pl and scripts/compare.pl for sample code.

Lastly, you are I<strongly> encouraged to peruse t/*.t.

=head1 Description

L<Genealogy::Gedcom::Date> provides a L<Marpa|Marpa::R2>-based parser for GEDCOM dates.

Calender escapes supported are (case-insensitive): French r/German/Gregorian/Hebrew/Julian.

Gregorian is the default, and does not need to be used at all.

Comparison of 2 C<Genealogy::Gedcom::Date>-based objects is supported by calling the sub
L</compare($other_object)> method on one object and passing the other object as the parameter.

Note: C<compare()> can return any one of four (4) values.

See L<the GEDCOM Specification|http://wiki.webtrees.net/en/Main_Page>, p 45.

=head1 Installation

Install L<Genealogy::Gedcom::Date> as you would for any C<Perl> module:

Run:

	cpanm Genealogy::Gedcom::Date

or run:

	sudo cpan Genealogy::Gedcom::Date

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = Genealogy::Gedcom::Date -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Genealogy::Gedcom::Date>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</date([$date])>]):

=over 4

=item o canonical => $integer

Note: Nothing is printed unless C<maxlevel> is set to C<debug>.

=over 4

=item o canonical => 0

Data::Dumper::Concise's Dumper() prints the output of the parse.

=item o canonical => 1

canonical_form() is called on the output of parse() to print a string.

=item o canonical => 2

canonocal_date() is called on each element in the result from parse(), to print strings on
separate lines.

=back

Default: 0.

=item o date => $date

The string to be parsed.

Each ',' is replaced by a space. See the L</FAQ> for details.

Default: ''.

=item o logger => $aLoggerObject

Specify a logger compatible with L<Log::Handler>, for the lexer and parser to use.

Default: A logger of type L<Log::Handler> which writes to the screen.

To disable logging, just set 'logger' to the empty string (not undef).

=item o maxlevel => $logOption1

This option affects L<Log::Handler>.

See the L<Log::Handler::Levels> docs.

By default nothing is printed.

Typical values are: 'error', 'notice', 'info' and 'debug'.

The default produces no output.

Default: 'notice'.

=item o minlevel => $logOption2

This option affects L<Log::Handler>.

See the L<Log::Handler::Levels> docs.

Default: 'error'.

No lower levels are used.

=back

Note: The parameters C<canonical> and C<date> can also be passed to L</parse([%args])>.

=head1 Methods

=head2 canonical([$integer])

Here, the [] indicate an optional parameter.

Gets or sets the C<canonical> option, which controls what exactly L</parse([%args])> prints when
L</maxlevel([$string])> is set to C<debug>.

By default nothing is printed.

See L</canonical_date($hashref)>, next, for sample code.

=head2 canonical_date($hashref)

$hashref is either element of the arrayref returned by L</parse([%args])>. The hashref may be
empty.

Returns a date string (or the empty string) normalized in various ways:

=over 4

=item o If Gregorian (in any form) was in the original string, it is discarded

This is done because it's the default.

=item o If any other calendar escape was in the original string, it is preserved

And it's output in all caps.

And as a special case, 'FRENCHR' is returned as 'FRENCH R'.

=item o If About, etc were in the orginal string, they are discarded

This means the C<flag> key in the hashref is ignored.

=back

Note: This method is called by L</parse([%args])> to populate the C<canonical> key in the arrayref
of hashrefs returned by C<parse()>.

Try:

	perl scripts/parse.pl -max debug -d 'From 21 Jun 1950 to @#dGerman@ 05.Mär.2015'

	perl scripts/parse.pl -max debug -d 'From 21 Jun 1950 to @#dGerman@ 05.Mär.2015' -c 0

	perl scripts/parse.pl -max debug -d 'From 21 Jun 1950 to @#dGerman@ 05.Mär.2015' -c 1

	perl scripts/parse.pl -max debug -d 'From 21 Jun 1950 to @#dGerman@ 05.Mär.2015' -c 2

=head2 canonical_form($arrayref)

Returns a date string containing zero, one or two dates.

This method calls L</canonical_date($hashref)> for each element in the $arrayref. The arrayref
may be empty.

Then it adds information from the C<flag> key in each element, if present.

For sample code, see L</canonical_date($hashref)> just above.

=head2 compare($other_object)

Returns an integer 0 .. 3 (sic) indicating the temporal relationship between the invoking object
($self) and $other_object.

Returns one of these values:

	0 if the dates have different date escapes.
	1 if $date_1 < $date_2.
	2 if $date_1 = $date_2.
	3 if $date_1 > $date_2.

Note: Gregorian years like 1510/02 are converted into 1510 before the dates are compared. Create a
sub-class and override L</normalize_date($date_hash)> if desired.

See scripts/compare.pl for sample code.

See also L</normalize_date($date_hash)>.

=head2 date([$date])

Here, [ and ] indicate an optional parameter.

Gets or sets the date to be parsed.

The date in C<< parse(date => $date) >> takes precedence over both C<< new(date => $date) >>
and C<date($date)>.

This means if you call C<parse()> as C<< parse(date => $date) >>, then the value C<$date> is stored
so that if you subsequently call C<date()>, that value is returned.

Note: C<date> is a parameter to new().

=head2 error()

Gets the last error message.

Returns '' (the empty string) if there have been no errors.

If L<Marpa::R2> throws an exception, it is caught by a try/catch block, and the C<Marpa> error
is returned by this method.

See L</parse([%args])> for more about C<error()>.

=head2 log($level, $s)

If a logger is defined, this logs the message $s at level $level.

=head2 logger([$logger_object])

Here, the [] indicate an optional parameter.

Get or set the logger object.

To disable logging, just set 'logger' to the empty string (not undef), in the call to L</new()>.

This logger is passed to other modules.

'logger' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 maxlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is ceated.
See L<Log::Handler::Levels>.

Typical values are: 'notice', 'info' and 'debug'. The default, 'notice', produces no output.

The code emits a message with log level 'error' if Marpa throws an exception, and it displays
the result of the parse at level 'debug' if maxlevel is set that high. The latter display uses
L<Data::Dumper::Concise>'s function C<Dumper()>.

'maxlevel' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 minlevel([$string])

Here, the [] indicate an optional parameter.

Get or set the value used by the logger object.

This option is only used if an object of type L<Log::Handler> is created.
See L<Log::Handler::Levels>.

'minlevel' is a parameter to L</new()>. See L</Constructor and Initialization> for details.

=head2 new([%args])

The constructor. See L</Constructor and Initialization>.

=head2 normalize_date($date_hash)

Normalizes $date_hash for each date during a call to L</compare($other_object)>.

Override in a sub-class if you wish to change the normalization technique.

=head2 parse([%args])

Here, [ and ] indicate an optional parameter.

C<parse()> returns an arrayref. See the L</FAQ> for details.

If the arrayref is empty, call L</error()> to retrieve the error message.

In particular, the arrayref will be empty if the input date is the empty string.

C<parse()> takes the same parameters as C<new()>.

Warning: The array can contain 1 element when 2 are expected. This can happen if your input contains
'From ... To ...' or 'Between ... And ...', and one of the dates is invalid. That is, the return
value from C<parse()> will contain the valid date but no indicator of the invalid one.

=head1 Extensions to the Gedcom specification

This chapter lists exactly how this code differs from the Gedcom spec.

=over 4

=item o Input may be in Unicode

=item o Input may be in any case

=item o Input may omit calendar escapes when the date is unambigous

=item o Any of the following tokens may be used

=over 4

=item o abt, about, circa

=item o aft, after

=item o and

=item o bc, b.c., bce

=item o bef, before

=item o bet, between

=item o cal, calculated

=item o french r, frenchr, german, gregorian, hebrew, julian,

=item o est, estimated

=item o from

=item o German BCE

vc, v.c., v.chr., vchr, vuz, v.u.z.

=item o German month names

jan, feb, mär, maer, mrz, apr, mai, jun, jul, aug, sep, sept, okt, nov, dez

=item o Gregorian month names

jan, feb, mar, apr, may, jun, jul, aug, sep, oct, nov, dec

=item o Hebrew month names

tsh, csh, ksl, tvt, shv, adr, ads, nsn, iyr, svn, tmz, aav, ell

=item o int, interpreted

=item o to

=back

=back

=head1 FAQ

=head2 What is the format of the value returned by parse()?

It is always an arrayref.

If the date is like '1950' or 'Bef 1950 BCE', there will be 1 element in the arrayref.

If the date contains both 'From' and 'To', or both 'Between' and 'And', then the arrayref will
contain 2 elements.

Each element is a hashref, with various combinations of the following keys. You need to check the
existence of some keys before processing the date.

This means missing values (day, month, bce) are never fabricated. These keys only appear in the
hashref if such a token was found in the input.

Keys:

=over 4

=item o bce

If the input contains any (case-insensitive) BCE indicator, under any calendar escape, the C<bce>
key will hold the exact indicator.

=item o canonical => $string

L</parse([%args])> calls L</canonical_date($hashref)> to populate this key.

=item o day => $integer

If the input contains a day, then the C<day> key will be present.

=item o flag => $string

If the input contains any of the following (case-insensitive), then the C<flag> key will be present:

=over 4

=item o Abt or About

=item o Aft or After

=item o And

=item o Bef or Before

=item o Bet or Between

=item o Cal or Calculated

=item o Est or Estimated

=item o From

=item o Int or Interpreted

=item o To

=back

$string will take one of these values (case-sensitive):

=over 4

=item o ABT

=item o AFT

=item o AND

=item o BEF

=item o BET

=item o CAL

=item o EST

=item o FROM

=item o INT

=item o TO

=back

=item o kind => 'Date' or 'Phrase'

The C<kind> key is always present, and always takes the value 'Date' or 'Phrase'.

If the value is 'Phrase', see the C<phrase> and C<type> keys.

During processing, there can be another - undocumented - element in the arrayref. It represents
the calendar escape, and in that case C<kind> takes the value 'Calendar'. This element is discarded
before the final arrayref is returned to the caller.

=item o month => $string

If the input contains a month, then the C<month> key will be present. The case of $string will be
exactly whatever was in the input.

=item o phrase => "($string)"

If the input contains a date phrase, then the C<phrase> key will be present. The case of $string
will be exactly whatever was in the input.

parse(date => 'Int 10 Nov 1200 (Approx)') returns:

	[
	  {
	    day => 10,
	    flag => "INT",
	    kind => "Date",
	    month => "Nov",
	    phrase => "(Approx)",
	    type => "Gregorian",
	    year => 1200
	  }
	]

parse(date => '(Unknown)') returns:

	[
	  {
	    kind => "Phrase",
	    phrase => "(Unknown)",
	    type => "Phrase"
	  }
	]

See also the C<kind> and C<type> keys.

=item o suffix => $two_digits

If the year contains a suffix (/00), then the C<suffix> key will be present. The '/' is
discarded.

Obviously, this key can only appear when the year is of the Gregorian form 1700/00.

See also the C<year> key below.

=item o type => $string

The C<type> key is always present, and takes one of these case-sensitive values:

=over 4

=item o 'French r'

=item o German

=item o Gregorian

=item o Hebrew

=item o Julian

=item o Phrase

See also the C<kind> and C<phrase> keys.

=back

=item o year => $integer

If the input contains a year, then the C<year> key is present.

If the year contains a suffix (/00), see also the C<suffix> key, above. This means the value of
the C<year> key is never "$integer/$two_digits".

=back

=head2 When should I use a calendar escape?

=over 4

=item o In theory, for every non-Gregorian date

In practice, if the month name is unique to a specific language, then the escape is not needed,
since L<Marpa::R2> and this code automatically handle ambiguity.

Likewise, if you use a Gregorian year in the form 1700/01, then the calendar escape is obvious.

The escape is, of course, always inserted into the values returned by the C<canonical> pair of
methods when they process non-Gregorian dates. That makes their output compatible with
other software. And no matter what case you use specifying the calendar escape, it is always
output in upper-case.

=item o When you wish to force the code to provide an unambiguous result

All Gregorian and Julian dates are ambiguous, unless they use the year format 1700/01.

So, to resolve the ambiguity, add the calendar escape.

=back

=head2 Why is '@' escaped with '\' when L<Data::Dumper::Concise>'s C<Dumper()> prints things?

That's just how that module handles '@'.

=head2 Does this module accept Unicode?

Yes.

See t/German.t for sample code.

=head2 Can I change the default calendar?

No. It is always Gregorian.

=head2 Are dates massaged before being processed?

Yes. Commas are replaced by spaces.

=head2 French month names

See L</Extensions to the Gedcom specification>.

=head2 German month names

See L</Extensions to the Gedcom specification>.

=head2 Hebrew month names

See L</Extensions to the Gedcom specification>.

=head2 What happens if C<parse()> is given a string like 'To 2000 From 1999'?

The code I<does not> reorder the dates.

=head2 Why was this module renamed from DateTime::Format::Gedcom?

The L<DateTime> suite of modules aren't designed, IMHO, for GEDCOM-like applications. It was a
mistake to use that name in the first place.

By releasing under the Genealogy::Gedcom::* namespace, I can be much more targeted in the data
types I choose as method return values.

=head2 Why did you choose Moo over Moose?

My policy is to use the lightweight L<Moo> for all modules and applications.

=head1 Trouble-shooting

Things to consider:

=over 4

=item o Error message: Marpa exited at (line, column) = ($line, $column) within the input string

Consider the possibility that the parse ends without a C<successful> parse, but the input is the
prefix of some input that C<can> lead to a successful parse.

Marpa is not reporting a problem during the read(), because you can add more to the input string,
and Marpa does not know that you do not plan to do this.

=item o You tried to enter the German month name 'Mär' via the shell

Read more about this by running 'perl scripts/parse.pl -h', where it discusses '-d'.

=item o You mistyped the calendar escape

Check: Are any of these valid?

=over 4

=item o @#FRENCH@

=item o @#JULIAN@

=item o @#djulian

=item o @#juliand

=item o @#djuliand

=item o @#dJulian@

=item o Julian

=item o @#dJULIAN@

=back

Yes, the last 3 are accepted by this module, and the last one is accepted by other software.

=item o The date is in American format (month day year)

=item o You used a Julian calendar with a Gregorian year

Dates - such as 1900/01 - which do not fit the Gedcom definition of a Julian year, are filtered
out.

=back

=head1 See Also

L<File::Bom::Utils>.

L<Genealogy::Gedcom>

L<DateTime>

L<DateTimeX::Lite>

L<Time::ParseDate>

L<Time::Piece> is in Perl core. See L<http://perltricks.com/article/59/2014/1/10/Solve-almost-any-datetime-need-with-Time-Piece>

L<Time::Duration> is more sophisticated than L<Time::Elapsed>

L<Time::Moment> implements L<ISO 8601|https://en.wikipedia.org/wiki/ISO_8601>

L<http://blogs.perl.org/users/buddy_burden/2015/09/a-date-with-cpan-part-1-state-of-the-union.html>

L<http://blogs.perl.org/users/buddy_burden/2015/10/a-date-with-cpan-part-2-target-first-aim-afterwards.html>

L<http://blogs.perl.org/users/buddy_burden/2015/10/-a-date-with-cpan-part-3-paving-while-driving.html>

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Genealogy-Gedcom-Date>.

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Genealogy::Gedcom::Date>.

=head1 Credits

Thanx to Eugene van der Pijll, the author of the Gedcom::Date::* modules.

Thanx also to the authors of the DateTime::* family of modules. See
L<http://datetime.perl.org/wiki/datetime/dashboard> for details.

Thanx for Mike Elston on the perl-gedcom mailing list for providing French month abbreviations,
amongst other information pertaining to the French language.

Thanx to Michael Ionescu on the perl-gedcom mailing list for providing the grammar for German dates
and German month abbreviations.

=head1 Author

L<Genealogy::Gedcom::Date> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Homepage: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
