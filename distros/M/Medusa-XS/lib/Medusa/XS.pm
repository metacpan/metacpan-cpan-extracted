package Medusa::XS;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.02';

require XSLoader;
XSLoader::load('Medusa::XS', $VERSION);

# Configuration hash - kept in Perl for user customizability
# All LOGIC is in XS, this is just configuration data
our %LOG;
our %AUDITED;

BEGIN {
    %LOG = (
        LOGGER      => 'Medusa::XS::Logger',
        LOG_LEVEL   => 'debug',
        LOG_FILE    => 'audit.log',
        LOG_INIT    => sub {
            (my $module = $LOG{LOGGER}) =~ s/::/\//g;
            require $module . '.pm';
            $LOG{LOGGER}->new(
                file => $LOG{LOG_FILE},
            );
        },
        TIME        => 'gmtime',
        TIME_FORMAT => 'default',
        LOG         => undef,
        QUOTE       => '†',
        OPTIONS     => {
            date           => 1,
            guid           => 1,
            guid_version   => 4,       # UUID version: 1-8, 0=NIL, -1=MAX
            guid_namespace => undef,   # For v3/v5: dns, url, oid, x500, or UUID string
            guid_name      => undef,   # For v3/v5: arbitrary name string
            level          => 1,
            elapsed_call   => 1,
            caller         => 1,
            colour         => 1,       # 0=off, 1=on, 'auto'=detect terminal
            colour_theme   => 'default', # Loo theme: default, light, monokai, none
        },
        LOG_FUNCTIONS => {
            error => 'error',
            info  => 'info',
            debug => 'debug',
        },
        # Default FORMAT_MESSAGE - wrapper around XS xs_format_message
        # Users can override with their own sub
        FORMAT_MESSAGE => \&xs_format_message
    );
}

# import(), MODIFY_CODE_ATTRIBUTES(), and FETCH_CODE_ATTRIBUTES()
# are implemented in XS for maximum performance

# On Perl < 5.14, newATTRSUB overwrites our :Audit wrapper after
# MODIFY_CODE_ATTRIBUTES returns.  Re-install deferred wraps once
# the entire compilation unit has finished compiling.
# The eval registers a CHECK block at compile time; no warnings suppresses
# "Too late to run CHECK block" if the module is loaded at runtime.
{ no warnings; eval 'CHECK { Medusa::XS::_apply_deferred_wraps() }' }

1;

__END__

=encoding utf8

=head1 NAME

Medusa::XS - High-performance XS audit logging with the C<:Audit> attribute

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

    package MyApp::User;
    use Medusa::XS;

    sub create :Audit {
        my ($self, %args) = @_;
        # ... your code ...
        return $user;
    }

    # Every call to create() is now automatically logged:
    #   entry  - arguments, caller stack, GUID, timestamp
    #   exit   - return values, elapsed time

=head1 DESCRIPTION

Medusa::XS is a drop-in XS replacement for L<Medusa> that provides automatic
subroutine audit logging via Perl attributes.  Marking a subroutine with the
C<:Audit> attribute causes every call to be logged with entry arguments, return
values, a unique GUID, caller stack trace, timestamp and elapsed time.

All hot-path work is done in C: UUID generation (via the B<Horus> library,
RFC 9562), caller-stack walking, timestamp formatting, argument serialisation
(via the B<Loo> library with optional ANSI colour), and log dispatch.  The
only Perl-level data is the C<< %Medusa::XS::LOG >> configuration hash.

=head1 USAGE

=head2 Applying the C<:Audit> attribute

    use Medusa::XS;

    sub my_method :Audit {
        ...
    }

When the attribute is compiled, B<Medusa::XS> wraps the subroutine with an
XS wrapper that logs entry and exit automatically.

=head2 Passing configuration at import

    use Medusa::XS (
        LOG_LEVEL   => 'info',
        LOG_FILE    => '/var/log/myapp-audit.log',
        TIME        => 'localtime',
        TIME_FORMAT => '%Y-%m-%dT%H:%M:%S.%ms',
    );

Key-value pairs are merged into C<< %Medusa::XS::LOG >>.

=head1 CONFIGURATION

All configuration lives in the package variable C<< %Medusa::XS::LOG >>.
Defaults are set at C<BEGIN> time and may be overridden before or after
C<use Medusa::XS>.

=over 4

=item B<LOGGER> I<(string, default C<"Medusa::XS::Logger">)>

Class name of the logger to instantiate when C<LOG_INIT> is called.

=item B<LOG_FILE> I<(string, default C<"audit.log">)>

Path passed to the logger constructor.

=item B<LOG_LEVEL> I<(string, default C<"debug">)>

The log level written into each message.  Also selects which method is
called on the logger object (via C<LOG_FUNCTIONS>).

=item B<LOG_INIT> I<(coderef)>

Called once (lazily, on the first audited call) to create the logger object.
Must return a blessed reference that is stored in C<< $LOG{LOG} >>.

=item B<LOG> I<(object, default C<undef>)>

The live logger instance.  Set automatically by C<LOG_INIT>, or assign your
own object before any audited call:

    $Medusa::XS::LOG{LOG} = My::Logger->new;

The object must implement the method named by C<LOG_FUNCTIONS> for the
current C<LOG_LEVEL> (e.g. C<debug>, C<info>, or C<error>).

=item B<TIME> I<(string, default C<"gmtime">)>

C<"gmtime"> or C<"localtime"> — controls the time zone of timestamps.

=item B<TIME_FORMAT> I<(string, default C<"default">)>

A C<strftime(3)>-compatible format string.  The special token C<%ms> is
replaced with zero-padded milliseconds.  The literal string C<"default">
produces C<strftime("%a %b %e %H:%M:%S %Y")>.

=item B<QUOTE> I<(string, default C<"†"> (U+2020 DAGGER))>

Delimiter wrapped around field values in the formatted log line.

=item B<FORMAT_MESSAGE> I<(coderef, default C<\&xs_format_message>)>

Formatter callback.  When set to the built-in C<xs_format_message> (or left
at the default), the fast all-C formatting path is used.  Supply your own
coderef to customize log output:

    $Medusa::XS::LOG{FORMAT_MESSAGE} = sub {
        my (%p) = @_;
        # %p contains: message, guid, caller, level, params, prefix,
        #              elapsed_call (on exit)
        return "CUSTOM: $p{message}";
    };

B<Note:> a custom Perl callback disables the zero-allocation fast path.

=item B<LOG_FUNCTIONS> I<(hashref)>

Maps log level names to method names on the logger object:

    {
        error => 'error',
        info  => 'info',
        debug => 'debug',
    }

=item B<OPTIONS> I<(hashref)>

Feature flags and GUID configuration.  Boolean fields default to B<1>
(enabled):

    {
        date           => 1,       # timestamp
        guid           => 1,       # unique call ID
        guid_version   => 4,       # UUID version (1-8, 0=NIL, -1=MAX)
        guid_namespace => undef,   # for v3/v5: dns, url, oid, x500, or UUID string
        guid_name      => undef,   # for v3/v5: arbitrary name string
        level          => 1,       # log level label
        caller         => 1,       # caller stack trace
        elapsed_call   => 1,       # elapsed time (exit messages only)
        colour         => 1,       # 0=off, 1=on, 'auto'=detect terminal
        colour_theme   => 'default', # Loo theme name
    }

C<colour> controls ANSI colour output in serialised parameters.
Set to C<0> to disable, C<1> to enable (default), or C<'auto'> to
auto-detect based on terminal and C<$ENV{NO_COLOR}>.

C<colour_theme> selects the colour palette.  Built-in themes:
C<"default">, C<"light">, C<"monokai">, C<"none">.

Set C<guid_version> to C<7> for time-ordered UUIDs (recommended for
database primary keys).  Versions 3 and 5 require C<guid_namespace>
and C<guid_name> to be set.

=back

=head1 FUNCTIONS

These are available as C<Medusa::XS::function_name()> and are implemented
entirely in C.

=head2 generate_guid

    my $v4  = Medusa::XS::generate_guid();            # default (v4)
    my $v7  = Medusa::XS::generate_guid(7);            # time-ordered
    my $v5  = Medusa::XS::generate_guid(5, 'dns', 'example.com');
    my $nil = Medusa::XS::generate_guid(0);            # NIL UUID
    my $max = Medusa::XS::generate_guid(-1);           # MAX UUID

Returns a UUID string (36 characters) generated via the Horus library
(RFC 9562).  The optional first argument selects the UUID version:

=over 4

=item C<1> - Time-based (Gregorian 100ns timestamp + node)

=item C<3> - MD5 namespace (requires namespace and name arguments)

=item C<4> - Random (default)

=item C<5> - SHA-1 namespace (requires namespace and name arguments)

=item C<6> - Reordered time (sortable, Gregorian)

=item C<7> - Unix epoch time-ordered (recommended for databases)

=item C<8> - Custom (random data with version/variant stamped)

=item C<0> - NIL UUID (all zeros)

=item C<-1> - MAX UUID (all ones)

=back

For versions 3 and 5, the second argument is the namespace (one of
C<"dns">, C<"url">, C<"oid">, C<"x500">, or a UUID string) and the
third argument is the name string.

=head2 format_time

    my $ts = Medusa::XS::format_time();             # gmtime, default fmt
    my $ts = Medusa::XS::format_time(0);            # localtime
    my $ts = Medusa::XS::format_time(1, '%Y-%m-%d');

Returns a formatted timestamp string.  First argument selects gmtime (true)
or localtime (false); second is an optional C<strftime> format.

=head2 collect_caller_stack

    my $stack = Medusa::XS::collect_caller_stack();

Walks Perl's context stack in C and returns a string like
C<"main:12-E<gt>Foo::Bar:34-E<gt>Baz::Qux:56">.

=head2 clean_dumper

    my $cleaned = Medusa::XS::clean_dumper($input);

Legacy pass-through kept for backward compatibility.  Returns the input
unchanged.  Previously cleaned L<Data::Dumper> output, but Loo's terse
mode makes this unnecessary.

=head2 dump_sv

    my $str = Medusa::XS::dump_sv($value);

Serialises any Perl value to a compact string using the B<Loo> library.
Supports scalars, array/hash refs, blessed objects, coderefs, regexps,
and circular references.  Respects the C<colour> and C<colour_theme>
settings in C<< $LOG{OPTIONS} >>.  Used internally for argument logging.

=head2 is_audited

    if (Medusa::XS::is_audited(\&Some::Sub)) { ... }

Returns true if the code reference has been wrapped with C<:Audit>.

=head2 wrap_sub

    Medusa::XS::wrap_sub(\&Some::Sub);
    Medusa::XS::wrap_sub(\&Some::Sub, 'method_name');

Programmatically wraps a subroutine with audit logging (same effect as
the C<:Audit> attribute).  Optional second argument overrides the method
name used in log messages.

=head2 log_message

    Medusa::XS::log_message(
        message => 'something happened',
        guid    => $guid,
        caller  => $stack,
        params  => \@args,
        prefix  => 'arg',
    );

Low-level: formats and dispatches a single log entry through the
configured C<FORMAT_MESSAGE> and logger.

=head2 xs_format_message

    my $line = Medusa::XS::xs_format_message(%params);

The default C<FORMAT_MESSAGE> implementation, written in C.  Accepts the
same keys as C<log_message> and returns a formatted string.

=head2 init_logger

    Medusa::XS::init_logger();

Calls C<< $LOG{LOG_INIT} >> if C<< $LOG{LOG} >> is not yet set.
Normally called automatically on the first audited subroutine call.

=head1 DEPENDENCIES

B<Horus> — pure C UUID library (header-only, bundled).

B<Loo> — pure XS data serialiser with colour support (header-only, bundled).

Neither requires separate installation; both are compiled directly into
Medusa::XS.

=head1 SEE ALSO

L<Medusa::XS::Logger> — the default XS file logger.

L<Medusa> — the pure-Perl original that this module replaces.

=head1 LICENSE

This module is free software; you may redistribute and/or modify it under
the same terms as Perl itself.

=cut
