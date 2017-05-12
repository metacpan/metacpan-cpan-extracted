package HTML::Calendar::Monthly;

# Monthly.pm -- A very simple HTML calendar
# RCS Info        : $Id: Monthly.pm,v 1.4 2009/06/25 09:18:25 jv Exp $
# Author          : Johan Vromans
# Created On      : Thu Apr 30 22:13:00 2009
# Last Modified By: Johan Vromans
# Last Modified On: Thu Jun 25 11:18:16 2009
# Update Count    : 4
# Status          : Unknown, Use with caution!

use strict;
use warnings;

our $VERSION = "0.03";

=head1 NAME

HTML::Calendar::Monthly - A very simple HTML calendar

=head1 SYNOPSIS

  use HTML::Calendar::Monthly;

  my $cal = HTML::Calendar::Monthly->new; # This month, this year
     $cal = HTML::Calendar::Monthly->new({ 'month' => $month }); # This year
     $cal = HTML::Calendar::Monthly->new({ 'month' => $month,
                                              'year'  => $year});

  my $month = $cal->month;
  my $year  = $cal->year;

  # Add a link for a day.
  $cal->add_link( $day, $link );

  # Get HTML representation.
  my $html = $cal->calendar_month;

=head1 DESCRIPTION

This is a very simple module which will make an HTML representation of
a given month. You can add links to individual days.

Yes, the inspiration for this came out of me looking at
HTML::Calendar::Simple, and thinking 'Hmmm. A bit too complicated for
what I want. I know, I will write a simplified version.' So I did.

=cut

use Date::Simple;

my @days   = qw( Ma Di Wo Do Vr Za Zo );
my @months = qw( Januari Februari Maart April Mei Juni Juli
                 Augustus September Oktober November December );

use constant DAYS_IN_WEEK => 7;
use constant DAYS_IN_MONTH => 31; # max

=head2 new

  my $cal = HTML::Calendar::Monthly->new;
  my $cal = HTML::Calendar::Monthly->new({ 'month' => $month });
  my $cal = HTML::Calendar::Monthly->new({ 'month' => $month,
                                              'year'  => $year });

This will make a new HTML::Calendar::Monthly object.

=cut

sub new {
    my $self = {};
    bless( $self, shift );
    $self->_init(@_);
    return $self;
}

sub _init {
    my $self = shift;
    # Validate the args passed to new, if there were any.
    my $valid_day = Date::Simple->new;
    my $ref = shift;
    if ( defined $ref && ref $ref eq 'HASH' ) {
	my $month = exists $ref->{month} ? $ref->{month} : $valid_day->month;
	my $year  = exists $ref->{year}  ? $ref->{year}  : $valid_day->year;
	$valid_day = $self->_date_obj($year, $month, 1);
	$valid_day = defined $valid_day ? $valid_day : Date::Simple->new;
    }
    $self->{month} = $valid_day->month;
    $self->{year}  = $valid_day->year;
    $self->{the_month} = $self->_days_list($self->{month}, $self->{year});
    return $self;
}

=head2 month

  my $month = $cal->month;

This will return the numerical value of the month.

  my $month = $cal->month_name;

This will return the name of the month.

=head2 year

  my $year = $cal->year;

This will return the four-digit year of the calendar

=cut

sub month      { $_[0]->{month}            } # month in numerical format
sub month_name { $months[$_[0]->{month}-1 ]} # month name
sub year       { $_[0]->{year}             } # year in YYYY form
sub _the_month { @{ $_[0]->{the_month} }   } # this is the list of hashrefs.

=head2 add_link

  $cal->add_link( $day, $link );    # puts an href on the day

=cut

sub add_link {
    my ($self, $day, $link) = @_;
    foreach my $day_ref ( $self->_the_month ) {
	next unless $day_ref && $day_ref->{date}->day == $day;
	$day_ref->{day_link} = $link;
	last;
    }
}

sub _cell {
    my ( $self, $ref ) = @_;
    return "<td class='hc_empty'></td>" unless $ref;

    if ( exists $ref->{day_link} ) {
	return
	  "<td class='hc_date_linked'>"
	    . "<a href='" . $ref->{day_link} . "'>" . $ref->{date}->day . "</a>"
	      . "</td>";
    }
    else {
	return
	  "<td class='hc_date'>"
	    . $ref->{date}->day
	      . "</td>";
    }
}

=head2 calendar_month

  my $html = $cal->calendar_month;

This will return an html string of the calendar month.

=cut

sub calendar_month {
    my $self = shift;
    my @seq  = $self->_the_month;
    my $cal  = "<table class='hc_month'>\n"
               . "  <tr>\n"
               . join("\n", map { "    <th>$_</th>" } @days )
               . "  </tr>\n";
    while ( @seq ) {
	my @week_row = splice( @seq, 0, DAYS_IN_WEEK );
	$#week_row = DAYS_IN_WEEK - 1;
	$cal .= "  <tr>\n"
                . join("\n", map { "    " . $self->_cell($_) } @week_row )
                . "\n  </tr>\n";
    }
    $cal .= "</table>\n";
    return $cal;
}


sub _date_obj { Date::Simple->new($_[1], $_[2], $_[3]) }

sub _days_list {
    my $self = shift;
    # Fill in a Date::Simple object for every day, Why not Date::Range object? 
    # Because I haven't installed it yet, and not sure it would be appropriate
    # for the way I have set this up.
    my ($month, $year) = @_;
    my $start = $self->_date_obj($year, $month, 1);
    my $end   = $start + DAYS_IN_MONTH;
    $end   = $self->_date_obj($end->year, $end->month, 1);

    my $st = $start->day_of_week;

    # We start weeks on monday.
    $st--;
    $st += DAYS_IN_WEEK if $st < 0;

    my @seq   = ( undef ) x $st;
    push @seq, { 'date' => $start++ } while ($start < $end);
    return \@seq;
}

=head1 AUTHOR

Johan Vromans E<lt>jvromans@squirrel.nlE<gt>

Parts of this module are copied from HTML::Calendar::Simple, written by Stray Toaster E<lt>coder@stray-toaster.co.ukE<gt>.

=cut

1;
