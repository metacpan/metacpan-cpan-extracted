package Log::Any::Simple;

use strict;
use warnings;
use utf8;

use Carp qw(croak cluck shortmess longmess);
use Data::Dumper;
use Log::Any;
use Log::Any::Adapter::Util 'numeric_level';
use Log::Any::Adapter;
use Readonly;
use Sub::Util 'set_subname';

our $VERSION = '0.03';

Readonly::Scalar my $DIE_AT_DEFAULT => numeric_level('fatal');
Readonly::Scalar my $DIE_AT_KEY => 'Log::Any::Simple/die_at';
Readonly::Scalar my $CATEGORY_KEY => 'Log::Any::Simple/category';
Readonly::Scalar my $PREFIX_KEY => 'Log::Any::Simple/prefix';
Readonly::Scalar my $DUMP_KEY => 'Log::Any::Simple/dump';

Readonly::Array my @ALL_LOG_METHODS =>
    (Log::Any::Adapter::Util::logging_methods(), Log::Any::Adapter::Util::logging_aliases);
Readonly::Hash my %ALL_LOG_METHODS => map { $_ => 1 } @ALL_LOG_METHODS;

Readonly::Array my @DEFAULT_LOG_METHODS => qw(trace debug info warning error fatal);

# The index of the %^H hash in the list returned by "caller".
Readonly::Scalar my $HINT_HASH => 10;

# All our methods that can be imported, other than the logging methods
# themselves.
Readonly::Array my @EXPORT_OK => qw(die_with_stack_trace get_logger);
Readonly::Hash my %EXPORT_OK => map { $_ => 1 } @EXPORT_OK;

sub import {  ## no critic (RequireArgUnpacking, ProhibitExcessComplexity)
  my (undef) = shift @_;  # This is the package being imported, so our self.

  my $calling_pkg_name = caller(0);
  my %to_export;

  while (defined (my $arg = shift)) {
    if ($arg eq ':default') {  ## no critic (ProhibitCascadingIfElse)
      $to_export{$_} = 1 for @DEFAULT_LOG_METHODS;
    } elsif ($arg eq ':all') {
      $to_export{$_} = 1 for @ALL_LOG_METHODS;
    } elsif (exists $ALL_LOG_METHODS{$arg}) {
      $to_export{$arg} = 1;
    } elsif ($arg eq ':die_at') {
      my $level = shift;
      if ($level eq 'none') {
        $^H{$DIE_AT_KEY} = numeric_level('emergency') - 1;
      } else {
        my $die_at = numeric_level($level);
        croak 'Invalid :die_at level' unless defined $die_at;
        $^H{$DIE_AT_KEY} = $die_at;
      }
    } elsif ($arg eq ':category') {
      my $category = shift;
      croak 'Invalid :category name' unless $category;
      $^H{$CATEGORY_KEY} = $category;
    } elsif ($arg eq ':prefix') {
      my $prefix = shift;
      croak 'Invalid :prefix value' unless $prefix;
      $^H{$PREFIX_KEY} = $prefix;
    } elsif ($arg eq ':dump_long') {
      $^H{$DUMP_KEY} = 'long';
    } elsif ($arg eq ':dump_short') {
      $^H{$DUMP_KEY} = 'short';
    } elsif (exists $EXPORT_OK{$arg}) {
      _export_module_method($arg, $calling_pkg_name);
    } elsif ($arg eq ':to_stderr') {
      _activate_logging($arg, \*STDERR, shift);
    } elsif ($arg eq ':to_stdout') {
      _activate_logging($arg, \*STDOUT, shift);
    } elsif ($arg eq ':from_argv') {
      _parse_argv();
    } else {
      croak "Unknown parameter: $arg";
    }
  }

  # We export all the methods at the end, so that all the modifications to the
  # %^H hash are already done and can be used by the _export method.
  _export_logger($calling_pkg_name, \%^H) if %to_export;
  _export_logging_method($_, $calling_pkg_name, \%^H) for keys %to_export;

  @_ = 'Log::Any';
  goto &Log::Any::import;
}

# Unimport is not documented at all, and only here to facilitate testing.
sub unimport {  ## no critic (RequireArgUnpacking)
  my (undef) = shift @_;  # This is the package being imported, so our self.

  while (defined (my $arg = shift)) {
    if ($arg eq ':logging') {
      _deactivate_logging();
    } else {
      croak "Unknown parameter: $arg";
    }
  }

  return;
}

# This is slightly ugly but the intent is that the user of a module using this
# module will set this variable to 1 to get full backtrace.
my $die_with_stack_trace;
my %die_with_stack_trace;

sub die_with_stack_trace {  ## no critic (RequireArgUnpacking)
  my ($category, $mode);
  if (@_ == 1) {
    ($mode) = @_;
  } elsif (@_ == 2) {
    ($category, $mode) = @_;
  } else {
    croak 'Invalid number of arguments for die_with_stack_trace(). Expecting 1 or 2, got '
        .(scalar(@_));
  }
  my @valid = qw(no none short small long full);
  my $valid_re = join('|', @valid);
  croak "Invalid mode passed to die_with_stack_trace: ${mode}"
      if defined $mode && $mode !~ m/^(?:${valid_re})$/;
  if (defined $category) {
    $die_with_stack_trace{$category} = $mode;
  } else {
    $die_with_stack_trace = $mode;
  }
  return;
}

sub _export_logger {
  my ($pkg_name, $hint_hash) = @_;
  my $category = _get_category($pkg_name, $hint_hash);
  my $logger = _get_logger($category, $hint_hash);
  no strict 'refs';  ## no critic (ProhibitNoStrict)
  *{"${pkg_name}::__log_any_simple_logger"} = \$logger;
  return;
}

# Export one of the methods of this module to our caller. Should only be called
# on methods from the @EXPORT_OK array.
sub _export_module_method {
  my ($method, $pkg_name) = @_;
  no strict 'refs';  ## no critic (ProhibitNoStrict)
  *{"${pkg_name}::${method}"} = \&{$method};
  return;
}

# Export one of the logging methods of Log::Any to our caller.
sub _export_logging_method {
  my ($method, $pkg_name, $hint_hash) = @_;

  my $log_method = $method.'f';
  my $sub;
  if (_should_die($method, $hint_hash)) {
    my $category = _get_category($pkg_name, $hint_hash);
    $sub = sub {
      no strict 'refs';  ## no critic (ProhibitNoStrict)
      my $logger = ${"${pkg_name}::__log_any_simple_logger"};
      _die($category, $logger->$log_method(@_));
    };
  } else {
    $sub = sub {
      no strict 'refs';  ## no critic (ProhibitNoStrict)
      my $logger = ${"${pkg_name}::__log_any_simple_logger"};
      $logger->$log_method(@_);
      return;
    };
  }
  no strict 'refs';  ## no critic (ProhibitNoStrict)
  *{"${pkg_name}::${method}"} = set_subname($method, $sub);
  return;
}

sub _get_category {
  my ($pkg_name, $hint_hash) = @_;
  return $hint_hash->{$CATEGORY_KEY} // $pkg_name;
}

sub _get_formatter {
  my ($hint_hash) = @_;
  my $dump = ($hint_hash->{$DUMP_KEY} // 'short') eq 'short' ? \&_dump_short : \&_dump_long;
  return sub {
    my (undef, undef, $format, @args) = @_;  # First two args are the category and the numeric level.
    for (@args) {
      $_ = $_->() if ref eq 'CODE';
      $_ = '<undef>' unless defined;
      next unless ref;
      $_ = $dump->($_);
    }
    return sprintf($format, @args);
  };
}

sub _get_logger {
  my ($category, $hint_hash) = @_;
  my @args = (category => $category);
  push @args, prefix => $hint_hash->{$PREFIX_KEY} if exists $hint_hash->{$PREFIX_KEY};
  push @args, formatter => _get_formatter($hint_hash);
  return Log::Any->get_logger(@args);
}

sub _should_die {
  my ($level, $hint_hash) = @_;
  return numeric_level($level) <= ($hint_hash->{$DIE_AT_KEY} // $DIE_AT_DEFAULT);
}

# This method is meant to be called only at logging time (and not at import time
# like the methods above)
sub _die {
  my ($category, $msg) = @_;
  my $trace = $die_with_stack_trace{$category} // $die_with_stack_trace // 'short';
  if ($trace eq 'long' || $trace eq 'full') {
    $msg = longmess($msg);
  } elsif ($trace eq 'short' || $trace eq 'small') {
    $msg = shortmess($msg);
  } elsif ($trace eq 'none' || $trace eq 'no') {
    $msg .= "\n";
  } else {
    cluck 'Invalid $die_with_stack_trace mode. Should not happen';  # The mode is validated.
  }
  # The message returned by shortmess and longmess always end with a new line,
  # so it’s fine to use die here.
  die $msg;  ## no critic (ErrorHandling::RequireCarping)
}

sub _dump_short {
  my ($ref) = @_;  # Can be called on anything but intended to be called on ref.
  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Pad = '';  ## no critic (ProhibitEmptyQuotes)
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Sparseseen = 1;
  local $Data::Dumper::Quotekeys = 0;
  # Consider Useqq = 1
  return Dumper($ref);
}

sub _dump_long {
  my ($ref) = @_;  # Can be called on anything but intended to be called on ref.
  local $Data::Dumper::Indent = 2;
  local $Data::Dumper::Pad = ' ' x 4;  ## no critic (ProhibitEmptyQuotes, ProhibitMagicNumbers)
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Sparseseen = 1;
  local $Data::Dumper::Quotekeys = 0;
  # Consider Useqq = 1
  chop(my $s = Dumper($ref));  # guaranteed to end in a newline, and does not depend on $/
  return $s;
}

sub _get_singleton_logger {
  my ($pkg_name, $hint_hash) = @_;
  my $logger;
  {
    no strict 'refs';  ## no critic (ProhibitNoStrict)
    $logger = ${"${pkg_name}::__log_any_simple_logger"};
  }
  return $logger if defined $logger;
  my $category = _get_category($pkg_name, $hint_hash);
  $logger = _get_logger($category, $hint_hash);
  {
    no strict 'refs';  ## no critic (ProhibitNoStrict)
    *{"${pkg_name}::__log_any_simple_logger"} = \$logger;
  }
  return $logger;
}

# Public alias for _get_singleton_logger
sub get_logger {
  my @caller = caller(0);
  return _get_singleton_logger($caller[0], $caller[$HINT_HASH]);
}

# This blocks generates in the Log::Any::Simple namespace logging methods
# that can be called directly by the user (although the standard approach would
# be to import them in the caller’s namespace). These methods are slower because
# They need to retrieve a logger each time.
for my $name (@ALL_LOG_METHODS) {
  no strict 'refs';  ## no critic (ProhibitNoStrict)
  *{$name} = set_subname(
    $name,
    sub {
      my @caller = caller(0);
      my $hint_hash = $caller[$HINT_HASH];
      my $logger = _get_singleton_logger($caller[0], $hint_hash);
      my $method = $name.'f';
      my $msg = $logger->$method(@_);
      _die(_get_category($caller[0], $hint_hash), $msg) if _should_die($name, $hint_hash);
    });
}

# The list of all Log::Any::Adapter objects set by this module.
my @set_adapters;

# Creates a Log::Any::Adapter that logs to the given file descriptor ($fh)
# starting at the given $level_str. $cmd_arg_name is used only for debugging and
# is the name of the "use" statement option that triggered this call.
sub _activate_logging {
  my ($cmd_arg_name, $fh, $level_str) = @_;
  my $log_from = numeric_level($level_str);
  my $numeric_debug = numeric_level('debug');
  croak "Invalid ${cmd_arg_name} level" unless defined $log_from;
  my $adapter = Log::Any::Adapter->set(
    'Capture',
    format => 'messages',
    to => sub {
      my ($level, $category, $text) = @_;
      my $num_level = numeric_level($level);
      return if $num_level > $log_from;
      if ($num_level >= $numeric_debug) {
        chomp($text);
        printf $fh "%s(%s) - %s\n", (uc $level), $category, $text;
      } else {
        chomp($text);
        printf $fh "%s - %s\n", (uc $level), $text;
      }
    });
  push @set_adapters, $adapter;
  return;
}

# Removes all the Log::Any::Adapter objects set by _activate_logging
sub _deactivate_logging {
  Log::Any::Adapter->remove($_) for splice @set_adapters;
  return;
}

# Parses @ARGV and activate logging if there is a --log argument in it.
sub _parse_argv {
  for my $i (0 .. $#ARGV) {
    last if $ARGV[$i] eq '--';
    next unless $ARGV[$i] =~ m/^--?log(?:=(.*))?$/;
    last if $i == $#ARGV && !defined $1;
    my $cmd;
    if (defined $1) {
      $cmd = $1;
      splice @ARGV, $i, 1;
    } else {
      $cmd = $ARGV[$i + 1];
      splice @ARGV, $i, 2;
    }
    _activate_logging(':from_argv', \*STDERR, $cmd);
    last;
  }
  return;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

Log::Any::Simple - Very thin wrapper around Log::Any, using a functional
interface that dies automatically when you log above a given level

=head1 SYNOPSIS

  use Log::Any::Simple ':default';

  info 'Starting program...';
  debug 'Printing the output of a costly function: %s', sub { costly_data() };
  trace 'Printing structured data: %s', $ref_to_complex_data_structure;
  fatal 'Received a %s signal', $signal;

=head1 DESCRIPTION

B<Disclaimer>: L<Log::Any> is already quite simple, and our module name does not
imply otherwise. Maybe B<Log::Any::SlightlySimpler> would have been a better
name.

B<Log::Any::Simple> is offering a purely functional interface to L<Log::Any>,
removing all possible clutter. The first intent, however, was to die() when
logging at the fatal() level or above, so that the application using the module
can control how much stack trace is printed in that case.

The main features of the module, in addition to those of L<Log::Any>, are:

=over 4

=item *

Purely functional interface with no object to manipulate.

=item *

Supports dying directly from call to the log function (by default at the
B<fatal> level and above, but this can be configured).

=item *

The consumer application can control the amount of stack-trace produced when a
module dies with B<Log::Any::Simple>.

=item *

Options to trivially control the log output, for simple programs or for tests.

=item *

Support for a simple command line based log output.

=item *

Support for lazily producing logged data.

=item *

Several formatting options for dumping data-structure.

=back

Except for that stack trace control, the usage of B<Log::Any::Simple> on the
application side (log consumer), is exactly the same as the usage of
L<Log::Any>. See L<Log::Any::Adapter> documentation, for how to consume logs in
your main application and L<Log::Any::Test> for how to test your logging
statements.

=head2 Importing

You can pass the following parameters on the C<use Log::Any::Simple> line:

=over 4

=item *

C<B<:default>> will export the following names in your namespace: C<trace>,
C<debug>, C<info>, C<warning>, C<error>, and C<fatal>.

=item *

C<B<:all>> will export logging methods for all the log levels supported by
B<Log::Any> as well as for all their aliases.

=item *

C<B<:die_at> =E<gt> I<level_name>> specifies the lowest logging level that
triggers a call to die() when used. By default this is C<fatal> (and so, the
C<critical>, C<alert>, and C<emergency> levels also dies). You can also pass
C<none> to disable this behavior entirely.

=item *

C<B<:category> =E<gt> I<category_name>> specifies the logging category to use.
If not specified, this defaults to your package name.

=item *

C<B<:prefix> =E<gt> I<prefix_value>> sets a I<prefix> that is prepended to
all logging messages. This is handled by directly passing this value to the
L<Log::Any::Proxy> object used internally.

=item *

C<B<:dump_long>> will use a multi-line layout for rendering complex
data-structures that are logged.

=item *

C<B<:dump_short>> will use a compact single-line layout for rendering complex
data-structures that are logged. This is the default.

=item *

C<B<:to_stderr> =E<gt> I<level_name>> Activate logging for messages at the given
level or above. All logs messages are prefixed with their level name and sent to
STDERR. In general this is meant for tests or very simple programs. Note that
this option has a global effect on the program and cannot be turned off.

=item *

C<B<:to_stdout> =E<gt> I<level_name>> is the same as C<B<:to_stderr>> but
sending the messages to STDOUT instead of STDERR.

=item *

C<B<:from_argv>> parses C<@ARGV> and activates logging based on its content. For
now this is not configurable and will look for a single C<--log> argument in the
command line, that can take only a single log level as argument (either as two
consecutive command line arguments or as C<--log=level>). If found, log messages
at that level or above will be sent to STDERR. The parsed arguments are removed
from C<@ARGV>. Note that this option has a global effect on the program and
cannot be turned off.

=back

In addition to these options, you can pass the names of any of the valid level
or alias as documented at L<Log::Any/"LOG LEVELS"> to import just these methods
and you can pass the name of B<Log::Any::Simple> public methods to import them
as well, as is standard.

If you do not import the logging methods into your package, you can still call
them directly from the B<Log::Any::Simple> namespace, but this is slightly less
efficient than importing them.

=head2 Logging methods

While we use the default level names for our methods (C<info>, C<error>, etc.),
they behave more like the C<f> variant of the L<Log::Any/Logging> methods. That
is, they expect any number of arguments where the first argument is a format
string following the L<C<sprintf>|https://perldoc.perl.org/functions/sprintf>
syntax and the rest are the arguments for the C<sprintf> call.

In addition to the normal behavior the following values can be passed in the
list of arguments (except in the first position):

=over 4

=item *

A code reference, which will be called if the logging actually happens. This is
useful when you want to log large or costly data-structures to avoid generating
them if detailed logging is not activated by the application.

=item *

Any other data reference, which will be dumped through L<Data::Dumper>. The
formatting being used can be controlled through the C<B<:dump_short>> and
C<B<:dump_long>> arguments passed on the C<use Log::Any::Simple> line. Note that
you can use a code reference that returns a data-reference and the data will be
generated and dumped lazily (in all cases, it will be dumped lazily even if not
returned by a code reference).

=item *

An I<undef> value, which will be rendered as C<< <undef> >>.

=back

Although this should be uncommon, you can call the get_logger() method (which
can be imported) to retrieve the underlying L<Log::Any> logger being used
internally for your package. But note that using this object bypass all the
specific behavior of B<Log::Any::Simple>. One use of this object is to call the
is_xxx() method family, indicating whether a given log level is activated.
However, thanks to the lazy-logging behavior of our module, the need for that
should be infrequent.

=head2 Controlling stack-traces

You can use the die_with_stack_trace() method (that can be imported) to control
the amount of stack-trace printed when the library dies following a call to a
logging method above the B<:die_at> level. This is meant to be called by the
application consuming the logs, rather than by the module producing them
(although this is possible too).

This method can be called in two ways:

  die_with_stack_trace($category => $mode);
  die_with_stack_trace($mode);

The first syntax sets a stack-trace mode for a specific logging category (by
default the package name from which you log) and the second sets a fallback mode
for categories for which you didn’t set a specific mode.

The valid values for B<$mode> are the following:

=over 4

=item *

C<B<none>>: no stack trace is printed at all, just the log message that goes to
STDERR, in addition to the default logging destination.

=item *

C<B<short>>: a short stack trace is printed, with just the name of the calling
method (similar to the default behavior of die()).

=item *

C<B<long>>: a long stack trace is printed, with all the chain of the calling
methods (similar to the behavior of croak()).

=item *

C<I<undef>>: delete the global or per-category setting for the stack trace mode.

=back

When neither a global nor a per-category mode is set, the default is
C<B<short>>.

=head1 RESTRICTIONS

Importing this module more than once in a given package is not supported and can
give unpredictable results.

=head1 AUTHOR

This program has been written by L<Mathias Kende|mailto:mathias@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright 2024 Mathias Kende

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

=head1 SEE ALSO

=over 4

=item *

L<Log::Any>

=back

=cut
