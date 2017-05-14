# $Id: Func.pm,v 1.4 2001/11/02 14:56:43 joern Exp $

package JaM::Func;

@ISA = qw ( JaM::GUI::Base );

use strict;
use Carp;
use JaM::GUI::Base;
use Date::Manip;

sub wrap_mail_text {
	my $class = shift;
	my %par = @_;
	my  ($text_sref, $wrap_length) =
	@par{'text_sref','wrap_length'};

	confess ("no wrap_length given") if not $wrap_length;

	my $new_text = "";
	my $line;
	
	my $DEBUG = 0;
	
	my $add_newline = 0;
	LINE: while ( $$text_sref =~ m/^(.*)$/mg ) {
		$DEBUG && print "read a new line\n";
		$line = $1;
		chomp $line;

		$DEBUG && print "line='$line'\n";
		
		if ( $line =~ /^\s*$/ ) {
			# empty line
			$new_text .= "\n";
			$add_newline = 0;
			next;
		}

		if ( $line =~ /^(\s+|\s*>)/ ) {
			# we dont wrap indented or quoted lines
			# (which distinguishes this from Text::Wrap)
			$new_text .= $line."\n";
			next;
		}

		# add newline, if there was no after the last wrapped line
		$new_text .= "\n" if $add_newline;

		# now wrap new_line
		my $wrapped_line = 0;
		$add_newline = 1;

		while ( 1 ) {
			if ( length($line) > $wrap_length ) {
				$wrapped_line = 1;
				$DEBUG && print "new_line too long\n";
				my ($left, $right) = ( $line =~ m/^(.{0,$wrap_length})(.*)/ );
				$DEBUG && print "left='$left'\n";
				$DEBUG && print "right='$right'\n";
				# did we cut a word?
				if ( $left =~ m/[^\s]$/ and $right =~ m/^[^\s]/ ) {
					$DEBUG && print "we cut a word\n";
					$left =~ s/([^\s]+)$//;
					if ( $left eq '' ) {
						$DEBUG && print "line too long\n";
						$new_text .= "$line\n";
						next LINE;
					}
					$DEBUG && print "word start from left: $1\n";
					$line = "$1$right";
					$new_text .= "$left\n";
				} else {
					$DEBUG && print "we NOT cut a word\n";
					$left =~ s/\s+$//;
					$new_text .= "$left\n";
					$right =~ s/^\s+//;
					$line = $right;
				}
			} else {
				$DEBUG && print "add to new_text: '$line'\n";
				$new_text .= "$line\n";
				$add_newline = 0 if not $wrapped_line;
				last;
			}
		}
	}
	
	$$text_sref = $new_text;
	
	1;
}

# convert a unix timestamp to date format

my @WEEKDAYS = ( 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat' );

sub format_date {
	my $class = shift;
	my %par = @_;
	my ($sent_time, $date, $nice) = @par{'time','date','nice'};

	# if $date is given, format to unix time
	if ( $date ) {
		$sent_time = UnixDate ($date, "%s");
	}

	# format sent date
	my $sent_nice;
	my @st = localtime($sent_time);
	my @tt = localtime(time);
	
	if ( not $nice ) {
		# full date
		return sprintf (
			"%s %02d.%02d.%04d %02d:%02d",
			$WEEKDAYS[$st[6]],
			$st[3],$st[4]+1,$st[5]+1900,$st[2], $st[1]
		);
	}
	
	if ( $st[7] == $tt[7] ) {
		# from today: only time
		$sent_nice = sprintf (
			"%02d:%02d",
			$st[2], $st[1]
		);
	} elsif ( $sent_time > time - 432000 ) {
		# less than 5 days: Weekday and time
		$sent_nice = sprintf (
			"%s %02d:%02d",
			$WEEKDAYS[$st[6]],
			$st[2], $st[1]
		);
	} else {
		# full date
		$sent_nice = sprintf (
			"%02d.%02d.%04d %02d:%02d",
			$st[3],$st[4]+1,$st[5]+1900,$st[2], $st[1]
		);
	}
	
	return $sent_nice;
}


1;
