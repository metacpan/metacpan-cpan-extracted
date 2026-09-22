package ForgeOps::Tracker::EventBuilder;

use strict;
use warnings;
use POSIX qw(strftime);
use ForgeOps::Tracker::PiiScrubber qw(scrub scrub_string);
use ForgeOps::Tracker::SqlStatement ();

my $MAX_FRAMES = 500;

# How many lines of source to grab on either side of the culprit line (see
# _attach_source_context), and the longest a single captured line is allowed to be before getting
# truncated: guards against a single pathological minified/generated line ballooning the
# payload. ForgeOps itself re-truncates on arrival too, the same "don't just trust the SDK"
# posture $MAX_FRAMES already gets on the server side.
my $CONTEXT_LINES = 5;
my $MAX_CONTEXT_LINE_LENGTH = 500;

# Identifies this client to the server's auto language-detection on the project the event lands
# in (see Project#note_sdk_platform server-side); matches this repo's own sdks/perl directory
# name, the same convention every other language's client follows.
my $SDK_NAME = 'perl';

sub new {
    my ($class, $configuration) = @_;
    return bless { configuration => $configuration }, $class;
}

# build($error, \%context): $error can be:
#   - a blessed exception object exposing ->message (or overloaded stringification) and,
#     optionally, ->trace returning a Devel::StackTrace-compatible object (frames() ->
#     filename/line/subroutine): e.g. Throwable::Error, Moo::Exception-based classes.
#   - a plain scalar, typically $@ after `die "..."` or `Carp::confess "..."`: Perl appends
#     " at FILE line N." to any die message that doesn't already end in "\n", and Carp::confess
#     appends a full "\tPACKAGE::sub(...) called at FILE line N" chain on top of that; both are
#     parsed below into real backtrace frames rather than left as one opaque string, verified
#     directly against real confess()/die output before relying on the format, not assumed from
#     documentation alone.
sub build {
    my ($self, $error, $context, $user, $breadcrumbs) = @_;
    $context ||= {};
    my $config = $self->{configuration};

    my ($exception_class, $message, $backtrace) = $self->_analyze($error);

    my %payload = (
        exception_class => $exception_class,
        message         => $message,
        backtrace       => $backtrace,
        occurred_at     => strftime('%Y-%m-%dT%H:%M:%SZ', gmtime),
        environment     => $config->{environment},
        release         => $config->{release},
        server_name     => $config->{server_name},
        context         => { %$context },
        tags            => {},
        sdk_name        => $SDK_NAME,
    );
    $payload{user} = { %$user } if $user && %$user;
    # Omitted entirely (never sent as an empty array) when there's nothing to report.
    $payload{breadcrumbs} = [ map { { %$_ } } @$breadcrumbs ] if $breadcrumbs && @$breadcrumbs;
    $self->_attach_sql(\%payload, $error);

    return $config->{scrub_pii} ? $self->_scrub_payload(\%payload) : \%payload;
}

# See SqlStatement for what's read off the error and how it's masked. The statement itself only
# goes out when capture_sql_statement is on; the extracted names go out on their own
# (capture_sql_objects) so an issue can still name the procedure or view involved.
sub _attach_sql {
    my ($self, $payload, $error) = @_;
    my $config = $self->{configuration};
    return unless $config->{capture_sql_objects} || $config->{capture_sql_statement};

    my $masked = ForgeOps::Tracker::SqlStatement::mask(ForgeOps::Tracker::SqlStatement::find_in($error));
    return unless defined $masked;

    my $objects = ForgeOps::Tracker::SqlStatement::objects($masked);
    $payload->{sql_objects} = $objects if $objects && $config->{capture_sql_objects};
    $payload->{sql_statement} = $masked if $config->{capture_sql_statement};
    return;
}

sub _analyze {
    my ($self, $error) = @_;

    if (ref $error && eval { $error->can('message') }) {
        my $exception_class = ref $error;
        my $message = $error->message;
        my $backtrace = eval { $error->can('trace') } ? $self->_frames_from_stack_trace($error->trace) : [];
        return ($exception_class, $message, $backtrace);
    }

    # Plain scalar (the common case: $@). "RuntimeError" mirrors the other SDKs' own fallback
    # exception_class for an error with no more specific type available.
    my $text = "$error";
    my ($message, $backtrace) = $self->_parse_die_text($text);
    return ('RuntimeError', $message, $backtrace);
}

sub _frames_from_stack_trace {
    my ($self, $trace) = @_;
    my @frames;
    for my $frame ($trace->frames) {
        last if @frames >= $MAX_FRAMES;
        push @frames, $self->_frame($frame->filename, $frame->line, $frame->subroutine);
    }
    return \@frames;
}

sub _parse_die_text {
    my ($self, $text) = @_;
    my @lines = split /\n/, $text;
    return ('', []) unless @lines;

    my @frames;
    my $message = shift @lines;
    # "MESSAGE at FILE line N.": what Perl itself appends to any die string not already ending
    # in "\n", and the first line Carp::confess/croak produce too.
    if ($message =~ s/\s+at\s+(\S+)\s+line\s+(\d+)\.\s*$//) {
        push @frames, $self->_frame($1, $2, undef);
    }

    # Remaining lines, present only from Carp::confess: "\tPACKAGE::sub(...) called at FILE line N"
    for my $line (@lines) {
        last if @frames >= $MAX_FRAMES;
        if ($line =~ /^\s*(\S+?)\(.*?\)\s+called\s+at\s+(\S+)\s+line\s+(\d+)/) {
            push @frames, $self->_frame($2, $3, $1);
        }
    }

    return ($message, \@frames);
}

sub _frame {
    my ($self, $file, $line, $method) = @_;
    my $frame = {
        file   => $file,
        line   => defined($line) ? $line + 0 : undef,
        method => $method,
        in_app => $self->_in_app($file),
    };
    return $self->_attach_source_context($frame);
}

sub _in_app {
    my ($self, $file) = @_;
    my $root = $self->{configuration}{app_root};
    return 0 unless $file && $root;
    return 0 unless index($file, $root) == 0;
    # A vendored/system library installed alongside the app's own lib/ directory is never in_app,
    # the same exclusion every other SDK applies for its own package-manager directory.
    return $file !~ m{/(?:local|vendor)/lib/perl5/};
}

# Reads a few lines of source straight off disk around the culprit line, at die/confess-time, in
# the same running process the error came from. Gated on two things: the frame has to be in_app
# (never a vendored/system library: there'd be nothing meaningful to show, and it's not the host
# app's own code to begin with), and configuration's capture_source_context has to be true (see
# Configuration for why it defaults to true and why ForgeOps' own per-project setting, not this
# flag, is the durable, protected way to turn it off). Best-effort: any file that can't be opened
# (deleted, permission denied, a path that only ever existed inside a build step and isn't present
# in this deployment) just means this one frame gets no source context, never a die of its own.
sub _attach_source_context {
    my ($self, $frame) = @_;
    return $frame unless $self->{configuration}{capture_source_context} && $frame->{in_app};

    my $lines = $self->_read_source_lines($frame->{file});
    return $frame unless $lines;

    my $index = $frame->{line} - 1;
    return $frame unless $index >= 0 && $index <= $#$lines;

    my $from = $index - $CONTEXT_LINES;
    $from = 0 if $from < 0;
    my $to = $index + $CONTEXT_LINES;
    $to = $#$lines if $to > $#$lines;

    $frame->{context_line} = _truncate_line($lines->[$index]);
    $frame->{pre_context}  = [ map { _truncate_line($_) } @{$lines}[$from .. $index - 1] ];
    $frame->{post_context} = [ map { _truncate_line($_) } @{$lines}[$index + 1 .. $to] ];

    return $frame;
}

# Isolated into its own method (rather than inlined into _attach_source_context) so tests can
# monkeypatch it to prove no read is ever attempted when capture_source_context is off.
sub _read_source_lines {
    my ($self, $file) = @_;
    return undef unless defined $file && length $file;
    open(my $fh, '<', $file) or return undef;
    my @lines = <$fh>;
    close $fh;
    chomp @lines;
    return \@lines;
}

sub _truncate_line {
    my ($line) = @_;
    return $line if length($line) <= $MAX_CONTEXT_LINE_LENGTH;
    return substr($line, 0, $MAX_CONTEXT_LINE_LENGTH) . '...';
}

# exception_class/occurred_at/environment/release/server_name/sdk_name/user are left alone:
# structured fields this client or the host app sets deliberately, not free text an exception or
# its context could accidentally spill sensitive data into. user specifically is a deliberate
# exemption, not an oversight: scrub_string's own email pattern would otherwise redact the exact
# thing this field exists to carry (the %scrubbed copy below never touches it either way).
sub _scrub_payload {
    my ($self, $payload) = @_;
    my %scrubbed = %$payload;
    $scrubbed{message} = scrub_string($payload->{message});
    $scrubbed{sql_statement} = scrub_string($payload->{sql_statement}) if defined $payload->{sql_statement};
    $scrubbed{backtrace} = [
        map {
            my %frame = %$_;
            $frame{file}   = scrub_string($frame{file})   if defined $frame{file};
            $frame{method} = scrub_string($frame{method}) if defined $frame{method};
            if (exists $frame{context_line}) {
                $frame{context_line} = scrub_string($frame{context_line});
                $frame{pre_context}  = [ map { scrub_string($_) } @{ $frame{pre_context} } ];
                $frame{post_context} = [ map { scrub_string($_) } @{ $frame{post_context} } ];
            }
            \%frame;
        } @{ $payload->{backtrace} }
    ];
    # Breadcrumb message/data are free text the host app or an integration wrote; category, level,
    # and timestamp are structured values set deliberately, the same split as the top-level
    # fields above, so they are left alone.
    if ($payload->{breadcrumbs}) {
        $scrubbed{breadcrumbs} = [
            map {
                my %crumb = %$_;
                $crumb{message} = scrub_string($crumb{message}) if defined $crumb{message};
                $crumb{data}    = scrub($crumb{data});
                \%crumb;
            } @{ $payload->{breadcrumbs} }
        ];
    }
    $scrubbed{context} = scrub($payload->{context});
    $scrubbed{tags}     = scrub($payload->{tags});
    return \%scrubbed;
}

1;
