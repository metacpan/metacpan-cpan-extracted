package Log::Contextual::SimpleLogger;
use strict;
use warnings;

our $VERSION = '0.009001';

{
  for my $name (qw( trace debug info warn error fatal )) {

    no strict 'refs';

    *{$name} = sub {
      my $self = shift;

      $self->_log($name, @_)
        if ($self->{$name});
    };

    *{"is_$name"} = sub {
      my $self = shift;
      return $self->{$name};
    };
  }
}

sub new {
  my ($class, $args) = @_;
  my $self = bless {}, $class;

  $self->{$_} = 1 for @{$args->{levels}};
  $self->{coderef} = $args->{coderef} || sub { print STDERR @_ };

  if (my $upto = $args->{levels_upto}) {

    my @levels = (qw( trace debug info warn error fatal ));
    my $i      = 0;
    for (@levels) {
      last if $upto eq $_;
      $i++
    }
    for ($i .. $#levels) {
      $self->{$levels[$_]} = 1
    }

  }
  return $self;
}

sub _log {
  my $self    = shift;
  my $level   = shift;
  my $message = join("\n", @_);
  $message .= "\n" unless $message =~ /\n$/;
  $self->{coderef}->(sprintf("[%s] %s", $level, $message));
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Arthur Axel "fREW" Schmidt

=head1 NAME

Log::Contextual::SimpleLogger - Super simple logger made for playing with Log::Contextual

=head1 VERSION

version 0.009001

=head1 SYNOPSIS

  use Log::Contextual::SimpleLogger;
  use Log::Contextual qw( :log ),
    -logger => Log::Contextual::SimpleLogger->new({ levels => [qw( debug )]});

  log_info { 'program started' }; # no-op because info is not in levels
  sub foo {
    log_debug { 'entered foo' };
    ...
  }

=head1 DESCRIPTION

This module is a simple logger made mostly for demonstration and initial
experimentation with L<Log::Contextual>.  We recommend you use a real logger
instead.  For something more serious but not overly complicated, take a look at
L<Log::Dispatchouli>.

=head1 METHODS

=head2 new

Arguments: C<< Dict[
  levels      => Optional[ArrayRef[Str]],
  levels_upto => Level,
  coderef     => Optional[CodeRef],
] $conf >>

  my $l = Log::Contextual::SimpleLogger->new({
    levels  => [qw( info warn )],
    coderef => sub { print @_ }, # the default prints to STDERR
  });

or

  my $l = Log::Contextual::SimpleLogger->new({
    levels_upto => 'debug',
    coderef     => sub { print @_ }, # the default prints to STDERR
  });

Creates a new SimpleLogger object with the passed levels enabled and optionally
a C<CodeRef> may be passed to modify how the logs are output/stored.

C<levels_upto> enables all the levels up to and including the level passed.

Levels may contain:

  trace
  debug
  info
  warn
  error
  fatal

=head2 $level

Arguments: C<@anything>

All of the following six methods work the same.  The basic pattern is:

  sub $level {
    my $self = shift;

    print STDERR "[$level] " . join qq{\n}, @_;
      if $self->is_$level;
  }

=head3 trace

  $l->trace( 'entered method foo with args ' join q{,}, @args );

=head3 debug

  $l->debug( 'entered method foo' );

=head3 info

  $l->info( 'started process foo' );

=head3 warn

  $l->warn( 'possible misconfiguration at line 10' );

=head3 error

  $l->error( 'non-numeric user input!' );

=head3 fatal

  $l->fatal( '1 is never equal to 0!' );

B<Note:> C<fatal> does not call C<die> for you, see L<Log::Contextual/EXCEPTIONS AND ERROR HANDLING>

=head2 is_$level

All of the following six functions just return true if their respective
level is enabled.

=head3 is_trace

  say 'tracing' if $l->is_trace;

=head3 is_debug

  say 'debuging' if $l->is_debug;

=head3 is_info

  say q{info'ing} if $l->is_info;

=head3 is_warn

  say 'warning' if $l->is_warn;

=head3 is_error

  say 'erroring' if $l->is_error;

=head3 is_fatal

  say q{fatal'ing} if $l->is_fatal;

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/haarg/Log-Contextual/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
