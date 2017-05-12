package Genealogy::Gedcom::Date::Actions;

use strict;
use warnings;

use Data::Dumper::Concise; # For Dumper().

our $calendar;

our $logger;

our $verbose = 0;

our $VERSION = '2.09';

# ------------------------------------------------

sub about_date
{
	my($cache, $t1, $t2) = @_;

	print STDERR '#=== about_date() action: ', Dumper($t1), Dumper($t2) if ($verbose);

	my($t3)    = $$t2[1];
	$t3        = $$t3[0] if (ref $t3 eq 'ARRAY');
	$$t3{flag} = 'ABT';

	return [$$t2[0], $t3];

} # End of about_date.

# ------------------------------------------------

sub after_date
{
	my($cache, $t1, $t2) = @_;

	print STDERR '#=== after_date() action: ', Dumper($t1), Dumper($t2) if ($verbose);

	my($t3)    = $$t2[1];
	$t3        = $$t3[0] if (ref $t3 eq 'ARRAY');
	$$t3{flag} = 'AFT';

	return [$$t2[0], $t3];

} # End of after_date.

# ------------------------------------------------

sub before_date
{
	my($cache, $t1, $t2) = @_;

	print STDERR '#=== before_date() action: ', Dumper($t1), Dumper($t2) if ($verbose);

	my($t3)    = $$t2[1];
	$t3        = $$t3[0] if (ref $t3 eq 'ARRAY');
	$$t3{flag} = 'BEF';

	return [$$t2[0], $t3];

} # End of before_date.

# ------------------------------------------------

sub between_date
{
	my($cache, $t1, $t2, $t3, $t4) = @_;

	print STDERR '#=== between_date() action: ', Dumper($t1), Dumper($t2), Dumper($t3), Dumper($t4) if ($verbose);

	my($t5)    = $$t2[1][0];
	$$t5{flag} = 'BET';
	my($t6)    = $$t4[1][0];
	$$t6{flag} = 'AND';

	if (ref $$t2[0] eq 'HASH')
	{
		$t1 = $$t2[0];
	}
	else
	{
		$t1 = {kind => 'Calendar', type => $calendar};
	}

	if (ref $$t4[0] eq 'HASH')
	{
		$t3 = $$t4[0];
	}
	else
	{
		$t3 = {kind => 'Calendar', type => $calendar};
	}

	$t1 = [$t1, $t5, $t3, $t6];

	return $t1;

} # End of between_date.

# ------------------------------------------------

sub calculated_date
{
	my($cache, $t1, $t2) = @_;

	print STDERR '#=== calculated_date() action: ', Dumper($t1), Dumper($t2) if ($verbose);

	my($t3)    = $$t2[1];
	$t3        = $$t3[0] if (ref $t3 eq 'ARRAY');
	$$t3{flag} = 'CAL';

	return [$$t2[0], $t3];

} # End of calculated_date.

# ------------------------------------------------

sub calendar_name
{
	my($cache, $t1) = @_;

	print STDERR '#=== calendar_name() action: ', Dumper($t1) if ($verbose);

	$t1 =~ s/\@\#d(.+)\@/$1/; # Zap gobbledegook if present.
	$t1 = ucfirst lc $t1;

	return
	{
		kind => 'Calendar',
		type => $t1,
	};

} # End of calendar_name.

# ------------------------------------------------

sub date_phrase
{
	my($cache, $t1) = @_;

	print STDERR '#=== date_phrase() action: ', Dumper($t1) if ($verbose);

	return
	{
		kind   => 'Phrase',
		phrase => "($$t1[0])",
		type   => 'Phrase',
	};

} # End of date_phrase.

# ------------------------------------------------

sub estimated_date
{
	my($cache, $t1, $t2) = @_;

	print STDERR '#=== estimated_date() action: ', Dumper($t1), Dumper($t2) if ($verbose);

	my($t3)    = $$t2[1];
	$t3        = $$t3[0] if (ref $t3 eq 'ARRAY');
	$$t3{flag} = 'EST';

	return [$$t2[0], $t3];

} # End of estimated_date.

# ------------------------------------------------

sub french_date
{
	my($cache, $t1) = @_;

	print STDERR '#=== french_date() action: ', Dumper($t1) if ($verbose);

	my($bce);
	my($day);
	my($month);
	my($year);

	# Check for year, month, day.

	if ($#$t1 == 0)
	{
		$year = $$t1[0];
	}
	elsif ($#$t1 == 1)
	{
		# First check for BCE.

		if ($$t1[1] =~ /[0-9]/)
		{
			$month = $$t1[0];
			$year  = $$t1[1];
		}
		else
		{
			$bce  = $$t1[1];
			$year = $$t1[0];
		}
	}
	else
	{
		$day   = $$t1[0];
		$month = $$t1[1];
		$year  = $$t1[2];
	}

	my($result) =
	{
		kind  => 'Date',
		type  => 'French r',
		year  => $year,
	};

	$$result{bce}   = $bce if (defined $bce);
	$$result{day}   = $day if (defined $day);
	$$result{month} = $month if (defined $month);
	$result         = [$result];

	return $result;

} # End of french_date.

# ------------------------------------------------

sub from_date
{
	my($cache, $t1, $t2) = @_;

	print STDERR '#=== from_date() action: ', Dumper($t1), Dumper($t2) if ($verbose);

	my($t3)    = $$t2[0];
	$t2        = $$t2[1];
	$t2        = $$t2[0] if (ref $t2 eq 'ARRAY');
	$$t2{flag} = 'FROM';

	# Is there a calendar hash present?

	if (ref $t3 eq 'HASH')
	{
		$t2 = [$t3, $t2];
	}

	return $t2;

} # End of from_date.

# ------------------------------------------------

sub german_date
{
	my($cache, $t1) = @_;

	print STDERR '#=== german_date() action: ', Dumper($t1) if ($verbose);

	my($bce);
	my($day);
	my($month);
	my($year);

	# Check for year, month, day.

	if ($#$t1 == 0)
	{
		$year = $$t1[0][0];
		$bce  = $$t1[0][1];
	}
	elsif ($#$t1 == 2)
	{
		$month = $$t1[0];
		$year  = $$t1[2][0];
		$bce   = $$t1[2][1];
	}
	else
	{
		$day   = $$t1[0];
		$month = $$t1[2];
		$year  = $$t1[4][0];
		$bce   = $$t1[4][1];
	}

	my($result) =
	{
		kind  => 'Date',
		type  => 'German',
		year  => $year,
	};

	$$result{bce}   = $bce if (defined $bce);
	$$result{day}   = $day if (defined $day);
	$$result{month} = $month if (defined $month);
	$result         = [$result];

	return $result;

} # End of german_date.

# ------------------------------------------------

sub gregorian_date
{
	my($cache, $t1) = @_;

	print STDERR '#=== gregorian_date() action: ', Dumper($t1) if ($verbose);

	# Is it a BCE date? If so, it's already a hashref.

	if (ref($$t1[0]) eq 'HASH')
	{
		return $$t1[0];
	}

	my($day);
	my($month);
	my($year);

	# Check for year, month, day.

	if ($#$t1 == 0)
	{
		$year = $$t1[0];
	}
	elsif ($#$t1 == 1)
	{
		$month = $$t1[0];
		$year  = $$t1[1];
	}
	else
	{
		$day   = $$t1[0];
		$month = $$t1[1];
		$year  = $$t1[2];
	}

	my($result) =
	{
		kind  => 'Date',
		type  => 'Gregorian',
		year  => $year,
	};

	# Check for /00.

	if ($year =~ m|/|)
	{
		($$result{year}, $$result{suffix}) = split(m|/|, $year);
	}

	$$result{month} = $month if (defined $month);
	$$result{day}   = $day   if (defined $day);
	$result         = [$result];

	return $result;

} # End of gregorian_date.

# ------------------------------------------------

sub gregorian_month
{
	my($cache, $t1) = @_;

	print STDERR '#=== gregorian_month() action: ', Dumper($t1) if ($verbose);

	$t1 = $$t1[0] if (ref $t1);

	return $t1;

} # End of gregorian_month.

# ------------------------------------------------

sub gregorian_year_bce
{
	my($cache, $t1, $t2) = @_;

	print STDERR '#=== gregorian_year_bce() action: ', Dumper($t1), Dumper($t2) if ($verbose);

	return
	{
		bce  => $t2,
		kind => 'Date',
		type => 'Gregorian',
		year => $t1,
	};

} # End of gregorian_year_bce.

# ------------------------------------------------

sub hebrew_date
{
	my($cache, $t1) = @_;

	print STDERR '#=== hebrew_date() action: ', Dumper($t1) if ($verbose);

	my($bce);
	my($day);
	my($month);
	my($year);

	# Check for year, month, day.

	if ($#$t1 == 0)
	{
		$year = $$t1[0];
	}
	elsif ($#$t1 == 1)
	{
		# First check for BCE.

		if ($$t1[1] =~ /[0-9]/)
		{
			$month = $$t1[0];
			$year  = $$t1[1];
		}
		else
		{
			$bce  = $$t1[1];
			$year = $$t1[0];
		}
	}
	else
	{
		$day   = $$t1[0];
		$month = $$t1[1];
		$year  = $$t1[2];
	}

	my($result) =
	{
		kind  => 'Date',
		type  => 'Hebrew',
		year  => $year,
	};

	$$result{bce}   = $bce if (defined $bce);
	$$result{day}   = $day if (defined $day);
	$$result{month} = $month if (defined $month);
	$result         = [$result];

	return $result;

} # End of hebrew_date.

# ------------------------------------------------

sub interpreted_date
{
	my($cache, $t1) = @_;

	print STDERR '#=== interpreted_date() action: ', Dumper($t1) if ($verbose);

	my($t2)      = $$t1[1][1][0];
	$$t2{flag}   = 'INT';
	$$t2{phrase} = "($$t1[2][0])";

	return [$$t1[1][0], $t2];

} # End of interpreted_date.

# ------------------------------------------------

sub julian_date
{
	my($cache, $t1) = @_;

	print STDERR '#=== julian_date() action: ', Dumper($t1) if ($verbose);

	# Is it a BCE date? If so, it's already a hashref.

	if (ref($$t1[0]) eq 'HASH')
	{
		return $$t1[0];
	}

	my($day);
	my($month);
	my($year);

	# Check for year, month, day.

	if ($#$t1 == 0)
	{
		$year = $$t1[0];
	}
	elsif ($#$t1 == 1)
	{
		$month = $$t1[0];
		$year  = $$t1[1];
	}
	else
	{
		$day   = $$t1[0];
		$month = $$t1[1];
		$year  = $$t1[2];
	}

	my($result) =
	{
		kind  => 'Date',
		type  => 'Julian',
		year  => $year,
	};

	$$result{month} = $month if (defined $month);
	$$result{day}   = $day if (defined $day);
	$result         = [$result];

	return $result;

} # End of julian_date.

# ------------------------------------------------

sub julian_year_bce
{
	my($cache, $t1, $t2) = @_;

	print STDERR '#=== julian_year_bce() action: ', Dumper($t1), Dumper($t2) if ($verbose);

	return
	{
		bce  => $t2,
		kind => 'Date',
		type => 'Julian',
		year => $t1,
	};

} # End of julian_year_bce.

# ------------------------------------------------

sub to_date
{
	my($cache, $t1, $t2) = @_;

	print STDERR '#=== to_date() action: ', Dumper($t1), Dumper($t2) if ($verbose);

	my($t3)    = $$t2[0];
	$t2        = $$t2[1];
	$t2        = $$t2[0] if (ref $t2 eq 'ARRAY');
	$$t2{flag} = 'TO';

	# Is there a calendar hash present?

	if (ref $t3 eq 'HASH')
	{
		$t2 = [$t3, $t2];
	}

	return $t2;

} # End of to_date.

# ------------------------------------------------

sub year
{
	my($cache, $t1, $t2) = @_;

	print STDERR '#=== year() action: ', Dumper($t1), Dumper($t2) if ($verbose);

	$t1 = "$t1/$t2" if (defined $t2);

	return $t1;

} # End of year.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<Genealogy::Gedcom::Date::Actions> - A nested SVG parser, using XML::SAX and Marpa::R2

=head1 Synopsis

See L<Genealogy::Gedcom::Date/Synopsis>.

=head1 Description

Basically just utility routines for L<Genealogy::Gedcom::Date>. Only used indirectly by
L<Marpa::R2>.

Specifially, calls to functions are triggered by items in the input stream matching elements of
the current grammar (and Marpa does the calling).

Each action function returns a arrayref or hashref, which Marpa gathers. The calling code in
L<Genealogy::Gedcom::Date> decodes the result so that its C<parse()> method can return an arrayref.

=head1 Installation

See L<Genealogy::Gedcom::Date/Installation>.

=head1 Constructor and Initialization

This class has no constructor. L<Marpa::R2> fabricates an instance, but won't let us get access to
it.

So, we use a global variable, C<$logger>, initialized in L<Genealogy::Gedcom::Date>,
in case we need logging. Details:

=over 4

=item o logger => aLog::HandlerObject

By default, an object of type L<Log::Handler> is created which prints to STDOUT,
but given the default, nothing is actually printed unless the C<maxlevel> attribute of this object
is changed in L<Genealogy::Gedcom::Date>.

Default: anObjectOfTypeLogHandler.

Usage (in this module): $logger -> log(info => $string).

=back

=head1 Methods

None.

=head1 Functions

Many.

=head1 Globals

Yes, some C<our> variables are used to communicate the C<Genealogy::Gedcom::Date>.

=head1 FAQ

See L<Genealogy::Gedcom::Date/FAQ>.

=head1 Author

L<Genealogy::Gedcom::Date> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2011.

Home page: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2011, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://dev.perl.org/licenses/

=cut
