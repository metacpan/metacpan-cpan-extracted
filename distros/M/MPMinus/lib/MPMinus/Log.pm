package MPMinus::Log; # $Id: Log.pm 266 2019-04-26 15:56:05Z minus $
use strict;
use utf8;

=encoding utf-8

=head1 NAME

MPMinus::Log - MPMinus logger

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

    use MPMinus::Log;

    my $logger = new MPMinus::Log( "ident string" );

    $logger->log_info(" ... blah-blah-blah ... ");

    $logger->log(Apache2::Const::LOG_INFO, " ... blah-blah-blah ... ");

    $m->log_info(" ... blah-blah-blah ... ");

    $m->log(Apache2::Const::LOG_INFO, " ... blah-blah-blah ... ");

=head1 DESCRIPTION

This module provides log methods for MPMinus logging.

Also You can call log-methods using the MPMinus context (MPMinus object), e.g.:

    $m->log_info(" ... blah-blah-blah ... ");

In this case, you must remember that the ident value is undefined.

=head2 new

    my $logger = new MPMinus::Log( "ident string" );

First parameter is string prefix (signature, ident) that prepended to every message.

=head1 METHODS

=over 8

=item B<log>, B<syslog>, B<logsys>

    $logger->log( $level, @message );
    $m->log( $level, @message );

The method just logs the supplied message corresponding to the LogLevel levels.

Messages will be logged to the virtualhost logfile (ErrorLog of your Apache virtualhost)

=over 8

=item B<$level>

$level can take the following values:

    debug (default), info, notice (note), warning (warn), error (err),
    crit, alert, emerg (emergency), fatal, except (exception)

Also $level can take the following Apache2 constants:

    Apache2::Const::LOG_DEBUG, Apache2::Const::LOG_INFO,
    Apache2::Const::LOG_NOTICE, Apache2::Const::LOG_WARNING,
    Apache2::Const::LOG_ERR, Apache2::Const::LOG_CRIT,
    Apache2::Const::LOG_ALERT, Apache2::Const::LOG_EMERG

See also L<Apache2::Log>

=item B<@message>

What to log. Strings list array

=back

The method returns work status

=item B<log_debug>, B<debug>

    $logger->log_debug( " ... blah-blah-blah ... " );
    $m->log_debug( " ... blah-blah-blah ... " );

Alias for call: $m->log( 'debug', " ... blah-blah-blah ... " )

=item B<log_info>, B<info>

    $logger->log_info( " ... blah-blah-blah ... " );
    $m->log_info( " ... blah-blah-blah ... " );

Alias for call: $m->log( 'info', " ... blah-blah-blah ... " )

=item B<log_notice>, B<notice>

    $logger->log_notice( " ... blah-blah-blah ... " );
    $m->log_notice( " ... blah-blah-blah ... " );

Alias for call: $m->log( 'notice', " ... blah-blah-blah ... " )

=item B<log_warning>, B<log_warn>, B<warn>

    $logger->log_warning( " ... blah-blah-blah ... " );
    $m->log_warning( " ... blah-blah-blah ... " );

Alias for call: $m->log( 'warning', " ... blah-blah-blah ... " )

=item B<log_error>, B<log_err>, B<error>

    $logger->log_error( " ... blah-blah-blah ... " );
    $m->log_error( " ... blah-blah-blah ... " );

Alias for call: $m->log( 'error', " ... blah-blah-blah ... " )

=item B<log_crit>, B<crit>

    $logger->log_crit( " ... blah-blah-blah ... " );
    $m->log_crit( " ... blah-blah-blah ... " );

Alias for call: $m->log( 'crit', " ... blah-blah-blah ... " )

=item B<log_alert>, B<alert>

    $logger->log_alert( " ... blah-blah-blah ... " );
    $m->log_alert( " ... blah-blah-blah ... " );

Alias for call: $m->log( 'alert', " ... blah-blah-blah ... " )

=item B<log_emerg>, B<emerg>

    $logger->log_emerg( " ... blah-blah-blah ... " );
    $m->log_emerg( " ... blah-blah-blah ... " );

Alias for call: $m->log( 'emerg', " ... blah-blah-blah ... " )

=item B<log_fatal>, B<fatal>

    $logger->log_fatal( " ... blah-blah-blah ... " );
    $m->log_fatal( " ... blah-blah-blah ... " );

Alias for call: $m->log( 'fatal', " ... blah-blah-blah ... " )

=item B<log_except>, B<log_exception>, B<except>, B<exception>

    $logger->log_except( " ... blah-blah-blah ... " );
    $m->log_except( " ... blah-blah-blah ... " );

Alias for call: $m->log( 'except', " ... blah-blah-blah ... " )

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

C<mod_perl2>, L<Apache2::Log>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<mod_perl2>, L<Apache2::Log>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw($VERSION);
$VERSION = '1.00';

use constant {
    LOGLEVELS       => {
        'debug'   => 0,
        'info'    => 1,
        'notice'  => 2, 'note' => -2,
        'warning' => 3, 'warn' => -3,
        'error'   => 4, 'err' => -4,
        'crit'    => 5,
        'alert'   => 6,
        'emerg'   => 7, 'emergency' => -7,
        'fatal'   => 8,
        'except'  => 9, 'exception' => -9,
    },
};

use Apache2::Const -compile => qw/ :log /;
use Apache2::RequestRec;
use Apache2::RequestUtil;
use Apache2::Log;

sub new {
    my $class = shift;
    my $ident = shift;

    return bless {
            log_ident => $ident,
        }, $class;
}

sub syslog {
    my $self = shift;
    my $first = shift;
    my @msg = @_;
    my $ll = lc($first // 'debug');
    my $ident = $self->{log_ident};

    my $loglevels = LOGLEVELS;
    my %levels  = %$loglevels;
    my %rlevels = reverse %$loglevels;
    my $level;
    if (($ll =~ /^[0-9]+$/) && exists($rlevels{$ll})) { # Apache2::Const::LOG_*
        if    ($ll == Apache2::Const::LOG_DEBUG)    { $ll = 0 }
        elsif ($ll == Apache2::Const::LOG_INFO)     { $ll = 1 }
        elsif ($ll == Apache2::Const::LOG_NOTICE)   { $ll = 2 }
        elsif ($ll == Apache2::Const::LOG_WARNING)  { $ll = 3 }
        elsif ($ll == Apache2::Const::LOG_ERR)      { $ll = 4 }
        elsif ($ll == Apache2::Const::LOG_CRIT)     { $ll = 5 }
        elsif ($ll == Apache2::Const::LOG_ALERT)    { $ll = 6 }
        elsif ($ll == Apache2::Const::LOG_EMERG)    { $ll = 7 }
        else  { $ll = 7 } # fatal && except
        $level = $rlevels{$ll};
    } elsif (($ll =~ /^[a-z]+$/) && exists($levels{$ll})) { # String
        $level = $ll;
    } else { # Incorrect!
        $level = 'debug';
        unshift(@msg, $first);
    }

    # Ident?
    if (defined($ident)) {
        unshift(@msg, $ident);
    }

    my $r = Apache2::RequestUtil->request;
    my $rlog = $r->log;
    if ($level eq 'except' or $level eq 'exception')  { # 9 exception (emerg alias)
        $rlog->emerg(@msg);
    } elsif ($level eq 'fatal') { # 8 fatal (emerg alias)
        $rlog->emerg(@msg);
    } elsif ($level eq 'emerg' or $level eq 'emergency') { # 7 system is unusable
        $rlog->emerg(@msg);
    } elsif ($level eq 'alert') { # 6 action must be taken immediately
        $rlog->alert(@msg);
    } elsif ($level eq 'crit') { # 5 critical conditions
        $rlog->crit(@msg);
    } elsif ($level eq 'error' or $level eq 'err') { # 4 error conditions
        $rlog->error(@msg);
    } elsif ($level eq 'warn' or $level eq 'warning') { # 3 warning conditions
        $rlog->warn(@msg);
    } elsif ($level eq 'notice' or $level eq 'note') { # 2 normal but significant condition
        $rlog->notice(@msg);
    } elsif ($level eq 'info') { # 1 informational
        $rlog->info(@msg);
    } else { # 0 debug-level messages (default)
        $rlog->debug(@msg);
    }

    return 1;
}

sub logsys { goto &syslog };
sub log { goto &syslog };
sub log_debug { shift->syslog('debug', @_) };
sub debug { goto &log_debug };
sub log_info { shift->syslog('info', @_) };
sub info { goto &log_info };
sub log_notice { shift->syslog('notice', @_) };
sub notice { goto &log_notice };
sub log_warning { shift->syslog('warning', @_) };
sub log_warn { goto &log_warning };
sub warn { goto &log_warning };
sub log_error { shift->syslog('error', @_) };
sub log_err { goto &log_error };
sub error { goto &log_error };
sub log_crit { shift->syslog('crit', @_) };
sub crit { goto &log_crit };
sub log_alert { shift->syslog('alert', @_) };
sub alert { goto &log_alert };
sub log_emerg { shift->syslog('emerg', @_) };
sub emerg { goto &log_emerg };
sub log_fatal { shift->syslog('fatal', @_) };
sub fatal { goto &log_fatal };
sub log_except { shift->syslog('except', @_) };
sub log_exception { goto &log_except };
sub except { goto &log_except };
sub exception { goto &log_except };

1;
