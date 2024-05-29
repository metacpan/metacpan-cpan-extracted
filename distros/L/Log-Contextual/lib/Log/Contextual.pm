package Log::Contextual;
use strict;
use warnings;

our $VERSION = '0.009001';

use Data::Dumper::Concise;

use B qw(svref_2object);

sub _stash_name {
  my ($coderef) = @_;
  ref $coderef or return;
  my $cv = B::svref_2object($coderef);
  $cv->isa('B::CV') or return;

  # bail out if GV is undefined
  $cv->GV->isa('B::SPECIAL') and return;

  return $cv->GV->STASH->NAME;
}

eval { ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval)
  require Log::Log4perl;
  die if $Log::Log4perl::VERSION < 1.29;
  Log::Log4perl->wrapper_register(__PACKAGE__)
};

sub router {
  our $Router_Instance ||= do {
    require Log::Contextual::Router;
    Log::Contextual::Router->new
  }
}

sub default_import {
  my ($class) = shift;

  die 'Log::Contextual does not have a default import list';
}

my @all_levels = qw(debug trace warn info error fatal);

sub arg_logger         { $_[1] }
sub arg_levels         { $_[1] || [@all_levels] }
sub arg_package_logger { $_[1] }
sub arg_default_logger { $_[1] }

my %exports;
for my $level (@all_levels) {
  $exports{$_.'_'.$level} = { type => $_, level => $level }
    for qw(Dlog DlogS Dslog DslogS);
  $exports{$_.'_'.$level} = { type => $_, level => $level }
    for qw(log logS slog slogS);
}

$exports{$_} = {}
  for qw( set_logger with_logger has_logger );
my %import_arguments = map +($_ => $_), qw(logger package_logger default_logger levels);
my %allowed_tags = map +($_ => $_), qw(log dlog);

sub import {
  my ($class, @args) = @_;
  my $target = caller;
  my %options;
  my @tags;
  my @imports;

  @args = qw(:default)
    if !@args;

  while (@args) {
    my $arg = shift @args;
    if ($arg =~ /\A[-:](.*)/s) {
      my $name = $1;
      if ($import_arguments{$name}) {
        my $option_args = shift @args;
        $options{$name} = $option_args;
      }
      elsif ($name eq 'default') {
        my @tag_args = ref $args[0] ? shift @args : ();
        push @args, map +($_ => @tag_args), $class->default_import;
      }
      elsif (defined $allowed_tags{$name}) {
        my $tag_args = ref $args[0] ? shift @args : undef;
        push @tags, { tag => $name, args => $tag_args };
      }
      else {
        die "Invalid argument $arg!";
      }
    }
    else {
      $arg =~ s/\A&//;
      my $export_config = $exports{$arg}
        or die "Invalid import $arg!";

      my $import_args = ref $args[0] ? shift @args : undef;
      push @imports, { import => $arg, args => $import_args, %$export_config };
    }
  }

  my @levels = @{$class->arg_levels($options{levels})};

  for my $tag (@tags) {
    my @want
      = $tag->{tag} eq 'log' ? qw(log logS slog slogS)
      : $tag->{tag} eq 'dlog' ? qw(Dlog DlogS Dslog DslogS)
      : die "Invalid tag $tag->{tag}";

    for my $want (@want) {
      push @imports, map +{
        import => "${want}_$_",
        args => $tag->{args},
        type => $want,
        level => $_
      }, @levels;
    }
  }

  my %router_args = (
    exporter  => $class,
    target    => $target,
    arguments => \%options,
  );
  my $router = $class->router;
  # wrapped in an extra sub so that caller levels match what they were when
  # using Exporter::Declare
  sub { $router->before_import(%router_args) }->();

  for my $import (@imports) {
    $class->_maybe_export($target, $import, $router);
  }

  sub { $router->after_import(%router_args) }->();
}

sub _maybe_export {
  my ($class, $target, $import, $router) = @_;

  my $name = $import->{import};
  my $import_args = $import->{args} || {};

  my $as = $import_args->{-as};
  my $prefix = $import_args->{-prefix};
  my $suffix = $import_args->{-suffix};

  my $target_name = defined $as ? $as : (
    (defined $prefix ? $prefix : '')
    . $name
    . (defined $suffix ? $suffix : '')
  );
  my $full_target = "${target}::${target_name}";

  my $method = '_gen_' . ($import->{type} || $name);
  my $level = $import->{level};

  my $sub = $class->$method($router, defined $level ? $level : ());

  no strict 'refs';
  if (defined &$full_target) {
    return
      if _stash_name(\&full_target) eq __PACKAGE__;

    # reexport will warn
  }
  *$full_target = $sub;
}

sub _gen_set_logger { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
  my ($class, $router) = @_;
  die ref($router) . " does not support set_logger()"
    unless $router->does('Log::Contextual::Role::Router::SetLogger');

  sub { $router->set_logger(@_) },
}

sub _gen_with_logger { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
  my ($class, $router) = @_;
  die ref($router) . " does not support with_logger()"
    unless $router->does('Log::Contextual::Role::Router::WithLogger');

  sub { $router->with_logger(@_) },
}

sub _gen_has_logger { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
  my ($class, $router) = @_;
  die ref($router) . " does not support has_logger()"
    unless $router->does('Log::Contextual::Role::Router::HasLogger');

  sub { $router->has_logger(@_) },
}

sub _gen_log { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
  my ($class, $router, $level) = @_;

  sub (&@) {
    my ($code, @args) = @_;
    $router->handle_log_request(
      exporter       => $class,
      caller_level   => 1,
      message_level  => $level,
      caller_package => scalar(caller),
      message_sub    => $code,
      message_args   => \@args,
    );
    return @args;
  };
}

sub _gen_slog { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
  my ($class, $router, $level) = @_;
  sub {
    my ($text, @args) = @_;
    $router->handle_log_request(
      exporter       => $class,
      caller_level   => 1,
      message_level  => $level,
      caller_package => scalar(caller),
      message_text   => $text,
      message_args   => \@args,
    );
    return @args;
  };
}

sub _gen_logS { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
  my ($class, $router, $level) = @_;
  sub (&@) {
    my ($code, @args) = @_;
    $router->handle_log_request(
      exporter       => $class,
      caller_level   => 1,
      message_level  => $level,
      caller_package => scalar(caller),
      message_sub    => $code,
      message_args   => \@args,
    );
    return $args[0];
  };
}

sub _gen_slogS { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
  my ($class, $router, $level) = @_;
  sub {
    my ($text, @args) = @_;
    $router->handle_log_request(
      exporter       => $class,
      caller_level   => 1,
      message_level  => $level,
      caller_package => scalar(caller),
      message_text   => $text,
      message_args   => \@args,
    );
    return $args[0];
  };
}


sub _gen_Dlog { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
  my ($class, $router, $level) = @_;
  sub (&@) {
    my ($code, @args) = @_;
    my $wrapped = sub {
      local $_ = (@_ ? Data::Dumper::Concise::Dumper @_ : '()');
      &$code;
    };
    $router->handle_log_request(
      exporter       => $class,
      caller_level   => 1,
      message_level  => $level,
      caller_package => scalar(caller),
      message_sub    => $wrapped,
      message_args   => \@args,
    );
    return @args;
  };
}

sub _gen_Dslog { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
  my ($class, $router, $level) = @_;
  sub {
    my ($text, @args) = @_;
    my $wrapped = sub {
      $text . (@_ ? Data::Dumper::Concise::Dumper @_ : '()');
    };
    $router->handle_log_request(
      exporter       => $class,
      caller_level   => 1,
      message_level  => $level,
      caller_package => scalar(caller),
      message_sub    => $wrapped,
      message_args   => \@args,
    );
    return @args;
  };
}

sub _gen_DlogS { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
  my ($class, $router, $level) = @_;
  sub (&$) {
    my ($code, $ref) = @_;
    my $wrapped = sub {
      local $_ = Data::Dumper::Concise::Dumper($_[0]);
      &$code;
    };
    $router->handle_log_request(
      exporter       => $class,
      caller_level   => 1,
      message_level  => $level,
      caller_package => scalar(caller),
      message_sub    => $wrapped,
      message_args   => [$ref],
    );
    return $ref;
  };
}

sub _gen_DslogS { ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
  my ($class, $router, $level) = @_;
  sub {
    my ($text, $ref) = @_;
    my $wrapped = sub {
      $text . Data::Dumper::Concise::Dumper($_[0]);
    };
    $router->handle_log_request(
      exporter       => $class,
      caller_level   => 1,
      message_level  => $level,
      caller_package => scalar(caller),
      message_sub    => $wrapped,
      message_args   => [$ref],
    );
    return $ref;
  };
}

for (qw(set with)) {
  no strict 'refs';
  my $sub = "${_}_logger";
  *{"Log::Contextual::$sub"} = sub {
    die "$sub is no longer a direct sub in Log::Contextual.  "
      . 'Note that this feature was never tested nor documented.  '
      . "Please fix your code to import $sub instead of trying to use it directly";
  }
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Arthur Axel "fREW" Schmidt Scalable passthrough

=head1 NAME

Log::Contextual - Simple logging interface with a contextual log

=head1 VERSION

version 0.009001

=head1 SYNOPSIS

  use Log::Contextual qw( :log :dlog set_logger with_logger );
  use Log::Contextual::SimpleLogger;
  use Log::Log4perl ':easy';
  Log::Log4perl->easy_init($DEBUG);

  my $logger  = Log::Log4perl->get_logger;

  set_logger $logger;

  log_debug { 'program started' };

  sub foo {

    my $minilogger = Log::Contextual::SimpleLogger->new({
      levels => [qw( trace debug )]
    });

    my @args = @_;

    with_logger $minilogger => sub {
      log_trace { 'foo entered' };
      my ($foo, $bar) = Dlog_trace { "params for foo: $_" } @args;
      # ...
      slog_trace 'foo left';
    };
  }

  foo();

Beginning with version 1.008 L<Log::Dispatchouli> also works out of the box
with C<Log::Contextual>:

  use Log::Contextual qw( :log :dlog set_logger );
  use Log::Dispatchouli;
  my $ld = Log::Dispatchouli->new({
    ident     => 'slrtbrfst',
    to_stderr => 1,
    debug     => 1,
  });

  set_logger $ld;

  log_debug { 'program started' };

=head1 DESCRIPTION

Major benefits:

=over 2

=item * Efficient

The default logging functions take blocks, so if a log level is disabled, the
block will not run:

  # the following won't run if debug is off
  log_debug { "the new count in the database is " . $rs->count };

Similarly, the C<D> prefixed methods only C<Dumper> the input if the level is
enabled.

=item * Handy

The logging functions return their arguments, so you can stick them in
the middle of expressions:

  for (log_debug { "downloading:\n" . join qq(\n), @_ } @urls) { ... }

=item * Generic

C<Log::Contextual> is an interface for all major loggers.  If you log through
C<Log::Contextual> you will be able to swap underlying loggers later.

=item * Powerful

C<Log::Contextual> chooses which logger to use based on L<< user defined C<CodeRef>s|/LOGGER CODEREF >>.
Normally you don't need to know this, but you can take advantage of it when you
need to later.

=item * Scalable

If you just want to add logging to your basic application, start with
L<Log::Contextual::SimpleLogger> and then as your needs grow you can switch to
L<Log::Dispatchouli> or L<Log::Dispatch> or L<Log::Log4perl> or whatever else.

=back

This module is a simple interface to extensible logging.  It exists to
abstract your logging interface so that logging is as painless as possible,
while still allowing you to switch from one logger to another.

It is bundled with a really basic logger, L<Log::Contextual::SimpleLogger>,
but in general you should use a real logger instead.  For something
more serious but not overly complicated, try L<Log::Dispatchouli> (see
L</SYNOPSIS> for example.)

=head1 A WORK IN PROGRESS

This module is certainly not complete, but we will not break the interface
lightly, so I would say it's safe to use in production code.  The main result
from that at this point is that doing:

  use Log::Contextual;

will die as we do not yet know what the defaults should be.  If it turns out
that nearly everyone uses the C<:log> tag and C<:dlog> is really rare, we'll
probably make C<:log> the default.  But only time and usage will tell.

=head1 IMPORT OPTIONS

See L</SETTING DEFAULT IMPORT OPTIONS> for information on setting these project
wide.

=head2 -logger

When you import this module you may use C<-logger> as a shortcut for
L</set_logger>, for example:

  use Log::Contextual::SimpleLogger;
  use Log::Contextual qw( :dlog ),
    -logger => Log::Contextual::SimpleLogger->new({ levels => [qw( debug )] });

sometimes you might want to have the logger handy for other stuff, in which
case you might try something like the following:

  my $var_log;
  BEGIN { $var_log = VarLogger->new }
  use Log::Contextual qw( :dlog ), -logger => $var_log;

=head2 -levels

The C<-levels> import option allows you to define exactly which levels your
logger supports.  So the default,
C<< [qw(debug trace warn info error fatal)] >>, works great for
L<Log::Log4perl>, but it doesn't support the levels for L<Log::Dispatch>.  But
supporting those levels is as easy as doing

  use Log::Contextual
    -levels => [qw( debug info notice warning error critical alert emergency )];

=head2 -package_logger

The C<-package_logger> import option is similar to the C<-logger> import option
except C<-package_logger> sets the logger for the current package.

Unlike L</-default_logger>, C<-package_logger> cannot be overridden with
L</set_logger> or L</with_logger>.

  package My::Package;
  use Log::Contextual::SimpleLogger;
  use Log::Contextual qw( :log ),
    -package_logger => Log::Contextual::WarnLogger->new({
      env_prefix => 'MY_PACKAGE'
    });

If you are interested in using this package for a module you are putting on
CPAN we recommend L<Log::Contextual::WarnLogger> for your package logger.

=head2 -default_logger

The C<-default_logger> import option is similar to the C<-logger> import option
except C<-default_logger> sets the B<default> logger for the current package.

Basically it sets the logger to be used if C<set_logger> is never called; so

  package My::Package;
  use Log::Contextual::SimpleLogger;
  use Log::Contextual qw( :log ),
    -default_logger => Log::Contextual::WarnLogger->new({
      env_prefix => 'MY_PACKAGE'
    });

=head1 SETTING DEFAULT IMPORT OPTIONS

=for Pod::Coverage arg_default_logger default_import arg_package_logger arg_levels arg_logger

Eventually you will get tired of writing the following in every single one of
your packages:

  use Log::Log4perl;
  use Log::Log4perl ':easy';
  BEGIN { Log::Log4perl->easy_init($DEBUG) }

  use Log::Contextual -logger => Log::Log4perl->get_logger;

You can set any of the import options for your whole project if you define your
own C<Log::Contextual> subclass as follows:

  package MyApp::Log::Contextual;

  use parent 'Log::Contextual';

  use Log::Log4perl ':easy';
  Log::Log4perl->easy_init($DEBUG)

  sub arg_default_logger { $_[1] || Log::Log4perl->get_logger }
  sub arg_levels { [qw(debug trace warn info error fatal custom_level)] }
  sub default_import { ':log' }

  # or maybe instead of default_logger
  sub arg_package_logger { $_[1] }

  # and almost definitely not this, which is only here for completeness
  sub arg_logger { $_[1] }

Note the C<< $_[1] || >> in C<arg_default_logger>.  All of these methods are
passed the values passed in from the arguments to the subclass, so you can
either throw them away, honor them, die on usage, etc.  To be clear,
if you define your subclass, and someone uses it as follows:

  use MyApp::Log::Contextual -default_logger => $foo,
                              -levels => [qw(bar baz biff)];

Your C<arg_default_logger> method will get C<$foo> and your C<arg_levels>
will get C<[qw(bar baz biff)]>;

Additionally, the C<default_import> method is what happens if a user tries to
use your subclass with no arguments.  The default just dies, but if you'd like
to change the default to import a tag merely return the tags you'd like to
import.  So the following will all work:

  sub default_import { ':log' }

  sub default_import { ':dlog' }

  sub default_import { qw(:dlog :log ) }

See L<Log::Contextual::Easy::Default> for an example of a subclass of
C<Log::Contextual> that makes use of default import options.

=head1 FUNCTIONS

=head2 set_logger

  my $logger = WarnLogger->new;
  set_logger $logger;

Arguments: L</LOGGER CODEREF>

C<set_logger> will just set the current logger to whatever you pass it.  It
expects a C<CodeRef>, but if you pass it something else it will wrap it in a
C<CodeRef> for you.  C<set_logger> is really meant only to be called from a
top-level script.  To avoid foot-shooting the function will warn if you call it
more than once.

=head2 with_logger

  my $logger = WarnLogger->new;
  with_logger $logger => sub {
    if (1 == 0) {
      log_fatal { 'Non Logical Universe Detected' };
    } else {
      log_info  { 'All is good' };
    }
  };

Arguments: L</LOGGER CODEREF>, C<CodeRef $to_execute>

C<with_logger> sets the logger for the scope of the C<CodeRef> C<$to_execute>.
As with L</set_logger>, C<with_logger> will wrap C<$returning_logger> with a
C<CodeRef> if needed.

=head2 has_logger

  my $logger = WarnLogger->new;
  set_logger $logger unless has_logger;

Arguments: none

C<has_logger> will return true if a logger has been set.

=head2 log_$level

Import Tag: C<:log>

Arguments: C<CodeRef $returning_message, @args>

C<log_$level> functions all work the same except that a different method
is called on the underlying C<$logger> object.  The basic pattern is:

  sub log_$level (&@) {
    if ($logger->is_$level) {
      $logger->$level(shift->(@_));
    }
    @_
  }

Note that the function returns its arguments.  This can be used in a number of
ways, but often it's convenient just for partial inspection of passthrough data

  my @friends = log_trace {
    'friends list being generated, data from first friend: ' .
      Dumper($_[0]->TO_JSON)
  } generate_friend_list();

If you want complete inspection of passthrough data, take a look at the
L</Dlog_$level> functions.

Which functions are exported depends on what was passed to L</-levels>.  The
default (no C<-levels> option passed) would export:

=over 2

=item log_trace

=item log_debug

=item log_info

=item log_warn

=item log_error

=item log_fatal

B<Note:> C<log_fatal> does not call C<die> for you, see L</EXCEPTIONS AND ERROR HANDLING>

=back

=head2 slog_$level

Mostly the same as L</log_$level>, but expects a string as first argument,
not a block. Arguments are passed through just the same, but since it's just a
string, interpolation of arguments into it must be done manually.

  my @friends = slog_trace 'friends list being generated.', generate_friend_list();

=head2 logS_$level

Import Tag: C<:log>

Arguments: C<CodeRef $returning_message, Item $arg>

This is really just a special case of the L</log_$level> functions.  It forces
scalar context when that is what you need.  Other than that it works exactly
same:

  my $friend = logS_trace {
    'I only have one friend: ' .  Dumper($_[0]->TO_JSON)
  } friend();

See also: L</DlogS_$level>.

=head2 slogS_$level

Mostly the same as L</logS_$level>, but expects a string as first argument,
not a block. Arguments are passed through just the same, but since it's just a
string, interpolation of arguments into it must be done manually.

  my $friend = slogS_trace 'I only have one friend.', friend();

=head2 Dlog_$level

Import Tag: C<:dlog>

Arguments: C<CodeRef $returning_message, @args>

All of the following six functions work the same as their L</log_$level>
brethren, except they return what is passed into them and put the stringified
(with L<Data::Dumper::Concise>) version of their args into C<$_>.  This means
you can do cool things like the following:

  my @nicks = Dlog_debug { "names: $_" } map $_->value, $frew->names->all;

and the output might look something like:

  names: "fREW"
  "fRIOUX"
  "fROOH"
  "fRUE"
  "fiSMBoC"

Which functions are exported depends on what was passed to L</-levels>.  The
default (no C<-levels> option passed) would export:

=over 2

=item Dlog_trace

=item Dlog_debug

=item Dlog_info

=item Dlog_warn

=item Dlog_error

=item Dlog_fatal

B<Note:> C<Dlog_fatal> does not call C<die> for you, see L</EXCEPTIONS AND ERROR HANDLING>

=back

=head2 Dslog_$level

Mostly the same as L</Dlog_$level>, but expects a string as first argument,
not a block. Arguments are passed through just the same, but since it's just a
string, no interpolation point can be used, instead the Dumper output is
appended.

  my @nicks = Dslog_debug "names: ", map $_->value, $frew->names->all;

=head2 DlogS_$level

Import Tag: C<:dlog>

Arguments: C<CodeRef $returning_message, Item $arg>

Like L</logS_$level>, these functions are a special case of L</Dlog_$level>.
They only take a single scalar after the C<$returning_message> instead of
slurping up (and also setting C<wantarray>) all the C<@args>

  my $pals_rs = DlogS_debug { "pals resultset: $_" }
    $schema->resultset('Pals')->search({ perlers => 1 });

=head2 DslogS_$level

Mostly the same as L</DlogS_$level>, but expects a string as first argument,
not a block. Arguments are passed through just the same, but since it's just a
string, no interpolation point can be used, instead the Dumper output is
appended.

  my $pals_rs = DslogS_debug "pals resultset: ",
    $schema->resultset('Pals')->search({ perlers => 1 });

=head1 LOGGER CODEREF

Anywhere a logger object can be passed, a coderef is accepted.  This is so
that the user can use different logger objects based on runtime information.
The logger coderef is passed the package of the caller, and the caller level the
coderef needs to use if it wants more caller information.  The latter is in
a hashref to allow for more options in the future.

Here is a basic example of a logger that exploits C<caller> to reproduce the
output of C<warn> with a logger:

  my @caller_info;
  my $var_log = Log::Contextual::SimpleLogger->new({
    levels  => [qw(trace debug info warn error fatal)],
    coderef => sub { chomp($_[0]); warn "$_[0] at $caller_info[1] line $caller_info[2].\n" }
  });
  my $warn_faker = sub {
    my ($package, $args) = @_;
    @caller_info = caller($args->{caller_level});
    $var_log
  };
  set_logger($warn_faker);
  log_debug { 'test' };

The following is an example that uses the information passed to the logger
coderef.  It sets the global logger to C<$l3>, the logger for the C<A1>
package to C<$l1>, except the C<lol> method in C<A1> which uses the C<$l2>
logger and lastly the logger for the C<A2> package to C<$l2>.

Note that it increases the caller level as it dispatches based on where
the caller of the log function, not the log function itself.

  my $complex_dispatcher = do {

    my $l1 = ...;
    my $l2 = ...;
    my $l3 = ...;

    my %registry = (
      -logger => $l3,
      A1 => {
        -logger => $l1,
        lol     => $l2,
      },
      A2 => { -logger => $l2 },
    );

    sub {
      my ( $package, $info ) = @_;

      my $logger = $registry{'-logger'};
      if (my $r = $registry{$package}) {
        $logger = $r->{'-logger'} if $r->{'-logger'};
        my (undef, undef, undef, $sub) = caller($info->{caller_level} + 1);
        $sub =~ s/^\Q$package\E:://g;
        $logger = $r->{$sub} if $r->{$sub};
      }
      return $logger;
    }
  };

  set_logger $complex_dispatcher;

=head1 LOGGER INTERFACE

Because this module is ultimately pretty looking glue (glittery?) with the
awesome benefit of the Contextual part, users will often want to make their
favorite logger work with it.  The following are the methods that should be
implemented in the logger:

  is_trace
  is_debug
  is_info
  is_warn
  is_error
  is_fatal
  trace
  debug
  info
  warn
  error
  fatal

The first six merely need to return true if that level is enabled.  The latter
six take the results of whatever the user returned from their coderef and log
them.  For a basic example see L<Log::Contextual::SimpleLogger>.

=head1 LOG ROUTING

=for Pod::Coverage router

In between the loggers and the log functions is a log router that is responsible for
finding a logger to handle the log event and passing the log information to the
logger. This relationship is described in the documentation for C<Log::Contextual::Role::Router>.

C<Log::Contextual> and packages that extend it will by default share a router singleton that
implements the with_logger() and set_logger() functions and also respects the -logger,
-package_logger, and -default_logger import options with their associated default value
functions. The router singleton is available as the return value of the router() function. Users
of Log::Contextual may overload router() to return instances of custom log routers that
could for example work with loggers that use a different interface.

=head1 EXCEPTIONS AND ERROR HANDLING

C<Log::Contextual>, by design, does not B<intentionally> invoke C<die> on your
behalf(L<*see footnote*|/footnote>) for C<log_fatal>.

Logging events are characterized as information, not flow control, and
conflating the two results in negative design anti-patterns.

As such, C<log_fatal> would at be better used to communicate information about a
I<future> failure, for example:

  if ( condition ) {
    log_fatal { "Bad Condition is true" };
    die My::Exception->new();
  }

This has a number of benefits:

=over 4

=item *

You're more likely to want to use useful Exception Objects and flow control
instead of cheating with log messages.

=item *

You're less likely to run a risk of losing what the actual problem was when some
error occurs in your creation of the Exception Object

=item *

You're less likely to run the risk of losing important log context due to
exceptions occurring mid way through C<die> unwinding and C<exit> global
destruction.

=back

If you're still too lazy to use exceptions, then you can do what you probably want
as follows:

  if ( ... ) {
    log_fatal { "Bad condition is true" };
    die "Bad condtion is true";
  }

Or for C<:dlog> style:

  use Data::Dumper::Consise qw( Dumper );
  if ( ... ) {
    # Dlog_fatal but not
    my $reason = "Bad condtion is true because: " . Dumper($thing);
    log_fatal { $reason };
    die $reason;
  }

=head2 footnote

The underlying behaviour of C<log_fatal> is dependent on the backing library.

All the Loggers shipping with C<Log::Contextual> behave this way, as do many of the supported
loggers, like C<Log::Log4perl>. However, not all loggers work this way, and one must be careful.

C<Log::Dispatch> doesn't support implementing C<log_fatal> L<at all|/-levels>

C<Log::Dispatchouli> implements C<log_fatal> using C<die> ( via Carp )

=head1 DESIGNER

mst - Matt S. Trout <mst@shadowcat.co.uk>

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/haarg/Log-Contextual/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 CONTRIBUTORS

=for stopwords Christian Walde Dan Book Florian Schlichtin Graham Knop Jakob Voss Karen Etheridge Kent Fredric Matt S Trout Peter Rabbitson Philippe Bruhat (BooK) Tyler Riddle Wes Malone

=over 4

=item *

Christian Walde <walde.christian@gmail.com>

=item *

Dan Book <grinnz@grinnz.com>

=item *

Florian Schlichtin <fsfs@debian.org>

=item *

Graham Knop <haarg@haarg.org>

=item *

Jakob Voss <voss@gbv.de>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Kent Fredric <kentfredric@gmail.com>

=item *

Matt S Trout <mst@shadowcat.co.uk>

=item *

Peter Rabbitson <ribasushi@cpan.org>

=item *

Philippe Bruhat (BooK) <book@cpan.org>

=item *

Tyler Riddle <t.riddle@shadowcat.co.uk>

=item *

Wes Malone <wes@mitsi.com>

=back

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
