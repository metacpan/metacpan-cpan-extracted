# Implemented optimizations:
# * log-method's (ERR(), WARN(), etc.) implementation generated
#   individually for each log-object (depending on it configuration)
#   to include only minimum necessary code to do it work
#   - each time log-object configuration changes (by calling config())
#     log-method's implementation re-generated to comply new configuration
#   - different log-objects may have different configuration and so will
#     need different implementation for same log-methods - so we have to
#     use unique package/class for each log-object (with class names looks
#     like 'Log::Fast::_12345678') - these classes will implement only
#     log-methods and inherit everything else from parent class (Log::Fast)
# * implementation for log-methods inactive on current log level replaced
#   by empty 'sub{}'
#   - each time log level changes (by calling config() or level())
#     implementation of all log-methods updated according to current
#     log level and set either to real implementation or empty 'sub{}'
# * if prefixes %D and/or %T are used, then cache will be used to store
#   formatted date/time to avoid calculating it often than once per second
# * when logging to syslog, packet header (which may contain:
#   log level, facility, timestamp, hostname, ident and pid) will be cached
#   (one cached header per each log level)
#   - if {add_timestamp} is true, then cached header will be used only for
#     one second and then recalculated
#   - if user change {ident} (by calling config() or ident()) cached
#     headers will be recalculated
# * if log-methods will be called with single param sprintf() won't be used

package Log::Fast;
use 5.010001;
use warnings;
use strict;
use utf8;
use Carp;

our $VERSION = 'v2.0.1';

use Scalar::Util qw( refaddr );
use Socket;
use Sys::Hostname ();
use Time::HiRes ();
use Sys::Syslog (); # for _PATH_LOG()


# from RFC3164
use constant LOG_USER       => 1*8;
use constant LOG_ERR        => 3;
use constant LOG_WARNING    => 4;
use constant LOG_NOTICE     => 5;
use constant LOG_INFO       => 6;
use constant LOG_DEBUG      => 7;
use constant PRI => {
    ERR     => LOG_ERR,
    WARN    => LOG_WARNING,
    NOTICE  => LOG_NOTICE,
    INFO    => LOG_INFO,
    DEBUG   => LOG_DEBUG,
};

use constant DEFAULTS => {
    level           => 'DEBUG',
    prefix          => q{},
    type            => 'fh',
    # used only when {type}='fh':
    fh              => \*STDERR,
    # used only when {type}='unix':
    path            => Sys::Syslog::_PATH_LOG() || '/dev/log', ## no critic(ProtectPrivateSubs)
    facility        => LOG_USER,
    add_timestamp   => 1,
    add_hostname    => 0,
    hostname        => Sys::Hostname::hostname(),
    ident           => do { my $s = $0; utf8::decode($s); $s =~ s{\A.*/(?=.)}{}xms; $s },
    add_pid         => 1,
    pid             => $$,
};

my $GLOBAL;

sub new {
    my ($class, $opt) = @_;
    $opt ||= {};
    croak 'options must be HASHREF' if ref $opt ne 'HASH';

    my $self = { # will also contain all keys defined in DEFAULTS constant
        # used only when {type}='unix':
        _sock           => undef,   # socket to {path}
        _header_ERR     => q{},     # cached "<PRI>TIMESTAMP IDENT[PID]: "
        _header_WARN    => q{},     # --"--
        _header_NOTICE  => q{},     # --"--
        _header_INFO    => q{},     # --"--
        _header_DEBUG   => q{},     # --"--
        _header_time    => 0,       # last update time for {_header_*}
        # used only if {prefix} contain %D or %T:
        _date           => q{},     # cached "YYYY-MM-DD"
        _time           => q{},     # cached "HH:MM:SS"
        _dt_time        => 0,       # last update time for {_date} and {_time}
    };

    my $sub_class = $class . '::_' . refaddr($self);
    { no strict 'refs';
      @{$sub_class.'::ISA'} = ( $class );
    }
    bless $self, $sub_class;

    $self->config({ %{ DEFAULTS() }, %{ $opt } });  ## no critic (ProhibitCommaSeparatedStatements)

    return $self;
}

sub global {
    my $class = shift;
    $GLOBAL ||= $class->new();
    return $GLOBAL;
}

sub config {
    my ($self, $opt) = @_;
    croak 'options must be HASHREF' if ref $opt ne 'HASH';

    for my $key (keys %{ $opt }) {
        if (!exists DEFAULTS->{ $key }) {
            croak 'unknown option: '.$key;
        }
        $self->{ $key } = $opt->{ $key };
    }

    $self->_generate_methods();
    if ($self->{type} eq 'unix') {
        $self->_connect_unix();
        $self->ident($self->{ident});
    }
    $self->level($self->{level});

    return;
}

sub level {
    my ($self, $level) = @_;
    my $prev_level = $self->{level};
    if (defined $level) {
        if (!exists PRI->{$level}) {
            croak '{level} must be one of: '.join ', ', keys %{ PRI() };
        }
        $self->{level} = $level;
        $self->_setup_level();
    }
    return $prev_level;
}

sub ident {
    my ($self, $ident) = @_;
    my $prev_ident = $self->{ident};
    if (defined $ident) {
        $self->{ident} = $ident;
        $self->_update_header();
    }
    return $prev_ident;
}

### Internal

sub _connect_unix {
    my ($self) = @_;
    socket $self->{_sock}, AF_UNIX, SOCK_DGRAM, 0 or croak "socket: $!";
    connect $self->{_sock}, sockaddr_un($self->{path}) or croak "connect: $!";
    return;
}

sub _update_header {
    my ($self) = @_;
    my $h = q{};
    if ($self->{add_timestamp}) {
        $self->{_header_time} = time;
        $h .= substr localtime $self->{_header_time}, 4, 16; ## no critic(ProhibitMagicNumbers)
    }
    if ($self->{add_hostname}) {
        $h .= $self->{hostname} . q{ };
    }
    my $ident_utf8 = $self->{ident};
    utf8::encode($ident_utf8);
    $h .= $ident_utf8;
    if ($self->{add_pid}) {
        $h .= '[' . $self->{pid} . ']';
    }
    $h .= ': ';
    for my $level (keys %{ PRI() }) {
        $self->{'_header_'.$level}
            = '<' . ($self->{facility} + PRI->{$level}) . '>' . $h;
    }
    return;
}

sub _setup_level {
    my ($self) = @_;
    my $pkg = ref $self;
    for my $level (keys %{ PRI() }) {
        my $is_active = PRI->{$level} <= PRI->{$self->{level}};
        no strict 'refs';
        no warnings 'redefine';
        *{$pkg.q{::}.$level} = $is_active ? \&{$pkg.q{::_}.$level} : sub {};
    }
    return;
}

sub _generate_methods {    ## no critic(ProhibitExcessComplexity)
    my ($self) = @_;
    my $pkg = ref $self;

    my %feature = map {$_=>1} $self->{prefix} =~ /%(.)/xmsg;
    $feature{timestamp} = $self->{type} eq 'unix' && $self->{add_timestamp};

    my @pfx = split /(%.)/xms, $self->{prefix};
    for (0 .. $#pfx) {
        utf8::encode($pfx[$_]);
    }

    for my $level (keys %{ PRI() }) {
        # ... begin
        my $code = <<'EOCODE';
sub {
    my $self = shift;
    my $msg = @_==1 ? $_[0] : sprintf shift, map {ref eq 'CODE' ? $_->() : $_} @_;
    utf8::encode($msg);
EOCODE
        # ... if needed, get current time
        if ($feature{S}) {
            $code .= <<'EOCODE';
    my $msec = sprintf '%.05f', Time::HiRes::time();
    my $time = int $msec;
EOCODE
        }
        elsif ($feature{D} || $feature{T} || $feature{timestamp}) {
            $code .= <<'EOCODE';
    my $time = time;
EOCODE
        }
        # ... if needed, update caches
        if ($feature{D} || $feature{T}) {
            $code .= <<'EOCODE';
    if ($self->{_dt_time} != $time) {
        $self->{_dt_time} = $time;
        my ($sec,$min,$hour,$mday,$mon,$year) = localtime $time;
        $self->{_date} = sprintf '%04d-%02d-%02d', $year+1900, $mon+1, $mday;
        $self->{_time} = sprintf '%02d:%02d:%02d', $hour, $min, $sec;
    }
EOCODE
        }
        if ($feature{timestamp}) {
            $code .= <<'EOCODE';
    if ($self->{_header_time} != $time) {
        $self->_update_header();
    }
EOCODE
        }
        # ... calculate prefix
        $code .= <<'EOCODE';
    my $prefix = q{}
EOCODE
        for my $pfx (@pfx) {
            if ($pfx eq q{%L}) { ## no critic(ProhibitCascadingIfElse)
                $code .= <<"EOCODE"
      . "\Q$level\E"
EOCODE
            }
            elsif ($pfx eq q{%S}) {
                $code .= <<'EOCODE'
      . $msec
EOCODE
            }
            elsif ($pfx eq q{%D}) {
                $code .= <<'EOCODE'
      . $self->{_date}
EOCODE
            }
            elsif ($pfx eq q{%T}) {
                $code .= <<'EOCODE'
      . $self->{_time}
EOCODE
            }
            elsif ($pfx eq q{%P}) {
                $code .= <<'EOCODE'
      . caller(0)
EOCODE
            }
            elsif ($pfx eq q{%F}) {
                $code .= <<'EOCODE'
      . do { my $s = (caller(1))[3] || q{}; substr $s, 1+rindex $s, ':' }
EOCODE
            }
            elsif ($pfx eq q{%_}) {
                $code .= <<'EOCODE'
      . do { my $n=0; 1 while caller(2 + $n++); ' ' x $n }
EOCODE
            }
            elsif ($pfx eq q{%%}) {
                $code .= <<'EOCODE'
      . '%'
EOCODE
            }
            else {
                $code .= <<"EOCODE"
      . "\Q$pfx\E"
EOCODE
            }
        }
        $code .= <<'EOCODE';
    ;
EOCODE
        # ... output
        if ($self->{type} eq 'fh') {
            $code .= <<'EOCODE';
    print { $self->{fh} } $prefix, $msg, "\n" or die "print() to log: $!";
EOCODE
        }
        elsif ($self->{type} eq 'unix') {
            $code .= <<"EOCODE";
    my \$header = \$self->{_header_$level};
EOCODE
            $code .= <<'EOCODE';
    send $self->{_sock}, $header.$prefix.$msg, 0 or do {
        $self->_connect_unix();
        send $self->{_sock}, $header.$prefix.$msg, 0 or die "send() to syslog: $!";
    };
EOCODE
        }
        else {
            croak '{type} should be "fh" or "unix"';
        }
        # ... end
        $code .= <<'EOCODE';
}
EOCODE
        # install generated method
        no strict 'refs';
        no warnings 'redefine';
        *{$pkg.'::_'.$level} = eval $code;  ## no critic (ProhibitStringyEval)
    }

    return;
}


1; # Magic true value required at end of module
__END__

=encoding utf8

=head1 NAME

Log::Fast - Fast and flexible logger


=head1 VERSION

This document describes Log::Fast version v2.0.1


=head1 SYNOPSIS

    use Log::Fast;

    $LOG = Log::Fast->global();
    $LOG = Log::Fast->new({
        level           => 'WARN',
        prefix          => '%D %T [%L] ',
        type            => 'fh',
        fh              => \*STDOUT,
    });

    use Sys::Syslog qw( LOG_DAEMON );
    $LOG->config({
        prefix          => '',
        type            => 'unix',
        path            => '/dev/log',
        facility        => LOG_DAEMON,
        add_timestamp   => 1,
        add_hostname    => 1,
        hostname        => 'somehost',
        ident           => 'someapp',
        add_pid         => 1,
        pid             => $$,
    });

    $LOG->ident('anotherapp');
    $LOG->level('INFO');

    $LOG->ERR('Some error');
    $LOG->WARN('Some warning');
    $LOG->NOTICE('user %s logged in', $user);
    $LOG->INFO('data loaded');
    $LOG->DEBUG('user %s have %d things', $user, sub {
        return SlowOperation_GetAmountOfThingsFor($user);
    });

=head1 DESCRIPTION

This is very fast logger, designed for use in applications with thousands
high-level events/operations per second (like network servers with
thousands clients or web spiders which download hundreds url per second).

For example, on Core2Duo sending about 5000 messages to log on enabled
log levels or 20000 messages on disabled log levels in I<one second> will
slow down your application only by 2-3%.

Comparing to some other CPAN modules, this one (in average):
faster than L<Log::Dispatch> in about 45 times,
faster than L<Log::Handler> in about 15 times,
faster than L<Sys::Syslog> in about 7 times,
and slower than L<Log::Syslog::Fast> in about 2 times.

=head2 FEATURES

=over

=item * Global and local logger objects

=item * Output to any open filehandle or local syslog

=item * 5 log levels: ERR, WARN, NOTICE, INFO, DEBUG

=item * Configurable prefix (log level, date/time, caller function name)

=item * sprintf() support

=item * Unicode support (UTF8)

=item * Can avoid calculating log message content on disabled log levels

=back


=head1 INTERFACE 

=head2 global

    $LOG = Log::Fast->global();

When called first time will create global log object using
L<default options|/OPTIONS> (you can reconfigure it using C<config()> later).

Global log object is useful if your application consists of several
independent modules which should share same logging options configured
outside of these modules. In this case all these modules should use
same C<global()> log object instead of creating C<new()> independent log
objects in each module.

Return global log object.

=head2 new

    $LOG = Log::Fast->new();
    $LOG = Log::Fast->new( \%opt );

Create new log object, configured using L<defaults|/OPTIONS> and
user-provided options, if any.

Return created log object.

=head2 config

    $LOG->config( \%opt );

Reconfigure log object. Any options (see L</OPTIONS>) can be changed at
any time, including changing output B<{type}> or setting options useless
with current output type (new values for these options will be used later,
if output type will be changed).

If you need to change only log B<{level}> or syslog's B<{ident}> you should use
C<level()> or C<ident()> methods because they are much faster than more general
C<config()>.

Return nothing. Throw exception if unable to connect to syslog.

=head2 level

    $level = $LOG->level();
    $level = $LOG->level( $new_level );

If B<$new_level> given will change current log level.
This is same as call C<< config({ level=>$new_level }) >> but much faster.

Return previous log level.

=head2 ident

    $ident = $LOG->ident();
    $ident = $LOG->ident( $new_ident );

If B<$new_ident> given will change current syslog's ident.
This is same as call C<< config({ ident=>$new_ident }) >> but much faster.

Return previous syslog's ident.

=head2 ERR

=head2 WARN

=head2 NOTICE

=head2 INFO

=head2 DEBUG

    $LOG->ERR( $message )
    $LOG->ERR( $format, @list )
    $LOG->WARN( $message )
    $LOG->WARN( $format, @list )
    $LOG->NOTICE( $message )
    $LOG->NOTICE( $format, @list )
    $LOG->INFO( $message )
    $LOG->INFO( $format, @list )
    $LOG->DEBUG( $message )
    $LOG->DEBUG( $format, @list )

Output B<$message> to log using different log levels.

If B<$format, @list> used instead of B<$message>, then use
C<sprintf($format, @list)> to calculate log message.

If B<@list> will contain CODEREF, they will be called (in LIST context)
and returned values will be placed inside B<@list> inplace of CODEREF.
This can be used to avoid calculating log message (or it part) on disabled
log levels - these CODEREF will be executed only on enabled log levels.
Example available in L</SYNOPSIS>.

If B<$message> or items in B<@list> will be Unicode strings, they will be
converted to UTF8 before sending to log.

Return nothing. Throw exception if fail to write message to log.


=head1 OPTIONS

Defaults for all options are:

    level           => 'DEBUG',
    prefix          => q{},

    type            => 'fh',
    fh              => \*STDERR,

    # these will be used if you will call config({ type=>'unix' })
    path            => Sys::Syslog::_PATH_LOG() || '/dev/log',
    facility        => LOG_USER,
    add_timestamp   => 1,
    add_hostname    => 0,
    hostname        => Sys::Hostname::hostname(),
    ident           => ..., # calculated from $0
    add_pid         => 1,
    pid             => $$,


=over

=item level

Current log level. Possible values are:
C<'ERR'>, C<'WARN'>, C<'NOTICE'>, C<'INFO'>, C<'DEBUG'>.

Only messages on current or higher levels will be sent to log.


=item prefix

String, which will be output at beginning of each log message.
May contain these placeholders:

    %L - log level of current message
    %S - hi-resolution time (seconds.microseconds)
    %D - current date in format YYYY-MM-DD
    %T - current time in format HH:MM:SS
    %P - caller's function package ('main' or 'My::Module')
    %F - caller's function name
    %_ - X spaces, where X is current stack depth
    %% - % character

Example output with prefix C<'%D %T [%L]%_%P::%F() '>:

    2010-11-17 18:06:20 [INFO] main::() something from main script
    2010-11-17 18:06:53 [INFO]  main::a() something from a
    2010-11-17 18:09:09 [INFO]   main::b2() something from b1->b2
    2010-11-17 18:06:56 [INFO]  main::c() something from c

If it will be Unicode string, it will be converted to UTF8.


=item type

Output type. Possible values are: C<'fh'> (output to any already open
filehandle) and C<'unix'> (output to syslog using UNIX socket).

When B<{type}> set to C<'fh'> you have to also set B<{fh}> to any open
filehandle (like C<\*STDERR>).

When B<{type}> set to C<'unix'> you have to also set B<{path}> to path to
existing UNIX socket (typically it's C<'/dev/log'>).

Luckily, default values for both B<{fh}> and B<{path}> are already provided,
so usually it's enough to just set B<{type}>.


=item fh

File handle to write log messages if B<{type}> set to C<'fh'>.

=item path

Syslog's UNIX socket path to write log messages if B<{type}> set to C<'unix'>.

=item facility

Syslog's facility (see L<Sys::Syslog/Facilities> for a list of well-known facilities).

This module doesn't export any constants, so if you wanna change it from default
LOG_USER value, you should import facility constants from L<Sys::Syslog> module.
Example available in L</SYNOPSIS>.


=item add_timestamp

If TRUE will include timestamp in syslog messages.


=item add_hostname

If TRUE will include hostname in syslog messages.


=item hostname

Host name which will be included in syslog messages if B<{add_hostname}> is TRUE.


=item ident

Syslog's ident (application name) field.

If it will be Unicode string, it will be converted to UTF8.
Using non-ASCII ALPHANUMERIC ident isn't allowed by RFC, but usually
works.


=item add_pid

If TRUE will include PID in syslog messages.


=item pid

PID which will be included in syslog messages if B<{add_pid}> is TRUE.


=back


=head1 SPEED HINTS

Empty prefix is fastest. Prefixes C<%L>, C<%P> and C<%%> are fast enough,
C<%D> and C<%T> has average speed, C<%S>, C<%F> and C<%_> are slowest.

Output to file is about 4 times faster than to syslog.

Calling log with single parameter is faster than with many parameters
(because in second case sprintf() have to be used).


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/powerman/perl-Log-Fast/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.
Feel free to fork the repository and submit pull requests.

L<https://github.com/powerman/perl-Log-Fast>

    git clone https://github.com/powerman/perl-Log-Fast.git

=head2 Resources

=over

=item * MetaCPAN Search

L<https://metacpan.org/search?q=Log-Fast>

=item * CPAN Ratings

L<http://cpanratings.perl.org/dist/Log-Fast>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Log-Fast>

=item * CPAN Testers Matrix

L<http://matrix.cpantesters.org/?dist=Log-Fast>

=item * CPANTS: A CPAN Testing Service (Kwalitee)

L<http://cpants.cpanauthors.org/dist/Log-Fast>

=back


=head1 AUTHOR

Alex Efros E<lt>powerman@cpan.orgE<gt>


=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2010- by Alex Efros E<lt>powerman@cpan.orgE<gt>.

This is free software, licensed under:

  The MIT (X11) License


=cut
