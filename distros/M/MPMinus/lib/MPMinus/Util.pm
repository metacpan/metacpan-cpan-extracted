package MPMinus::Util; # $Id: Util.pm 128 2013-05-08 12:35:26Z minus $
use strict;

=head1 NAME

MPMinus::Util - Utility functions

=head1 VERSION

Version 1.12

=head1 SYNOPSIS

    use base qw/ MPMinus::Util /;

=head1 DESCRIPTION

The module works with the fundamental tools for the configuration mod_perl level

=over 8

=item B<exception>

    my $excstat = exception( $message );

Write exception information to file and sending e-mail messages if its text contains the 
substring "[SENDMAIL]" and on the flag _errorsendmail_

    $message - Log (exception) message

=item B<debug>

    my $debugstat = debug( $message, $verbose, $file );

Write debugging information to file

    $message - Log (debug) message
    
    $verbose - System information flag. 1 - verbose mode, on / 0 - regular mode, off

    $file - Log file (absolute). Default as: <modperl_root>/mpminus-<prefix>_debug.log.
    If the flag _syslog_ the value is ignored - the message is written to the Apache logfile.

It should be noted that if the flag is omitted then the output information _debug_ be ignored.    

=item B<log>

    my $logstat = $m->log( $message, $level, $file, $separator );

Main logging method

    $message - Log message

    $level - logging level. It may be either a numeric or string value of the form:
    
        debug   -- 0 (default)
        info    -- 1
        notice  -- 2
        warning -- 3
        error   -- 4
        crit    -- 5
        alert   -- 6
        emerg   -- 7
        fatal   -- 8
        except  -- 9
    
    $file - Log File (absolute). Default as: <modperl_root>/mpminus-<prefix>_error.log. 
    If the flag _syslog_ the value is ignored - the message is written to the Apache logfile
    
    $separator - Log-record separator char's string. Default as char(32): ' '

=item B<log_debug>

Alias for call: $m->log( $message, 'debug' )

=item B<log_info>

Alias for call: $m->log( $message, 'info' )

=item B<log_notice>

Alias for call: $m->log( $message, 'notice' )

=item B<log_warning>

Alias for call: $m->log( $message, 'warning' )

=item B<log_warn>

Alias for call: $m->log( $message, 'warning' )

=item B<log_error>

Alias for call: $m->log( $message, 'error' )

=item B<log_err>

Alias for call: $m->log( $message, 'error' )

=item B<log_crit>

Alias for call: $m->log( $message, 'crit' )

=item B<log_alert>

Alias for call: $m->log( $message, 'alert' )

=item B<log_emerg>

Alias for call: $m->log( $message, 'emerg' )

=item B<log_fatal>

Alias for call: $m->log( $message, 'fatal' )

=item B<log_except>

Alias for call: $m->log( $message, 'except' )

=item B<log_exception>

Alias for call: $m->log( $message, 'except' )

=item B<sendmail, send_mail>

    my $sendstatus = $m->sendmail(
        -to         => $m->conf('server_admin'),
        -cc         => 'foo@example.com',   ### OPTIONAL
        -from       => sprintf('"%s" <%s>',$m->conf('server_name'),$m->conf('server_admin')),
        -subject    => 'Subject',
        -message    => 'Message',
        
        # Encoding/Types
        -type       => 'text/plain',        ### OPTIONAL
        -charset    => 'windows-1251',      ### OPTIONAL
        
        # Program sendmail
        -sendmail   => '/usr/sbin/sendmail',### OPTIONAL
        -flags      => '-t',                ### OPTIONAL
        
        # SMTP
        -smtp       => ($m->conf('smtp_host') || ''),    ### OPTIONAL
        -smtpuser   => ($m->conf('smtp_user') || ''),    ### OPTIONAL
        -smtppass   => ($m->conf('smtp_password') || ''),### OPTIONAL
        
        # Attaches
        -attach => [                        ### OPTIONAL
                { 
                    Type=>'text/plain', 
                    Data=>'document 1 content', 
                    Filename=>'doc1.txt', 
                    Disposition=>'attachment',
                },
                
                {
                    Type=>'text/plain', 
                    Data=>'document 2 content', 
                    Filename=>'doc2.txt', 
                    Disposition=>'attachment',
                },
                
                ### ... ###
            ],
    );

If you need to send a letter with only one attachment:

    -attach => {
        Type=>'text/html', 
        Data=>$att, 
        Filename=>'response.htm', 
        Disposition=>'attachment',
    },

or

    -attach => {
        Type=>'image/gif', 
        Path=>'aaa000123.gif',
        Filename=>'logo.gif', 
        Disposition=>'attachment',
    },

Sending mail via L<CTK::Util/sendmail>

=item B<syslog, logsys>

    my $logstat = $m->syslog( $message, $level );

Apache logging to the Apache logfile (ErrorLog of your virtualhost)

$level can take the following values:

    debug (default), info, notice, warning, error, crit, alert, emerg, fatal, except

The function returns work status

=back

=head1 HISTORY

=over 8

=item B<1.00 / 27.02.2008>

Init version on base mod_main 1.00.0002

=item B<1.10 / 01.04.2008>

Module is merged into the global module level

=item B<1.11 / Wed Apr 24 14:53:38 2013 MSK>

General refactoring

=back

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://serzik.ru> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw($VERSION);
$VERSION = 1.12;

use constant {
    LOGLEVELS       => { 
        'debug'   => 0,
        'info'    => 1,
        'notice'  => 2,
        'warning' => 3,
        'error'   => 4,
        'crit'    => 5,
        'alert'   => 6,
        'emerg'   => 7,
        'fatal'   => 8,
        'except'  => 9,
    },
};

use Apache2::Const qw/ :log /;
use MPMinus::MainTools;
use CTK::Util qw/ :BASE /; # Утилитарий
use MIME::Lite;
use FileHandle;

sub log {
    #
    # Процедура логирования данных.
    # !!! Используется для ПРИКЛАДНЫХ а не системных нужд
    #
    # IN:
    #   message - сообщение.
    #   level   - Уровень записи лога (см. процедуру syslog())
    #   file    - АБСОЛЮТНЫЙ путь и имя файла куда писать. По умолчанию используется файл default.log TEMP-директории
    #   sep     - Разделитель значений. По умолчанию пробел
    #
    my $self    = shift;
    my $message = shift;
    $message = '' unless defined $message;
    my $level   = shift || 'debug';
    my $file    = shift || $self->conf('errorlog');
    my $sep     = shift;
    $sep = ' ' unless defined $sep;
    
    my $usesyslog = $self->conf('_syslog_') ? 1 : 0;
    
    # Определяем уровень
    my $loglevels = LOGLEVELS;
    my %levels  = %$loglevels;
    my %rlevels = reverse %$loglevels;
    my $ll;
    if (defined($level) && ($level =~ /^[0-9]+$/) && defined $rlevels{$level}) {
        $ll = $rlevels{$level};
    } elsif (defined($level) && ($level =~ /^[a-z0-9]+$/i) && defined $levels{lc($level)}) {
        $ll = lc($level);
    } else {
        $ll = 'debug'; # Обработчик по умолчанию
    }
    my $llc = $levels{$ll} || 0; # числовое значени
    
    # Смотрим на уровень лога f($ll), если он установлен < чем LogLevl заданный конфигурацией то просто выходим
    my $llsys = $self->r->server->loglevel();
    $llsys = Apache2::Const::LOG_EMERG unless defined $llsys;
    my $llcalc = 0; # debug (default)
    if ($llsys == Apache2::Const::LOG_DEBUG) { $llcalc = 0 }
    elsif ($llsys == Apache2::Const::LOG_INFO) { $llcalc = 1 }
    elsif ($llsys == Apache2::Const::LOG_NOTICE) { $llcalc = 2 }
    elsif ($llsys == Apache2::Const::LOG_WARNING) { $llcalc = 3 }
    elsif ($llsys == Apache2::Const::LOG_ERR) { $llcalc = 4 }
    elsif ($llsys == Apache2::Const::LOG_CRIT) { $llcalc = 5 }
    elsif ($llsys == Apache2::Const::LOG_ALERT) { $llcalc = 6 }
    elsif ($llsys == Apache2::Const::LOG_EMERG) { $llcalc = 7 }
    else { $llcalc = 7 }
    
    unless (($llc == 0) && $self->conf('_debug_')) { # если передан level=debug и установлен флаг дебага - пропскаем проверку!
        return 0 if $llc < $llcalc;
    }
    
    # Формируем выходную строку
    my @sl;
    unless ($usesyslog) {
        @sl = (
            sprintf('[%s]',dtf("%w %MON %DD %hh:%mm:%ss %YYYY")), # Tue Feb 02 16:15:18 2013
            sprintf('[%s]',$ll),
            sprintf('[client %s]',$self->conf('remote_addr')),
        );
    }
    push @sl, sprintf('[sid %s]',$self->conf('sid'));
    push @sl, sprintf('[user %s]',$self->conf('remote_user')) if $self->conf('remote_user');
    push @sl, sprintf('[uri %s]',$self->conf('request_uri'));
    push @sl, $message;
    my $logstring = join($sep, @sl);

    # Запись!
    return syslog($self,$logstring,$level) if $usesyslog; # В системный лог
    return _log_flush($file, $logstring); # В свой лог. Тут сложнее, идет заморочка с файлами
}
sub log_debug { shift->log(shift,'debug') };
sub log_info { shift->log(shift,'info') };
sub log_notice { shift->log(shift,'notice') };
sub log_warning { shift->log(shift,'warning') };
sub log_warn { goto &log_warning };
sub log_error { shift->log(shift,'error') };
sub log_err { goto &log_error };
sub log_crit { shift->log(shift,'crit') };
sub log_alert { shift->log(shift,'alert') };
sub log_emerg { shift->log(shift,'emerg') };
sub log_fatal { shift->log(shift,'fatal') };
sub log_except { shift->log(shift,'except') };
sub log_exception { goto &log_except };
sub _log_flush {
    # сбрасываем буфер в файл, возвращая статус операции
    my $fn = shift;
    my $buffer = shift;
    return 0 unless defined $fn;
        
    my $fh = FileHandle->new($fn,'a');
    unless ($fh) {
        carp(defined($!) ? $! : "Can't open file \"$fn\"");
        return 0;
    }
    
    $fh->print(defined($buffer) ? $buffer : '',"\n");
    $fh->close();

    return 1;
}
sub syslog {
    #
    # Процедура использует функцию апача для вставки записей в лог
    #
    # IN:
    #   message - сообщение.
    #   level   - Уровень записи лога (см. процедуру syslog())
    #
    my $self    = shift;
    my $message = shift;
    my $level   = shift || 'debug'; # emerg(), alert(), crit(), error(), warn(), notice(), info(), debug()
    my $msg = translate(defined($message) ? $message : '');
    
    my $r = Apache2::RequestUtil->request;
    my $rlog = $r->log;
    
    if ($level eq 'except')  {      # 9 exception (emerg alias)
        $rlog->emerg($msg);
    } elsif ($level eq 'fatal') {   # 8 fatal (emerg alias)
        $rlog->emerg($msg);
    } elsif ($level eq 'emerg') {   # 7 system is unusable
        $rlog->emerg($msg);
    } elsif ($level eq 'alert') {   # 6 action must be taken immediately
        $rlog->alert($msg);
    } elsif ($level eq 'crit') {    # 5 critical conditions
        $rlog->crit($msg);
    } elsif ($level eq 'error' or $level eq 'err') { # 4 error conditions
        $rlog->error($msg);
    } elsif ($level eq 'warn' or $level eq 'warning') { # 3 warning conditions
        $rlog->warn($msg);
    } elsif ($level eq 'notice') {  # 2 normal but significant condition
        $rlog->notice($msg);
    } elsif ($level eq 'info') {    # 1 informational
        $rlog->info($msg);
    } else {                        # 0 debug-level messages (default)
        $rlog->debug($msg);
    }
    return 1;
    
}
sub logsys { goto &syslog };
sub debug {
    #
    # Процедура отладки. Записывает в отладочный файл информацию.
    # !!! Используется для ПРИКЛАДНЫХ а не системных нужд
    #
    # IN:
    #    $message - сообщение
    #    $verbose - флаг системной информации. 1 - включить добавление системной информации / 0 - выкл
    #    $file    - ИМЯ файла для отладки. По умолчанию - $CONF{file_debug}
    #
    my $self    = shift;
    my $message = shift;
    $message = '' unless defined $message;
    my $verbose = shift || 0;
    my $file    = shift || $self->conf('debuglog');
    
    return 0 unless $self->conf('_debug_');
    
    # Берем значение по умолчанию если оно не задано
    my $buff = '';
    if ($verbose) {
        my ($pkg, $fn, $ln) = caller;
        my $tm = sprintf "%+.*f",4, (getHiTime() - $self->conf('hitime'));
        $buff = "[time $tm] [package $pkg] [file $fn] [line $ln]".($message ? ' '  : '').$message;
    } else {
        $buff = $message;
    }
    $self->log($buff,'debug',$file);

}
sub exception {
    # Процедура реагирования на exception
    my $self = shift;
    my $message = shift;
    $message = '' unless defined $message;
    
    # Анализ @_ и если первый элемент списка содержит преффикс [SENDMAIL],
    if ($message =~ /\[SENDMAIL\]/) {
        $message =~ s/\[SENDMAIL\]//;
        
        # Отправляем письмо администратору
        CTK::Util::send_mail(
            -to         => $self->conf('server_admin'),
            -from       => sprintf('"%s" <%s>',$self->conf('server_name'),$self->conf('server_admin')),
            -subject    => sprintf('MPMinus internal error on "%s"',$self->conf('server_name')),
            -message    => $message,
            -type       => 'text/html',
            -smtp       => ($self->conf('smtp_host') || ''),
            -smtpuser   => ($self->conf('smtp_user') || ''),
            -smtppass   => ($self->conf('smtp_password') || ''),
        ) if $self->conf('_errorsendmail_');
    }
    $self->log_except($message);
}
sub sendmail {
    # Отправка письма с помощью модуля CTK::Util::send_mail
    my $self = shift;
    return 0 unless $self->conf('_sendmail_'); # Если запрещёно отправлять письма то выход со статусом 0
    return CTK::Util::send_mail(@_);
}
sub send_mail { goto &sendmail };
1;
