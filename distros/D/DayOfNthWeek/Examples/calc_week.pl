#!/usr/local/bin/perl

# This is included in the distribution of DayOfNthWeek so people
# who are interested can check my logic and correct it if
# it is wrong or feel better seeing that I am going to 
# give them the correct answer every time.

# mday is the month day as from localtime() range is 1..31
# wday is the day of the week as from localtime() range is 0..6 (Sun=0)
# cday is the value from the loop to calculate the solution range is 0..6

# This program goes cycles through every mday 
# then calculates each wday for that mday

# Compare the out put of this program against the file months.txt
# and you will see that wday always gives the correct week
# while cday is often wrong.  This is why I calculate all of the
# days and push them into a has keyed by wday instead of just running
# the calculation and using cday. 

# I am no mathematician so I cannot do the proof showing why this
# formula works, it just does.  

for $mday (1 .. 31) {

# makes mday index from 0 just like wday

	$date= $mday - 1;
	
	print "\nMday\tWday\tWeek\tCday\n$mday\n";

	for $c (0 ..6 ) {  # $c == cday 

		$day = $date+$c;

		$wday = $day%7;
		$week  = (int($day/7))+1;

		print "\t$wday\t$week\t$c\n";	
	}

} 


# Copyright 2002 by Andy Murren

# This is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself. 
