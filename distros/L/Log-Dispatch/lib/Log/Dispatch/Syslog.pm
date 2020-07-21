package Log::Dispatch::Syslog;

use strict;
use warnings;

our $VERSION = '2.70';

use Log::Dispatch::Types;
use Params::ValidationCompiler qw( validation_for );
use Scalar::Util qw( reftype );
use Sys::Syslog 0.28 ();
use Try::Tiny;

use base qw( Log::Dispatch::Output );

my $thread_lock;

{
    my ($DefaultIdent) = $0 =~ /(.+)/;

    my $validator = validation_for(
        params => {
            ident => {

                # It's weird to allow an empty string but that's how this
                # worked pre-PVC.
                type    => t('Str'),
                default => $DefaultIdent
            },
            logopt => {
                type    => t('Str'),
                default => q{},
            },
            facility => {
                type    => t('NonEmptyStr'),
                default => 'user'
            },
            socket => {
                type    => t('SyslogSocket'),
                default => undef,
            },
            lock => {
                type    => t('Bool'),
                default => 0,
            },
        },
        slurpy => 1,
    );

    my $threads_loaded;

    sub new {
        my $class = shift;
        my %p     = $validator->(@_);

        my $self = bless { map { $_ => delete $p{$_} }
                qw( ident logopt facility socket lock ) },
            $class;

        if ( $self->{lock} ) {
            unless ($threads_loaded) {
                local ( $@, $SIG{__DIE__} ) = ( undef, undef );

                ## no critic (BuiltinFunctions::ProhibitStringyEval)
                # These need to be loaded with use, not require.
                die $@ unless eval 'use threads; use threads::shared; 1;';
                $threads_loaded = 1;
            }
            &threads::shared::share( \$thread_lock );
        }

        $self->_basic_init(%p);

        return $self;
    }
}

{
    my @priorities = (
        'DEBUG',
        'INFO',
        'NOTICE',
        'WARNING',
        'ERR',
        'CRIT',
        'ALERT',
        'EMERG',
    );

    sub log_message {
        my $self = shift;
        my %p    = @_;

        my $pri = $self->_level_as_number( $p{level} );

        lock($thread_lock) if $self->{lock};

        return
            if try {
            if ( defined $self->{socket} ) {
                Sys::Syslog::setlogsock(
                    ref $self->{socket}
                        && reftype( $self->{socket} ) eq 'ARRAY'
                    ? @{ $self->{socket} }
                    : $self->{socket}
                );
            }

            Sys::Syslog::openlog(
                $self->{ident},
                $self->{logopt},
                $self->{facility}
            );
            Sys::Syslog::syslog( $priorities[$pri], $p{message} );
            Sys::Syslog::closelog();

            1;
            };

        warn $@ if $@ and $^W;
    }
}

1;

# ABSTRACT: Object for logging to system log.

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Dispatch::Syslog - Object for logging to system log.

=head1 VERSION

version 2.70

=head1 SYNOPSIS

  use Log::Dispatch;

  my $log = Log::Dispatch->new(
      outputs => [
          [
              'Syslog',
              min_level => 'info',
              ident     => 'Yadda yadda'
          ]
      ]
  );

  $log->emerg("Time to die.");

=head1 DESCRIPTION

This module provides a simple object for sending messages to the
system log (via UNIX syslog calls).

Note that logging may fail if you try to pass UTF-8 characters in the
log message. If logging fails and warnings are enabled, the error
message will be output using Perl's C<warn>.

=for Pod::Coverage new log_message

=head1 CONSTRUCTOR

The constructor takes the following parameters in addition to the standard
parameters documented in L<Log::Dispatch::Output>:

=over 4

=item * ident ($)

This string will be prepended to all messages in the system log.
Defaults to $0.

=item * logopt ($)

A string containing the log options (separated by any separator you
like). See the openlog(3) and Sys::Syslog docs for more details.
Defaults to ''.

=item * facility ($)

Specifies what type of program is doing the logging to the system log.
Valid options are 'auth', 'authpriv', 'cron', 'daemon', 'kern',
'local0' through 'local7', 'mail, 'news', 'syslog', 'user',
'uucp'. Defaults to 'user'

=item * socket ($, \@, or \%)

Tells what type of socket to use for sending syslog messages. Valid
options are listed in C<Sys::Syslog>.

If you don't provide this, then we let C<Sys::Syslog> simply pick one
that works, which is the preferred option, as it makes your code more
portable.

If you pass an array reference, it is dereferenced and passed to
C<Sys::Syslog::setlogsock()>.

If you pass a hash reference, it is passed to C<Sys::Syslog::setlogsock()> as
is.

=item * lock ($)

If this is set to a true value, then the calls to C<setlogsock()>,
C<openlog()>, C<syslog()>, and C<closelog()> will all be guarded by a
thread-locked variable.

This is only relevant when running you are using Perl threads in your
application. Setting this to a true value will cause the L<threads> and
L<threads::shared> modules to be loaded.

This defaults to false.

=back

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/houseabsolute/Log-Dispatch/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Log-Dispatch can be found at L<https://github.com/houseabsolute/Log-Dispatch>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Dave Rolsky.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
