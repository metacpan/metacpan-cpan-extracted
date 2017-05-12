package Football::League::Match;

use strict;
use warnings;

use Time::Piece;

$Football::League::Match::VERSION = '0.01';

=head1 NAME

Football::League::Match - A single footie match

=head1 SYNOPSIS

	use Football::League::Match;

	my $match = Football::League::Match->from_soccerdata($data);

	my $final_year_of_season = $match->final_year_of_season;
	
	my $division = $match->division;
	
	my $hometeam = $match->home_team;
	my $awayteam = $match->away_team;

	my $homescore = $match->home_score;
	my $awaycore = $match->away_score;
	my $result = $match->result;

	my Time::Piece $date = $match->date;

=head1 DESCRIPTION

This will create a little object with when passed data about a footie
match. 

Currently, the only format the data can ve passed in is that defined 
by that supplied by

http://www.soccerdata.com

=cut

sub _validate_date {
	my ($class, $date) = @_;
	my $tp = eval { Time::Piece->strptime($date, "%Y%m%d") };
	die "Invalid date" if $@;
	return $tp;
}

sub _validate_soccerdata {
	my ($class, $data) = @_;
	$data =~ s/"//g;
	my @fields = split ",", $data;
	die "Invalid number of fields" unless scalar @fields == 7;
	$fields[6] = $class->_validate_date($fields[6]);
	return @fields;
}

sub from_soccerdata {
	my ($class, $data) = @_;
	my @fields = $class->_validate_soccerdata($data);
	bless [@fields], $class;
}

=head1 METHODS

=head2 final_year_of_season

	my $fyos = $match->final_year_of_season;

This will return the final year of the season in which the match took place.

=head2 divison

	my $division = $match->division;

This is the divison the match took place in.

=head2 home_team

	my $home_team = $match->home_team;

The home team.

=head2 away_team

	my $away_team = $match->away_team;

The away team.

=head2 home_score

	my $home_score = $match->home_score;

The number of goals the home team scored.

=head2 away_score

	my $away_score = $match->away_score;

The number of goals the away team scored.

=head2 result

	my $result = $match->result;

This is the result in 2-1 type form.

=head2 date

	my Time::Piece $date = $match->date;

This is the date of the match as a Time::Piece object.

=cut

sub final_year_of_season { shift->[0] }
sub division   { shift->[1] }
sub home_team  { shift->[2] }
sub home_score { shift->[3] }
sub away_team  { shift->[4] }
sub away_score { shift->[5] }
sub date       { shift->[6] }

sub result {
	my $self = shift;
	return join "-", $self->home_score, $self->away_score;
}

=head1 ADDITIONAL INFO

=head2 soccerdata data format

The data supplied by soccerdata is in the form:

1,2,3,4,5,6,7

1 = final year of season (4 digit)
2 = division (P/1/2/3)
3 = home team (12 xharacters)
4 = home score (2 digits)
5 = away team (12 characters)
6 = away score (2 digits)
7 = match date (YYYYMMDD)

=head1 TODO

Well, this isn't really an inspired (or inspiring) moudle. As you may (or may
not) guess, this is part of A Bigger Picture. 

o Parse different match formats, perhaps screen scraped from some site 
  every saturday night.

=head1 BUGS

Craig McLaughlan has a lot to answer for. Mona, mostly.

=head1 SHOWING YOUR APPRECIATION

There was a thread on london.pm mailing list about working in a vacumn
- that it was a bit depressing to keep writing modules but never get
any feedback. So, if you use and like this module then please send me
an email and make my day.

All it takes is a few little bytes.

(Leon wrote that, not me!)

=head1 SEE ALSO

http://www.soccerdata.com

=head1 AUTHOR

Stray Toaster, E<lt>coder@stray-toaster.co.ukE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Stray Toaster

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

return qw/Foxes Never Quit/;
