package Log::Unrotate;
{
  $Log::Unrotate::VERSION = '1.32';
}

use strict;
use warnings;

=head1 NAME

Log::Unrotate - Incremental log reader with a transparent rotation handling

=head1 VERSION

version 1.32

=head1 SYNOPSIS

  use Log::Unrotate;

  my $reader = Log::Unrotate->new({
      log => 'xxx.log',
      pos => 'xxx.pos',
  });

  my $line = $reader->read();
  my $another_line = $reader->read();

  $reader->commit(); # serialize the position on disk into 'pos' file

  my $position = $reader->position();
  $reader->read();
  $reader->read();
  $reader->commit($position); # rollback the last 2 reads

  my $lag = $reader->lag();

=head1 DESCRIPTION

C<Log::Unrotate> allows you to read any log file incrementally and transparently.

B<Incrementally> means that you can store store the reading position to the special file ("pos-file") using C<commit()>, restart the process, and then continue from where you left.

B<Transparently> means that C<Log::Unrotate> automatically jumps from one log to the next. For example, if you were reading I<foo.log>, then stored the position and left for a day, and then while you were away, I<foo.log> got renamed to I<foo.log.1>, while the new I<foo.log> got some new content in it, C<Log::Unrotate> will find the right log and give you the remaining lines from I<foo.log.1> before moving to I<foo.log>.

Even better, it will do the right thing even if the log rotation happens while you were reading the log.

C<Log::Unrotate> tries really hard to never skip any data from logs. If it's not sure about what to do, it throws an exception. This is an extremely rare situation, and it is a good default for building a simple and robust message queue on top of this class, but if you prefer a quick-and-dirty recovering, you can enable I<autofix_cursor> option.

=cut

use Carp;

use IO::Handle;
use Digest::MD5 qw(md5_hex);

use Fcntl qw(SEEK_SET SEEK_CUR SEEK_END);
use Log::Unrotate::Cursor::File;
use Log::Unrotate::Cursor::Null;

sub _defaults ($) {
    my ($class) = @_;
    return {
        start => 'begin',
        lock => 'none',
        end => 'fixed',
        check_inode => 0,
        check_lastline => 1,
        check_log => 0,
        autofix_cursor => 0,
        rollback_period => 300,
    };
}

our %_start_values = map { $_ => 1 } qw(begin end first);
our %_end_values = map { $_ => 1 } qw(fixed future);

=head1 METHODS

=over

=cut

=item B<< new($params) >>

Creates a new unrotate object.

=over

=item I<pos>

Name of a file to store log reading position. Will be created automatically if missing.

Value '-' means not to use a position file. I.e., pretend it doesn't exist at the start and ignore commit calls.

=item I<cursor>

Instead of C<pos> file, you can specify any custom cursor. See C<Log::Unrotate::Cursor> for the cursor API details.

=item I<autofix_cursor>

Recreate a cursor if it's broken.

Warning will be printed on recovery.

=item I<rollback_period>

Time period in seconds.
If I<rollback_period> is greater than 0, C<commit> method will save some positions history (at least one previous position older then I<rollback_period> would be preserved)
to allow recovery when the last position is broken for some reason. (Position may sometimes become invalid because of the host's hard reboot.)

The feature is enabled by default (with value 300), set to 0 to disable, or set to some greater value if your heavily-loaded host is not flushing its filesystem buffers on disk this often.

=item I<log>

Name of a log file. Value C<-> means standard input stream.

=item I<start>

Describes the initialization behavior of new cursors. Allowed values: C<begin> (default), C<end>, C<first>.

=over 4

=item *

When I<start> is C<begin>, we'll read current I<log> from the beginning.

=item *

When I<start> is C<end>, we'll put current position in C<log> at the end (useful for big files when some new script don't need to read everything).

=item *

When I<start> is C<first>, C<Log::Unrotate> will start from the oldest log file available.

=back

I.e., if there are I<foo.log>, I<foo.log.1>, and I<foo.log.2>, C<begin> will start from the top of I<foo.log>, C<end> will skip to the bottom of I<foo.log>, while C<first> will start from the top of I<foo.log.2>.

=item I<end>

Describes the reading behavior when we reach the end of a log. Allowed values: C<fixed> (default), C<future>.

=over 4

=item *

When I<end> is C<fixed>, the log is read up to the position where it ended when the reader object was created. This is the default, so you don't wait in a reading loop indefinitely because somebody keeps adding new lines to the log.

=item *

When I<end> is C<future>, it allows the reading of the part of the log that was appended after the reader was created (useful for reading from stdin).

=back

=item I<lock>

Describes the locking behaviour. Allowed values: C<none> (default), C<blocking>, C<nonblocking>.

=over 4

=item *

When I<lock> is C<blocking>, lock named I<pos>.lock will be acquired in the blocking mode.

=item *

When I<lock> is C<nonblocking>, lock named I<pos>.lock will be acquired in the nonblocking mode; if lock file is already locked, exception will be raised.

=back

=item I<check_lastline>

This flag is set by default. It enables content checks when detecting log rotations. There is actually no reason to disable this option.

=item I<check_inode>

Enable inode checks when detecting log rotations. This option should not be enabled when retrieving logs via rsync or some other way which modifies inodes.

This flag is disabled by default, because I<check_lastline> is superior and should be enough for finding the right file.

=back

=cut
sub new ($$)
{
    my ($class, $args) = @_;
    my $self = {
        %{$class->_defaults()},
        %$args,
    };

    croak "unknown start value: '$self->{start}'" unless $_start_values{$self->{start}};
    croak "unknown end value: '$self->{end}'" unless $_end_values{$self->{end}};
    croak "either check_inode or check_lastline should be on" unless $self->{check_inode} or $self->{check_lastline};

    bless $self => $class;

    if ($self->{pos} and $self->{cursor}) {
        croak "only one of 'pos' and 'cursor' should be specified";
    }
    unless ($self->{pos} or $self->{cursor}) {
        croak "one of 'pos' and 'cursor' should be specified";
    }

    my $posfile = delete $self->{pos};
    if ($posfile) {
        if ($posfile eq '-') {
            croak "Log not specified and posfile is '-'" if not defined $self->{log};
            $self->{cursor} = Log::Unrotate::Cursor::Null->new();
        }
        else {
            croak "Log not specified and posfile is not found" if not defined $self->{log} and not -e $posfile;
            $self->{cursor} = Log::Unrotate::Cursor::File->new($posfile, { lock => $self->{lock}, rollback_period => $self->{rollback_period} });
        }
    }

    my $pos = $self->{cursor}->read();
    if ($pos) {
        my $logfile = delete $pos->{LogFile};
        if ($self->{log}) {
            die "logfile mismatch: $logfile ne $self->{log}" if $self->{check_log} and $logfile and $self->{log} ne $logfile;
        } else {
            $self->{log} = $logfile or die "'logfile:' not found in cursor $self->{cursor} and log not specified";
        }
    }

    $self->_set_last_log_number();
    $self->_set_eof();

    if ($pos) {
        my $error;
        while () {
            eval {
                $self->_find_log($pos);
            };
            $error = $@;
            last unless $error;
            last unless $self->{cursor}->rollback();
            $pos = $self->{cursor}->read();
        }
        if ($error) {
            if ($self->{autofix_cursor}) {
                warn $error;
                warn "autofix_cursor is enabled, cleaning $self->{cursor}";
                $self->{cursor}->clean();
                $self->_start();
            }
            else {
                die $error;
            }
        }
    } else {
        $self->_start();
    }

    return $self;
}

sub _seek_end_pos ($$) {
    my $self = shift;
    my ($handle) = @_;

    seek $handle, -1, SEEK_END;
    read $handle, my $last_byte, 1;
    if ($last_byte eq "\n") {
        return tell $handle;
    }

    my $position = tell $handle;
    while (1) {
        # we have reached beginning of the file and haven't found "\n"
        return 0 if $position == 0;

        my $read_portion = 1024;
        $read_portion = $position if ($position < $read_portion);
        seek $handle, -$read_portion, SEEK_CUR;
        my $data;
        read $handle, $data, $read_portion;
        if ($data =~ /\n(.*)\z/) { # match *last* \n
            my $len = length $1;
            seek $handle, $position, SEEK_SET;
            return $position - $len;
        }
        seek $handle, -$read_portion, SEEK_CUR;
        $position -= $read_portion;
    }
}

sub _find_end_pos ($$) {
    my $self = shift;
    my ($handle) = @_;

    my $tell = tell $handle;
    my $end = $self->_seek_end_pos($handle);
    seek $handle, $tell, SEEK_SET;
    return $end;
}

sub _get_last_line ($) {
    my ($self) = @_;
    my $handle = $self->{Handle};
    my $number = $self->{LogNumber};
    my $position = tell $handle if $handle;

    unless ($position) { # 'if' not 'while'!
        $number++;
        my $log = $self->_log_file($number);
        undef $handle; # need this to keep $self->{Handle} unmodified!
        open $handle, '<', $log or return ""; # missing prev log
        $position = $self->_seek_end_pos($handle);
    }

    my $backstep = 256; # 255 + "\n"
    $backstep = $position if $backstep > $position;
    seek $handle, -$backstep, SEEK_CUR;
    my $last_line;
    read $handle, $last_line, $backstep;
    return $last_line;
}

sub _last_line ($) {
    my ($self) = @_;
    my $last_line = $self->{LastLine} || $self->_get_last_line();
    $last_line =~ /(.{0,255})$/ and $last_line = $1;
    return $last_line;
}

# pos not found, reading log for the first time
sub _start($)
{
    my $self = shift;
    $self->{LogNumber} = 0;
    if ($self->{start} eq 'end') { # move to the end of file
        $self->_reopen(0);
        $self->_seek_end_pos($self->{Handle}) if $self->{Handle};
    } elsif ($self->{start} eq 'begin') { # move to the beginning of last file
        $self->_reopen(0);
    } elsif ($self->{start} eq 'first') { # find oldest file
        $self->{LogNumber} = $self->{LastLogNumber};
        $self->_reopen(0);
    } else {
        die; # impossible
    }
}

sub _reopen ($$)
{
    my ($self, $position) = @_;

    my $log = $self->_log_file();

    if (open my $FILE, "<$log") {
        my @stat = stat $FILE;
        return 0 if $stat[7] < $position;
        return 0 if $stat[7] == 0 and $self->{LogNumber} == 0 and $self->{end} eq 'fixed';
        seek $FILE, $position, SEEK_SET;
        $self->{Handle} = $FILE;
        $self->{Inode} = $stat[1];
        return 1;

    } elsif (-e $log) {
        die "log '$log' exists but is unreadable";
    } else {
        return;
    }
}

sub _set_last_log_number ($)
{
    my ($self) = @_;
    my $log = $self->{log};
    my @numbers = sort { $b <=> $a } map { /\.(\d+)$/ ? $1 : () } glob "$log.*";
    $self->{LastLogNumber} = $numbers[0] || 0;
}

sub _set_eof ($)
{
    my ($self) = @_;
    return unless $self->{end} eq 'fixed';
    my @stat = stat $self->{log};
    my $eof = $stat[7];
    $self->{EOF} = $eof || 0;
}

sub _log_file ($;$)
{
    my ($self, $number) = @_;
    $number = $self->{LogNumber} unless defined $number;
    my $log = $self->{log};
    $log .= ".$number" if $number;
    return $log;
}

sub _print_position ($$)
{
    my ($self, $pos) = @_;
    my $lastline = defined $pos->{LastLine} ? $pos->{LastLine} : "[unknown]";
    my $inode = defined $pos->{Inode} ? $pos->{Inode} : "[unknown]";
    my $position = defined $pos->{Position} ? $pos->{Position} : "[unknown]";
    my $logfile = $self->{log};
    my $cursor = $self->{cursor};
    return "Cursor: $cursor, LogFile: $logfile, Inode: $inode, Position: $position, LastLine: $lastline";
}

# look through .log .log.1 .log.2, etc., until we'll find log with correct inode and/or checksum.
sub _find_log ($$)
{
    my ($self, $pos) = @_;

    undef $self->{LastLine};
    $self->_set_last_log_number();

    for ($self->{LogNumber} = 0; $self->{LogNumber} <= $self->{LastLogNumber}; $self->{LogNumber}++) {
        next unless $self->_reopen($pos->{Position});
        next if ($self->{check_inode} and $pos->{Inode} and $self->{Inode} and $pos->{Inode} ne $self->{Inode});
        next if ($self->{check_lastline} and $pos->{LastLine} and $pos->{LastLine} ne $self->_last_line());
        while () {
            # check if we're at the end of file
            return 1 if $self->_find_end_pos($self->{Handle}) > tell $self->{Handle};

            while () {
                return 0 if $self->{LogNumber} <= 0;
                $self->{LogNumber}--;
                last if $self->_reopen(0);
            }
        }
    }

    die "unable to find the log: ", $self->_print_position($pos);
}

################################################# Public methods ######################################################

=item B<< read() >>

Read a line from the log file.

=cut
sub read {
    my $self = shift;

    my $line;
    while (1) {
        my $FILE = $self->{Handle};
        return undef unless defined $FILE;
        if (defined $self->{EOF} and $self->{LogNumber} == 0) {
            my $position = tell $FILE;
            return undef if $position >= $self->{EOF};
        }
        $line = <$FILE>;
        if (defined $line) {
            if ($line =~ /\n$/) {
                last;
            }
            seek $FILE, - length $line, SEEK_CUR;
        }
        return undef unless $self->_find_log($self->position());
    }

    $self->{LastLine} = $line;
    return $line;
}

=item B<< position() >>

Get your current position in I<log> as an object passible to C<commit()>.

=cut
sub position($)
{
    my $self = shift;
    my $pos = {};

    if ($self->{Handle}) {
        $pos->{Position} = tell $self->{Handle};
        $pos->{Inode} = $self->{Inode};
        $pos->{LastLine} = $self->_last_line();  # undefined LastLine forces _last_line to backstep
        $pos->{LogFile} = $self->{log}; # always .log, not .log.N
    }

    return $pos;
}

=item B<< commit() >>

=item B<< commit($position) >>

Save the current position to the pos-file. You can also save some other position, previosly obtained with C<position()>.

Pos-file gets commited using a temporary file, so it won't be lost if disk space is depleted.

=cut
sub commit($;$)
{
    my ($self, $pos) = @_;
    $pos ||= $self->position();
    return unless defined $pos->{Position}; # pos is missing and log either => do nothing

    $self->{cursor}->commit($pos);
}

=item B<< lag() >>

Get the size of data remaining to be read, in bytes.

It takes all log files into account, so if you're in the middle of I<foo.log.1>, it will return the size of remaining data in it, plus the size of I<foo.log> (if it exists).

=cut
sub lag ($)
{
    my ($self) = @_;
    die "lag failed: missing log file" unless defined $self->{Handle};

    my $lag = 0;

    my $number = $self->{LogNumber};
    while () {
        my @stat = stat $self->_log_file($number);
        $lag += $stat[7] if @stat;
        last if $number <= 0;
        $number--;
    }

    $lag -= tell $self->{Handle};
    return $lag;
}

=item B<< log_number() >>

Get the current log's number.

=cut
sub log_number {
    my ($self) = @_;
    return $self->{LogNumber};
}

=item B<< log_name() >>

Get the log's name. Doesn't contain C<< .N >> postfix even if cursor points to old log file.

=cut
sub log_name {
    my ($self) = @_;
    return $self->{log};
}

=back

=head1 BUGS & CAVEATS

To find and open correct log is a race-condition-prone task.

This module was used in production environment for many years, and many bugs were found and fixed. The only known case when position file can become broken is when logrotate is invoked twice in *very* short amount of time, which should never be a case.

Don't set the I<check_inode> option on virtual hosts, especially on openvz-based ones. If you move your data, inodes of files will change and your position file will become broken. In fact, don't set I<check_inode> at all, it's deprecated.

The logrotate config should not use the C<compress> option to make that module function properly. If you need to compress logs, set C<delaycompress> option too.

This module expects the logs to be named I<foo.log>, I<foo.log.1>, I<foo.log.2>, etc. Skipping some numbers in the sequence is ok, but postfixes should be *positive integers* to be properly sorted. If you use some other naming scheme, for example, I<foo.log.20130604-140500>, you're out of luck. Patches welcome!

=head1 AUTHORS

Andrei Mishchenko C<druxa@yandex-team.ru>, Vyacheslav Matjukhin C<me@berekuk.ru>.

=head1 SEE ALSO

L<File::LogReader> - another implementation of the same idea.

L<unrotate> - console script for reading logs.

=head1 COPYRIGHT

Copyright (c) 2006-2013 Yandex LTD. All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

1;
