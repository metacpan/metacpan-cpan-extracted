package Log::Contextual::WarnLogger;
use strict;
use warnings;

our $VERSION = '0.009001';

use Carp 'croak';

my @default_levels = qw( trace debug info warn error fatal );

# generate subs to handle the default levels
# anything else will have to be handled by AUTOLOAD at runtime
{
  for my $level (@default_levels) {

    no strict 'refs';

    my $is_name = "is_$level";
    *{$level} = sub {
      my $self = shift;

      $self->_log($level, @_)
        if $self->$is_name;
    };

    *{$is_name} = sub {
      my $self = shift;
      return 1 if $ENV{$self->{env_prefix} . '_' . uc $level};
      my $upto = $ENV{$self->{env_prefix} . '_UPTO'};
      return unless $upto;
      $upto = lc $upto;

      return $self->{level_num}{$level} >= $self->{level_num}{$upto};
    };
  }
}

our $AUTOLOAD;

sub AUTOLOAD {
  my $self = $_[0];

  (my $name = our $AUTOLOAD) =~ s/.*:://;
  return if $name eq 'DESTROY';

  # extract the log level from the sub name
  my ($is, $level) = $name =~ m/^(is_)?(.+)$/;
  my $is_name = "is_$level";

  no strict 'refs';
  *{$level} = sub {
    my $self = shift;

    $self->_log($level, @_)
      if $self->$is_name;
  };

  *{$is_name} = sub {
    my $self = shift;

    my $prefix_field = $self->{env_prefix} . '_' . uc $level;
    return 1 if $ENV{$prefix_field};

    # don't log if the variable specifically says not to
    return 0 if defined $ENV{$prefix_field} and not $ENV{$prefix_field};

    my $upto_field = $self->{env_prefix} . '_UPTO';
    my $upto       = $ENV{$upto_field};

    if ($upto) {
      $upto = lc $upto;

      croak "Unrecognized log level '$upto' in \$ENV{$upto_field}"
        if not defined $self->{level_num}{$upto};

      return $self->{level_num}{$level} >= $self->{level_num}{$upto};
    }

    # if we don't recognize this level and nothing says otherwise, log!
    return 1 if not $self->{custom_levels};
  };
  goto &$AUTOLOAD;
}

sub new {
  my ($class, $args) = @_;

  my $levels = $args->{levels};
  croak 'invalid levels specification: must be non-empty arrayref'
    if defined $levels and (ref $levels ne 'ARRAY' or !@$levels);

  my $custom_levels = defined $levels;
  $levels ||= [@default_levels];

  my %level_num;
  @level_num{@$levels} = (0 .. $#{$levels});

  my $self = bless {
    levels        => $levels,
    level_num     => \%level_num,
    custom_levels => $custom_levels,
  }, $class;

  $self->{env_prefix} = $args->{env_prefix}
    or die 'no env_prefix passed to Log::Contextual::WarnLogger->new';
  return $self;
}

sub _log {
  my $self    = shift;
  my $level   = shift;
  my $message = join("\n", @_);
  $message .= "\n" unless $message =~ /\n$/;
  warn "[$level] $message";
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Arthur Axel "fREW" Schmidt

=head1 NAME

Log::Contextual::WarnLogger - logger for libraries using Log::Contextual

=head1 VERSION

version 0.009001

=head1 SYNOPSIS

  package My::Package;
  use Log::Contextual::WarnLogger;
  use Log::Contextual qw( :log ),
    -default_logger => Log::Contextual::WarnLogger->new({
      env_prefix => 'MY_PACKAGE',
      levels => [ qw(debug info notice warning error critical alert emergency) ],
    });

  # warns '[info] program started' if $ENV{MY_PACKAGE_TRACE} is set
  log_info { 'program started' }; # no-op because info is not in levels
  sub foo {
    # warns '[debug] entered foo' if $ENV{MY_PACKAGE_DEBUG} is set
    log_debug { 'entered foo' };
    ...
  }

=head1 DESCRIPTION

This module is a simple logger made for libraries using L<Log::Contextual>.  We
recommend the use of this logger as your default logger as it is simple and
useful for most users, yet users can use L<Log::Contextual/set_logger> to override
your choice of logger in their own code thanks to the way L<Log::Contextual>
works.

=head1 METHODS

=head2 new

Arguments: C<< Dict[ env_prefix => Str, levels => List ] $conf >>

  my $l = Log::Contextual::WarnLogger->new({ env_prefix => 'BAR' });

or:

  my $l = Log::Contextual::WarnLogger->new({
    env_prefix => 'BAR',
    levels => [ 'level1', 'level2' ],
  });

Creates a new logger object where C<env_prefix> defines what the prefix is for
the environment variables that will be checked for the log levels.

The log levels may be customized, but if not defined, these are used:

=over 4

=item trace

=item debug

=item info

=item warn

=item error

=item fatal

=back

For example, if C<env_prefix> is set to C<FREWS_PACKAGE> the following environment
variables will be used:

  FREWS_PACKAGE_UPTO

  FREWS_PACKAGE_TRACE
  FREWS_PACKAGE_DEBUG
  FREWS_PACKAGE_INFO
  FREWS_PACKAGE_WARN
  FREWS_PACKAGE_ERROR
  FREWS_PACKAGE_FATAL

Note that C<UPTO> is a convenience variable.  If you set
C<< FOO_UPTO=TRACE >> it will enable all log levels.  Similarly, if you
set it to C<FATAL> only fatal will be enabled.

=head2 $level

Arguments: C<@anything>

All of the following six methods work the same.  The basic pattern is:

  sub $level {
    my $self = shift;

    warn "[$level] " . join qq{\n}, @_;
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

If different levels are specified, appropriate functions named for your custom
levels work as you expect.

B<Note:> C<fatal> does not call C<die> for you, see L<Log::Contextual/EXCEPTIONS AND ERROR HANDLING>

=head2 is_$level

All of the following six functions just return true if their respective
environment variable is enabled.

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

If different levels are specified, appropriate is_$level functions work as you
would expect.

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
