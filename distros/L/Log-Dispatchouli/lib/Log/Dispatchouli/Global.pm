use strict;
use warnings;
package Log::Dispatchouli::Global;
# ABSTRACT: a system for sharing a global, dynamically-scoped logger
$Log::Dispatchouli::Global::VERSION = '2.015';
use Carp ();
use Log::Dispatchouli;
use Scalar::Util ();

use Sub::Exporter::GlobExporter 0.002 qw(glob_exporter); # pass-through args
use Sub::Exporter -setup => {
  collectors => {
    '$Logger' => glob_exporter(Logger => \'_build_logger'),
  },
};

#pod =head1 DESCRIPTION
#pod
#pod B<Warning>: This interface is still experimental.
#pod
#pod Log::Dispatchouli::Global is a framework for a global logger object. In your
#pod top-level programs that are actually executed, you'd add something like this:
#pod
#pod   use Log::Dispatchouli::Global '$Logger' => {
#pod     init => {
#pod       ident     => 'My::Daemon',
#pod       facility  => 'local2',
#pod       to_stdout => 1,
#pod     },
#pod   };
#pod
#pod This will import a C<$Logger> into your program, and more importantly will
#pod initialize it with a new L<Log::Dispatchouli> object created by passing the
#pod value for the C<init> parameter to Log::Dispatchouli's C<new> method.
#pod
#pod Much of the rest of your program, across various libraries, can then just use
#pod this:
#pod
#pod   use Log::Dispatchouli::Global '$Logger';
#pod
#pod   sub whatever {
#pod     ...
#pod
#pod     $Logger->log("about to do something");
#pod
#pod     local $Logger = $Logger->proxy({ proxy_prefix => "whatever: " });
#pod
#pod     for (@things) {
#pod       $Logger->log([ "doing thing %s", $_ ]);
#pod       ...
#pod     }
#pod   }
#pod
#pod This eliminates the need to pass around what is effectively a global, while
#pod still allowing it to be specialized within certain contexts of your program.
#pod
#pod B<Warning!>  Although you I<could> just use Log::Dispatchouli::Global as your
#pod shared logging library, you almost I<certainly> want to write a subclass that
#pod will only be shared amongst your application's classes.
#pod Log::Dispatchouli::Global is meant to be subclassed and shared only within
#pod controlled systems.  Remember, I<sharing your state with code you don't
#pod control is dangerous>.
#pod
#pod =head1 USING
#pod
#pod In general, you will either be using a Log::Dispatchouli::Global class to get
#pod a C<$Logger> or to initialize it (and then get C<$Logger>).  These are both
#pod demonstrated above.  Also, when importing C<$Logger> you may request it be
#pod imported under a different name:
#pod
#pod   use Log::Dispatchouli::Global '$Logger' => { -as => 'L' };
#pod
#pod   $L->log( ... );
#pod
#pod There is only one class method that you are likely to use: C<current_logger>.
#pod This provides the value of the shared logger from the caller's context,
#pod initializing it to a default if needed.  Even this method is unlikely to be
#pod required frequently, but it I<does> allow users to I<see> C<$Logger> without
#pod importing it.
#pod
#pod =head1 SUBCLASSING
#pod
#pod Before using Log::Dispatchouli::Global in your application, you should subclass
#pod it.  When you subclass it, you should provide the following methods:
#pod
#pod =head2 logger_globref
#pod
#pod This method should return a globref in which the shared logger will be stored.
#pod Subclasses will be in their own package, so barring any need for cleverness,
#pod every implementation of this method can look like the following:
#pod
#pod   sub logger_globref { no warnings 'once'; return \*Logger }
#pod
#pod =cut

sub logger_globref {
  no warnings 'once';
  \*Logger;
}

sub current_logger {
  my ($self) = @_;

  my $globref = $self->logger_globref;

  unless (defined $$$globref) {
    $$$globref = $self->default_logger;
  }

  return $$$globref;
}

#pod =head2 default_logger
#pod
#pod If no logger has been initialized, but something tries to log, it gets the
#pod default logger, created by calling this method.
#pod
#pod The default implementation calls C<new> on the C<default_logger_class> with the
#pod result of C<default_logger_args> as the arguments.
#pod
#pod =cut

sub default_logger {
  my ($self) = @_;

  my $ref = $self->default_logger_ref;

  $$ref ||= $self->default_logger_class->new(
    $self->default_logger_args
  );
}

#pod =head2 default_logger_class
#pod
#pod This returns the class on which C<new> will be called when initializing a
#pod logger, either from the C<init> argument when importing or the default logger.
#pod
#pod Its default value is Log::Dispatchouli.
#pod
#pod =cut

sub default_logger_class { 'Log::Dispatchouli' }

#pod =head2 default_logger_args
#pod
#pod If no logger has been initialized, but something tries to log, it gets the
#pod default logger, created by calling C<new> on the C<default_logger_class> and
#pod passing the results of calling this method.
#pod
#pod Its default return value creates a sink, so that anything logged without an
#pod initialized logger is lost.
#pod
#pod =cut

sub default_logger_args {
  return {
    ident     => "default/$0",
    facility  => undef,
  }
}

#pod =head2 default_logger_ref
#pod
#pod This method returns a scalar reference in which the cached default value is
#pod stored for comparison.  This is used when someone tries to C<init> the global.
#pod When someone tries to initialize the global logger, and it's already set, then:
#pod
#pod =for :list
#pod * if the current value is the same as the default, the new value is set
#pod * if the current value is I<not> the same as the default, we die
#pod
#pod Since you want the default to be isolated to your application's logger, the
#pod default behavior is default loggers are associated with the glob reference to
#pod which the default might be assigned.  It is unlikely that you will need to
#pod interact with this method.
#pod
#pod =cut

my %default_logger_for_glob;

sub default_logger_ref {
  my ($self) = @_;

  my $glob = $self->logger_globref;
  my $addr = Scalar::Util::refaddr($glob);
  return \$default_logger_for_glob{ $addr };
}

sub _equiv {
  my ($self, $x, $y) = @_;

  return 1 if Scalar::Util::refaddr($x) == Scalar::Util::refaddr($y);
  return 1 if $x->config_id eq $y->config_id;
  return
}

sub _build_logger {
  my ($self, $arg) = @_;

  my $globref = $self->logger_globref;
  my $default = $self->default_logger;

  my $Logger  = $$$globref;

  if ($arg and $arg->{init}) {
    my $new_logger = $self->default_logger_class->new($arg->{init});

    if ($Logger
      and not(
        $self->_equiv($Logger, $new_logger)
        or
        $self->_equiv($Logger, $default)
      )
    ) {
      # We already set up a logger, so we'll check that our new one is
      # equivalent to the old.  If so, we'll keep the old, since it's good
      # enough.  If not, we'll raise an exception: you can't configure the
      # logger twice, with different configurations, in one program!
      # -- rjbs, 2011-01-21
      my $old = $Logger->config_id;
      my $new = $new_logger->config_id;

      Carp::confess(sprintf(
        "attempted to initialize %s logger twice; old config %s, new config %s",
        $self,
        $old,
        $new,
      ));
    }

    $$$globref = $new_logger;
  } else {
    $$$globref ||= $default;
  }

  return $globref;
}

#pod =head1 COOKBOOK
#pod
#pod =head2 Common Logger Recipes
#pod
#pod Say you often use the same configuration for one kind of program, like
#pod automated tests.  You've already written your own subclass to get your own
#pod storage and defaults, maybe C<MyApp::Logger>.
#pod
#pod You can't just write a subclass with a different default, because if another
#pod class using the same global has set the global with I<its> default, yours won't
#pod be honored.  You don't just want this new value to be the default, you want it
#pod to be I<the> logger.  What you want to do in this case is to initialize your
#pod logger normally, then reexport it, like this:
#pod
#pod   package MyApp::Logger::Test;
#pod   use parent 'MyApp::Logger';
#pod
#pod   use MyApp::Logger '$Logger' => {
#pod     init => {
#pod       ident    => "Tester($0)",
#pod       to_self  => 1,
#pod       facility => undef,
#pod     },
#pod   };
#pod
#pod This will set up the logger and re-export it, and will properly die if anything
#pod else attempts to initialize the logger to something else.
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatchouli::Global - a system for sharing a global, dynamically-scoped logger

=head1 VERSION

version 2.015

=head1 DESCRIPTION

B<Warning>: This interface is still experimental.

Log::Dispatchouli::Global is a framework for a global logger object. In your
top-level programs that are actually executed, you'd add something like this:

  use Log::Dispatchouli::Global '$Logger' => {
    init => {
      ident     => 'My::Daemon',
      facility  => 'local2',
      to_stdout => 1,
    },
  };

This will import a C<$Logger> into your program, and more importantly will
initialize it with a new L<Log::Dispatchouli> object created by passing the
value for the C<init> parameter to Log::Dispatchouli's C<new> method.

Much of the rest of your program, across various libraries, can then just use
this:

  use Log::Dispatchouli::Global '$Logger';

  sub whatever {
    ...

    $Logger->log("about to do something");

    local $Logger = $Logger->proxy({ proxy_prefix => "whatever: " });

    for (@things) {
      $Logger->log([ "doing thing %s", $_ ]);
      ...
    }
  }

This eliminates the need to pass around what is effectively a global, while
still allowing it to be specialized within certain contexts of your program.

B<Warning!>  Although you I<could> just use Log::Dispatchouli::Global as your
shared logging library, you almost I<certainly> want to write a subclass that
will only be shared amongst your application's classes.
Log::Dispatchouli::Global is meant to be subclassed and shared only within
controlled systems.  Remember, I<sharing your state with code you don't
control is dangerous>.

=head1 USING

In general, you will either be using a Log::Dispatchouli::Global class to get
a C<$Logger> or to initialize it (and then get C<$Logger>).  These are both
demonstrated above.  Also, when importing C<$Logger> you may request it be
imported under a different name:

  use Log::Dispatchouli::Global '$Logger' => { -as => 'L' };

  $L->log( ... );

There is only one class method that you are likely to use: C<current_logger>.
This provides the value of the shared logger from the caller's context,
initializing it to a default if needed.  Even this method is unlikely to be
required frequently, but it I<does> allow users to I<see> C<$Logger> without
importing it.

=head1 SUBCLASSING

Before using Log::Dispatchouli::Global in your application, you should subclass
it.  When you subclass it, you should provide the following methods:

=head2 logger_globref

This method should return a globref in which the shared logger will be stored.
Subclasses will be in their own package, so barring any need for cleverness,
every implementation of this method can look like the following:

  sub logger_globref { no warnings 'once'; return \*Logger }

=head2 default_logger

If no logger has been initialized, but something tries to log, it gets the
default logger, created by calling this method.

The default implementation calls C<new> on the C<default_logger_class> with the
result of C<default_logger_args> as the arguments.

=head2 default_logger_class

This returns the class on which C<new> will be called when initializing a
logger, either from the C<init> argument when importing or the default logger.

Its default value is Log::Dispatchouli.

=head2 default_logger_args

If no logger has been initialized, but something tries to log, it gets the
default logger, created by calling C<new> on the C<default_logger_class> and
passing the results of calling this method.

Its default return value creates a sink, so that anything logged without an
initialized logger is lost.

=head2 default_logger_ref

This method returns a scalar reference in which the cached default value is
stored for comparison.  This is used when someone tries to C<init> the global.
When someone tries to initialize the global logger, and it's already set, then:

=over 4

=item *

if the current value is the same as the default, the new value is set

=item *

if the current value is I<not> the same as the default, we die

=back

Since you want the default to be isolated to your application's logger, the
default behavior is default loggers are associated with the glob reference to
which the default might be assigned.  It is unlikely that you will need to
interact with this method.

=head1 COOKBOOK

=head2 Common Logger Recipes

Say you often use the same configuration for one kind of program, like
automated tests.  You've already written your own subclass to get your own
storage and defaults, maybe C<MyApp::Logger>.

You can't just write a subclass with a different default, because if another
class using the same global has set the global with I<its> default, yours won't
be honored.  You don't just want this new value to be the default, you want it
to be I<the> logger.  What you want to do in this case is to initialize your
logger normally, then reexport it, like this:

  package MyApp::Logger::Test;
  use parent 'MyApp::Logger';

  use MyApp::Logger '$Logger' => {
    init => {
      ident    => "Tester($0)",
      to_self  => 1,
      facility => undef,
    },
  };

This will set up the logger and re-export it, and will properly die if anything
else attempts to initialize the logger to something else.

=head1 AUTHOR

Ricardo SIGNES <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
