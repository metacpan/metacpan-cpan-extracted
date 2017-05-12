package Mindcal;
use strict;
use warnings;
use DateTime;
use Log::Log4perl qw(:easy);

our $VERSION = '0.01';

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    my $self = {
        month_items => [qw(0 3 3 6 1 4 6 2 5 0 3 5)],
        century_adjust => {
            qw(1700 4 1800 2 1900 0 2000 6 
               2100 4 2200 2 2300 0)
        },
        dows => [qw[Sunday Monday Tuesday Wednesday Thursday Friday Saturday]],
        %options,
    };

    if(!defined $self->{date} or 
        ref($self->{date}) ne "DateTime") {
        LOGDIE "new() called without DateTime date";
    }

    bless $self, $class;
    return $self;
}

###########################################
sub month_item {
###########################################
    my($self) = @_;

    return $self->{month_items}->[$self->{date}->month() - 1];
}

###########################################
sub year_item {
###########################################
    my($self) = @_;

    use integer;
    my $year  = $self->{date}->year();
    my $year2 = ($year % 100);

    return (($year2 + ($year2 / 4)) % 7);
}

###########################################
sub century_adjust {
###########################################
    my($self) = @_;

    use integer;

    my $year  = $self->{date}->year();
    my $month = $self->{date}->month();
    my $cent = $year / 100;

    if(!exists $self->{century_adjust}->{ $cent * 100 }) {
        LOGDIE "Century $cent not supported (yet).";
    }

    return $self->{century_adjust}->{ $cent*100 };
}

###########################################
sub day_item {
###########################################
    my($self) = @_;

    return $self->{date}->day();
}

###########################################
sub weekday {
###########################################
    my($self) = @_;

    my $dow = $self->year_item() +
              $self->month_item() +
              $self->day_item() + 
              $self->adjust;

    return $self->{dows}->[ $dow % 7 ];
}

###########################################
sub adjust {
###########################################
    my($self) = @_;

    my $adj = $self->century_adjust();
    my $month = $self->{date}->month();

    $adj-- if $self->is_leap_year() and $month <= 2;

    return $adj;
}

###########################################
sub is_leap_year {
###########################################
    my($self) = @_;

    my $year = $self->{date}->year();

    return 0 if $year % 4;
    return 1 if $year % 100;
    return 0 if $year % 400;
    return 1;
}

1;
__END__

=head1 NAME

Mindcal - Calculate day-of-week of any given date in your head

=head1 SYNOPSIS

  use Mindcal;
  use DateTime;

  my $mc = Mindcal->new(
    date => DateTime->new(
        day   => 1,
        month => 1,
        year  => 2000,
    )
  );

  print "Year item:  ", $mc->year_item(), "\n";
  print "Month item: ", $mc->month_item(), "\n";
  print "Day item:   ", $mc->day_item(), "\n";
  print "Adjust:     ", $mc->adjust(), "\n";
  print "Weekday:    ", $mc->weekday(), "\n";

=head1 DESCRIPTION

This module helps training the necessary mental steps to determine the
day of the week of any given date in your head.

The method was invented by Lewis Carroll ("Alice in Wonderland") and
eloquently described as hack #43 in "Mind Performance Hacks" by Ron 
Hale-Evans, O'Reilly 2006.

The method involves calculating four different values of a given date in
your head, the year item, the month item, the day item and an adjustment.
Once you've calculated those four values, simply add them up and calculate
the remainder of a division by seven (so that's modulo 7) and look up 
the day of the week in the following table:

    0 Sunday
    1 Monday
    2 Tuesday
    3 Wednesday
    4 Thursday
    5 Friday
    6 Saturday

=head2 The Year Item

The year item can be determined by the following formula:

    (YY + (YY div 4)) mod 7

YY is the two-digit year, the century gets discarded. YY of 2007 is simply 
07.  

The 'div' operator is an ordinary division but it drops the remainder. In
this way, "7 div 4" is 1. Why? 7/4 results in 1, remainder 3, 
which gets discarded.

The 'mod' operator is a modulo operation, which is the remainder after an
ordinary division. "7 mod 4" is 3. Why? 7/4 results in 1, remainder 3. Only
the remainder is kept.

So, according to the formula above, the year item for the year 2007 is

    (7 + (7 div 4)) mod 7

which is

    (7 + 1) mod 7

and therefore 1.

=head2 The Month Item

The month items are best memorized as a string of numbers:

    01  02  03  04  05  06    07  08  09  10  11  12
     0   3   3   6   1   4     6   2   5   0   3   5

I personally memorize them as 

=over 4

=item *

Start with "033".

=item *

Continue with "614" (like 314, which is PI, just start with 6)

=item *

Continue with "625" (that's 25*25, the area of a rectangle, as opposed
to a circle, as suggested by the previously used PI)

=item * 

End with "035" (that's two more than the start sequence "033")

=back

It takes some practice to memorize these 12 numbers, but I've found that 
it's quite easy to do if you split it up in two groups of 6 and map the
desired month number onto the correct group of 6.

To calculate the month item, look it up in the table above. For example,
the month item for July is 6.

=head2 The Day Item

The day item is simply the day of the month. For example, the day item
for July 27th is 27.

=head2 The Adjustment

The adjustment is dependent on the century and if the given year is a leap
year or not. For beginners, I recommend only memorizing the following numbers:

    1900 0
    2000 6

So for a date between 1900 and 1999, the adjustment value is 0. Between
2000 and 2099, it is 6.

If the given year is a leap year and the given date is in January or 
February, subtract 1 from the adjustment value. For example, if you 
want to calculate the weekday of 1/1/2000 and you know that 2000 is a leap
year, the adjustment value is 5. Why? For 2000, according to the table
above, we have to add 6, but since it's a date in January of a leap year,
we subtract 1.

For more advanced users, here's the table for additional centuries:

    1700 4
    1800 2
    1900 0
    2000 6
    2100 4
    2200 2
    2300 0

=head2 Adding it all up

After adding the year, month, day values and the adjustment, determine
the remainder after a division by 7 (in math terms, the result of
a modulo 7 operation).

For example, to determine the weekday of 11/27/1964, we calculate 

=over 4

=item *

a year item of 3

=item *

a month item of 3

=item *

a day item of 27

=item *

an adjustment of 0

=back

Adding 3+3+27 yields 33, which has a remainder of 5 after a division by 7
(28 is the next-lowest number divisible by 7 and 33-28=5).

Looking up 5 in the weekday table yields a Friday. Therefore, 
11/27/1964 is a Friday.

=head1 EXAMPLES

Let's train calculating year items on random years between 1900 and 2099:

  use Mindcal;
  use DateTime;

  while(1) {
    my $year = 1900 + int rand 200;
    print "$year?\n";
    <>;

    my $mc = Mindcal->new(
        date => DateTime->new(
            day   => 1,
            month => 1,
            year  => $year,
        )
    );

    print "Year item:  ", $mc->year_item(), "\n";
  }

For a script printing random dates and, on a push of a button, the 
corresponding year, month, day, and adjustment values, try C<mindcal>
which comes with the Mindcal CPAN distribution.

=head1 AUTHOR

Mike Schilli, E<lt>m@perlmeister.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Mike Schilli

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
