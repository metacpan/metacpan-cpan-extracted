package Log::Dispatch::Win32EventLog;

require 5.005;

use strict;

# use warnings; # 5.006 feature

use vars qw($VERSION);
$VERSION = '0.14';

# $VERSION = eval $VERSION;

use Log::Dispatch 2.01;
use base qw(Log::Dispatch::Output);

use Win32 ();
use Win32::EventLog;

use Params::Validate qw(validate SCALAR);
Params::Validate::validation_options( allow_extra => 1 );

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my %params = validate(
        @_,
        {
            source   => SCALAR,
            register => 0,
        }
    );

    my $self = bless {}, $class;
    $self->_basic_init(%params);

    $self->{win32_source} = $params{source};
    $self->{win32_log}    = "Application";

    if ( $self->{win32_source} =~ /[\\]/ ) {
        $self->{win32_source} =~ s/\\/_/g;    #
        warn "Backslashes in source removed";
    }

    if ( $params{register} ) {

        # We want to use Win32::IsAdminUser to check if a user is an
        # administrator, but this only appears to be available in Win32
        # v0.23, with Perl 5.8.4.

        #       unless (Win32::IsAdminUser) {
        #           warn "Admin user is required to register event sources";
        #       }

        eval {
            require Win32::EventLog::Message;
            import Win32::EventLog::Message;

            my @log_list = ();
            GetEventLogList( Win32::NodeName, \@log_list );
            my %log_hash = ( map { $_ => 1 } @log_list );

            if ( exists $log_hash{ $params{register} } ) {
                Win32::EventLog::Message::RegisterSource( $params{register},
                    $params{source} );
                $self->{win32_register} = $params{register};
                $self->{win32_log}      = $params{source};
            }
            else {
                die "Invalid log";
            }
        };
        if ($@) {
            warn "Unable to register source to log $params{register}: $@";
        }
    }

    $self->{win32_handle} =
      Win32::EventLog->new( $self->{win32_log}, Win32::NodeName )
      or die "Could not instaniate the event application";

    return $self;
}

sub log_message {
    my $self   = shift;
    my %params = @_;

    my $level = $self->_level_as_number( $params{level} );

    if ( ( $self->{win32_register} || "" ) eq 'Security' ) {
        if ( $level > 2 ) {
            $level = EVENTLOG_AUDIT_FAILURE;
        }
        else {
            $level = EVENTLOG_AUDIT_SUCCESS;
        }
    }
    else {
        if ( $level > 3 ) {
            $level = EVENTLOG_ERROR_TYPE;
        }
        elsif ( $level > 2 ) {
            $level = EVENTLOG_WARNING_TYPE;
        }
        else {
            $level = EVENTLOG_INFORMATION_TYPE;
        }
    }

    $self->{win32_handle}->Report(
        {
            Computer  => Win32::NodeName,
            EventID   => 0,
            Category  => 0,
            Source    => $self->{win32_source},
            EventType => $level,
            Strings   => $params{message} . "\0",
            Data      => "",
        }
    );
}

sub DESTROY {
    my $self = shift;
    if ( $self->{win32_handle} ) {
        $self->{win32_handle}->Close;
    }
}

1;
__END__

=head1 NAME

Log::Dispatch::Win32EventLog - Class for logging to the Windows NT Event Log

=head1 VERSION

This document describes version 0.14 of Log::Dispatch::Win32EventLog, released
2006-10-21.

=head1 SYNOPSIS

  use Log::Dispatch::Win32EventLog;

  my $log = Log::Dispatch::Win32EventLog->new(
      name       => 'myname'
      min_level  => 'info',
      source     => 'My App'
  );

  $log->log(level => 'emergency', messsage => 'something BAD happened');

=head1 DESCRIPTION

Log::Dispatch::Win32EventLog is a subclass of Log::Dispatch::Output, which
inserts logging output into the windows event registry.

=head2 METHODS

=over

=item new

  $log = Log::Dispatch::Win32EventLog->new(%params);

This method takes a hash of parameters. The following options are valid:

=item name

=item min_level

=item max_level

=item callbacks

Same as various Log::Dispatch::* classes.

=item source

This will be the source that the event is recorded from.  Usually this
is the name of your application.

The source name should I<not> contain any backslash characters.  If it
does, they will be changed to underscores and a warning will be
issued.  This is due to a restriction of the NT Event Log.

=item register

Registration of an event source removes the warning about the event
being from an unknown source.  It also allows you to post to a log
other than the Application log.

When you register a source to particular log, all future events will
be posted to that log, even if you unregister the source and attempt
to register it to a different log.  If you want to change the log, you
will have to change the source name.

If you register a source to the Security log, informational events
will be tagged as "Audit Success" and higher levels will be tagged as
"Audit Failure".

In order to use this feature, you must have
L<Win32::EventLog::Message> installed.

The process that registers the event sources may need permission to
register the event.  In some cases you may first need to run a simple
script which registers the source name while logged in as an
administrator:

  use Log::Dispatch;
  use Log::Dispatch::Win32EventLog 0.10;

  my $dispatch = Log::Dispatch->new;
  
  $dispatch->add( Log::Dispatch::Win32EventLog->new(
    source   => 'MySourceName',
    register => 'System',
  );

afterwards the source name should be properly registered, and any
script with rights to post to the event logs should be able to post.

I<This is an experimental feature.> See the L</KNOWN ISSUES>
section for more information.

=item log_message

inherited from L<Log::Dispatch::Output>.

=back

=head2 Using with Log4perl

This module can be used as a L<Log::Log4perl> appender.  The
configuration file should have the following:

  log4perl.appender.EventLog         = Log::Dispatch::Win32EventLog
  log4perl.appender.EventLog.layout  = Log::Log4perl::Layout::SimpleLayout
  log4perl.appender.EventLog.source  = MySourceName
  log4perl.appender.EventLog.Threshold = INFO

Replace MySourceName with the source name of your application.

You can also use the log4j wrapper instead:

  log4j.category.cat1                = INFO, myAppender

  log4j.appender.myAppender          = org.apache.log4j.NTEventLogAppender
  log4j.appender.myAppender.source   = MySourceName
  log4j.appender.myAppender.layout   = org.apache.log4j.SimpleLayout

See L<Log::Log4perl::JavaMap::NTEventLogAppender> for more information.

=head1 KNOWN ISSUES

See L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Log-Dispatch-Win32EventLog>
for an up-to-date list of known issues and bugs.

=head2 Full Event Logs

Depending on event log settings, if they are at their maximum size and
the automatic purging of older events is disabled, then some of the
tests may fail.  Clear the event logs and re-test the module.

=head2 Source Registration

Event source registration may fail sporadically.  It may not work when
a source is registered for the first time, or when the event log has
been newly cleared.

=head2 IIS and Windows Server 2003

In some server configurations using IIS (Windows Server 2003), you may
need to set security policy to grant permissions to write to the event
log(s).

See Microsoft KnowledgeBase Article 323076 at
L<http://support.microsoft.com/default.aspx?scid=kb;en-us;323076>.

=head2 Older versions of Win32.pm

Earlier versions of L<Win32> do not have a function called C<IsAdminUser>.
Tests which require the user to be an administrator will be skipped, with
a message saying that the "User is not an administrator" (even when the
user is an administrator).

=head1 SEE ALSO

L<Log::Dispatch>, L<Win32::EventLog>, L<Log::Log4perl>

=head2 Related Modules

L<Win32::EventLog::Carp> traps warn and die signals and sends them to
the NT event log.

=head1 AUTHOR

David Landgren (current maintainer) E<lt>dland at cpan.orgE<gt>

Robert Rothenberg E<lt>rrwo at cpan.orgE<gt>

Artur Bergman E<lt>abergman at cpan.orgE<gt>

Gunnar Hansson E<lt>gunnar at telefonplan.nuE<gt>

=head2 Acknowledgements

Much thanks to Frank Chan E<lt>fpchan at aol.comE<gt> for testing
several developer releases of this module.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
