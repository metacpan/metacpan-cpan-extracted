package Labyrinth::Audit;

use warnings;
use strict;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Audit - Audit Handler for Labyrinth.

=head1 SYNOPSIS

  use Labyrinth::Audit;

  SetLogFile(%hash);
  LogRecord($level,@args);

  # examples
  SetLogFile(
    FILE   => $logfile,
    USER   => $username,
    LEVEL  => $LOG_LEVEL_INFO,
    CLEAR  => 1,
    CALLER => 1
  );

  LogRecord($LOG_LEVEL_INFO,'Process Started');

=head1 DESCRIPTION

The Audit package contains a number of variables and functions that can be
used within the framework to provide error, debugging and trace information.

=head1 EXPORT

  DumpToFile

  SetLogFile
  LogRecord

  LogError
  LogWarning
  LogInfo
  LogDebug

  $LOG_LEVEL_ERROR
  $LOG_LEVEL_WARN
  $LOG_LEVEL_INFO
  $LOG_LEVEL_DEBUG

  $LOG_LEVEL

=cut

# -------------------------------------
# Export Details

require Exporter;
@ISA = qw(Exporter);

%EXPORT_TAGS = (
    'all' => [ qw(
        DumpToFile
        SetLogFile LogRecord
        LogError LogWarning LogInfo LogDebug
        $LOG_LEVEL_DEBUG $LOG_LEVEL_INFO
        $LOG_LEVEL_WARN  $LOG_LEVEL_ERROR
        $LOG_LEVEL
    ) ],
);

@EXPORT_OK = ( @{$EXPORT_TAGS{'all'}} );
@EXPORT    = ( @{$EXPORT_TAGS{'all'}} );

# -------------------------------------
# Library Modules

use IO::File;
use Log::LogLite;

# -------------------------------------
# Variables

# Log level constants
our $LOG_LEVEL_DEBUG    = 4;
our $LOG_LEVEL_INFO     = 3;
our $LOG_LEVEL_WARN     = 2;
our $LOG_LEVEL_ERROR    = 1;

# Default log level (can be over-ridden by Labyrinth)
our $LOG_LEVEL = $LOG_LEVEL_ERROR;
our $VERBOSE = 0;
our $CALLER  = 0;

my $firstpass = 1;
my $logfile = undef;
my $username;

# -------------------------------------
# The Subs

=head1 FUNCTIONS

=head2 Audit Log Handling

Audit Log functions enable tracing of actions for a user at a given time.

=over 4

=item DumpToFile($file,@blocks)

Writes blocks (separated by new lines) to the given file. Creates the file if
it doesn't exist, and overwrites if it does.

=cut

sub DumpToFile {
    my $file = shift;

    my $fh = IO::File->new($file, 'w+') or return;
    print $fh join("\n",@_) . "\n";
    $fh->close;
}

=item SetLogFile(%hash)

Hash table entries can be as follows:

    FILE  => $logfile,
    USER  => $username,
    LEVEL => $LOG_LEVEL_INFO,
    CLEAR => 1;

Note that FILE and USER are mandatory.

Sets the path of the file to be used as the log, together with the current
username accessing the application.

Note that if there is any failure, such as no file access, the audit trail is
disabled.

=cut

sub SetLogFile {
    my %hash = @_;

    return  unless($hash{FILE});
    return  unless($hash{USER});

    eval { if(!-e $hash{FILE}) { my $fh = IO::File->new("$hash{FILE}", 'w+'); $fh->close } };
    return  if($@ || ! -w $hash{FILE});

    $username  = $hash{USER};
    $LOG_LEVEL = $hash{LEVEL}   if($hash{LEVEL});
    $CALLER    = 1              if($hash{CALLER});

    if($hash{CLEAR}) { my $fh = IO::File->new("$hash{FILE}", 'w+'); $fh->close }

    $logfile = Log::LogLite->new($hash{FILE},$LOG_LEVEL);
    return  unless($logfile);
    $logfile->template( "[<date>] <message>\n" );
}

=item LogRecord($level,@args)

Record informational messages to Audit Log.

=cut

sub LogRecord {
    my $level = shift || $LOG_LEVEL_DEBUG;
    my $mess = '';

    return  unless($logfile);

    {
        local $" = ",";
        $mess = "@_"    if(@_);
    }

    my $audit = "<:$username> [$level] $mess";

    if($CALLER) {
        my $i = 1;
        while(my @calls = caller($i++)) {;
            $audit .= " => CALLER($calls[1],$calls[2])";
        }
    }

    print STDERR $mess . "\n"   if($VERBOSE && $level <= $LOG_LEVEL_INFO);

    return  if($level > $LOG_LEVEL);

    $logfile->write('-' x 40,$level)    if($firstpass);
    $logfile->write($audit,$level);
    $firstpass = 0;
}

=item LogError(@args)

Shorthand call for Error messages.

=item LogWarning(@args)

Shorthand call for Warning messages.

=item LogInfo(@args)

Shorthand call for Information messages.

=item LogDebug(@args)

Shorthand call for Debug messages.

=cut

sub LogError    { LogRecord($LOG_LEVEL_ERROR,@_)    if($LOG_LEVEL >= $LOG_LEVEL_ERROR); }
sub LogWarning  { LogRecord($LOG_LEVEL_WARN ,@_)    if($LOG_LEVEL >= $LOG_LEVEL_WARN ); }
sub LogInfo     { LogRecord($LOG_LEVEL_INFO ,@_)    if($LOG_LEVEL >= $LOG_LEVEL_INFO ); }
sub LogDebug    { LogRecord($LOG_LEVEL_DEBUG,@_)    if($LOG_LEVEL >= $LOG_LEVEL_DEBUG); }

1;

__END__

=back

=head1 SEE ALSO

  Log::LogLite
  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
