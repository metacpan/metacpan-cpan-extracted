package Lab::Measurement::KeyboardHandling;
#ABSTRACT: Minimal keyboard input handling
$Lab::Measurement::KeyboardHandling::VERSION = '3.881';
use v5.20;

use Term::ReadKey;

my $labkey_initialized = 0;

sub labkey_safe_exit {
    ReadMode('normal');
    exit(@_);
}

sub labkey_safe_int {
    ReadMode('normal');
    exit(1);
}

sub labkey_safe_die {
    ReadMode('normal');

    # In order to print stack trace do not call exit(@_) here.
}

sub labkey_init {
    $SIG{'INT'}   = \&labkey_safe_int;
    $SIG{'QUIT'}  = \&labkey_safe_exit;
    $SIG{__DIE__} = \&labkey_safe_die;
    END { labkey_safe_exit(); }
    ReadMode('raw');
    $labkey_initialized = 1;
}

sub labkey_check {

    # handle as much as we can here directly
    # q - exit: if parameter soft=1 is passed, just return "DIE", otherwise exit
    # p - pause, i.e. output "Measurement paused, press any key to continue"
    # t - output script timing info
    my $soft = shift;

    if (   ( $labkey_initialized == 1 )
        && ( defined( my $key = ReadKey(-1) ) ) ) {

        # input waiting; it's in $key
        if ( $key eq 'q' ) {
            print "Terminating on keyboard request\n";
            if   ( $soft == 1 ) { return "DIE"; }
            else                { exit; }
        }
        if ( $key eq 'p' ) {
            print "Measurement paused, press any key to continue\n";
            while ( !defined( my $key = ReadKey(-1) ) ) {
                sleep 1;
            }
            print "Measurement continuing\n";
        }
        if ( $key eq 't' ) {
            print "Timing info following (maybe, sometime)\n";
        }
    }
    return "";
}

sub labkey_soft_check {
    return labkey_check(1);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Measurement::KeyboardHandling - Minimal keyboard input handling

=head1 VERSION

version 3.881

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by the Lab::Measurement team; in detail:

  Copyright 2012       Andreas K. Huettel, Hermann Kraus
            2016       Simon Reinhardt
            2017       Andreas K. Huettel
            2020       Andreas K. Huettel


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
