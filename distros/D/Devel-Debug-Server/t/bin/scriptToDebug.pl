use strict;
use warnings;
use Time::HiRes qw(usleep nanosleep);

#this dummy script is just a test program to manipulate with the debugger

sub dummySubroutine($){
    my ($value) = @_;
    return $value++;
}


my $dummyVariable = "dummy";

my $infiniteLoop = 1;
for (my $i=0;$infiniteLoop == 1;$i++){ #we are in a infinite loop except 
                           #if someone modify $infiniteLoop with a debugger
    print $dummyVariable.$i."\n";
    my $computedValue = dummySubroutine($i);
    print "foo : ".$computedValue."\n";
    usleep(100);
}


