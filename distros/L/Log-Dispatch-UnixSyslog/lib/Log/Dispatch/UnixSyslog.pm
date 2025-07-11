use v5.20.0;
use warnings;
package Log::Dispatch::UnixSyslog 0.004;

use parent qw(Log::Dispatch::Output);
# ABSTRACT: log events to syslog with Unix::Syslog

use Log::Dispatch 2.0 ();
use Unix::Syslog;

#pod =head1 SYNOPSIS
#pod
#pod   use Log::Dispatch;
#pod   use Log::Dispatch::UnixSyslog;
#pod
#pod   my $log = Log::Dispatch->new;
#pod
#pod   $log->add(
#pod     Log::Dispatch::UnixSyslog->new(
#pod       ident => 'super-cool-daemon',
#pod       min_level => 'debug',
#pod       flush_if  => sub { (shift)->event_count >= 60 },
#pod     )
#pod   );
#pod
#pod   while (@events) {
#pod     $log->warn($_);
#pod   }
#pod
#pod =head1 DESCRIPTION
#pod
#pod This provides a Log::Dispatch log output plugin that sends things to syslog.
#pod "But there's already Log::Dispatch:Syslog!" you cry.  Well, that uses
#pod Sys::Syslog, which is core, but it's overcomplicated and inefficient, too.
#pod This plugin uses Unix::Syslog, which does a lot less, and should be more
#pod efficient at doing it.
#pod
#pod =method new
#pod
#pod  my $output = Log::Dispatch::UnixSyslog->new(\%arg);
#pod
#pod This method constructs a new Log::Dispatch::UnixSyslog output object.  In
#pod addition to the standard parameters documented in L<Log::Dispatch::Output>,
#pod this takes the following arguments:
#pod
#pod   ident     - a string to prepend to all messages in the system log; required
#pod   facility  - which syslog facility to log to (as a string); required
#pod   logopt    - the numeric value of the openlog options parameter; (default: 0)
#pod
#pod =cut

my %IS_FACILITY = map {; $_ => 1 } qw(
  auth    authpriv    cron    daemon
  ftp     kern        lpr     mail
  news    security    syslog  user
  uucp
  local0  local1      local2  local3
  local4  local5      local6  local7
);

sub new {
  my ($class, %arg) = @_;

  Carp::croak('required parameter "ident" empty or undefined')
    unless length $arg{ident};

  Carp::croak('required parameter "facility" not defined')
    unless defined $arg{facility};

  Carp::croak('provided facility value is not a valid syslog facility')
    unless $IS_FACILITY{ $arg{facility} };

  my $const_name = "LOG_\U$arg{facility}";

  Carp::croak('provided facility value is valid but unknown?!')
    unless my $const = Unix::Syslog->can($const_name);

  my $self = {
    ident     => $arg{ident},
    facility  => scalar $const->(),
    logopt    => $arg{logopt} // 0,
  };

  bless $self => $class;

  # this is our duty as a well-behaved Log::Dispatch plugin
  $self->_basic_init(%arg);

  return $self;
}

sub _maybe_openlog {
  my ($self) = @_;

  return if $self->{_opened_in_pid} && $self->{_opened_in_pid} == $$;

  # hand wringing: What if someone is re-openlog-ing after this?  Well, they
  # ought not to do that!  We could re-open every time, but let's just see how
  # this goes, for now. -- rjbs, 2020-08-11
  Unix::Syslog::openlog($self->{ident}, $self->{logopt}, $self->{facility});
  $self->{_opened_in_pid} = $$;

  return;
}

#pod =method log_message
#pod
#pod This is the method which performs the actual logging, as detailed by
#pod Log::Dispatch::Output.
#pod
#pod =cut

sub log_message {
  my ($self, %p) = @_;

  # In syslog, emergency is 0 and debug is 7.  In Log::Dispatch, it is the
  # reverse.  Bah. -- rjbs, 2020-08-11
  my $sys_level = 7 - $self->_level_as_number($p{level});
  my $priority  = $sys_level | $self->{facility};

  $self->_maybe_openlog;
  Unix::Syslog::syslog($priority, '%s', $p{message});

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::UnixSyslog - log events to syslog with Unix::Syslog

=head1 VERSION

version 0.004

=head1 SYNOPSIS

  use Log::Dispatch;
  use Log::Dispatch::UnixSyslog;

  my $log = Log::Dispatch->new;

  $log->add(
    Log::Dispatch::UnixSyslog->new(
      ident => 'super-cool-daemon',
      min_level => 'debug',
      flush_if  => sub { (shift)->event_count >= 60 },
    )
  );

  while (@events) {
    $log->warn($_);
  }

=head1 DESCRIPTION

This provides a Log::Dispatch log output plugin that sends things to syslog.
"But there's already Log::Dispatch:Syslog!" you cry.  Well, that uses
Sys::Syslog, which is core, but it's overcomplicated and inefficient, too.
This plugin uses Unix::Syslog, which does a lot less, and should be more
efficient at doing it.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 METHODS

=head2 new

 my $output = Log::Dispatch::UnixSyslog->new(\%arg);

This method constructs a new Log::Dispatch::UnixSyslog output object.  In
addition to the standard parameters documented in L<Log::Dispatch::Output>,
this takes the following arguments:

  ident     - a string to prepend to all messages in the system log; required
  facility  - which syslog facility to log to (as a string); required
  logopt    - the numeric value of the openlog options parameter; (default: 0)

=head2 log_message

This is the method which performs the actual logging, as detailed by
Log::Dispatch::Output.

=head1 AUTHOR

Ricardo SIGNES <cpan@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Ricardo Signes

=over 4

=item *

Ricardo Signes <rjbs@semiotic.systems>

=item *

Ricardo Signes <rjbs@users.noreply.github.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
