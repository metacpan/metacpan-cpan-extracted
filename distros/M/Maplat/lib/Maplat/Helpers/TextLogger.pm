# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Helpers::TextLogger;
use strict;
use warnings;
use Carp;

use Maplat::Helpers::DateStrings;
our $VERSION = 0.995;

sub new {
    my ($class, %config) = @_;
    my $self = bless \%config, $class;

    
    $self->log("Logfile for " . $self->{appname} . " (re)started");
    return $self;
}

sub logLine {
    my ($self, $logline) = @_;
    
    my $fullline = getISODate() . "  $logline\n";
    
    open($self->{fh}, ">>", $self->{logfile}) or croak($!);
    print {$self->{fh}} $fullline;
    close($self->{fh});
    print $fullline . "\n";
    return;
}

sub alive {
    my ($self) = @_;
    
    $self->log("-- " . $self->{appname} . " is alive --");
    return;
}

sub DESTROY {
    my ($self) = @_;
    
    $self->log("Stopping logfile");
    return;
}

1;

=head1 NAME

Maplat::Helpers::TextLogger - log to STDOUT and a logfile

=head1 SYNOPSIS

  use Maplat::Helpers::TextLogger qw(tabsToTable normalizeString);
  
  my $logger = new Maplat::Helpers::TextLogger(
                    appname    => "myApp",
                    logfile    => "yada.log"
                );
  $logger->log("Something happend");
  $logger->alive; # Notify the user that we're still alive

=head1 DESCRIPTION

This is a helper module to log to STDOUT as well as to a text file with the current date and time
prefixed to the logline.

=head2 new

  my $logger = new Maplat::Helpers::TextLogger(
                    appname    => "myApp",
                    logfile    => "yada.log"
                );

appname is the application name or some other unique identifier. logfile is the filename
of the logfile we want to use.

=head2 logLine

Takes one argument, the text we want to log.

=head2 alive

Log a "application_name is alive" log line. Use this if your program prints our log lines very
infrequently to show that the application is still running. Every 5 to 10 minutes or so is a good rule
of thumb.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

