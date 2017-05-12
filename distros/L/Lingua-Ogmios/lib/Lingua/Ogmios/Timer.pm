package Lingua::Ogmios::Timer;

use strict;
use warnings;

use Time::HiRes qw( gettimeofday tv_interval);

my $debug_devel_level = 0;

sub new {
    my ($class) = @_;

    my $timer = {
	'timeStart' => undef,
	'temporaryTimeEnd' => undef,
	'userTimeStart' => undef,
	'userTimeEnd' => undef,
	'NumberOfSteps' => 0,
	'laps' => [],
	'userTimeStartBySteps' => [],
	'userTimeEndBySteps' => [],
	'timeByCategory' => {},
    };
    bless $timer, $class;
    return $timer;
}

# By Category

sub getTimeByCategory {
    my ($self) = @_;

    return($self->{"timeByCategory"});
}


sub resetTimeByCategory {
    my ($self) = @_;

    $self->{"timeByCategory"} = {};
}


sub addNewCategory {
    my ($self, $categoryName) = @_;

    if (!exists $self->getTimeByCategory->{$categoryName}) {
	$self->getTimeByCategory->{$categoryName} = {'times' => [],
						 'lastItem' => -1,
						 };
    }
    return($self->getTimeByCategory->{$categoryName});
}

sub getCategory {
    my ($self, $categoryName) = @_;

    return($self->getTimeByCategory->{$categoryName});
}

sub startsLapByCategory {
    my ($self, $categoryName) = @_;

    my $time = [gettimeofday];
    my $category = $self->getCategory($categoryName);

    if (!defined $category) {
	$category = $self->addNewCategory($categoryName);
    }

    # warn $self->getLastItem($category);
    push @{$category->{'times'}}, {'start' => $time, 'end' => $time};

    $category->{'lastItem'}++;
    # warn $self->getLastItem($category);
}

sub endsLapByCategory {
    my ($self, $categoryName, $item) = @_;

    my $category = $self->getCategory($categoryName);

    if (!defined($item)) {
	# warn "not defined item for $categoryName\n";
	$item = $self->getLastItem($category);
    }

    if (!defined $item) {
	warn " not defined item for $categoryName\n";
    }
    $category->{'times'}->[$item]->{'end'} = [gettimeofday];
#    $category->{'lastItem'}--;
}

sub getLastItem {
    my ($self, $category) = @_;

    # warn $category->{'lastItem'} . "\n";
    return($category->{'lastItem'});
}

sub _printTimeByCategory {
    my ($self, $printDetails) = @_;
    my $categoryName;
    my $i;
    my $timeSum;
    my $time;

    foreach $categoryName (keys %{$self->getTimeByCategory}) {
	warn "Category: $categoryName\n";
	$timeSum = 0;
	for($i=0;$i < scalar(@{$self->getCategory($categoryName)->{'times'}});$i++) {
	    $time =  tv_interval($self->getCategory($categoryName)->{'times'}->[$i]->{'start'}, $self->getCategory($categoryName)->{'times'}->[$i]->{'end'});
	    $timeSum += $time;
	    if ((!defined $printDetails) || ($printDetails != 0)) {
		warn "\tItem $i: $time\n";
	    }
	}
	warn "    Total: $timeSum\n";
    }
    warn "\n";
}




########################################################################


# Lap (BySteps)

sub startsLap {
    my ($self, $stepName) = @_;

    $self->incrNumberOfSteps;
    $self->setLap($stepName);
}


sub getLaps {
    my $self = shift;

    return $self->{'laps'};
}

sub setLap {
    my ($self, $stepName) = @_;

    my $time = [gettimeofday];
    $self->getLaps->[$self->NumberOfSteps - 1] = {'timeStart' => $time, 
						  'stepName' => $stepName};
    $self->lapStartUserTimeBySteps($time);
    $self->lapEndUserTimeBySteps($time);
}

sub NumberOfSteps {
    my $self = shift;

    $self->{'NumberOfSteps'} = shift if @_;
    return $self->{'NumberOfSteps'};
}

sub getLapCurrentStep {
    my $self = shift;

    return($self->{'laps'}->[$self->NumberOfSteps - 1]);
}

sub getTimeLapCurrentStep {
    my $self = shift;

    return($self->getLapCurrentStep->{'timeStart'});
}

sub getNameLapCurrentStep {
    my $self = shift;

    return($self->getLapCurrentStep->{'stepName'});
}

sub incrNumberOfSteps {
    my ($self) = @_;

    return($self->NumberOfSteps($self->NumberOfSteps + 1));
}

sub lapStartUserTimeBySteps {
    my ($self, $value) = @_;

    if (!defined $value) {
	$value = [gettimeofday];
    }
    $self->getUserTimeStartBySteps->[$self->NumberOfSteps - 1] = $value;
}

sub lapEndUserTimeBySteps {
    my ($self, $value) = @_;

    if (!defined $value) {
	$value = [gettimeofday];
    }
    $self->getUserTimeEndBySteps->[$self->NumberOfSteps - 1] = $value;
}

sub getUserTimeStartBySteps {
    my ($self) = @_;

    return($self->{'userTimeStartBySteps'});
}

sub getUserTimeEndBySteps {
    my ($self) = @_;

    return($self->{'userTimeEndBySteps'});
}

sub getLapUserTimeStartBySteps {
    my ($self, $step) = @_;

    if (!defined $step) {
	$step = $self->NumberOfSteps - 1;
    }

    return($self->getUserTimeStartBySteps->[$step]);
}

sub getLapUserTimeEndBySteps {
    my ($self, $step) = @_;

    if (!defined $step) {
	$step = $self->NumberOfSteps - 1;
    }

    return($self->getUserTimeEndBySteps->[$step]);
}

sub getTimesBySteps {
    my ($self) = @_;

    my $userTime = 0;
    my $systemTimeBefore = 0;
    my $systemTimeAfter = 0;
    my $systemTime = 0;
    my $fullTime = 0;
    
    my $currentTime = [gettimeofday];
    $userTime = tv_interval($self->getLapUserTimeStartBySteps, $self->getLapUserTimeEndBySteps) ;

    $systemTimeBefore = tv_interval($self->getTimeLapCurrentStep, $self->getLapUserTimeStartBySteps) ;
    $systemTimeAfter = tv_interval($self->getLapUserTimeEndBySteps, $currentTime);

    $systemTime = $systemTimeBefore + $systemTimeAfter;

    $fullTime = tv_interval($self->getTimeLapCurrentStep, $currentTime);
    
    return($fullTime, $systemTime, $systemTimeBefore, $systemTimeAfter, $userTime);
}

sub _printTimesBySteps {
    my ($self) = @_;

    my @times = $self->getTimesBySteps;
    warn "    Step: " . ($self->NumberOfSteps - 1) . " (step: " . $self->getNameLapCurrentStep . ")\n";
    warn "\tFull time processing: " . $times[0] . "\n";
    warn "\tSystem time processing: " . $times[1] . "\n";
    warn "\tSystem time processing (Before): " . $times[2] . "\n";
    warn "\tSystem time processing (After): " . $times[3] . "\n";
    warn "\tUser time processing: " . $times[4] . "\n";
    warn "\n";
}

########################################################################

sub start {
    my ($self) = @_;

    $self->{'timeStart'} = [gettimeofday];
}

sub suspendWithUserTime {
    my ($self) = @_;

    my $userTimeInterval = 0;

    my $lastTemporaryTimeEnd = $self->getTemporaryTimeEnd;

    if (!defined $lastTemporaryTimeEnd ) {
	$lastTemporaryTimeEnd = $self->getTimeStart;
	if (!defined $lastTemporaryTimeEnd ) {
	    warn "The timer is not start. Timer functions disabled\n";
	}
    }
    $self->{'temporaryTimeEnd'} = [gettimeofday];

    my $fullTimeInterval = tv_interval ( $lastTemporaryTimeEnd, $self->{'temporaryTimeEnd'} ) ;

    my $startUserTime = $self->getStartUserTime;
    my $endUserTime = $self->getEndUserTime;

    if (!defined($startUserTime) && !(defined $endUserTime)) {
	warn "The user time not set. Feature disabled\n";
    } else {
	$userTimeInterval = tv_interval($self->getStartUserTime, $self->getEndUserTime);
    }

    my $systemTimeInterval = 0;
    if (defined $userTimeInterval) {
	$systemTimeInterval = $fullTimeInterval - $userTimeInterval;
    } else {
	$systemTimeInterval = $fullTimeInterval;
    }
    return($fullTimeInterval, $systemTimeInterval, $userTimeInterval);
}

sub _printTimes {
    my ($self) = @_;

    my @times = $self->suspendWithUserTime;
    warn "\tFull time processing: " . $times[0] . "\n";
    warn "\tSystem time processing: " . $times[1] . "\n";
    warn "\tUser time processing: " . $times[2] . "\n";

}

sub _printTimesInLine {
    my ($self,$tool) = @_;

    my @times = $self->suspendWithUserTime;
    warn "# tool\tFull time processing\tSystem time processing\tUser time processing\n";
    warn "Running Time for $tool\t" . $times[0] . "\t" . $times[1] . "\t" . $times[2] . "\n";
}

sub markEndUserTime {
    my ($self) = @_;

    $self->{'userTimeEnd'} = [gettimeofday];
}

sub markStartUserTime {
    my ($self) = @_;

    $self->{'userTimeStart'} = [gettimeofday];
}

sub getEndUserTime {
    my ($self) = @_;

    return($self->{'userTimeEnd'});
}

sub getStartUserTime {
    my ($self) = @_;

    return($self->{'userTimeStart'});
}

sub suspend {
    my ($self) = @_;

    my $lastTemporaryTimeEnd = $self->getTemporaryTimeEnd;

    if (!defined $lastTemporaryTimeEnd ) {
	$lastTemporaryTimeEnd = $self->getTimeStart;
	if (!defined $lastTemporaryTimeEnd ) {
	    warn "The timer is not start. Timer functions disabled\n";
	}
    }
    $self->{'temporaryTimeEnd'} = [gettimeofday];
    return(tv_interval ( $lastTemporaryTimeEnd, $self->{'temporaryTimeEnd'} ) );
}

sub suspendFromStart {
    my ($self) = @_;

    $self->{'temporaryTimeEnd'} = [gettimeofday];
    return(tv_interval ( $self->getTimeStart, $self->{'temporaryTimeEnd'} ) );
}

sub reset {
    my ($self) = @_;

    $self->{'startTime'} = undef;
    $self->{'temporaryTimeEnd'} = undef;
}

sub getTemporaryTimeEnd {
    my ($self) = @_;

    return($self->{'temporaryTimeEnd'});
}

sub setTemporaryTimeEnd {
    my ($self) = @_;

    $self->{'temporaryTimeEnd'} = [gettimeofday];
}

sub getTimeStart {
    my ($self) = @_;

    return($self->{'timeStart'});
}

sub getTime {
    my ($self, $time) = @_;

    my $sec = $time->[0];
    my $usec = $time->[1];

    return($sec+$usec*1e6);
}

1;

__END__

=head1 NAME

Lingua::Ogmios::Timer - Perl extension for the timer of the Ogmios NLP platform

=head1 SYNOPSIS

use Lingua::Ogmios::???;

my $timer = Lingua::Ogmios::???::new();


=head1 DESCRIPTION


=head1 METHODS

=head2 function()

    function($rcfile);

=head1 SEE ALSO


=head1 AUTHORS

Thierry Hamon <thierry.hamon@limsi.fr>

=head1 LICENSE

Copyright (C) 2013 by Thierry Hamon

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut

