package Format::LongNumber;

our $VERSION = '0.02';

=head1 NAME

Format::LongNumber - Format long numbers to human readable view.

=cut

=head1 SYNOPSIS

	use Format::LongNumber;

	my $seconds = 3600*24*3 + 3600*4 + 60*5 + 11;
	print full_time($seconds); # '3d 4h 5m 11s'

	my $bytes = 123456789;
	print full_traffic($bytes); # '117Mb 755Kb 277b'
	print short_traffic($bytes); # '117.74Mb'

	# You may create custom formats by functions:
	# short_value(%grade_table, $value);
	# full_value(%grade_table, $value);

	# For example:
	my %my_time_grade = (
		3600*24	=> " day ",
		3600	=> " hour ",
		60		=> " min ",
		1		=> " sec "
	);
	print full_value(\%my_time_grade, 121); # '2 min 1 sec'
);


=cut


use strict;
use warnings;


require Exporter;
our @ISA = qw| Exporter |;
our @EXPORT = (qw|
	full_time
	full_traffic
	full_number
	full_value
	short_time
	short_traffic
	short_value
	short_number
|);

my %_TIME_GRADE = (
	3600*24	=> "d ",
	3600	=> "h ",
	60		=> "m ",
	1		=> "s "
);

my %_TRAFFIC_GRADE = (
	1024**4	=> "Tb ",
	1024**3	=> "Gb ",
	1024**2	=> "Mb ",
	1024	=> "Kb ",
	1		=> "b"
);

my %_NUMBER_GRADE = (
	1000**3	=> ".",
	1000**2	=> ".",
	#1000	=> ".",
	#1		=> ""
);

=head1 DESCRIPTION

=over

=item * full_value(\%grade_table, $total)

Abstract function of the final value 

Params: 

	%grade_table - hash with dimensions, where the key is a value dimension, and the value is the symbol dimension 
	$total - value to bring us to the desired mean

=back
=cut

sub full_value {
	my ($grade_table, $total) = @_;
	
	$total ||= 0;

	$total = 0 if $total < 0;

	my $result = "";
	my @grades = sort { $b <=> $a } keys %$grade_table;
	for my $grade (@grades) {
		my $value = int($total / $grade);
		if ($value) {
			$total = $total % $grade;
			$result .= $value. $grade_table->{$grade};#. " ";
		}
	}

	unless ($result) {
		$result = "0". $grade_table->{$grades[$#grades]};
	} 
	#else {
	#	chop $result;
	#}

	$result =~ s/\s+$//;
	
	return $result;
}
#
# Wrapper for full_value(time_value)
#
sub full_time {
	my $seconds = shift;

	return full_value(\%_TIME_GRADE, $seconds);
}
#
# Wrapper for full_value(traffic_value)
#
sub full_traffic {
	my $bytes = shift;
	
	return full_value(\%_TRAFFIC_GRADE, $bytes);
}
#
# Wrapper for full_value(number_value)
#
sub full_number {
	my $number = shift;
	
	return full_value(\%_NUMBER_GRADE, $number);
}

=over

=item * short_value(\%grade_table, $total) 

Converts the given value only to the largest grade-value

=cut 

sub short_value {
	my ($grade_table, $total) = @_;
	
	$total ||= 0;
	
	$total = 0 if $total < 0;
	
	my $result = "";
	my @grades = sort { $b <=> $a } keys %$grade_table;
	for my $grade (@grades) {
		my $value = sprintf("%.2f", $total / $grade);
		my $fraction = $total % $grade;
		if (int $value) {
			$value = int $value if ($fraction == 0);
			$result = $value. $grade_table->{$grade};
			last;
		}
	}

	unless ($result) {
		$result = "0". $grade_table->{$grades[$#grades]};
	} 
	
	$result =~ s/\s+$//;

	return $result;
}	
#
# Wrapper for short_value(time_value)
#
sub short_time {
	my $seconds = shift;

	return short_value(\%_TIME_GRADE, $seconds);
}
#
# Wrapper for short_value(traffic_value) 
#
sub short_traffic {
	my $bytes = shift;
	
	return short_value(\%_TRAFFIC_GRADE, $bytes);
}
#
# Wrapper for short_value(number_value)Í
#
sub short_number {
	my $number = shift;
	
	return short_value(\%_NUMBER_GRADE, $number);
}
#
# The End
#
1;

=head1 AUTHOR

Mikhail N Bogdanov C<< <mbogdanov at cpan.org> >>

