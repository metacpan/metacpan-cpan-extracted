#PODNAME: Lab::XPRESS::Utilities
#ABSTRACT: Global utility functions for XPRESS

use v5.20;

no strict; # FIXME

#note: this is no "package"

use Term::ReadKey;
use Time::HiRes qw/usleep/, qw/time/;

# collection of some useful subroutines:

sub my_sleep {
    my $sleeptime    = shift;
    my $self         = shift;
    my $user_command = shift;
    if ( $sleeptime >= 5 ) {
        countdown( $sleeptime * 1e6, $self, $user_command );
    }
    else {
        usleep( $sleeptime * 1e6 );
    }
}

sub my_usleep {
    my $sleeptime    = shift;
    my $self         = shift;
    my $user_command = shift;
    if ( $sleep_time >= 5 ) {
        countdown( $sleeptime, $self, $user_command );
    }
    else {
        usleep($sleeptime);
    }
}

sub countdown {
    my $duration     = shift;
    my $self         = shift;
    my $user_command = shift;

    ReadMode('cbreak');

    $duration /= 1e6;
    my $hours   = int( $duration / 3600 );
    my $minutes = int( ( $duration - $hours * 3600 ) / 60 );
    my $seconds = $duration - $hours * 3600 - $minutes * 60;

    my $t_0 = time();

    local $| = 1;

    my $message = "Waiting for ";

    if    ( $hours > 1 )    { $message .= "$hours hours "; }
    elsif ( $hours == 1 )   { $message .= "one hour "; }
    if    ( $minutes > 1 )  { $message .= "$minutes minutes "; }
    elsif ( $minutes == 1 ) { $message .= "one minute "; }
    if    ( $seconds > 1 )  { $message .= "$seconds seconds "; }
    elsif ( $seconds == 1 ) { $message .= "one second "; }

    $message .= "\n";

    print $message;

    while ( ( $t_0 + $duration - time() ) > 0 ) {

        my $char = ReadKey(1);

        if ( defined($char) && $char eq 'c' ) {
            last;
        }
        elsif ( defined($char) ) {
            if ( defined $user_command ) {
                $user_command->( $self, $char );
            }
            else {
                user_command($char);
            }
        }

        my $left    = ( $t_0 + $duration - time() );
        my $hours   = int( $left / 3600 );
        my $minutes = int( ( $left - $hours * 3600 ) / 60 );
        my $seconds = $left - $hours * 3600 - $minutes * 60;

        print sprintf( "%02d:%02d:%02d", $hours, $minutes, $seconds );
        print "\r";

        #sleep(1);

    }
    ReadMode('normal');
    $| = 0;
    print "\n\nGO!\n";

}

sub timestamp {

    my (
        $Sekunden, $Minuten,   $Stunden,   $Monatstag, $Monat,
        $Jahr,     $Wochentag, $Jahrestag, $Sommerzeit
    ) = localtime(time);

    $Monat     += 1;
    $Jahrestag += 1;
    $Monat     = $Monat < 10     ? $Monat     = "0" . $Monat     : $Monat;
    $Monatstag = $Monatstag < 10 ? $Monatstag = "0" . $Monatstag : $Monatstag;
    $Stunden   = $Stunden < 10   ? $Stunden   = "0" . $Stunden   : $Stunden;
    $Minuten   = $Minuten < 10   ? $Minuten   = "0" . $Minuten   : $Minuten;
    $Sekunden  = $Sekunden < 10  ? $Sekunden  = "0" . $Sekunden  : $Sekunden;
    $Jahr += 1900;

    return "$Monatstag.$Monat.$Jahr", "$Stunden:$Minuten:$Sekunden";

}

sub user_command {
    my $cmd = shift;

    print "test user_command = $cmd\n";

    # do something;
}

sub seconds2time {
    my $duration = shift;

    my $hours   = int( $duration / 3600 );
    my $minutes = int( ( $duration - $hours * 3600 ) / 60 );
    my $seconds = $duration - $hours * 3600 - $minutes * 60;

    my $formated = $hours . "h " . $minutes . "m " . $seconds . "s ";

    return $formated;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::XPRESS::Utilities - Global utility functions for XPRESS (deprecated)

=head1 VERSION

version 3.899

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       Stefan Geissler
            2013       Andreas K. Huettel
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
