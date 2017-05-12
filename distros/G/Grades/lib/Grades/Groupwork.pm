#Last Edit: 2014 Jan 01, 12:16:04 PM
#$Id: Groupwork.pm 1947 2014-01-01 04:17:44Z drbean $

use MooseX::Declare;

=head1 NAME

Grades::Groupwork - A way of working as a team in a competition or school

=head1 SYNOPSIS

	use Grades;
	use Grades::Groupwork;

	my $grades = Grades->new( league => $league );
	my $classworkgrades = $grades->classwork;

=head1 DESCRIPTION

A superclass for the various ways a group (as opposed to pair) can work together and achieve a result.

Grades' Classwork role delegates its methods to one of a number of approaches. Some popular approaches, or forms of curriculum, are subclasses of Groupwork, like Groupwork::Responsible, Groupwork::NoFault. Other popular non-Groupwork approaches are Compcomp, and Jigsaw.

Keywords: gold stars, token economies, bean counter

=cut

=head1 ATTRIBUTES & METHODS

=cut

class Groupwork extends Approach {
	use List::Util qw/max min sum/;
	use List::MoreUtils qw/any/;
	use Carp;
	use POSIX;
	use Grades::Types qw/Beancans Card Results/;
	use Try::Tiny;

=head3 classMax

The maximum score possible in individual lessons for classwork.

=cut

	has 'classMax' => (is => 'ro', isa => 'Int', lazy => 1, required => 1,
			default => sub { shift->league->yaml->{classMax} } );

=head3 beancanseries

The different beancans for each of the sessions in the series. In the directory for each session of the series, there is a file called beancans.yaml, containing mappings of a beancan name to a sequence of PlayerNames, the members of the beancan. If beancans.yaml cannot be found, a file called groups.yaml is used instead.

=cut

    has 'beancanseries' => ( is => 'ro', lazy_build => 1 );
    method _build_beancanseries {
	my $dir = $self->groupworkdirs;
        my $series = $self->series;
        my $league = $self->league->id;
	my %beancans;
	for my $round ( @$series ) {
	    my $beancanfile = "$dir/$round/beancans.yaml";
	    my $file = -e $beancanfile? $beancanfile: "$dir/$round/groups.yaml";
	    try { $beancans{$round} = $self->inspect( $file ) }
		catch { local $" = ', ';
		    warn "Missing beancans in $league $dir round $round," };
	}
	return \%beancans;
    }

=head3 beancans

A hashref of all the beancans in a given session with the names keying the ids of the members of each beancan. The number, composition and names of the beancans may change from one session of the series to the next.
	
Players in one beancan all get the same Groupwork grade for that session. The beancan members may be the same as the members of the class group, who work together in class, or may be individuals. Usually in a big class, the beancans will be the same as the groups, and in a small class they will be individuals.

Players in the 'Absent' beancan all get a grade of 0 for the session.

Rather than refactor the class to work with individuals rather than groups, and expand some methods (?) to fall back to league members if it finds them in the weekly files instead of groups, I decided to introduce another file, beancans.yaml, and change all variable and method names mentioning group to beancan.

=cut 

	method beancans (Str $session) {
	    my $beancans = $self->beancanseries->{$session};
	    my $league = $self->league;
	    my %beancans = map { my $can = $_;
	        $can => { map { $_ => $league->ided( $_ ) }
	        		    @{$beancans->{$can}} } } keys %$beancans;
	    return \%beancans;
	}
=head3 beancan_names

A hashref of all the beancans in a given session with the names of the members of each beancan.
	
=cut 

	method beancan_names (Str $session) { $self->beancanseries->{$session}; }

=head3 allfiles

The files (unsorted) containing classwork points (beans) awarded to beancans, of form, groupworkdir/\d+\.yaml$

=cut


	has 'allfiles'  => ( is => 'ro', isa => 'ArrayRef', lazy_build => 1 );
	method _build_allfiles {
		my $dir = $self->groupworkdirs;
		my $series = $self->series;
		my $league = $self->league->id;
		my $files = [ grep m|/(\d+)\.yaml$|, glob "$dir/*.yaml"];
		croak "${league}'s @$series session files: @$files?" unless @$files;
		return $files;
	}

=head3 all_ided_files

The files containing classwork points (beans) awarded to beancans, of form, groupworkdir/\d+\.yaml$ keyed on the \d+.

=cut


	has 'all_ided_files'  => ( is => 'ro', isa => 'HashRef', lazy_build => 1 );
	method _build_all_ided_files {
		my $files = $self->allfiles;
		my %files = map { m|/(\d+)\.yaml$|; $1 => $_ } @$files;
		croak "No classwork files: $files?" unless %files;
		return \%files;
	}

=head3 all_events

The events (an array ref of integers) in which beans were awarded.

=cut

	has 'all_events' => ( is => 'ro', isa => 'ArrayRef', lazy_build => 1 );
	method _build_all_events {
		my $files = $self->all_ided_files;
		my @events = sort { $a <=> $b } keys %$files;
		croak "No classwork weeks: @events" unless @events;
		return \@events;
	}

=head3 lastweek

The last week in which beans were awarded. TODO lexicographic order, not numerical order.

=cut

	has 'lastweek' => ( is => 'ro', isa => 'Int', lazy_build => 1 );
	method _build_lastweek {
		my $weeks = $self->all_events;
		max @$weeks;
	}

=head3 data

The beans awarded to the beancans in the individual cards over the weeks of the series (semester.)

=cut

	has 'data' => (is => 'ro', isa => 'HashRef', lazy_build => 1);
	method _build_data {
		my $files = $self->all_ided_files;
		+{ map { $_ => $self->inspect( $files->{$_} ) } keys %$files };
	}

=head3 card

Classwork beans for each beancan for the given week

=cut

	method card (Num $week) {
		my $card = $self->data->{$week};
		croak "Week $week card probably has undefined or non-numeric Merit, Absence, Tardy scores, or possibly illegal beancan."
		    unless is_Card( $card );
		return $card;
	}

=head3 active

Given a session, returns the active beancans, ie all but the 'Absent' beancan.

=cut

	method active (Str $session) {
		my $beancans = $self->beancan_names($session);
		my %active = %$beancans;
		delete $active{Absent};
		return \%active;
	}

=head3 files

Given a session, returns the files containing beans awarded during the session according to the league.yaml session key. The files are of form, \d+\.yaml$

=cut

    method files (Str $session) {
	my $sessions = $self->league->session;
	croak "No session $session.\n" unless defined $sessions->{$session};
	my $firstweek = $sessions->{$session};
	my $allfiles = $self->allfiles;
	my @files;
	if ( defined $sessions->{$session+1} ) {
	    my $nextfirstweek = $sessions->{$session+1};
	    my $lastweek = $nextfirstweek - 1;
	    if ( $lastweek >= $firstweek ) {
		my $range = ( $firstweek .. $lastweek );
		@files = grep { m/\/(\d+)*\.yaml/;
		    $1 >= $firstweek && $1 <= $lastweek } @$allfiles;
	    }
	    else {
croak "Following session starts in week $nextfirstweek, the same week as or earlier than the start of session $session, in week $firstweek\n"
	    }
	}
	else {
	    @files = grep { m/(\d+)*\.yaml/; $1 >= $firstweek } @$allfiles;
	}
	return \@files;
    }

=head3 weeks

Given a session, returns the weeks (an array ref of integers) in which beans were awarded in the session.

=cut

    method weeks (Str $session) {

	my $files = $self->files($session);
	[ map { m|(\d+)\.yaml$|; $1 } @$files ];
    }

=head3 week2session

	$Groupwork->week2session(15) # fourth

Given the name of a week, return the name of the session it is in.

=cut

	method week2session (Num $week) {
		my $sessions = $self->series;
		my %sessions2weeks = map { $_ => $self->weeks($_) } @$sessions;
		while ( my ($session, $weeks) = each %sessions2weeks ) {
			return $session if any { $_ eq $week } @$weeks;
		}
		croak "Week $week in none of @$sessions sessions.\n";
	}

=head3 names2beancans

A hashref of names of members of beancans (players) and the beancans they were members of in a given session.

=cut

	method names2beancans (Str $session) {
		my $beancans = $self->beancan_names($session);
		my %beancansreversed;
		while ( my ($beancan, $names) = each %$beancans ) {
			for my $name ( @$names ) {
			croak
	"$name in $beancan beancan and other beancan in $session session.\n"
					if exists $beancansreversed{$name};
				$beancansreversed{$name} = $beancan;
			}
		}
		\%beancansreversed;
	}

=head3 name2beancan

	$Groupwork->name2beancan( $week, $playername )

Given the name of a player, the name of the beancan they were a member of in the given week.

=cut

	method name2beancan (Num $week, Str $name) {
		croak "Week $week?" unless defined $week;
		my $session = $self->week2session($week);
		my $beancans = $self->beancan_names($session);
		my @names; push @names, @$_ for values %$beancans;
		my @name2beancans;
		while ( my ($beancan, $names) = each %$beancans ) {
			push @name2beancans, $beancan for grep /^$name$/, @$names;
		}
		croak "$name not in exactly one beancan in $session session.\n"
					unless @name2beancans == 1;
		shift @name2beancans;
	}

=head3 beancansNotInCard

	$Groupwork->beancansNotInCard( $beancans, $card, 3)

Test all beancans, except Absent, exist in the beancans listed on the card for the week.

=cut

	method beancansNotInCard (HashRef $beancans, HashRef $card, Num $week) {
		my %common; $common{$_}++ for keys %$beancans, keys %$card;
		my @notInCard = grep { $common{$_} != 2 and $_ ne 'Absent' }
						keys %$beancans;
		croak "@notInCard beancans not in week $week data" if
					@notInCard;
	}

=head3 beancanDataOnCard

	$Groupwork->beancansNotInCard( $beancans, $card, 3)

Test all of the beancans, except Absent, have all the points due them for the week. Duplicates the check done by the Card type.

=cut

	method beancanDataOnCard (HashRef $beancans, HashRef $card, Num $week) {
		my @noData = grep { my $beancan = $card->{$_};
				$_ ne 'Absent' and ( 
					not defined $beancan->{merits}
					# or not defined $beancan->{absent}
					# or not defined $beancan->{tardies}
				    ) }
				keys %$beancans;
		croak "@noData beancans missing data in week $week" if @noData;
	}

=head3 merits

The points the beancans gained for the given week.

=cut

	method merits (Num $week) {
		my $session = $self->week2session($week);
		my $beancans = $self->active($session);
		my $card = $self->card($week);
		$self->beancansNotInCard($beancans, $card, $week);
		$self->beancanDataOnCard($beancans, $card, $week);
		+{ map { $_ => $card->{$_}->{merits} } keys %$beancans };
	}

=head3 absences

The numbers of players absent from the beancans in the given week.

=cut

	method absences (Num $week) {
		my $session = $self->week2session($week);
		my $beancans = $self->active($session);
		my $card = $self->card($week);
		$self->beancansNotInCard($beancans, $card, $week);
		$self->beancanDataOnCard($beancans, $card, $week);
		+{ map { $_ => $card->{$_}->{absences} } keys %$beancans };
	}

=head3 tardies

The numbers of players not on time in the beancans in the given week.

=cut

	method tardies (Num $week) {
		my $session = $self->week2session($week);
		my $beancans = $self->active($session);
		my $card = $self->card($week);
		$self->beancansNotInCard($beancans, $card, $week);
		$self->beancanDataOnCard($beancans, $card, $week);
		+{ map { $_ => $card->{$_}->{tardies} } keys %$beancans };
	}

}

=head2 Grades' Cooperative Methods

The idea of Cooperative Learning, giving individual members of a group all the same score, is that individuals are responsible for the behavior of the other members of the group. Absences and tardies of individual members can lower the scores of the members who are present.

Also, grading to the curve is employed so that the average classwork grade over a session for each student is 80 percent.

=cut

class Cooperative extends Groupwork {
	use List::Util qw/max min sum/;
	use List::MoreUtils qw/any/;
	use Carp;
	use POSIX;
	use Grades::Types qw/Beancans Card Results/;
	use Try::Tiny;

=head3 payout

How much should be given out for each beancan (except the 'Absent' beancan) for each week in this session, so that the total score of each player over the session averages 80?

=cut

	method payout (Str $session) {
		my $sessions = $self->series;
		my $beancans = $self->active($session);
		my $weeks = $self->weeks($session);
		my $payout = (80/@$sessions) * (keys %$beancans ) / @$weeks;
	}

=head3 demerits

The demerits that week. calculated as twice the number of absences, plus the number of tardies. In a four-member beancan, this ranges from 0 to 8.

=cut

	method demerits (Num $week) {
		my $absences = $self->absences($week);
		my $tardies = $self->tardies($week);
		my $session = $self->week2session($week);
		my $beancans = $self->active($session);
		+{map {$_ => ($absences->{$_} * 2 + $tardies->{$_} * 1)} keys %$beancans};
	}

=head3 favor

A score of 1 given to beancans with no more than 6 demerits, to prevent beancans who were all there but didn't do anything (ie had no merits and no demerits) from getting a log score of 0, and so getting a grade of 0 for that week.

=cut

	method favor (Num $week) {
		my $demerits = $self->demerits($week);
		my $session = $self->week2session($week);
		my $beancans = $self->active($session);
		+{ map {$_ => ($demerits->{$_} < 7? 1: 0)} keys %$beancans };
	}

=head3 maxDemerit

The max demerit that week. achieved by the beancan with the most absences and tardies.

=cut

	method maxDemerit (Num $week) {
		my $demerits = $self->demerits($week);
		max( values %$demerits );
	}

=head3 meritDemerit

Let beancans with no merits, and no demerits get a score greater than 1, so the log score is greater than 0. Let beancans with 3 or more absences and 1 tardies not be eligible for this favor, but get at least 0. Let other beancans get the number of merits - number of demerits, but also be eligible for the favor, and get a score of above 1.

=cut

	method meritDemerit (Num $week) {
		my $merits = $self->merits($week);
		my $demerits = $self->demerits($week);
		my $maxDemerit = $self->maxDemerit($week);
		my $favor = $self->favor($week);
		my $session = $self->week2session($week);
		my $beancans = $self->active($session);
		+{ map {$_=> $merits->{$_} + $favor->{$_} +
				$maxDemerit - $demerits->{$_}}
			keys %$beancans };
	}

=head3 work2grades

The work (ie merits - demerits) of the individual beancans for the week, as a percentage of the total work of all the beancans, determines the payout of grades, which should average 80 over the sessions of play. I was logscaling grades. I am now not doing that.

=cut

	method work2grades (Num $week) {
		# my $work = $self->logwork($week);
		my $work = $self->meritDemerit($week);
		my $session = $self->week2session($week);
		my $beancans = $self->active($session);
		my $totalwork = sum values %$work;
		my $payout = $self->payout($session);
		my %grades = map { $_ => $totalwork == 0? 0:
					( $work->{$_}*$payout/ $totalwork )
							} keys %$beancans;
		$grades{Absent} = 0;
		return \%grades;
	}

=head3 logwork

The points given by the teacher are log-scaled to prevent active students from taking all the payout, and the other students getting very low grades. There may be better ways of grading to the curve than using log scaling. The log of one point is 0, which results in a grade of 0 for that week for that beancan.

=cut

	method logwork (Num $week) {
		my $work = $self->meritDemerit($week);
		my $session = $self->week2session($week);
		my $beancans = $self->active($session);
		+{ map { $_ => $work->{$_} == 0 ?  0 : 1 + log $work->{$_} }
			keys %$beancans };
	}

=head3 grades4session

Totals for the beancans over the given session. TODO Why '+=' in sessiontotal?

=cut

	method grades4session (Str $session) {
		my $weeks = $self->weeks($session);
		my $beancans = $self->beancan_names($session);
		my (%sessiontotal);
		for my $week ( @$weeks ) {
			my $grade = $self->work2grades($week);
			for my $can ( keys %$beancans ) {
				if ( $can =~ m/absent/i ) {
					$sessiontotal{$can} = 0;
					next;
				}
				carp "$can not in week $week Groupwork"
					unless defined $grade->{$can};
				$sessiontotal{$can} += $grade->{$can};
			}
		}
		\%sessiontotal;
	}

=head3 playerGrade4session

Total for individual ids out of 100, for the given session

=cut
	method playerGrade4session (Str $session) {
		my $members = $self->league->members;
		my $series = $self->series;
		my %grades; $grades{$_->{id}} = 0 for @$members;
		my %presentMembers;
		my $can = $self->names2beancan_names($session);
		my $grade = $self->grades4session($session);
		for my $member ( @$members ) {
			my $name = $member->{name};
			my $id = $member->{id};
			my $beancan = $can->{$member->{name}};
			if ( defined $beancan ) {
				my $grade = $grade->{$can->{$name}};
				carp $member->{name} .
					" not in session $session"
					unless defined $grade;
				$grades{$id} += $grade;
			} else {
				carp $member->{name} .
				"'s beancan in session $session?"
			}
		}
		for my $member ( @$members ) {
			my $id = $member->{id};
			if ( exists $grades{$id} ) {
				$grades{$id} = min( 100, $grades{$id} );
			}
			else {
				my $name = $member->{name};
				carp "$name $id Groupwork?";
				$grades{$id} = 0;
			}
		}
		\%grades;
	}

=head3 totalPercent

Running totals for individual ids out of 100, over the whole series.

=cut
	has 'totalPercent' => ( is => 'ro', isa => Results, lazy_build => 1 );
	method _build_totalPercent {
		my $members = $self->league->members;
		my $series = $self->series;
		my (%grades);
		for my $session ( @$series ) {
			my %presentMembers;
			my $can = $self->names2beancans($session);
			my $grade = $self->grades4session($session);
			for my $member ( @$members ) {
				my $name = $member->{name};
				my $id = $member->{id};
				my $beancan = $can->{$member->{name}};
				if ( defined $beancan ) {
					my $grade = $grade->{$can->{$name}};
					carp $member->{name} .
						" not in session $session"
						unless defined $grade;
					$grades{$id} += $grade;
				} else {
					carp $member->{name} .
					"'s beancan in session $session?"
				}
			}
		}
		for my $member ( @$members ) {
			my $id = $member->{id};
			if ( exists $grades{$id} ) {
				my $grade = min( 100, $grades{$id} );
				my $rounded = sprintf '%.2f', $grade;
				$grades{$id} = $rounded;
			}
			else {
				my $name = $member->{name};
				carp "$name $id Groupwork?";
				$grades{$id} = 0;
			}
		}
		\%grades;
	}

}

=head2 Grades' GroupworkNoFault Approach

Unlike the Cooperative approach, GroupworkNoFault does not penalize members of a group who are present for the absence of other members who are not present or tardy. Instead the individual members not present get a grade of 0 for that class.

Also, no scaling of the grades (a group's merits) takes place. 

=cut

class GroupworkNoFault extends Groupwork {
	use List::Util qw/max min sum/;
	use List::MoreUtils qw/any/;
	use Carp;
	use POSIX;
	use Grades::Types qw/Beancans TortCard PlayerNames Results/;
	use Try::Tiny;

=head3 card

Classwork beans for each beancan for the given week. Not TortCard difference to Groupwork's card method.

=cut

	method card (Num $week) {
		my $card = $self->data->{$week};
		croak "Week $week card probably has undefined or non-numeric Merit, Absence, Tardy scores, or possibly illegal beancan."
		    unless is_TortCard( $card );
		return $card;
	}


=head3 absent

The players absent from each beancan in the given week.

=cut

        method absent (Num $week) {
                my $session = $self->week2session($week);
                my $beancans = $self->active($session);
                my $card = $self->card($week);
                $self->beancansNotInCard($beancans, $card, $week);
                $self->beancanDataOnCard($beancans, $card, $week);
                +{ map { $_ => $card->{$_}->{absent} } keys %$beancans };
        }


=head3 tardy

The players tardy from each beancan in the given week.

=cut

        method tardy (Num $week) {
                my $session = $self->week2session($week);
                my $beancans = $self->active($session);
                my $card = $self->card($week);
                $self->beancansNotInCard($beancans, $card, $week);
                $self->beancanDataOnCard($beancans, $card, $week);
                +{ map { $_ => $card->{$_}->{tardy} } keys %$beancans };
        }

=head3 points

The merits the beancans gained for the given week, except for those members who were absent, and who get zero, or tardy and who get 1. Keyed on player id.

=cut

	method points (Num $week) {
	    my $members = $self->league->members;
	    my %points;
	    for my $member ( @$members ) {
		my $name = $member->{name};
		my $id = $member->{id};
		my $beancan = $self->name2beancan( $week, $name );
		my $absent = $self->absent($week)->{$beancan};
		my $tardy = $self->tardy($week)->{$beancan};
		unless ( ( $absent and ref $absent eq 'ARRAY' ) or
			( $tardy and ref $tardy eq 'ARRAY' ) ) {
		    $points{$id} = $self->merits($week)->{$beancan}; 
		}
		else {
		    $points{$id} = ( any { $name eq $_ } @$absent ) ?
			0 : ( any { $name eq $_ } @$tardy ) ?
			1 : $self->merits($week)->{$beancan};
		}
	    }
	    return \%points;
	}

=head3 sessionMerits

The merits the beancans gained for the given session, with the Absent beancan getting zero. Keyed on beancan.

=cut

    method sessionMerits (Num $session) {
	my $weeks = $self->weeks($session);
	my $beancans = $self->beancan_names($session);
	my %merits;
	for my $week ( @$weeks ) {
	    my $merits = $self->merits($week);
	    $merits->{Absent} = 0;
	    $merits{$_} += $merits->{$_} for keys %$beancans;
	}
	$merits{Absent} = 0;
	return \%merits;
    }

=head3 grades4session

Totals for the beancans over the given session, keyed on individual names.

=cut

    method grades4session (Str $session) {
	my $weeks = $self->weeks($session);
	my $beancans = $self->beancan_names($session);
	my %tally;
	for my $week ( @$weeks ) {
	    my $grade = $self->merits($week);
	    my $absent = $self->absent($week);
	    for my $can ( keys %$beancans ) {
		my $members = $beancans->{$can};
		if ( $can =~ m/absent/i ) {
		    my @missing = @$members;
			$tally{$_} = 0 for @missing;
			next;
		}
		carp "$can not in week $week Groupwork"
			unless defined $grade->{$can};
		my $absent = $self->absent($week)->{$can};
		for my $member ( @$members ) {
		    if ( any { $member eq $_ } @$absent ) {
			$tally{$member} += 0;
		    }
		    else { $tally{$member} += $grade->{$can}; }
		}
	    }
	}
	\%tally;
    }

=head3 total

Totals for individual ids, over the whole series.

=cut

    has 'total' => ( is => 'ro', isa => Results, lazy_build => 1 );
    method _build_total {
	my $members = $self->league->members;
	my $series = $self->series;
	my (%grades);
	for my $session ( @$series ) {
	    my %presentMembers;
	    my $can = $self->names2beancans($session);
	    my $grade = $self->grades4session($session);
	    for my $member ( @$members ) {
		my $name = $member->{name};
		my $id = $member->{id};
		my $beancan = $can->{$member->{name}};
		if ( defined $beancan ) {
		    my $grade = $grade->{$name};
		    carp $member->{name} .
			"'s groupwork in session $session"
			unless defined $grade;
		    $grades{$id} += $grade;
		} else {
		    carp $member->{name} .
		    "'s beancan in session $session?"
		}
	    }
	}
	for my $member ( @$members ) {
	    my $id = $member->{id};
	    if ( exists $grades{$id} ) {
		$grades{$id} = min( 100, $grades{$id} );
	    }
	    else {
		my $name = $member->{name};
		carp "$name $id Groupwork?";
		$grades{$id} = 0;
	    }
	}
	\%grades;
    }

=head3 totalPercent

Running totals for individual ids out of 100, over the whole series.

=cut
	has 'totalPercent' => ( is => 'ro', isa => Results, lazy_build => 1 );
	method _build_totalPercent {
		my $members = $self->league->members;
		my $weeks = $self->all_events;
		my $weeklyMax = $self->classMax;
		my $totalMax = $weeklyMax * @$weeks;
		my $grades = $self->total;
		my $series = $self->series;
		my %percent;
		for my $member ( @$members ) {
		    my $id = $member->{id};
		    my $score = 100 * $grades->{$id} / $totalMax ;
		    warn "$member->{name}: ${id}'s classwork score of $score"
			if $score > 100;
		    my $rounded = sprintf '%.2f', $score;
		    $percent{$id} = $rounded;
		}
		return \%percent;
	}

}


1;    # End of Grades::Groupwork

=head1 AUTHOR

Dr Bean, C<< <drbean, followed by the at mark (@), cpan, then a dot, and finally, org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-grades at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Grades>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Grades

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Grades>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Grades>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Grades>

=item * Search CPAN

L<http://search.cpan.org/dist/Grades>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2010 Dr Bean, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


# vim: set ts=8 sts=4 sw=4 noet:
__END__
