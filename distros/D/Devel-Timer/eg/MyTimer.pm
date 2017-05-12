package MyTimer;
use strict;
use warnings;

##
## This is an example of how to subclass Devel::Timer
##

use strict;
use Devel::Timer;
use vars qw(@ISA);

@ISA = ("Devel::Timer");

sub initialize {
    my ($self) = @_;

    my $log = "timer.log";
    open(my $fh, '>>', $log) or die("Unable to open [$log] for writing.");
    $self->{MyTimer_fh} = $fh;
}

sub print {
    my($self, $msg) = @_;
    print {$self->{MyTimer_fh}} $msg . "\n";
}

sub shutdown {
    my ($self) = @_;
    close $self->{MyTimer_fh};
}

1;

