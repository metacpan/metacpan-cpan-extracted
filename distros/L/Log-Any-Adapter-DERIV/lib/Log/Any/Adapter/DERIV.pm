package Log::Any::Adapter::DERIV;
# ABSTRACT: one company's example of a standardised logging setup

use strict;
use warnings;

our $AUTHORITY = 'cpan:DERIV';    # AUTHORITY
our $VERSION   = '0.007';

use feature qw(state);
use parent  qw(Log::Any::Adapter::Coderef);
use Syntax::Keyword::Try;

use utf8;

=encoding utf8

=head1 NAME

Log::Any::Adapter::DERIV - standardised logging to STDERR and JSON file

=begin markdown

[![Test status](https://circleci.com/gh/binary-com/perl-Log-Any-Adapter-DERIV.svg?style=shield&circle-token=bed2af8f8e388746eafbbf905cf6990f84dbd69e)](https://app.circleci.com/pipelines/github/binary-com/perl-Log-Any-Adapter-DERIV)

=end markdown

=head1 SYNOPSIS

    use Log::Any;

    # print text log to STDERR, json format when inside docker container,
    # colored text format when STDERR is a tty, non-colored text format when
    # STDERR is redirected.
    use Log::Any::Adapter ('DERIV');

    #specify STDERR directly
    use Log::Any::Adapter ('DERIV', stderr => 1)

    #specify STDERR's format
    use Log::Any::Adapter ('DERIV', stderr => 'json')

    #specify the json log name
    use Log::Any::Adapter ('DERIV', json_log_file => '/var/log/program.json.log');

=head1 DESCRIPTION

Applies some opinionated log handling rules for L<Log::Any>.

B<This is extremely invasive>. It does the following, affecting global state
in various ways:

=over 4

=item * applies UTF-8 encoding to STDERR

=item * writes to a C<.json.log> file.

=item * overrides the default L<Log::Any::Proxy> formatter to provide data as JSON

=item * when stringifying, may replace some problematic objects with simplified versions

=back

An example of the string-replacement approach would be the event loop in asynchronous code:
it's likely to have many components attached to it, and dumping that would effectively end up
dumping the entire tree of useful objects in the process. This is a planned future extension,
not currently implemented.

=head2 Why

This is provided as a CPAN module as an example for dealing with multiple outputs and formatting.
The existing L<Log::Any::Adapter> modules tend to cover one thing, and it's
not immediately obvious how to extend formatting, or send data to multiple logging mechanisms at once.

Although the module may not be directly useful, it is hoped that other teams may find
parts of the code useful for their own logging requirements.

There is a public repository on Github, anyone is welcome to fork that and implement
their own version or make feature/bug fix suggestions if they seem generally useful:

L<https://github.com/binary-com/perl-Log-Any-Adapter-DERIV>

=head2 PARAMETERS

=over 4

=item * json_log_file

Specify a file name to which you want the json formatted logs printed into.
If not given, then it prints the logs to STDERR.

=item * STDERR

If it is true, then print logs to STDERR

If the value is json or text, then print logs with that format

If the value is just a true value other than `json` or `text`,
then if it is running in a container, then it prints the logs in `json` format.
Else if STDERR is a tty, then it prints `colored text` format.
Else it prints non-color text format.

=back

If no parameters provided, then default `stderr => 1`;

=cut

=head1 METHODS

=cut

use Time::Moment;
use Path::Tiny;
use curry;
use JSON::MaybeUTF8 qw(:v1);
use PerlIO;
use Config;
use Term::ANSIColor;
use Log::Any                qw($log);
use Fcntl                   qw(:DEFAULT :seek :flock);
use Log::Any::Adapter::Util qw(numeric_level logging_methods);
use Clone                   qw(clone);

# Used for stringifying data more neatly than Data::Dumper might offer
our $JSON = JSON::MaybeXS->new(
    # Multi-line for terminal output, single line if redirecting somewhere
    pretty => _fh_is_tty(\*STDERR),
    # Be consistent
    canonical => 1,
    # Try a bit harder to give useful output
    convert_blessed => 1,
);

# Simple mapping from severity levels to Term::ANSIColor definitions.
our %SEVERITY_COLOUR = (
    trace    => [qw(grey12)],
    debug    => [qw(grey18)],
    info     => [qw(green)],
    warning  => [qw(bright_yellow)],
    error    => [qw(red bold)],
    fatal    => [qw(red bold)],
    critical => [qw(red bold)],
);

my $adapter_context;
my @methods     = reverse logging_methods();
my %num_to_name = map { $_ => $methods[$_] } 0 .. $#methods;

# The obvious way to handle this might be to provide our own proxy class:
#     $Log::Any::OverrideDefaultProxyClass = 'Log::Any::Proxy::DERIV';
# but the handling for proxy classes is somewhat opaque - and there's an ordering problem
# where `use Log::Any` before the adapter is loaded means we end up with some classes having
# the default anyway.
# Rather than trying to deal with that, we just provide our own default:
{
    no warnings 'redefine';    ## no critic (ProhibitNoWarnings)

    # We expect this to be loaded, but be explicit just in case - we'll be overriding
    # one of the methods, so let's at least make sure it exists first
    require Log::Any::Proxy;

    # Mostly copied from Log::Any::Proxy
    *Log::Any::Proxy::_default_formatter = sub {
        my ($cat, $lvl, $format, @params) = @_;
        return $format->() if ref($format) eq 'CODE';

        chomp(
            my @new_params = map {
                eval { $JSON->encode($_) }
                    // Log::Any::Proxy::_stringify_params($_)
            } @params
        );
        s{\n}{\n  }g for @new_params;

        # Perl 5.22 adds a 'redundant' warning if the number parameters exceeds
        # the number of sprintf placeholders. If a user does this, the warning
        # is issued from here, which isn't very helpful. Doing something
        # clever would be expensive, so instead we just disable warnings for
        # the final line of this subroutine.
        no warnings;    ## no critic (ProhibitNoWarnings)
        return sprintf($format, @new_params);
    };
}

# Upgrade any `warn ...` lines to send through Log::Any.
$SIG{__WARN__} = sub {    ## no critic (RequireLocalizedPunctuationVars)
                          # We don't expect anything called from here to raise further warnings, but
                          # let's be safe and try to avoid any risk of recursion
    local $SIG{__WARN__} = undef;
    chomp(my $msg = shift);
    $log->warn($msg);
};

sub new {
    my ($class, %args) = @_;
    my $self = $class->SUPER::new(sub { }, %args);

    # if there is json_log_file, then print json to that file
    if ($self->{json_log_file}) {
        $self->{json_fh} = path($self->{json_log_file})->opena_utf8 or die 'unable to open log file - ' . $!;
        $self->{json_fh}->autoflush(1);
    }

    # if there is stderr, then print log to stderr also
    # if stderr is json or text, then use that format
    # else, if it is in_container, then json, else text
    if (!$self->{json_log_file} && !$self->{stderr}) {
        $self->{stderr} = 1;
    }

    for my $stdfile (['stderr', \*STDERR], ['stdout', \*STDOUT]) {
        my ($name, $fh) = $stdfile->@*;
        if ($self->{$name}) {
            $self->{$name} = {format => $self->{$name}} if ref($self->{$name}) ne 'HASH';
            # docker tends to prefer JSON
            $self->{$name}{format} = _in_container() ? 'json' : 'text'
                if (!$self->{$name}{format} || $self->{$name}{format} ne 'json' && $self->{$name}{format} ne 'text');
            $self->apply_filehandle_utf8($fh);
            $self->{$name}{fh} = $fh;
            $self->{$name}{color} //= _fh_is_tty($fh);
        }
    }

    # Keep a strong reference to this, since we expect to stick around until exit anyway
    $self->{code} = $self->curry::log_entry;
    return $self;
}

=head2 apply_filehandle_utf8

Applies UTF-8 to filehandle if it is not utf-flavoured already

    $object->apply_filehandle_utf8($fh);

=over 4

=item * C<$fh> file handle

=back

=cut

sub apply_filehandle_utf8 {
    my ($class, $fh) = @_;
    # We'd expect `encoding(utf-8-strict)` and `utf8` if someone's already applied binmode
    # for us, but implementation details in Perl may change those names slightly, and on
    # some platforms (Windows?) there's also a chance of one of the UTF16LE/BE variants,
    # so we make this check quite lax and skip binmode if there's anything even slightly
    # utf-flavoured in the mix.
    $fh->binmode(':encoding(UTF-8)')
        unless grep { /utf/i } PerlIO::get_layers($fh, output => 1);
    $fh->autoflush(1);
}

=head2 format_line

Formatting the log entry with timestamp, from which the message populated,
severity and message.

If color/colour param passed it adds appropriate color code for timestamp,
log level, from which this log message populated and actual message.
For non-color mode, it just returns the formatted message.

    $object->format_line($data, {color => $color});

=over 4

=item * C<$data> hashref - The data with stack info like package method from
which the message populated, timestamp, severity and message

=item * C<$opts> hashref - the options color

=back

Returns only formatted string if non-color mode. Otherwise returns formatted
string with embedded ANSI color code using L<Term::ANSIColor>

=cut

sub format_line {
    my ($class, $data, $opts) = @_;

    # With international development teams, no matter which spelling we choose
    # someone's going to get this wrong sooner or later... or to put another
    # way, we got country *and* western.
    $opts->{colour} = $opts->{color} || $opts->{colour};

    # Expand formatting if necessary: it's not immediately clear how to defer
    # handling of structured data, the ->structured method doesn't have a way
    # to return the stringified data back to the caller for example
    # for edge cases like `my $msg = $log->debug(...);` so we're still working
    # on how best to handle this:
    # https://metacpan.org/release/Log-Any/source/lib/Log/Any/Proxy.pm#L105
    # $_ = sprintf $_->@* for grep ref, $data->{message};

    # If we have a stack entry, report the context - default to "main" if we're at top level
    my $from = $data->{stack}[-1] ? join '->', @{$data->{stack}[-1]}{qw(package method)} : 'main';

    # Start with the plain-text details
    my @details = (
        Time::Moment->from_epoch($data->{epoch})->strftime('%Y-%m-%dT%H:%M:%S%3f'),
        uc(substr $data->{severity}, 0, 1),
        "[$from]", $data->{message});

    # This is good enough if we're in non-colour mode
    return join ' ', @details unless $opts->{colour};

    my @colours = ($SEVERITY_COLOUR{$data->{severity}} || die 'no severity definition found for ' . $data->{severity})->@*;

    # Colour formatting codes applied at the start and end of each line, in case something else
    # gets inbetween us and the output
    local $Term::ANSIColor::EACHLINE = "\n";
    my ($ts, $level) = splice @details, 0, 2;
    $from = shift @details;

    return join ' ', colored($ts, qw(bright_blue)), colored($level, @colours), colored($from, qw(grey10)), map { colored($_, @colours) } @details;
}

=head2 log_entry

Add format and add color code using C<format_line> and writes the log entry

    $object->log_entry($data);

=over 4

=item *C<$data> hashref - The log data

=back

=cut

sub log_entry {
    my ($self, $data) = @_;
    $data            = $self->_process_data($data);
    $data            = $self->_process_context($data);
    $data->{message} = mask_sensitive($data->{message});
    my $json_data;
    my %text_data = ();
    my $get_json  = sub { $json_data //= encode_json_text($data) . "\n"; return $json_data; };
    my $get_text =
        sub { my $color = shift // 0; $text_data{$color} //= $self->format_line($data, {color => $color}) . "\n"; return $text_data{$color}; };

    if ($self->{json_fh}) {
        _lock($self->{json_fh});
        $self->{json_fh}->print($get_json->());
        _unlock($self->{json_fh});
    }

    for my $stdfile (qw(stderr stdout)) {
        next unless $self->{$stdfile};
        my $txt =
              $self->{$stdfile}{format} eq 'json'
            ? $get_json->()
            : $get_text->($self->{$stdfile}{color});
        my $fh = $self->{$stdfile}{fh};

        _lock($fh);
        $fh->print($txt);
        _unlock($fh);
    }
}

=head2 _process_data

Process the data before printing out. Reduce the continues L<Future> stack
messages and filter the messages based on log level.

    $object->_process_data($data);

=over 4

=item * C<$data> hashref - The log data.

=back

Returns a hashref - the processed data

=cut

sub _process_data {
    my ($self, $data) = @_;

    $data = clone($data);
    $data = $self->_collapse_future_stack($data);
    $data = $self->_filter_stack($data);

    return $data;
}

=head2 _filter_stack

Filter the stack message based on log level.

    $object->_filter_stack($data);

=over 4

=item * C<$data> hashref - Log stack data

=back

Returns hashref - the filtered data

=cut

sub _filter_stack {
    my ($self, $data) = @_;

    return $data if (numeric_level($data->{severity}) <= numeric_level('warn'));

    # now severity > warn
    return $data if $self->{log_level} >= numeric_level('debug');

    delete $data->{stack};

    return $data;
}

=head2 _collapse_future_stack

Go through the caller stack and if continuous L<Future> messages then keep
only one at the first.

    $object->_collapse_future_stack($data);

=over 4

=item * C<$data> hashref - Log stack data

=back

Returns a hashref - the reduced log data

=cut

sub _collapse_future_stack {
    my ($self, $data) = @_;
    my $stack = $data->{stack};
    my @new_stack;
    my $previous_is_future;

    for my $frame ($stack->@*) {
        if ($frame->{package} eq 'Future' || $frame->{package} eq 'Future::PP') {
            next if ($previous_is_future);
            push @new_stack, $frame;
            $previous_is_future = 1;
        } else {
            push @new_stack, $frame;
            $previous_is_future = 0;
        }
    }
    $data->{stack} = \@new_stack;

    return $data;
}

=head2 _fh_is_tty

Check the filehandle opened to tty

=over 4

=item * C<$fh> file handle

=back

Returns boolean

=cut

sub _fh_is_tty {
    my $fh = shift;

    return -t $fh;    ## no critic (ProhibitInteractiveTest)
}

=head2 _in_container

Returns true if we think we are currently running in a container.

At the moment this only looks for a C<.dockerenv> file in the root directory;
future versions may expand this to provide a more accurate check covering
other container systems such as `runc`.

Returns boolean

=cut

sub _in_container {
    return -r '/.dockerenv';
}

=head2 _linux_flock_data

Based on the type of lock requested, it packs into linux binary flock structure
and return the string of that structure.

Linux struct flock: "s s l l i"
	short l_type short - Possible values: F_RDLCK(0) - read lock, F_WRLCK(1) - write lock, F_UNLCK(2) - unlock
	short l_whence - starting offset
	off_t l_start - relative offset
	off_t l_len - number of consecutive bytes to lock
	pid_t l_pid - process ID

=over 4

=item * C<$type> integer lock type - F_WRLCK or F_UNLCK

=back

Returns a string of the linux flock structure

=cut

sub _linux_flock_data {
    my ($type) = @_;
    my $FLOCK_STRUCT = "s s l l i";

    return pack($FLOCK_STRUCT, $type, SEEK_SET, 0, 0, 0);
}

=head2 _flock

call fcntl to lock or unlock a file handle

=over 4

=item * C<$fh> file handle

=item * C<$type> lock type, either F_WRLCK or F_UNLCK

=back

Returns boolean or undef

=cut

# We don't use `flock` function directly here
# In some cases the program will do fork after the log file opened.
# In such case every subprocess can get lock of the log file at the same time.
# Using fcntl to lock a file can avoid this problem
sub _flock {
    my ($fh, $type) = @_;
    my $lock   = _linux_flock_data($type);
    my $result = fcntl($fh, F_SETLKW, $lock);

    return $result if $result;

    return undef;
}

=head2 _lock

Lock a file handler with fcntl.

=over 4

=item * C<$fh> File handle

=back

Returns boolean

=cut

sub _lock {
    my ($fh) = @_;

    return _flock($fh, F_WRLCK);
}

=head2 _unlock

Unlock a file handler locked by fcntl

=over 4

=item * C<$fh> File handle

=back

Returns boolean

=cut

sub _unlock {
    my ($fh) = @_;

    return _flock($fh, F_UNLCK);
}

=head2 level

Return the current log level name.

=cut

sub level {
    my $self = shift;
    return $num_to_name{$self->{log_level}};
}

=head2 _process_context

add context key value pair into data object

=cut

sub _process_context {
    my ($self, $data) = @_;
    # Iterate over the keys in $adapter_context
    foreach my $key (keys %{$adapter_context}) {
        $data->{$key} = $adapter_context->{$key};
    }
    return $data;
}

=head2 set_context

Set the log context hash

=cut

sub set_context {
    my ($self, $context) = @_;
    $adapter_context = $context;
}

=head2 clear_context

undef the log context hash

=cut

sub clear_context {
    my ($self) = @_;
    $adapter_context = undef;
}

=head2 mask_sensitive

Mask sensitive data in the message and logs error in case of failure

=over 4

=item * C<$message> string - The message to be masked

=back

Returns string - The masked message

=cut

sub mask_sensitive {
    my ($message) = @_;

    # Define a lookup list for all sensitive data regex patterns to be logged

    my @sensitive_patterns = (
        qr/\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}\b/i,             #Email
        qr/\b(?:token|key|oauth[ _-]?token)\s*[:=]\s*([^\s]+)/i,    #Token or API key , = : value
        qr/(?:a1|r1|ct1)-[a-z0-9]{29}/i,                            #OAuth, Refresh, and CTrader token patterns
        qr/[a-z0-9]{15}/i,                                          #API Token pattern
    );

    try {
        foreach my $pattern (@sensitive_patterns) {
            $message =~ s/$pattern/'*' x length($&)/ge;
        }
    } catch ($e) {
        # Disable the custom warning handler temporarily to avoid potential recursion issues.
        local $SIG{__WARN__} = undef;

        # Extract the error message from the exception.
        chomp(my $error_msg = $e);

        # Log the error for further investigation and troubleshooting.
        $log->warn("Error in mask_sensitive: $error_msg");
    };

    return $message;
}

1;

=head1 AUTHOR

Deriv Group Services Ltd. C<< DERIV@cpan.org >>

=head1 LICENSE

Copyright Deriv Group Services Ltd 2020-2021. Licensed under the same terms as Perl itself.
