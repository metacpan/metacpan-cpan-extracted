# Date Object Package by Dmitry Sagaev <zurik@mail.ru>

package EasyDate;

use strict;
use warnings;

our %month = (	1 => 'Jan', 
		2 => 'Feb',
		3 => 'Mar',
		4 => 'Apr',
		5 => 'May',
		6 => 'Jun',
		7 => 'Jul',
		8 => 'Aug',
		9 => 'Sen',
		10 => 'Oct', 
		11 => 'Nov',
		12 => 'Dec'	);

# --------------------------------------------------------------------------
# obj new([int,int,int])
# Description: This will create a new date object.
# --------------------------------------------------------------------------
sub new {

	my $the_day = $_[0] || 1;
	my $the_mon = $_[1] || 1;
	my $the_year = $_[2] || 2005;

	my $date = {
		the_day => $the_day,  the_mon => $the_mon,  the_year => $the_year
	};

	bless($date);
	return $date;
}

# --------------------------------------------------------------------------
# int day([int])
# Description: Access to Day parameter.
# --------------------------------------------------------------------------
sub day {
	my $self = shift;
	$self->{the_day} = shift if (@_);
	return $self->{the_day};
}

# --------------------------------------------------------------------------
# int mon([int])
# Description: Access to Month parameter.
# --------------------------------------------------------------------------
sub mon {
	my $self = shift;
	$self->{the_mon} = shift if (@_);
	return $self->{the_mon};
}

# --------------------------------------------------------------------------
# int year([int])
# Description: Access to Year parameter.
# --------------------------------------------------------------------------
sub year {
	my $self = shift;
	$self->{the_year} = shift if (@_);
	return $self->{the_year};
}


# --------------------------------------------------------------------------
# void setDate(int,int,int)
# Description: Set all date parameters.
# --------------------------------------------------------------------------
sub setDate {
	if (@_ == 4) {
		my $self = shift;
		$self->day(shift);
		$self->mon(shift);
		$self->year(shift);
	} else {
		print "Error using setDate. Not enough parameters.\n";
	}
}


# --------------------------------------------------------------------------
# int monMinus(obj)
# Description: Return current month of received object minus 1. 
# (for futher proposals)
# --------------------------------------------------------------------------
sub monMinus {
	my $self = shift;
	my $result;
	if ($self->mon eq '1')  {
		$result=12;
	} else {
		$result=$self->mon-1;
	}
	return $result;
}

# --------------------------------------------------------------------------
# int monPlus(obj)
# Description: Return current month of received object plus 1. 
# (for futher proposals)
# --------------------------------------------------------------------------
sub monPlus {
	my $self = shift;
	my $result;
	if ($self->mon eq '12')  {
		$result=1;
	} else {
		$result=$self->mon+1;
	}
	return $result;
}

# --------------------------------------------------------------------------
# void print()
# Description: Print all parameters.
# --------------------------------------------------------------------------
sub print {
	my $self = shift;
	print $self->day, "/", $self->mon, "/", $self->year, "\n";
}

# --------------------------------------------------------------------------
# int get_daysnum(int month, int year)
# Description: Return number of days in received M-Y (month,year)
# Example: &EasyDate::get_daysnum(6,2005);
# --------------------------------------------------------------------------
sub get_daysnum {
	my $mon = shift;
	my $year = shift;

	my %mondays = (	1 => "31", 2 => "",
			3 => "31", 4 => "30",
			5 => "31", 6 => "30",
			7 => "31", 8 => "31",
			9 => "30", 10 => "31",
		       11 => "30", 12 => "31");

  	$mondays{2} = ($year % 4) ? "28" : "29";
	return $mondays{$mon};
}

# --------------------------------------------------------------------------
# obj get_tDate()
# Description: Return date object with todays date parameters.
# Example: $mydate = $mydate->get_tDate;
# --------------------------------------------------------------------------
sub get_tDate {
	my ($sec, $min, $hour, $day, $mon, $year) = localtime();
	$mon+=1; $year+=1900;
	my $obj = new mydate;
	$obj->setDate($day, $mon, $year);
	return $obj;
}

# --------------------------------------------------------------------------
# int compare()
# Description: Compares two date object and returns 
#	        -1  - if first received object is less than second.
# 	         0  - if objects are equal.
# 	         1  - if first received object is more than second.
# --------------------------------------------------------------------------
sub compare {
	my $date1 = shift;
	my $date2 = shift;

	my $result;

	return (seconds($date1) < seconds($date2)) ? -1 :
		(seconds($date1) == seconds($date2)) ? 0 :
			 1;

}

# --------------------------------------------------------------------------
# int seconds(obj);
# Description: Convert received object's parameters (date) to 
# a seconds.
# --------------------------------------------------------------------------
sub seconds {
	my $self = shift;
#	my $yeardays = ($self->year % 4) ? 365 : 366;
	return ($self->day*24*60*60)+
	 ($self->mon*&mydate::get_daysnum($self->mon, $self->year)*24*60*60)+
	  ($self->year*365*24*60*60);
}

=head1 NAME

easyDate - A easy Interface For Date Objects;

=head1 SYNOPSIS

	use easyDate;
	
	my $obj = new easyDate(21,07,2005);
	my $newObj = new easyDate;


	$newObj->setDate(1,1,2005);
	$newObj->day(15);
	$newObj->mon(12);

	$result = &easyDate::compare($obj,$newObj);
	
	unless ($result) { print "Objects are equal!"; }

	$newObj = &easyDate::get_tDate;

	$newObj->print;	


=head1 DESCRIPTION

This module provides a fairly easy interface for creating and
using date objects. 

=head2 Methods


=over 13;

=item C<new>

Returns a new easyDate object. It can 
takes three arguments: The day, the month and the year.

check readme for more information.


=back

=head1 INSTALLATION

Just download the file to whatever location you like and C<use> it in
your scripts.

=head1 BUGS

Not known.

=head1 AUTHOR

Dmitry Sagaev - <zurik@mail.ru>

=head1 SEE ALSO

L<Time::Local>

=cut

1;