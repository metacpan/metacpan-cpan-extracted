package Gtk2::Ex::ICal::Recur::Selection;

our $VERSION = '0.04';

use strict;
use warnings;
use Data::Dumper;

sub new {
	my ($class, $column_names, $data_attributes) = @_;
	my $self  = {};
	bless ($self, $class);
	return $self;
}

sub day_of_the_year {
	my ($self, $callback) = @_;
	my $day_of_the_year = [
		'1st to 40th day' =>
			$self->make_struct(1, 40, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),
		'41th to 80th day' =>
			$self->make_struct(41, 80, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),
		'81th to 120th day' =>
			$self->make_struct(81, 120, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),
		'121th to 160th day' =>
			$self->make_struct(121, 160, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),
		'161th to 200th day' =>
			$self->make_struct(161, 200, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),
		'201th to 240th day' =>
			$self->make_struct(201, 240, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),
		'241th to 280th day' =>
			$self->make_struct(241, 280, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),
		'281th to 320th day' =>
			$self->make_struct(281, 320, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),
		'321th to 344th day' =>
			$self->make_struct(321, 366, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),

		'last to (last - 40)th day' =>
			$self->make_struct(-1, -40, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),
		'(last - 41)th to (last - 80)th day' =>
			$self->make_struct(-41, -80, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),
		'(last - 81)th to (last - 120)th day' =>
			$self->make_struct(-81, -120, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),
		'(last - 121)th to (last - 160)th day' =>
			$self->make_struct(-121, -160, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),
		'(last - 161)th to (last - 200)th day' =>
			$self->make_struct(-161, -200, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),
		'(last - 201)th to (last - 240)th day' =>
			$self->make_struct(-201, -240, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),
		'(last - 241)th to (last - 280)th day' =>
			$self->make_struct(-241, -280, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),
		'(last - 281)th to (last - 320)th day' =>
			$self->make_struct(-281, -320, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),
		'(last - 321)th to (last - 344)th day' =>
			$self->make_struct(-321, -366, 'byyearday', '<FROM> to <TO> week', 'on the <THIS> day of the year', $callback),

	];
	return $day_of_the_year;
}

sub month_of_the_year {
	my ($self, $callback) = @_;
	my $day_of_the_year = [				
		'during the month of January'       => {
			callback => $callback,
			callback_data => ['bymonth','during the month of January', 1]
		},
		'during the month of February'       => {
			callback => $callback,
			callback_data => ['bymonth','during the month of February', 2]
		},
		'during the month of March'       => {
			callback => $callback,
			callback_data => ['bymonth','during the month of March', 3]
		},
		'during the month of April'       => {
			callback => $callback,
			callback_data => ['bymonth','during the month of April', 4]
		},
		'during the month of May'       => {
			callback => $callback,
			callback_data => ['bymonth','during the month of May', 5]
		},
		'during the month of June'       => {
			callback => $callback,
			callback_data => ['bymonth','during the month of June', 6]
		},
		'during the month of July'       => {
			callback => $callback,
			callback_data => ['bymonth','during the month of July', 7]
		},
		'during the month of August'       => {
			callback => $callback,
			callback_data => ['bymonth','during the month of August', 8]
		},
		'during the month of September'       => {
			callback => $callback,
			callback_data => ['bymonth','during the month of September', 9]
		},
		'during the month of October'       => {
			callback => $callback,
			callback_data => ['bymonth','during the month of October', 10]
		},
		'during the month of November'       => {
			callback => $callback,
			callback_data => ['bymonth','during the month of November',11]
		},
		'during the month of December'       => {
			callback => $callback,
			callback_data => ['bymonth','during the month of December', 12]
		},
	];
	return $day_of_the_year;
}

sub speak {
	my ($num) = @_;
	if ($num eq 1) {
		return '1st';
	} elsif ($num eq 2) {
		return '2nd';		
	} elsif ($num eq 3) {
		return '3rd';		
	} else {
		return $num.'th';
	}
}

sub make_struct {
	my ($self, $from, $to, $type, $parentstring, $childstring, $callback) = @_;
	my $spoken_from = speak($from);
	my $spoken_to = speak($to);	
	$parentstring =~ s/<FROM>/$spoken_from/;
	$parentstring =~ s/<TO>/$spoken_to/;
	my @children;
	if ($from > $to) {
		($from, $to) = ($to, $from);
	}
	for (my $i=$from; $i<=$to; $i++) {
		my $tempchildstring = $childstring;
		my $spoken_i;
		if ($i < 0) {
			if ($i == -1) {
				$spoken_i = 'last';
			} else {
				my $j = $i+1;
				$spoken_i = '(last '.$j.')th';
			}
		} else {
			$spoken_i = speak($i);
		}
		$tempchildstring  =~ s/<THIS>/$spoken_i/;
		push @children, $tempchildstring;
		push @children , {
			callback => $callback,
			callback_data => [$type, $tempchildstring, $i],
		};		
	}
	my $hash = {
			item_type  => '<Branch>',			
			children => \@children,
	};
	return $hash;
}

sub weeknumber_of_the_year {
	my ($self, $callback) = @_;
	my $weeknumber_of_the_year = [
		'1st to 30th week' =>
			$self->make_struct(1, 30, 'byweekno', '<FROM> to <TO> week', 'during the <THIS> week of the year', $callback),
		'31th to 52th week' =>
			$self->make_struct(31, 52, 'byweekno', '<FROM> to <TO> week', 'during the <THIS> week of the year', $callback),
		'last to (last - 30)th week' =>
			$self->make_struct(-1, -30, 'byweekno', '<FROM> to <TO> week', 'during the <THIS> week of the year', $callback),
		'(last - 31)th to (last - 52)th week' =>
			$self->make_struct(-31, -52, 'byweekno', '<FROM> to <TO> week', 'during the <THIS> week of the year', $callback),
	];
	return $weeknumber_of_the_year;
}

sub month_day_by_week {
	my ($self, $callback) = @_;
	my @temp;

	push @temp, @{make_struct_month_day_by_week("Sunday", "su", $callback)};
	push @temp, @{make_struct_month_day_by_week("Monday", "mo", $callback)};
	push @temp, @{make_struct_month_day_by_week("Tuesday", "tu", $callback)};
	push @temp, @{make_struct_month_day_by_week("Wednesday", "we", $callback)};
	push @temp, @{make_struct_month_day_by_week("Thursday", "th", $callback)};
	push @temp, @{make_struct_month_day_by_week("Friday", "fr", $callback)};
	push @temp, @{make_struct_month_day_by_week("Saturday", "sa", $callback)};
	return \@temp;
}

sub make_struct_month_day_by_week {
	my ($weekday, $abbr, $callback) = @_;
	my $struct = [
		"$weekday"  => {
			item_type  => '<Branch>',			
			children => [
				"on the 1st $weekday of the month"       => {
					callback => $callback,
					callback_data => ['byday', "on the 1st $weekday of the month", "1$abbr"],
				},
				"on the 2nd $weekday of the month"       => {
					callback => $callback,
					callback_data => ['byday', "on the 2nd $weekday of the month", "2$abbr"],
				},
				"on the 3rd $weekday of the month"       => {
					callback => $callback,
					callback_data => ['byday', "on the 3rd $weekday of the month", "3$abbr"],
				},
				"on the 4th $weekday of the month"       => {
					callback => $callback,
					callback_data => ['byday', "on the 4th $weekday of the month", "4$abbr"],
				},
				"on the last $weekday of the month"       => {
					callback => $callback,
					callback_data => ['byday', "on the last $weekday of the month", "-1$abbr"],
				},
				"on the (last - 1)th $weekday of the month"       => {
					callback => $callback,
					callback_data => ['byday', "on the (last - 1)th $weekday of the month", "-2$abbr"],
				},
				"on the (last - 2)th $weekday of the month"       => {
					callback => $callback,
					callback_data => ['byday', "on the (last - 2)th $weekday of the month", "-3$abbr"],
				},
				"on the (last - 3)th $weekday of the month"       => {
					callback => $callback,
					callback_data => ['byday', "on the (last - 3)th $weekday of the month", "-4$abbr"],
				},
			],
		},
	];
	return $struct;
}

sub month_day_by_day {
	my ($self, $callback) = @_;
	my $month_day = [
		'1st to 31th day' =>
			$self->make_struct(1, 31, 'bymonthday', '<FROM> to <TO> day', 'on the <THIS> day of the month', $callback),
		'last to (last - 31)th day' =>
			$self->make_struct(-1, -31, 'bymonthday', '<FROM> to <TO> day', 'on the <THIS> day of the month', $callback),
	];
	return $month_day;
}

sub week_day {
	my ($self, $callback) = @_;
	my $day_of_the_week = [
		'on the Sunday'       => {
			callback => $callback,
			callback_data => ['byday', 'on the Sunday', 'su'],
		},
		'on the Monday'       => {
			callback => $callback,
			callback_data => ['byday', 'on the Monday', 'mo'],
		},
		'on the Tuesday'       => {
			callback => $callback,
			callback_data => ['byday', 'on the Tuesday', 'tu'],
		},
		'on the Wednesday'       => {
			callback => $callback,
			callback_data => ['byday', 'on the Wednesday', 'we'],
		},
		'on the Thursday'       => {
			callback => $callback,
			callback_data => ['byday', 'on the Thursday', 'th'],
		},
		'on the Friday'       => {
			callback => $callback,
			callback_data => ['byday', 'on the Friday', 'fr'],
		},
		'on the Saturday'       => {
			callback => $callback,
			callback_data => ['byday', 'on the Saturday', 'sa'],
		},
	];
	return $day_of_the_week;
}

1;

__END__
=head1 NAME

Gtk2::Ex::ICal::Recur::Selection - This class is not to be used directly. This is just a 
helper class for the C<Gtk2::Ex::ICal::Recur> module.

=head1 AUTHOR

Ofey Aikon, C<< <ofey.aikon at gmail dot com> >>

=head1 BUGS

You tell me. Send me an email !

=head1 ACKNOWLEDGEMENTS

To the wonderful gtk-perl-list.

=head1 COPYRIGHT & LICENSE

Copyright 2004 Ofey Aikon, All Rights Reserved.
This library is free software; you can redistribute it and/or modify it under the terms of the GNU Library General Public License as published by the Free Software Foundation; 
This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Library General Public License for more details.
You should have received a copy of the GNU Library General Public License along with this library; if not, write to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307 USA.

=head1 SEE ALSO

Gtk2::Ex::ICal::Recur

=cut
