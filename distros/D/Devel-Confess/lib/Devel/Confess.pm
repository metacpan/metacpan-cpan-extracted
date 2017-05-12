package Devel::Confess;
BEGIN {
  my $can_use_informative_names = "$]" >= 5.008;
  # detect -d:Confess.  disable debugger features for now.  we'll
  # enable them when we need them.
  if (!defined &DB::DB && $^P & 0x02) {
    $can_use_informative_names = 1;
    $^P = 0;
  }
  *_CAN_USE_INFORMATIVE_NAMES
    = $can_use_informative_names ? sub () { 1 } : sub () { 0 };
}

use 5.006;
use strict;
use warnings;
no warnings 'once';

our $VERSION = '0.009004';
$VERSION = eval $VERSION;

use Carp ();
use Symbol ();
use Devel::Confess::_Util qw(
  blessed
  refaddr
  weaken
  longmess
  _str_val
  _in_END
  _can_stringify
  _can
  _isa
);
use Config ();
BEGIN {
  *_BROKEN_CLONED_DESTROY_REBLESS
    = ("$]" >= 5.008009 && "$]" < 5.010000) ? sub () { 1 } : sub () { 0 };
  *_BROKEN_CLONED_GLOB_UNDEF
    = ("$]" > 5.008009 && "$]" <= 5.010000) ? sub () { 1 } : sub () { 0 };
  *_BROKEN_SIG_DELETE
    = ("$]" < 5.008008) ? sub () { 1 } : sub () { 0 };
  *_DEBUGGING
    = (
      defined &Config::non_bincompat_options
        ? (grep $_ eq 'DEBUGGING', Config::non_bincompat_options())
        : ($Config::Config{ccflags} =~ /-DDEBUGGING\b/)
    ) ? sub () { 1 } : sub () { 0 };
  my $inf = 9**9**9;
  *_INF = sub () { $inf }
}

$Carp::Internal{+__PACKAGE__}++;

our %NoTrace;
$NoTrace{'Throwable::Error'}++;
$NoTrace{'Moose::Error::Default'}++;

our %OPTIONS = (
  objects   => !!1,
  builtin   => undef,
  dump      => !!0,
  color     => !!0,
  source    => 0,
  evalsource => 0,
  errors    => !!1,
  warnings  => !!1,
  better_names => !!1,
);
our %ENABLEOPTS = (
  dump => 3,
  source => 3,
  evalsource => 3,
);
our %NUMOPTS = (
  dump => 1,
  source => 1,
  evalsource => 1,
);

our @options = sort keys %OPTIONS;
our ($opt_match) =
  map qr/^-?(?:(no[_-]?)(?:$_)|(?:$_)(?:(\d+)|=(.*)|))$/,
  join '|',
  map {
    my $o = $_;
    $o =~ s/_/[-_]?/g;
    '('.$o.')';
  }
  @options;

sub _parse_options {
  my %opts;
  my @bad;
  while (@_) {
    my $arg = shift;
    my @match = defined $arg ? $arg =~ $opt_match : ();
    if (@match) {
      my $no = shift @match;
      my $equal = pop @match;
      my $num = pop @match;
      my ($opt) =
        map $options[$_ % @options],
        grep defined $match[$_],
        0 .. $#match;
      my $value
        = defined $no       ? !!0
        : defined $equal    ? $equal
        : defined $num      ? $num
        : @_ && (!defined $_[0] || $_[0] =~ /^\d+$/) ? shift
        : defined $ENABLEOPTS{$opt} ? $ENABLEOPTS{$opt}
        : !!1;

      if ($NUMOPTS{$opt}) {
        $value
          = !defined $value ? 0
          : !$value ? _INF
          : 0+$value;
      }
      $opts{$opt} = $value;
    }
    else {
      push @bad, $arg;
    }
  }
  if (@bad) {
    local $SIG{__DIE__};
    Carp::croak("invalid options: " . join(', ', map { defined $_ ? $_ : '[undef]' } @bad));
  }
  \%opts;
}

if (my $env = $ENV{DEVEL_CONFESS_OPTIONS}) {
  local $@;
  eval {
    my $options = _parse_options(grep length, split /[\s,]+/, $env);
    @OPTIONS{keys %$options} = values %$options;
    1;
  } or warn "DEVEL_CONFESS_OPTIONS: $@";
}

our %OLD_SIG;

sub import {
  my $class = shift;

  my $options = _parse_options(@_);
  @OPTIONS{keys %$options} = values %$options;

  if (defined $OPTIONS{builtin}) {
    require Devel::Confess::Builtin;
    my $do = $OPTIONS{builtin} ? 'import' : 'unimport';
    Devel::Confess::Builtin->$do;
  }
  if ($OPTIONS{source} || $OPTIONS{evalsource}) {
    require Devel::Confess::Source;
    Devel::Confess::Source->import;
  }
  if ($OPTIONS{color} && $^O eq 'MSWin32') {
    if (eval { require Win32::Console::ANSI }) {
      Win32::Console::ANSI->import;
    }
    else {
      local $SIG{__WARN__};
      Carp::carp
        "Devel::Confess color option requires Win32::Console::ANSI on Windows";
      $OPTIONS{color} = 0;
    }
  }

  if ($OPTIONS{errors} && !$OLD_SIG{__DIE__}) {
    $OLD_SIG{__DIE__} = $SIG{__DIE__}
      if $SIG{__DIE__} && $SIG{__DIE__} ne \&_die;
    $SIG{__DIE__} = \&_die;
  }
  if ($OPTIONS{warnings} && !$OLD_SIG{__WARN__}) {
    $OLD_SIG{__WARN__} = $SIG{__WARN__}
      if $SIG{__WARN__} && $SIG{__WARN__} ne \&_warn;
    $SIG{__WARN__} = \&_warn;
  }

  # enable better names for evals and anon subs
  $^P |= 0x100 | 0x200
    if _CAN_USE_INFORMATIVE_NAMES && $OPTIONS{better_names};
}

sub unimport {
  for my $sig (
    [ __DIE__ => \&_die ],
    [ __WARN__ => \&_warn ],
  ) {
    my ($name, $sub) = @$sig;
    my $now = $SIG{$name} or next;
    my $old = $OLD_SIG{$name};
    if ($now ne $sub && $old) {
      local $SIG{__WARN__};
      warn "Can't restore $name handler!\n";
      delete $SIG{$sig};
    }
    elsif ($old) {
      $SIG{$name} = $old;
      delete $OLD_SIG{$name};
    }
    else {
      no warnings 'uninitialized'; # bogus warnings on perl < 5.8.8
      undef $SIG{$name}
        if _BROKEN_SIG_DELETE;
      delete $SIG{$name};
    }
  }
}

sub _find_sig {
  my $sig = $_[0];
  return undef
    if !defined $sig;
  return $sig
    if ref $sig;
  return undef
    if $sig eq 'DEFAULT' || $sig eq 'IGNORE';
  # this isn't really needed because %SIG entries are always fully qualified
  package #hide
    main;
  no strict 'refs';
  defined &{$sig} ? \&{$sig} : undef;
}

sub _warn {
  local $SIG{__WARN__};
  return warn @_
    if our $warn_deep;
  my @convert = _convert(@_);
  if (my $sig = _find_sig($OLD_SIG{__WARN__})) {
    local $warn_deep = 1;
    (\&$sig)->(ref $convert[0] ? $convert[0] : join('', @convert));
  }
  else {
    @convert = _ex_as_strings(@convert);
    @convert = _colorize(33, @convert) if $OPTIONS{color};
    warn @convert;
  }
}

sub _die {
  local $SIG{__DIE__};
  return
    if our $die_deep;
  my @convert = _convert(@_);
  if (my $sig = _find_sig($OLD_SIG{__DIE__})) {
    local $die_deep = 1;
    (\&$sig)->(ref $convert[0] ? $convert[0] : join('', @convert));
  }
  @convert = _ex_as_strings(@convert) if _can_stringify;
  @convert = _colorize(31, @convert) if $OPTIONS{color} && _can_stringify;
  if (_DEBUGGING && _in_END) {
    local $SIG{__WARN__};
    warn @convert;
    $! ||= 1;
    return;
  }
  die @convert unless ref $convert[0];
}

sub _colorize {
  my ($color, @convert) = @_;
  if ($OPTIONS{color} eq 'force' || -t *STDERR) {
    if (@convert == 1) {
      $convert[0] = s/(.*)//;
      unshift @convert, $1;
    }
    $convert[0] = "\e[${color}m$convert[0]\e[m";
  }
  return @convert;
}

sub _ref_formatter {
  require Data::Dumper;
  local $SIG{__WARN__} = sub {};
  local $SIG{__DIE__} = sub {};
  no warnings 'once';
  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Purity = 0;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Useqq = 1;
  local $Data::Dumper::Maxdepth = $OPTIONS{dump} == _INF ? 0 : $OPTIONS{dump};
  Data::Dumper::Dumper($_[0]);
}

sub _stack_trace {
  no warnings 'once';
  local $Carp::RefArgFormatter
    = $OPTIONS{dump} ? \&_ref_formatter : \&_str_val;
  my $message = &longmess;
  $message =~ s/\.?$/./m;
  if ($OPTIONS{source} || $OPTIONS{evalsource}) {
    $message .= Devel::Confess::Source::source_trace(1,
      $OPTIONS{evalsource} ? ($OPTIONS{evalsource}, 1) : $OPTIONS{source});
  }
  $message;
}

# these are package varibles to control their lifetime.  they should not be
# used externally.
our $PACK_SUFFIX = 'A000';

our %EXCEPTIONS;
our %PACKAGES;
our %MESSAGES;
our %CLONED;

sub CLONE {
  my %id_map = map {
    my $ex = $EXCEPTIONS{$_};
    defined $ex ? ($_ => refaddr($ex)) : ();
  } keys %EXCEPTIONS;

  %EXCEPTIONS = map {; $id_map{$_} => $EXCEPTIONS{$_}} keys %id_map;
  %PACKAGES = map {; $id_map{$_} => $PACKAGES{$_}} keys %id_map;
  %MESSAGES = map {; $id_map{$_} => $MESSAGES{$_}} keys %id_map;
  %CLONED = map {; $_ => 1 } values %id_map
    if _BROKEN_CLONED_DESTROY_REBLESS || _BROKEN_CLONED_GLOB_UNDEF;
  weaken($_)
    for values %EXCEPTIONS;
}

sub _update_ex_refs {
  for my $id ( keys %EXCEPTIONS ) {
    next
      if defined $EXCEPTIONS{$id};
    delete $EXCEPTIONS{$id};
    delete $PACKAGES{$id};
    delete $MESSAGES{$id};
    delete $CLONED{$id}
      if _BROKEN_CLONED_DESTROY_REBLESS || _BROKEN_CLONED_GLOB_UNDEF;
  }
}

sub _convert {
  _update_ex_refs;
  if (my $class = blessed(my $ex = $_[0])) {
    return @_
      unless $OPTIONS{objects};
    return @_
      if ! do {no strict 'refs'; defined &{"Devel::Confess::_Attached::DESTROY"} };
    my $message;
    my $id = refaddr($ex);
    if (defined $EXCEPTIONS{$id}) {
      return @_
        if _isa($ex, "Devel::Confess::_Attached");

      # something is going very wrong.  possibly from a Safe compartment.
      # we probably broke something, but do the best we can.
      if ((ref $ex) =~ /^Devel::Confess::__ANON_/) {
        my $oldclass = $PACKAGES{$id};
        $message = $MESSAGES{$id};
        bless $ex, $oldclass;
      }
      else {
        # give up
        return @_;
      }
    }

    my $does = _can($ex, 'can') && ($ex->can('does') || $ex->can('DOES')) || sub () { 0 };
    if (
      grep {
        $NoTrace{$_}
        && _can($ex, 'isa')
        && $ex->isa($_)
        || $ex->$does($_)
      } keys %NoTrace
    ) {
      return @_;
    }

    $message ||= _stack_trace();

    weaken($EXCEPTIONS{$id} = $ex);
    $PACKAGES{$id} = $class;
    $MESSAGES{$id} = $message;

    my $newclass = __PACKAGE__ . '::__ANON_' . $PACK_SUFFIX++ . '__';

    {
      no strict 'refs';
      @{$newclass . '::ISA'} = ('Devel::Confess::_Attached', $class);
    }

    bless $ex, $newclass;
    return $ex;
  }
  elsif (ref($ex = $_[0])) {
    my $id = refaddr($ex);

    my $message = _stack_trace;

    weaken($EXCEPTIONS{$id} = $ex);
    $PACKAGES{$id} = undef;
    $MESSAGES{$id} ||= $message;

    return $ex;
  }

  my $out = join('', @_);

  if (caller(1) eq 'Carp') {
    my $long = longmess();
    my $long_trail = $long;
    $long_trail =~ s/.*?\n//;
    $out =~ s/\Q$long\E\z|\Q$long_trail\E\z//
      or $out =~ s/(.*) at .*? line .*?\n\z/$1/;
  }

  my $source_trace;
  $out =~ s/^(={75}\ncontext for .*^={75}\n\z)//ms
    and $source_trace = $1
    if $OPTIONS{source} || $OPTIONS{evalsource};
  my $trace = _stack_trace();
  $trace =~ s/^(.*\n?)//;
  my $where = $1;
  my $new_source_trace;
  $trace =~ s/^(={75}\ncontext for .*^={75}\n\z)//ms
    and $new_source_trace = $1
    if $OPTIONS{source} || $OPTIONS{evalsource};
  my $find = $where;
  $find =~ s/(\.?\n?)\z//;
  my $trace_re = length $trace ? "(?:\Q$trace\E)?" : '';
  $out =~ s/(\Q$find\E(?: during global destruction)?(\.?\n?))$trace_re\z//
    and $where = $1;
  if (defined $source_trace) {
    if (defined $new_source_trace) {
      $new_source_trace =~ s/^={75}\n//;
      $source_trace =~ s/^(([-=])\2{74}\n)(?:\Q$new_source_trace\E)?\z/$1/ms;
    }
    $trace .= $source_trace;
  }
  if (defined $new_source_trace) {
    $trace .= $new_source_trace;
  }
  return ($out, $where . $trace);
}

sub _ex_as_strings {
  my $ex = $_[0];
  return @_
    unless ref $ex;
  my $id = refaddr($ex);
  my $class = $PACKAGES{$id};
  my $message = $MESSAGES{$id};
  my $out;
  if (blessed $ex) {
    my $newclass = ref $ex;
    bless $ex, $class if $class;
    if ($OPTIONS{dump} && !overload::OverloadedStringify($ex)) {
      $out = _ref_formatter($ex);
    }
    else {
      $out = "$ex";
    }
    bless $ex, $newclass if $class;
  }
  elsif ($OPTIONS{dump}) {
    $out = _ref_formatter($ex);
  }
  else {
    $out = "$ex";
  }
  return ($out, $message);
}

{
  package #hide
    Devel::Confess::_Attached;
  use overload
    fallback => 1,
    'bool' => sub {
      package
        Devel::Confess;
      my $ex = $_[0];
      my $class = $PACKAGES{refaddr($ex)};
      my $newclass = ref $ex;
      bless $ex, $class;
      my $out = $ex ? !!1 : !!0;
      bless $ex, $newclass;
      return $out;
    },
    '0+' => sub {
      package
        Devel::Confess;
      my $ex = $_[0];
      my $class = $PACKAGES{refaddr($ex)};
      my $newclass = ref $ex;
      bless $ex, $class;
      my $out = 0+sprintf '%.20g', $ex;
      bless $ex, $newclass;
      return $out;
    },
    '""' => sub {
      package
        Devel::Confess;
      join('', _ex_as_strings(@_));
    },
  ;

  sub DESTROY {
    package
      Devel::Confess;
    my $ex = $_[0];
    my $id = refaddr($ex);
    my $class = delete $PACKAGES{$id} or return;
    delete $MESSAGES{$id};
    delete $EXCEPTIONS{$id};

    my $newclass = ref $ex;

    my $cloned;
    # delete_package is more complete, but can explode on some perls
    if (_BROKEN_CLONED_GLOB_UNDEF && delete $CLONED{$id}) {
      $cloned = 1;
      no strict 'refs';
      @{"${newclass}::ISA"} = ();
      my $stash = \%{"${newclass}::"};
      delete @{$stash}{keys %$stash};
    }
    else {
      Symbol::delete_package($newclass);
    }

    if (_BROKEN_CLONED_DESTROY_REBLESS && $cloned || delete $CLONED{$id}) {
      my $destroy = _can($class, 'DESTROY') || return;
      goto $destroy;
    }

    bless $ex, $class;

    # after reblessing, perl will re-dispatch to the class's own DESTROY.
    ();
  }
}

1;
__END__

=encoding utf8

=head1 NAME

Devel::Confess - Include stack traces on all warnings and errors

=head1 SYNOPSIS

Use on the command line:

  # Make every warning and error include a full stack trace
  perl -d:Confess script.pl

  # Also usable as a module
  perl -MDevel::Confess script.pl

  # display warnings in yellow and errors in red
  perl -d:Confess=color script.pl

  # set options by environment
  export DEVEL_CONFESS_OPTIONS='color dump'
  perl -d:Confess script.pl

Can also be used inside a script:

  use Devel::Confess;

  use Devel::Confess 'color';

  # disable stack traces
  no Devel::Confess;

=head1 DESCRIPTION

This module is meant as a debugging aid. It can be used to make a script
complain loudly with stack backtraces when C<warn()>ing or C<die()>ing.
Unlike other similar modules (e.g. L<Carp::Always>), stack traces will also be
included when exception objects are thrown.

The stack traces are generated using L<Carp>, and will work for all types of
errors.  L<Carp>'s C<carp> and C<croak> functions will also be made to include
stack traces.

  # it works for explicit die's and warn's
  $ perl -d:Confess -e 'sub f { die "arghh" }; sub g { f }; g'
  arghh at -e line 1.
          main::f() called at -e line 1
          main::g() called at -e line 1

  # it works for interpreter-thrown failures
  $ perl -d:Confess -w -e 'sub f { $a = shift; @a = @$a };' \
                                        -e 'sub g { f(undef) }; g'
  Use of uninitialized value $a in array dereference at -e line 1.
          main::f(undef) called at -e line 2
          main::g() called at -e line 2

Internally, this is implemented with L<$SIG{__WARN__}|perlvar/%SIG> and
L<$SIG{__DIE__}|perlvar/%SIG> hooks.

Stack traces are also included if raw non-object references are thrown.

This module is compatible with all perl versions back to 5.6.2, without
additional prerequisites.  It contains workarounds for a number of bugs in the
perl interpreter, some of which effect comparatively simpler modules, like
L<Carp::Always>.

=head1 METHODS

=head2 import( @options )

Enables stack traces and sets options.  A list of options to enable can be
passed in.  Prefixing the options with C<no_> will disable them.

=over 4

=item C<objects>

Enable attaching stack traces to exception objects.  Enabled by default.

=item C<builtin>

Load the L<Devel::Confess::Builtin> module to use built in
stack traces on supported exception types.  Disabled by default.

=item C<dump>

Dumps the contents of references in arguments in stack trace, instead
of only showing their stringified version.  Also causes exceptions that are
non-object references and objects without string overloads to be dumped if
being displayed.  Shows up to three references deep.
Disabled by default.

=item C<dump0>, C<dump1>, C<dump2>, etc

The same as the dump option, but with a different max depth to dump.  A depth
of 0 is treated as infinite.

=item C<color>

Colorizes error messages in red and warnings in yellow.  Disabled by default.

=item C<source>

Includes a snippet of the source for each level of the stack trace. Disabled
by default.

=item C<source0>, C<source1>, C<source2>, etc

Enables source display, but with a specified number of lines of context to show.
Context of 0 will show the entire source of the files.

=item C<evalsource>

Similar to the source option, but only shows includes source for string evals.
Useful for seeing the results of code generation.  Disabled by default.
Overrides the source option.

=item C<evalsource0>, C<evalsource1>, C<evalsource2>, etc

Enables eval source display, but with a specified number of lines of context to
show.  Context of 0 will show the entire source of the evals.

=item C<better_names>

Use more informative names to string evals and anonymous subs in stack
traces.  Enabled by default.

=item C<errors>

Add stack traces to errors.  Enabled by default.

=item C<warnings>

Add stack traces to warnings.  Enabled by default.

=back

The default options can be changed by setting the C<DEVEL_CONFESS_OPTIONS>
environment variable to a space separated list of options.

=head1 CONFIGURATION

=head2 C<%Devel::Confess::NoTrace>

Classes or roles added to this hash will not have stack traces
attached to them.  This is useful for exception classes that provide
their own stack traces, or classes that don't cope well with being
re-blessed.  If L<Devel::Confess::Builtin> is loaded, it will
automatically add its supported exception types to this hash.

Default Entries:

=over 4

=item L<Throwable::Error>

Provides a stack trace

=item L<Moose::Error::Default>

Provides a stack trace

=back

=head1 ACKNOWLEDGMENTS

The idea and parts of the code and documentation are taken from L<Carp::Always>.

=head1 SEE ALSO

=over 4

=item *

L<Carp::Always>

=item *

L<Carp>

=item *

L<Acme::JavaTrace> and L<Devel::SimpleTrace>

=item *

L<Carp::Always::Color>

=item *

L<Carp::Source::Always>

=item *

L<Carp::Always::Dump>

=back

=head1 CAVEATS

This module uses several ugly tricks to do its work and surely has bugs.

=over 4

=item *

This module uses C<$SIG{__WARN__}> and C<$SIG{__DIE__}> to accomplish its goal,
and thus may not play well with other modules that try to use these hooks.
Significant effort has gone into making this work as well as possible, but
global variables like these can never be fully encapsulated.

=item *

To provide stack traces on exception objects, this module re-blesses the
exception objects into a generated class.  While it tries to have the smallest
effect it can, some things cannot be worked around.  In particular,
C<ref($exception)> will return a different value than may be expected.  Any
module that relies on the specific return value from C<ref> like already has
bugs though.

=back

=head1 SUPPORT

Please report bugs via
L<CPAN RT|http://rt.cpan.org/NoAuth/Bugs.html?Dist=Devel-Confess>.


=head1 AUTHORS

=over 4

=item *

Graham Knop <haarg@haarg.org>

=back

=head1 CONTRIBUTORS

=over 4

=item *

Adriano Ferreira <ferreira@cpan.org>

=back

=head1 COPYRIGHT

Copyright (c) 2005-2013 the L</AUTHORS> and L</CONTRIBUTORS>
as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See L<http://dev.perl.org/licenses/>.

=cut
