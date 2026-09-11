package Developer::Dashboard::Handle;

use strict;
use warnings;

use Cwd ();
use Capture::Tiny qw(capture);
use Developer::Dashboard::PathRegistry;
use Developer::Dashboard::FileRegistry;
use Developer::Dashboard::Config;
use Developer::Dashboard::JSON qw(json_decode);

our $VERSION = '4.31';

our $AUTOLOAD;

# new(%args)
# Builds a lazy runtime handle scoped to a working directory, matching the
# same layer discovery the dashboard/d2 CLI uses to resolve path aliases.
# Input: cwd => directory string (optional, defaults to Cwd::cwd()).
# Output: Developer::Dashboard::Handle object.
sub new {
    my ( $class, %args ) = @_;
    return bless { cwd => $args{cwd} // Cwd::cwd() }, $class;    # uncoverable condition false Cwd::cwd() cannot return undef
}

# paths()
# Returns the resolved path-alias table for this handle's directory - the
# same aliases `dashboard paths` prints: built-in runtime roots plus any
# custom alias added with `dashboard path add`. In-process, no subprocess.
# Input: none.
# Output: hash reference of alias name => resolved directory path.
sub paths {
    my ($self) = @_;
    return $self->{_paths_cache} //= $self->_registry->all_path_aliases;
}

# run($subcommand, @args)
# Runs `dashboard <subcommand> @args` exactly as it would run on the command
# line, for anything not covered by an in-process method such as paths().
# Existing for subcommands that cannot be spelled as a bareword Perl method
# (dotted Tira commands such as tira.ticket.show) and as the mechanism
# AUTOLOAD delegates to for everything else.
# Input: subcommand name string, list of further CLI arguments.
# Output: decoded Perl structure when stdout parses as JSON, otherwise the
#         raw trimmed stdout string. Dies (with stderr attached) on a
#         nonzero exit - a failed command never silently returns as if it
#         had succeeded.
sub run {
    my ( $self, $subcommand, @args ) = @_;
    die 'Missing subcommand' if !defined $subcommand || $subcommand eq '';

    # DD-670: system() sets the global $? - localize it here so a subprocess
    # call this sub makes never leaks a changed $? into the caller's scope.
    local $?;

    my ( $stdout, $stderr, $exit ) = capture {
        local $ENV{PATH} = $ENV{PATH};
        system( 'dashboard', $subcommand, @args );
    };
    $exit >>= 8;
    die "dashboard $subcommand @args failed (exit $exit): $stderr"
      if $exit != 0;

    $stdout =~ s/\A\s+|\s+\z//g;
    return $stdout if $stdout eq '';

    my $decoded = eval { json_decode($stdout) };
    return $decoded if !$@ && ref($decoded);
    return $stdout;
}

# _registry()
# Builds (once per handle) the PathRegistry with configured named aliases
# registered, scoped to this handle's cwd - the same composition
# Developer::Dashboard::CLI::TableHelpers::build_paths + run_paths_command's
# alias-loading closure use.
# Input: none.
# Output: Developer::Dashboard::PathRegistry object.
sub _registry {
    my ($self) = @_;
    return $self->{_registry} //= do {
        my $home  = $ENV{HOME} || '';
        my @roots = grep { defined && -d } map { "$home/$_" } qw(projects src work);    # uncoverable branch false the interpolated map above always yields a defined string
        my $paths = Developer::Dashboard::PathRegistry->new(
            home            => $home,
            cwd             => $self->{cwd},
            workspace_roots => \@roots,
            project_roots   => \@roots,
        );
        my $files  = Developer::Dashboard::FileRegistry->new( paths => $paths );
        my $config = Developer::Dashboard::Config->new( files => $files, paths => $paths );
        $paths->register_named_paths( $config->path_aliases );
        $paths;
    };
}

# AUTOLOAD($self, @args)
# Any method name not defined above (e.g. d2->doctor) is treated as a
# single-word dashboard subcommand and delegated to run(). Dotted
# subcommands cannot be spelled this way (a dot is not a valid bareword
# method character) - use run() directly for those.
# Input: method-call arguments.
# Output: same as run().
# AUTOLOAD($name, @args)
# Begins a lazy command chain. Returns a proxy that accumulates dotted segments
# as each bareword method is called and shells out ONLY when the chain is
# terminated with a call - d2()->collector->list->() runs `dashboard
# collector.list`. Nothing executes here: an un-terminated chain is inert in
# boolean, numeric and string context (owner decision Q-100), and there is no
# depth-1 special case, so a bare d2()->doctor is a proxy too (Q-101).
# Input: the method name Perl could not resolve, plus any arguments.
# Output: a Developer::Dashboard::Handle::Proxy.
sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;
    $name =~ s/.*:://;
    return if $name eq 'DESTROY';
    return Developer::Dashboard::Handle::Proxy->_begin( $self, $name, @_ );
}

1;


package Developer::Dashboard::Handle::Proxy;

use strict;
use warnings;

# A deferred command chain. It exists so that d2()->foo->bar->() can mirror the
# CLI's own dotted dispatch (`d2 foo.bar`) at arbitrary depth: the first method
# call cannot know whether another is coming, so it must return something
# chainable rather than a value.
#
# THE THREE VALUE CONTEXTS ARE ALL DECLARED EXPLICITLY. Perl autogenerates a
# missing stringify from numify, so leaving q{""} out would silently replace the
# deliberately non-executing "d2 proxy: ..." text with a generated one - and the
# whole point of Q-100's answer is that a proxy must be obviously inert when
# printed. Declaring all three closes that hole at the source.
#
# fallback IS 1, NOT 0, and the difference cost a test. With 0 nothing is ever
# derived, so `$proxy eq ''` dies with "Operation eq: no method found" even
# though q{""} is right there - which broke an existing assertion that had every
# right to compare a stringifiable object. The risk fallback => 0 was reached for
# is already gone: it only mattered while q{""} might be absent, and it is not.
use overload
  '&{}'    => sub { my $self = shift; return sub { return $self->_execute(@_) } },
  q{""}    => sub { my $self = shift; return 'd2 proxy: ' . join '.', @{ $self->{segments} } },
  '0+'     => sub { return 0 },
  'bool'   => sub { return 1 },
  fallback => 1;

our $AUTOLOAD;

# _dispatch_name($name)
# Translates one Perl method name into the CLI's spelling by rewriting
# underscores as hyphens (Q-107).
# Input:  one segment, as the caller typed it.
# Output: the segment as the command line spells it.
#
# WHY THIS IS NOT COSMETIC. A Perl method name cannot contain a hyphen, and
# hyphens are the ordinary way shell commands are named - so without this
# rewrite the entire hyphenated half of the CLI is simply unreachable through
# d2()->foo->bar, no matter how the chain is written.
#
# THE ACCEPTED COST, recorded here so it is not later rediscovered as a bug: a
# command genuinely spelled with an underscore can no longer be reached through
# the chained form. That was stated in the option the owner chose. run() is
# unaffected and remains the way to name such a command verbatim.
sub _dispatch_name {
    my ($name) = @_;
    $name =~ tr/_/-/;
    return $name;
}

# _begin($handle, $name, @args)
# Starts a chain from a Handle. Input: the owning handle, the first segment,
# and any arguments. Output: a new proxy carrying one segment.
#
# The segment is translated HERE, at capture, rather than when the chain is
# finally joined - so {segments} always holds what will actually be dispatched,
# and the stringification a developer sees while debugging names a command that
# exists rather than the one they typed.
sub _begin {
    my ( $class, $handle, $name, @args ) = @_;
    return bless { handle => $handle, segments => [ _dispatch_name($name) ], args => [@args] }, $class;
}

# AUTOLOAD($name, @args)
# Appends one segment and returns a NEW proxy, so a chain can be branched or
# held without one call mutating another's accumulated path.
# Input: the method name, plus any arguments. Output: a new proxy.
#
# THERE IS DELIBERATELY NO `return if $name eq 'DESTROY'` GUARD HERE, and the
# omission is load-bearing rather than an oversight. This package defines a real
# DESTROY below, so perl calls that directly and AUTOLOAD can never receive the
# name - the guard was unreachable, and Devel::Cover reported it as exactly that
# (line 196, branch 50%, true side never taken). The Handle package above keeps
# its identical guard because it defines NO DESTROY, so there the guard is live
# and measured covered.
#
# THE COUPLING THIS CREATES: if DESTROY below is ever removed, this AUTOLOAD
# starts treating destruction as a chain segment again. Remove one and you must
# restore the other.
sub AUTOLOAD {
    my $self = shift;
    my $name = $AUTOLOAD;
    $name =~ s/.*:://;
    return bless {
        handle   => $self->{handle},
        segments => [ @{ $self->{segments} }, _dispatch_name($name) ],
        args     => [ @{ $self->{args} }, @_ ],
    }, ref $self;
}

# _execute(@args)
# Terminates the chain: joins the segments with '.' exactly as the CLI's dotted
# dispatch expects and hands them to Handle::run, which shells out through the
# real entrypoint and so gets layered hook execution for free.
# Input: any further arguments. Output: whatever run() returns.
sub _execute {
    my ( $self, @args ) = @_;
    return $self->{handle}->run( ( join '.', @{ $self->{segments} } ), @{ $self->{args} }, @args );
}

# DESTROY()
# Explicitly does nothing. Without it the proxy's AUTOLOAD would receive
# DESTROY as just another bareword segment when a chain goes out of scope
# un-terminated, which is how an inert chain would come to invoke something.
# NOT "UNREACHABLE" - MEASURED TO RUN, AND UNATTRIBUTABLE ANYWAY. Devel::Cover
# does not credit destruction to this sub: it reports count 0 here whether the
# body is one line or several, and whether the proxy is dropped in scope or left
# to global destruction. That is an instrument limitation, not dead code, and it
# was proved rather than assumed - wrapping this sub and dropping the last
# reference shows perl calling it twice for a two-segment chain:
#
#     my $p = $h->collector->list; undef $p;   ->   DESTROY called count = 2
#
# The annotation therefore records a fact about the MEASUREMENT, not a claim
# that the code cannot run. Removing this sub would be a real regression (see
# the coupling noted on AUTOLOAD above), so it must not be deleted to reach 100.
# One criterion per comment - two criteria on one line are honoured for neither.
# uncoverable subroutine
# uncoverable statement
sub DESTROY { return }

package Developer::Dashboard::Handle;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Developer::Dashboard::Handle - in-process proxy for the dashboard/d2 CLI

=head1 VERSION
4.30

=head1 PURPOSE

Gives Perl code a single-line way to reach the same runtime the
C<dashboard>/C<d2> command line resolves, instead of hand-building a
L<Developer::Dashboard::PathRegistry>, L<Developer::Dashboard::FileRegistry>,
and L<Developer::Dashboard::Config> to answer one question such as a
configured path alias.

=head1 WHY IT EXISTS

Filed after the project's owner asked directly (over the project's Telegram
bridge) for a shorter Perl equivalent of C<dashboard path resolve NAME>, then
widened the request to cover any dashboard subcommand: "Anything I can run
with d2 on bash [...] I am expecting the d2() subroutine can do the same."
C<paths()> answers the original, narrower ask in-process (no subprocess,
since path aliases are cheap to resolve directly against the registry);
C<run()> and C<AUTOLOAD> answer the widened one by shelling out to the real
CLI for everything else, which is the only way to reach the full command
surface without reimplementing it.

=head1 WHEN TO USE

From any Perl script or module in this project (or one with this
distribution installed) that needs a configured path alias, or the output of
any other C<dashboard> subcommand, without forking a subprocess by hand and
parsing its output itself.

=head1 HOW TO USE

    use Developer::Dashboard;

    my $foo = d2->paths->{foo};              # fast, in-process

    # A bareword method starts a LAZY chain. Nothing runs until the chain is
    # terminated with a call - the trailing ->().
    my $out = d2->doctor->();                # shells to `dashboard doctor`
    my $lst = d2->collector->list->();       # shells to `dashboard collector.list`

    # Un-terminated, a chain is inert and says so if you print it:
    print d2->collector->list;               # "d2 proxy: collector.list"

    my $res = d2->run( 'tira.ticket.show', '--ref', 'DD-726' );
                                             # run() still takes its words separately

C<d2()> (exported by L<Developer::Dashboard>) memoizes one handle per working
directory, so repeated calls from the same directory reuse the same
registry rather than rebuilding it.

=head1 WHAT USES IT

Nothing in the shipped CLI itself - this is a convenience entrypoint for
external Perl code (scripts, other distributions) that embeds this one.
L<Developer::Dashboard::CLI::Paths> and the rest of the CLI continue to
build their own registries directly, unchanged by this module.

=head1 EXAMPLES

    use Developer::Dashboard;

    # A custom alias added with `dashboard path add reports /var/reports`:
    my $dir = d2->paths->{reports};   # '/var/reports'

    # UNDERSCORES BECOME HYPHENS in every segment, because a Perl method name
    # cannot contain a hyphen and hyphenated commands are the shell's normal
    # spelling. Without the rewrite that half of the CLI is unreachable here.
    my $out = d2->foo->bar->soemthing_executable->();  # `dashboard foo.bar.soemthing-executable`

    # The cost of that rewrite: a command genuinely spelled with an underscore
    # cannot be named through the chain. Use run() for those - it is verbatim.
    my $verbatim = d2->run('an_underscored_command');

    # Anything else the CLI can do - remember the terminating ->():
    my $version_text = d2->version->();

    # Arbitrary depth, mirroring the CLI's own dotted dispatch:
    my $out = d2->foo->bar->zzz->();  # `dashboard foo.bar.zzz`

=cut
