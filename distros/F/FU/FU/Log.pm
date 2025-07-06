package FU::Log 1.2;
use v5.36;
use Exporter 'import';
use POSIX 'strftime';

our @EXPORT_OK = ('log_write');

my $dest = [\*STDERR];
my $capture_warn = 0;
my $fmt = \&default_fmt;
our $in_log = 0;

sub default_fmt($msg, @extra) {
    my $pre = '';
    $msg =~ s/^\s+//;
    $msg =~ s/\s+$//;
    if ($msg =~ /\n/) {
        $msg =~ s/(^|\n)/\n# /g;
        $msg .= "\n";
        $pre = "\n";
    } else {
        $msg = " # $msg";
    }
    sprintf "%s%sZ%s%s\n", $pre, strftime('%Y-%m-%d %H:%M:%S', gmtime), join('', map " $_", @extra), $msg
}

sub log_write($msg) {
    local $SIG{__WARN__} = undef if $capture_warn;

    my $line = (!$in_log && eval {
        local $in_log = 1;
        $fmt->($msg)
    }) || default_fmt($msg);
    utf8::encode($line);

    for my $out (@$dest) {
        if (ref $out eq 'GLOB') {
            print $out $line;
        } elsif (open my $F, '>>', $out) {
            flock $F, 2;
            seek $F, 0, 2;
            print $F $line;
            flock $F, 4;
            close $F;
        }
    }
}

sub capture_warn($enabled) {
    $capture_warn = !!$enabled;
    $SIG{__WARN__} = $enabled ? sub { log_write($_) for @_ } : undef;
}

sub set_fmt :prototype(&) ($f) { $fmt = $f || \&default_fmt }

sub set_file($path) {
    $dest = !defined $path ? [\*STDERR] :
        [ $path ne '-' && -t STDERR ? \*STDERR : (), $path eq '-' ? \*STDOUT : $path ];
}

1;
__END__

=head1 NAME

FU::Log - Extremely Basic Process-Wide Logging Infrastructure

=head1 SYNOPSIS

  use FU::Log 'log_write';

  FU::Log::capture_warn(1);
  FU::Log::set_file('/var/log/mylog.log');

=head1 DESCRIPTION

This module doesn't do a whole lot. Its main purpose is to have a
centrally-configured logging facility so that modules can log stuff and an
application can configure where those logs should end up.

There's no log levels or filtering; the I<what> to log question is better
answered with separate configuration options per module. There's no OO-style
interface either; the entire point of this module is that it only handles
process-global logging. This module mainly exists for users of the L<FU>
framework.

=head1 Configuration

=over

=item FU::Log::set_file($path)

Set the path to write logs to.

If no path is configured or if C<$path> is C<undef>, logs are written to
C<STDERR>. If C<$path> is C<->, logs are written to C<STDOUT>.

When writing to file, logs are still replicated to C<STDERR> if that is a TTY.

=item FU::Log::capture_warn($enabled)

Whether to capture Perl C<warn> messages.

=item FU::Log::set_fmt($sub)

Subroutine to call to format the log messages. Is given a log message as
Unicode string as first argument and should return a formatted Unicode string.

The given message may include newlines, it is up to the formatting function to
decide how to log that.

This function is not called when inside C<log_write()>, the default log format
is then used instead. This is to avoid recursion.

=back

=head1 Exportable function

=over

=item log_write($msg)

Write a message to the log.

=back

=head1 COPYRIGHT

MIT.

=head1 AUTHOR

Yorhel <projects@yorhel.nl>
