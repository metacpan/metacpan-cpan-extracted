package Lab::Moose::Countdown;
$Lab::Moose::Countdown::VERSION = '3.682';
#ABSTRACT: Verbose countdown/delay with pretty printing of remaining time

use 5.010;
use warnings;
use strict;

use Exporter 'import';
use Time::HiRes qw/time sleep/;
use Time::Seconds;

our @EXPORT = qw/countdown/;



sub countdown {

    # Do not use MooseX::Params::Validate for performance reasons.
    my $delay = shift;
    my $prefix = shift // "Sleeping for ";

    if ( $delay < 0.5 ) {
        sleep $delay;
        return;
    }

    my $t1 = time();

    my $autoflush = STDOUT->autoflush();

    while () {
        my $remaining = $delay - ( time() - $t1 );
        if ( $remaining < 0.5 ) {
            sleep $remaining;
            last;
        }
        $remaining = Time::Seconds->new( int($remaining) + 1 );
        sleep 0.1;
        print $prefix, $remaining->pretty, "               \r";
    }
    say " " x 80;
    STDOUT->autoflush($autoflush);
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Countdown - Verbose countdown/delay with pretty printing of remaining time

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose::Countdown;

 # Sleep for 23.45678 seconds with pretty countdown
 countdown(23.45678, "Getting ready, Remaining time is ");

=head1 FUNCTIONS

=head2 countdown

 my $delay = 2 # seconds
 countdown($delay)

 my $prefix = "Some prefix text";
 countdown($delay, $prefix);

Replacement for C<Time::HiRes::sleep>. Pretty print the remaining
hours/minutes/seconds. If the argument is smaller than 0.5 seconds, no
countdown is printed and the function behaves exactly like C<Time::HiRes::sleep>.
Default C<$prefix> is C<"Sleeping for">.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
