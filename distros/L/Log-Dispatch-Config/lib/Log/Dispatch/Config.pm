package Log::Dispatch::Config;

use strict;
use vars qw($VERSION);
$VERSION = "1.04";

use Log::Dispatch 2.00;
use base qw(Log::Dispatch);

# caller depth: can be changed from outside
$Log::Dispatch::Config::CallerDepth = 0;

sub _croak { require Carp; Carp::croak(@_); }

# accessor for symblic reference
sub __instance {
    my $class = shift;
    no strict 'refs';
    my $instance = "$class\::_instance";
    $$instance = shift if @_;
    return $$instance;
}

sub _configurator_for {
    my($class, $stuff) = @_;
    return $stuff if UNIVERSAL::isa($stuff, 'Log::Dispatch::Configurator');
    require Log::Dispatch::Configurator::AppConfig;
    return Log::Dispatch::Configurator::AppConfig->new($stuff);
}

sub configure {
    my($class, $stuff) = @_;
    _croak "no config file or configurator supplied" unless $stuff;
    my $config = $class->_configurator_for($stuff);
    $config->myinit;
    $class->__instance($config);
}

sub configure_and_watch {
    my $class = shift;
    $class->configure(@_);
    $class->__instance->should_watch(1); # tells conf to watch config file
}

# backward compatibility
sub Log::Dispatch::instance { __PACKAGE__->instance; }

sub instance {
    my $class = shift;

    my $instance = $class->__instance or _croak "configure not yet called.";
    if ($instance->isa('Log::Dispatch::Config')) {
        # reload singleton on the fly
	$class->reload if $instance->needs_reload;
    }
    else {
        # first time call: $_instance is L::D::Configurator::*
	$class->__instance($class->create_instance($instance));
    }
    return $class->__instance;
}

sub needs_reload {
    my $self = shift;
    return $self->{config}->should_watch && $self->{config}->needs_reload;
}

sub reload {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $instance = $class->__instance;
    $instance->{config}->reload;
    $class->__instance($class->create_instance($instance->{config}));
}

sub create_instance {
    my($class, $config) = @_;
    $config->{LDC_ctime} = time;	# creation time

    my $global = $config->get_attrs_global;
    my $callback = $class->format_to_cb($global->{format}, 0);
    my %dispatchers;
    foreach my $disp (@{$global->{dispatchers}}) {
        $dispatchers{$disp} = $class->config_dispatcher(
	    $disp, $config->get_attrs($disp),
	);
    }
    my %args;
    $args{callbacks} = $callback if defined $callback;
    my $instance = $class->new(%args);

    for my $dispname (keys %dispatchers) {
	my $logclass = delete $dispatchers{$dispname}->{class};
	$instance->add(
	    $logclass->new(
		name => $dispname,
		%{$dispatchers{$dispname}},
	    ),
	);
    }

    $instance->{config} = $config;
    return $instance;
}

sub config_dispatcher {
    my($class, $disp, $var) = @_;

    my $dispclass = $var->{class} or _croak "class param missing for $disp";

    eval qq{require $dispclass};
    _croak $@ if $@ && $@ !~ /locate/;

    if (exists $var->{format}) {
        $var->{callbacks} = $class->format_to_cb(delete $var->{format}, 2);
    }
    return $var;
}

sub format_to_cb {
    my($class, $format, $stack) = @_;
    return undef unless defined $format;

    # caller() called only when necessary
    my $needs_caller = $format =~ /%[FLP]/;
    return sub {
	my %p = @_;
	$p{p} = delete $p{level};
	$p{m} = delete $p{message};
	$p{n} = "\n";
	$p{'%'} = '%';

 	if ($needs_caller) {
	    my $depth = 0;
	    $depth++ while caller($depth) =~ /^Log::Dispatch/;
 	    $depth += $Log::Dispatch::Config::CallerDepth;
 	    @p{qw(P F L)} = caller($depth);
 	}

	my $log = $format;
	$log =~ s{
	    (%d(?:{(.*?)})?)|	# $1: datetime $2: datetime fmt
	    (?:%([%pmFLPn]))	# $3: others
	}{
	    if ($1 && $2) {
		_strftime($2);
	    }
	    elsif ($1) {
		scalar localtime;
	    }
	    elsif ($3) {
		$p{$3};
	    }
	}egx;
	return $log;
    };
}

{
    use vars qw($HasTimePiece);
    BEGIN { eval { require Time::Piece; $HasTimePiece = 1 }; }

    sub _strftime {
	my $fmt = shift;
	if ($HasTimePiece) {
	    return Time::Piece->new->strftime($fmt);
	} else {
	    require POSIX;
	    return POSIX::strftime($fmt, localtime);
	}
    }
}

1;
__END__

=head1 NAME

Log::Dispatch::Config - Log4j for Perl

=head1 SYNOPSIS

  use Log::Dispatch::Config;
  Log::Dispatch::Config->configure('/path/to/log.conf');

  my $dispatcher = Log::Dispatch::Config->instance;
  $dispatcher->debug('this is debug message');
  $dispatcher->emergency('something *bad* happened!');

  # automatic reloading conf file, when modified
  Log::Dispatch::Config->configure_and_watch('/path/to/log.conf');

  # or if you write your own config parser:
  use Log::Dispatch::Configurator::XMLSimple;

  my $config = Log::Dispatch::Configurator::XMLSimple->new('log.xml');
  Log::Dispatch::Config->configure($config);

=head1 DESCRIPTION

Log::Dispatch::Config is a subclass of Log::Dispatch and provides a
way to configure Log::Dispatch object with configulation file
(default, in AppConfig format). I mean, this is log4j for Perl, not
with all API compatibility though.

=head1 METHOD

This module has a class method C<configure> which parses config file
for later creation of the Log::Dispatch::Config singleton instance.
(Actual construction of the object is done in the first C<instance>
call).

So, what you should do is call C<configure> method once in somewhere
(like C<startup.pl> in mod_perl), then you can get configured
dispatcher instance via C<Log::Dispatch::Config-E<gt>instance>.

=head1 CONFIGURATION

Here is an example of the config file:

  dispatchers = file screen

  file.class = Log::Dispatch::File
  file.min_level = debug
  file.filename = /path/to/log
  file.mode = append
  file.format = [%d] [%p] %m at %F line %L%n

  screen.class = Log::Dispatch::Screen
  screen.min_level = info
  screen.stderr = 1
  screen.format = %m

In this example, config file is written in AppConfig format. See
L<Log::Dispatch::Configurator::AppConfig> for details.

See L</"PLUGGABLE CONFIGURATOR"> for other config parsing scheme.

=head2 GLOBAL PARAMETERS

=over 4

=item dispatchers

  dispatchers = file screen

C<dispatchers> defines logger names, which will be splitted by spaces.
If this parameter is unset, no logging is done.

=item format

  format = [%d] [%p] %m at %F line %L%n

C<format> defines log format. Possible conversions format are

  %d	datetime string (ctime(3))
  %p	priority (debug, info, warning ...)
  %m	message string
  %F	filename
  %L	line number
  %P	package
  %n	newline (\n)
  %%	% itself

Note that datetime (%d) format is configurable by passing C<strftime>
fmt in braket after %d. (I know it looks quite messy, but its
compatible with Java Log4j ;)

  format = [%d{%Y%m%d}] %m  # datetime is now strftime "%Y%m%d"

If you have Time::Piece, this module uses its C<strftime>
implementation, otherwise POSIX.

C<format> defined here would apply to all the log messages to
dispatchers. This parameter is B<optional>.

See L</"CALLER STACK"> for details about package, line number and
filename.

=back

=head2 PARAMETERS FOR EACH DISPATCHER

Parameters for each dispatcher should be prefixed with "name.", where
"name" is the name of each one, defined in global C<dispatchers>
parameter.

You can also use C<.ini> style grouping like:

  [foo]
  class = Log::Dispatch::File
  min_level = debug

See L<Log::Dispatch::Configurator::AppConfig> for details.

=over 4

=item class

  screen.class = Log::Dispatch::Screen

C<class> defines class name of Log::Dispatch subclasses. This
parameter is B<essential>.

=item format

  screen.format = -- %m --

C<format> defines log format which would be applied only to the
dispatcher. Note that if you define global C<format> also, C<%m> is
double formated (first global one, next each dispatcher one). This
parameter is B<optional>.

=item (others)

  screen.min_level = info
  screen.stderr = 1

Other parameters would be passed to the each dispatcher
construction. See Log::Dispatch::* manpage for the details.

=back

=head1 SINGLETON

Declared C<instance> method would make C<Log::Dispatch::Config> class
singleton, so multiple calls of C<instance> will all result in
returning same object.

  my $one = Log::Dispatch::Config->instance;
  my $two = Log::Dispatch::Config->instance; # same as $one

See GoF Design Pattern book for Singleton Pattern.

But in practice, in persistent environment like mod_perl, lifetime of
Singleton instance becomes sometimes messy. If you want to reload
singleton object manually, call C<reload> method.

  Log::Dispatch::Config->reload;

And, if you want to reload object on the fly, as you edit C<log.conf>
or something like that, what you should do is to call
C<configure_and_watch> method on Log::Dispatch::Config instead of
C<configure>. Then C<instance> call will check mtime of configuration
file, and compares it with instanciation time of singleton object. If
config file is newer than last instanciation, it will automatically
reload object.

=head1 NAMESPACE COLLISION

If you use Log::Dispatch::Config in multiple projects on the same perl
interpreter (like mod_perl), namespace collision would be a
problem. Bizzare thing will happen when you call
C<Log::Dispatch::Config-E<gt>configure> multiple times with differenct
argument.

In such cases, what you should do is to define your own logger class.

  package My::Logger;
  use Log::Dispatch::Config;
  use base qw(Log::Dispatch::Config);

Or make wrapper for it. See L<POE::Component::Logger> implementation
by Matt Sergeant.

=head1 PLUGGABLE CONFIGURATOR

If you pass filename to C<configure> method call, this module handles
the config file with AppConfig. You can change config parsing scheme
by passing another pluggable configurator object.

Here is a way to declare new configurator class. The example below is
hardwired version equivalent to the one above in L</"CONFIGURATION">.

=over 4

=item *

Inherit from Log::Dispatch::Configurator.

  package Log::Dispatch::Configurator::Hardwired;
  use base qw(Log::Dispatch::Configurator);

Declare your own C<new> constructor. Stub C<new> method is defined in
Configurator base class, but you want to put parsing method in your
own constructor. In this example, we just bless reference. Note that
your object should be blessed hash.

  sub new { bless {}, shift }

=item *

Implement two required object methods C<get_attrs_global> and
C<get_attrs>.

C<get_attrs_global> should return hash reference of global parameters.
C<dispatchers> should be an array reference of names of dispatchers.

  sub get_attrs_global {
      my $self = shift;
      return {
          format => undef,
          dispatchers => [ qw(file screen) ],
      };
  }

C<get_attrs> accepts name of a dispatcher and should return hash
reference of parameters associated with the dispatcher.

  sub get_attrs {
      my($self, $name) = @_;
      if ($name eq 'file') {
          return {
              class     => 'Log::Dispatch::File',
              min_level => 'debug',
              filename  => '/path/to/log',
              mode      => 'append',
              format  => '[%d] [%p] %m at %F line %L%n',
          };
      }
      elsif ($name eq 'screen') {
          return {
	      class     => 'Log::Dispatch::Screen',
	      min_level => 'info',
	      stderr    => 1,
	      format  => '%m',
	  };
      }
      else {
	  die "invalid dispatcher name: $name";
      }
  }

=item *

Implement optional C<needs_reload> and C<reload>
methods. C<needs_reload> should return boolean value if the object is
stale and needs reloading itself. This method will be triggered when
you configure logging object with C<configure_and_watch> method.

Stub config file mtime based C<needs_reload> method is declared in
Log::Dispatch::Configurator, so if your config class is based on
filesystem files, you do not need to reimplement this.

If you do not need I<singleton-ness> at all, always return true.

  sub needs_reload { 1 }

C<reload> method should redo parsing of the config file. Configurator
base class has a stub null C<reload> method, so you should better
override it.

See Log::Dispatch::Configurator::AppConfig source code for details.

=item *

That's all. Now you can plug your own configurator (Hardwired) into
Log::Dispatch::Config. What you should do is to pass configurator
object to C<configure> method call instead of config file name.

  use Log::Dispatch::Config;
  use Log::Dispatch::Configurator::Hardwired;

  my $config = Log::Dispatch::Configurator::Hardwired->new;
  Log::Dispatch::Config->configure($config);

=back

=head1 CALLER STACK

When you call logging method from your subroutines / methods, caller
stack would increase and thus you can't see where the log really comes
from.

  package Logger;
  my $Logger = Log::Dispatch::Config->instance;

  sub logit {
      my($class, $level, $msg) = @_;
      $Logger->$level($msg);
  }

  package main;
  Logger->logit('debug', 'foobar');

You can adjust package variable C<$Log::Dispatch::Config::CallerDepth>
to increase the caller stack depth. The default value is 0.

  sub logit {
      my($class, $level, $msg) = @_;
      local $Log::Dispatch::Config::CallerDepth = 1;
      $Logger->$level($msg);
  }

Note that your log caller's namespace should not match against
C</^Log::Dispatch/>, which makes this module confusing.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt> with much help from
Matt Sergeant E<lt>matt@sergeant.orgE<gt>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Log::Dispatch::Configurator::AppConfig>, L<Log::Dispatch>,
L<AppConfig>, L<POE::Component::Logger>

=cut
