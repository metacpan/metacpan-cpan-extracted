package MPMinus::Helper::Handlers; # $Id: Handlers.pm 224 2017-04-04 10:27:41Z minus $
use strict;

=head1 NAME

MPMinus::Helper::Handlers - MPMinus helper's handlers

=head1 VERSION

Version 1.06

=head1 SYNOPSIS

    use base qw/MPMinus::Helper::Handlers/;

=head1 DESCRIPTION

MPMinus helper's handlers

See mpm manpage

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>minus@serzik.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

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
$VERSION = 1.06;

use constant {
        NOTCONFIGURED => "MPMinus is not configured! Please type following command:\n\n\tmpm config",
        NOTBUILDED  => "Skeleton is not builded! Please check your internet connection (http port)",
        NOTPROJECT  => "Project missing. Use mpm project <projectname>",
        MAINTAINER  => "http://search.cpan.org/src/ABALAMA/MPMinus-[VERSION]/src/mpminus-skel.tar.gz",
        OPERATIONS  => [
                [qw/list controllerlist clist/],
                [qw/install commit apply/],
                [qw/add controlleradd cadd/],
                [qw/del controllerdel cdel remove rm/],
                [qw/exit quit/],
            ],
        READONLY    => 0, # Устанавливаются только при создании проекта далее игнорируются
        STATIC      => 1, # Вшиваются намертво в файл MAkeFile и не редактируются автоматически!
        DYNAMIC     => 2, # Позволяют их редактировать и сохраняются в папку mpminus/config/*.conf
        
    };

use CTK;
use CTK::ConfGenUtil;
use Config::General;
use TemplateM;
use Text::SimpleTable;
use Data::Dumper; $Data::Dumper::Deparse = 1;
use MPMinus::Helper::Util;
use MPMinus::Helper::Skel;
use MPMinus::Debug::System qw/metadata_info/;
use Try::Tiny;
use Perl::OSType qw/ os_type /;
use Cwd;
use File::Copy;     # Export: copy / move
#use File::Path;     # Export: mkpath / rmtree
use File::Basename; # Export: dirname / basename
use File::Temp qw/tempfile tempdir/;
use File::Copy::Recursive qw(dircopy dirmove);

BEGIN {
    sub start { local $| = 1; print CTK::CTKCP @_ ? @_ : '' if CTK::DEBUG && $OPT{debug} }
    sub finish { say(@_) if CTK::DEBUG && $OPT{debug} }
    sub _{my $s=shift||'';my $l=length $s;$s.($l<70?('.'x(70-$l)):'').' '}
}

my @ATTRIBUTES = (
        [ GMT                   => READONLY ],
        [ ServerConfigFile      => READONLY ],
        [ HttpdRoot             => READONLY ],
        [ Platform              => READONLY ],
        [ PlatformType          => READONLY ],
        [ ProjectName           => STATIC ],
        [ ProjectNameL          => STATIC ],
        [ ProjectVersion        => STATIC ],
        [ DefaultCharset        => STATIC ],
        [ ContentType           => STATIC ],
        [ License               => STATIC ],
        [ Author                => STATIC ],
        [ ServerName            => DYNAMIC ],
        [ ServerNameF           => DYNAMIC ],
        [ ServerNameC           => DYNAMIC ],
        [ ServerAlias           => DYNAMIC ],
        [ ServerAdmin           => DYNAMIC ],
        [ DocumentRoot          => DYNAMIC ],
        [ ModperlRoot           => DYNAMIC ],
        [ NameVirtualHost       => DYNAMIC ],
        [ IncludePath           => DYNAMIC ],
        [ SMTP                  => DYNAMIC ],
        [ GlobalDebug           => READONLY ],
        [ ServerStatus          => READONLY ],
        [ ServerInfo            => READONLY ],
        [ PerlStatus            => READONLY ],
        [ RootController        => READONLY ],
        [ InfoController        => READONLY ],
    );

sub VOID {
    my %cmd = @_; #debug(join "; ",@{$cmd{arguments}});
    my $c = _generalc();
    my $config = $c->config;
    
    # Подготавливаем данные
    my $cgsf = [];
    if (value($config,'loadstatus')) {
        $cgsf = array($config, 'configfiles') || [];
    }
    my $env = Dumper(\%ENV);
    my $inc = Dumper(\@INC);
    my $cfg = Dumper($config);

    # Непосредственно данные
    my @rslth = qw/foo bar baz/;
    my @rsltd = (
            [qw/qwe rty uiop/],
            [qw/asd fgh jkl/],
            [qw/zxc vbn m/],
        );
    my $data = _result('text',\@rslth,\@rsltd);

    # Отладка
    debug "Directories:";
    debug "    DATADIR  : ",$c->datadir;
    debug "    LOGDIR   : ",$c->logdir;
    debug "    LOGFILE  : ",$LOGFILE;
    debug "    CONFDIR  : ",$c->confdir;
    debug "    CONFFILE : ",$c->cfgfile;
    debug "Loaded configuration files:";
    debug("    ",($_ || '')) for (@$cgsf);
    debug "-----BEGIN ENV DUMP-----";
    debug $env;
    debug "-----END ENV DUMP-----";
    debug "-----BEGIN INC DUMP-----";
    debug $inc;
    debug "-----END INC DUMP-----";
    debug "-----BEGIN CFG DUMP-----";
    debug $cfg;
    debug "-----END CFG DUMP-----";
    debug "Data:";
    debug $data;
    
    # Всяка-разна
    
    1;
}
sub CONFIG {
    # Настройка системы
    say("MPMinus configuration...");
    my %cmd = @_;
    my ($param, $value) = @{$cmd{arguments}};
    my $c = _generalc();
    my $config = $c->config;
    my $cfile = $CONFFILE;
    my $skel = new MPMinus::Helper::Skel( -c => $c, s => $OPT{sharedir}, -url => MAINTAINER, );
    unless ($skel->checkstatus) { say(NOTBUILDED) unless $skel->build }
    my $voidconfig = $config->{loadstatus} && $config->{httpdroot} ? 0 : 1;
    
    debug("Config file     : $cfile");
    debug("Config status   : ".($voidconfig ? 'VOID' : 'OK'));
    debug("Skeleton status : ".($skel->checkstatus ? 'OK' : 'ERROR'));

    if ($param) {
        # Конфигурирование отдельно-взятого параметра
        say("Edit configuration option \"$param\"...");
        unless ($value) {
            my $now = value($config, $param);
            $now = '' unless defined $now;
            $value = $c->cli_prompt("Input new value (now set: \"$now\"):");
        }
        $config->{$param} = $value;
        say("Option \"$param\" set to: \"",$value,"\"");
    } else {
        # Переконфигурирование системы полностью
        if ($voidconfig 
            or $c->cli_prompt('Are you sure you want to change all of parameter setting?:','no') =~ /^\s*y/i
        ) {
            say("Creating mpm configuration...") if $voidconfig;
            $config = newconfig($c);
        } else {
            say("Aborted");
            return 1;
        }
    }
    #say Dumper($config);
    
    # Запись в файл
    my $conf = new Config::General( -ConfigHash => $config );
    $conf->save_file($cfile);
    say("Done");
    
    1;
}
sub TEST {
    # Тестирование функционала и вывод итоговой таблицы
    my $c = _generalc();
    my $config = $c->config;
    say(NOTCONFIGURED) && return 0 unless $config->{loadstatus} && $config->{httpdroot};
    
    my ($steps, $i) = (11,0);
    my $tbl = Text::SimpleTable->new( 
            [ 25, 'PARAM' ],
            [ 57, 'VALUE / MESSAGE' ],
            [ 7,  'RESULT' ],
        );
    my $tst = '';
    my $v = '';
    
    # PASSED  -- Тест пройден!
    # FAILED  -- Тест НЕ пройден!
    # SKIPPED -- Тест пропущен!
    
    # debug's finishes:
    #  DONE   -- Процесс тестирования прошел корректно
    #  ERROR  -- Процесс тестирования прошел с ошибками
    
    # 1. Процесс httpd, доступность переменных и основных каталогов
    $tst = "HTTPD values";
    start _ sprintf('%d/%d %s',++$i,$steps, $tst);
    my $apache = getApache();
    my ($aroot, $aconfig, $sver, $aver) = (
            $apache->{HTTPD_ROOT},
            $apache->{SERVER_CONFIG_FILE},
            $apache->{SERVER_VERSION},
            $apache->{APACHE_VERSION},
        );
    $tbl->row('HTTPD Root Directory', $aroot, ($aroot && (-e $aroot) && ((-d $aroot) || (-l $aroot))) ? 'PASSED' : 'FAILED');
    $tbl->row('HTTPD Server Config File', $aconfig, ($aconfig && (-e $aconfig) && ((-f $aconfig) || (-l $aconfig))) ? 'PASSED' : 'FAILED');
    $tbl->row('HTTPD Server Version', $sver, ($sver) ? 'PASSED' : 'FAILED');
    $tbl->row('HTTPD Apache Version', $aver, ($aver && $aver > 2) ? 'PASSED' : 'FAILED');
    
    finish "DONE";
    
    # 2. ModPerlRoot
    $tst = "MPMinus root directory";
    start _ sprintf('%d/%d %s',++$i,$steps, $tst);
    $v = to_void($config->{lc('ModPerlRoot')});
    if ($v) { $tbl->row($tst, $v, ((-e $v) && ((-d $v) || (-l $v))) ? 'PASSED' : 'FAILED') } 
    else { $tbl->row($tst, $v, 'SKIPPED') }
    finish "DONE";
    
    # 3. ApacheHomePath
    $tst = "Apache root directory";
    start _ sprintf('%d/%d %s',++$i,$steps, $tst);
    $v = to_void($config->{httpdroot});
    if ($v) { $tbl->row($tst, $v, ((-e $v) && ((-d $v) || (-l $v))) ? 'PASSED' : 'FAILED') } 
    else { $tbl->row($tst, $v, 'SKIPPED') }
    finish "DONE";

    # 4. ApacheConfigFile
    $tst = "Apache config file";
    start _ sprintf('%d/%d %s',++$i,$steps, $tst);
    $v = to_void($config->{serverconfigfile});
    if ($v) { $tbl->row($tst, $v, ((-e $v) && ((-f $v) || (-l $v))) ? 'PASSED' : 'FAILED') } 
    else { $tbl->row($tst, $v, 'SKIPPED') }
    finish "DONE";

    # 5. ServerName
    $tst = "Global server name";
    start _ sprintf('%d/%d %s',++$i,$steps, $tst);
    $v = to_void($config->{lc('ServerName')});
    eval "
        no warnings;
        no strict;
        require Net::Ping;
        my \$pingo = Net::Ping->new('tcp', 5);
        my (\$hn,\$pn) = split(':','$v');
        \$hn ||= '$v';
        \$pn ||= '80';
        \$hn =~ s/\:.*//g;
        \$pingo->port_number(\$pn);
        my \$ee = \"Server \\\"\$hn\\\" not reachable on port \\\"\$pn\\\"\" 
        unless \$pingo->ping(\$hn);
        \$pingo->close();
        undef(\$pingo);
        die(\$ee) if \$ee;
    ";
    my $evalerror = $@ || '';
    if ($evalerror) {
        $tbl->row($tst, $v."\n".$evalerror, 'FAILED');
        finish "ERROR";
        debug($evalerror);
    } else {
        $tbl->row($tst, $v, $v ? 'PASSED' : 'SKIPPED');
        finish "DONE";
    }
    
    # 6. NameVirtualHost
    $tst = "NameVirtualHost";
    start _ sprintf('%d/%d %s',++$i,$steps, $tst);
    $v = to_void(value($config->{lc('NameVirtualHost')}));
    $tbl->row($tst, $v, $v ? 'PASSED' : 'FAILED');    
    finish "DONE";

    # 7. SMTP
    $tst = "SMTP server";
    start _ sprintf('%d/%d %s',++$i,$steps, $tst);
    my $smtptrysend = 1;
    $v = to_void(value($config->{lc('SMTP')}));
    if ($v) {
        eval "
            no warnings;
            no strict;
            require Net::SMTP;
            my \$smtp = Net::SMTP->new('$v', Timeout => 5);
            die('Server \"$v\" not reachable') unless \$smtp;
            my \$domainresult = \$smtp->domain() || '';
            my \$ee = 'SMTP domain not defined' unless \$domainresult;
            \$smtp->quit;
            die(\$ee) if \$ee;
        ";
        $evalerror = $@ || '';
        if ($evalerror) {
            $tbl->row($tst, $v."\n".$evalerror, 'FAILED');
            finish "ERROR";
            debug($evalerror);
            $smtptrysend = 0;
        } else {
            $tbl->row($tst, $v, 'PASSED');
            finish "DONE";
        }
    } else {
        $smtptrysend = 0 if $c->isostype("Windows");
        $tbl->row($tst, $v, 'SKIPPED');    
        finish "DONE";
    }

    # 8. MAIL address
    $tst = "MAIL address";
    start _ sprintf('%d/%d %s',++$i,$steps, $tst);
    $v = to_void($config->{lc('MailTo')});
    $tbl->row('MailTo', $v, $v ? 'PASSED' : 'FAILED');
    $v = to_void($config->{lc('MailFrom')});
    $tbl->row('MailFrom', $v, $v ? 'PASSED' : 'FAILED');
    $v = to_void($config->{lc('ErrorMail')});
    $tbl->row('ErrorMail', $v, $v ? 'PASSED' : 'FAILED');
    $v = to_void($config->{lc('MailCC')});
    $tbl->row('MailCC', $v, $v ? 'PASSED' : 'SKIPPED');
    $v = to_void($config->{lc('MailChrST')});
    $tbl->row('MailCharSet', $v, $v ? 'PASSED' : 'SKIPPED');
    $v = to_void($config->{lc('MailCmd')});
    $tbl->row('MailCommand', $v, $v ? 'PASSED' : 'SKIPPED');
    $v = to_void($config->{lc('MailFlag')});
    $tbl->row('MailFlag', $v,  $v ? 'PASSED' : 'SKIPPED');
    finish "DONE";
    
    # 9. Skeleton files
    $tst = "Skeleton files";
    start _ sprintf('%d/%d %s',++$i,$steps, $tst);
    my $skel = new MPMinus::Helper::Skel( -c => $c, s => $OPT{sharedir}, -url => MAINTAINER, );
    if ($skel->checkstatus) { $v = 1 } else { $v = $skel->build }
    $tbl->row($tst, $skel->{skeldir}, $v ? 'PASSED' : 'FAILED');    
    finish "DONE";
    
    # 10. Версия MPMinus (backward)
    $tst = "Version of mpminus-skel";
    start _ sprintf('%d/%d %s',++$i,$steps, $tst);
    my $mpminusv = $skel->{rplc}{VERSION};
    $tbl->row($tst, $mpminusv, $mpminusv =~ /^\d+\.\d+$/ ? 'PASSED' : 'FAILED');    
    finish "DONE";

    # 11. Отправка письма
    $tst = "Trying mail sending";
    start _ sprintf('%d/%d %s',++$i,$steps, $tst);
    
    if ($smtptrysend) {
        $v = CTK::sendmail(
            -to      => $config->{lc('MailTo')},
            -cc      => $config->{lc('MailCC')},
            -from    => $config->{lc('MailFrom')},
            -charset => $config->{lc('MailChrST')},
            -smtp    => $config->{lc('SMTP')},
            -sendmail=> $config->{lc('MailCmd')},
            -flags   => $config->{lc('MailFlag')},
            -subject => 'MPMinus test message',
            -message => "Test report\n===========\n\n".$tbl->draw,
        );
        if ($v) {
            $tbl->row($tst, 'Mail has been sent', 'PASSED');
            finish "DONE";
            
        } else {
            $tbl->row($tst, 'Mail was NOT sent', 'FAILED');
            finish "ERROR";
            debug('Mail was NOT sent');
        }
    } else {
        $tbl->row($tst, '', 'SKIPPED');
        finish "DONE";
    }
    
    #exception("blah-blah-blah");
    say($tbl->draw);
    1;
}
sub CREATE {
    # Создание проекта
    my %cmd = @_;
    my ($pname) = @{$cmd{arguments}};
    my $c = _generalc();
    my $config = $c->config;
    say(NOTCONFIGURED) && return 0 unless $config->{loadstatus} && $config->{httpdroot};
    my $skel = new MPMinus::Helper::Skel( -c => $c, s => $OPT{sharedir}, -url => MAINTAINER, );
    unless ($skel->checkstatus) { say(NOTBUILDED) && return 0 unless $skel->build }
    my %h;
    
    # 1. Создаем табличку как в тесте для отображения результатов
    my $tbl = Text::SimpleTable->new( 
            [ 25, 'PARAM' ],
            [ 57, 'VALUE / MESSAGE' ],
        );

    # 2. Наполняем переменные которые будут использоваться для стеширования
    #    они делятся на два типа - статические и динамические. Статические данные
    #    это те данные которые не подлежат правке, и носятся в Makefile.PL когда
    #    как динамические - все остальные, которые могут быть поправлены.
    #    Для динамических данных существует своя настройка и они как правило
    #    лежат в системной папке */mpminus/conf/ под именем PROJECTNAME.conf
    #    Существует отдельная группа - READONLY. Эти данные располагаются 
    #    в конфигурационном файле но модифицируются независимо от пользователя
    
    # ServerConfigFile & HttpdRoot
    $h{ServerConfigFile} = to_void(value($config->{lc('ServerConfigFile')}));
    $h{ServerConfigFile} =~ s/\\/\//g;
    $h{HttpdRoot} = to_void(value($config->{lc('HttpdRoot')}));
    $h{HttpdRoot} =~ s/\\/\//g;
    
    # GMT
    my $gmt = CTK::dtf("%w %MON %_D %hh:%mm:%ss %YYYY %Z", time(), 'GMT'); # scalar(gmtime)." GMT";
    $h{GMT}  = $gmt;
    
    # Platform
    my $platform = $^O || 'Unix';
    $platform =~ s/[^a-z0-9_]/X/ig;
    $h{Platform} = $platform;
    $h{PlatformType} = os_type($platform);
    
    say("\nGeneral project data\n");
    
    # ProjectName & ProjectNameL
    $pname = cleanProjectName($pname);
    unless ($pname) {
        $pname = cleanProjectName($c->cli_prompt('Project Name:', 'Foo'));
    }
    $h{'ProjectName'} = $pname;
    $h{'ProjectNameL'} = lc("$pname");

    # ServerName & ServerNameF & ServerNameC
    my $servername = cleanServerName($c->cli_prompt('Server Name (site):', 
            lc("$pname").'.'.(value($config->{lc('ServerName')}) || 'localhost')
        ));
    $h{ServerName} = $servername;
    my $servernamef = cleanServerNameF($servername);
    $h{ServerNameF} = $servernamef;
    my $servernamec = $servername;
    $servernamec =~ s/\:\d+$//;
    $h{ServerNameC} = $servernamec;
    
    # ServerAlias
    my $serveralias = cleanServerName($c->cli_prompt('Server Alias (second site name):',''));
    $h{ServerAlias} = $serveralias;
    
    # ProjectVersion
    my $prjver = $c->cli_prompt('Current Project Version:','1.00');
    if ($prjver !~ /^\d{1,2}\.\d{1,2}$/) {
        # Некорректная версия
        say("   Invalid Version \"$prjver\"");
        $prjver = '1.00';
    }
    $h{ProjectVersion} = $prjver;

    # ServerAdmin
    my $serveradmin = $c->cli_prompt('Server Admin Email:', 
            value($config->{lc('ErrorMail')}) || 'root@localhost'
        );
    $h{ServerAdmin} = $serveradmin;

    # SMTP
    my $smtp = $c->cli_prompt('SMTP Server:', value($config->{lc('SMTP')}) || '');
    $h{SMTP} = $smtp || '0';

    # DefaultCharset
    my $defaultcharset = $c->cli_prompt('DefaultCharset:','utf-8');
    $h{DefaultCharset} = $defaultcharset;
    
    # ContentType
    my $contenttype = $c->cli_prompt('ContentType:',"text/html; charset=$defaultcharset");
    $h{ContentType} = $contenttype;

    # DocumentRoot & ModperlRoot
    my $modperlroot  = to_void(value($config->{lc('ModperlRoot')}));
    my $documentroot = $c->cli_prompt('DocumentRoot:', CTK::catdir($modperlroot || CTK::webdir, $servernamec));
    $documentroot =~ s/\\/\//g;
    $h{DocumentRoot} = $documentroot;
    
    # ModperlRoot
    my $newmproot = $c->cli_prompt('ModperRoot (DocumentRoot for MPM):', $documentroot);
    $h{ModperlRoot} = $newmproot;

    # Спрашиваем, ведь папка введена существующая
    if ( $documentroot && -e $documentroot && $c->cli_prompt('Directory already exists! Are you sure you want to continue?:','no') !~ /^\s*y/i) {
        say('Operation aborted');
        return 1;
    }

    # VirtualHost
    $h{NameVirtualHost} = to_void(value($config->{lc('NameVirtualHost')}));

    # IncludePath
    $h{IncludePath} = CTK::catdir($documentroot,'inc');
    $h{IncludePath} =~ s/\\/\//g;

    say("\nAddition information\n");
    
    # License
    my $lic = $c->cli_prompt('License:','GPL');
    $h{License} = $lic;

    # Author
    my $author = $c->cli_prompt('Your Full Name:','Mr. Anonymous');
    $h{Author} = $author;

    say("\nSystem flags\n");
    
    # GlobalDebug
    my $globaldebug = $c->cli_prompt('Flag GlobalDebug:','no');
    $h{GlobalDebug} = $globaldebug  && $globaldebug =~ /^\s*y/i ? 1 : 0;
    
    say("\nDebug handlers (serverstatus, serverinfo and perlstatus)\n");
    
    # ServerStatus
    my $serverstatus = $c->cli_prompt('ServerStatus Location enable?:','no') =~ /^\s*y/i ? 1 : 0;
    $h{ServerStatus} = $serverstatus;
    
    # ServerInfo
    my $serverinfo = $c->cli_prompt('ServerInfo Location enable?:','no') =~ /^\s*y/i ? 1 : 0;
    $h{ServerInfo} = $serverinfo;
    
    # PerlStatus
    my $perlstatus = $c->cli_prompt('PerlStatus Location enable?:','no') =~ /^\s*y/i ? 1 : 0;
    $h{PerlStatus} = $perlstatus;
    
    say("\nEnabled controllers\n");

    # RootController
    my $rootc = $c->cli_prompt('Enable Root controller?:','yes') =~ /^\s*y/i ? 1 : 0;
    $h{RootController} = $rootc;
    
    # InfoController
    my $infoc = $c->cli_prompt('Enable Info (Kernel) controller?:','yes') =~ /^\s*y/i ? 1 : 0;
    $h{InfoController} = $infoc;
    
    # 3. Отрисовка результата перед запросом
    $tbl->row( $_->[0], $h{$_->[0]} ) for grep { $_->[1] != READONLY } @ATTRIBUTES;
    say($tbl->draw);
    say('Operation aborted') && return 1 unless $c->cli_prompt('All right?:','yes') =~ /^\s*y/i;

    # Запрос на отправку письма
    my $sendreport = $c->cli_prompt('Send report to e-mail?:','no') =~ /^\s*y/i ? 1 : 0;

    say("\nCreating project \"$pname\"...");
    
    # 4. Получается список файлов (с их путями) для создания проекта из файла MANIFEST
    # MANIFEST и SUMMARY не должны быть приведены в файле MANIFEST!
    start _ ">>> Reading MANIFEST file";
    my $manifest = $skel->readmanifest;
    finish $manifest && ref($manifest) eq 'HASH' ? "OK" : "ERROR";
    #say Dumper($skel->readmanifest);
    
    start _ ">>> Reading SUMMARY file";
    my $summary = $skel->readsummary;
    finish $summary ? "OK" : "ERROR";
    
    my $tmpdir = tempdir( CLEANUP => 1 );
    
    # 5. Создается проект используя шаблонные методы templatem через try {} catch {};
    $manifest = {} unless $manifest && ref($manifest) eq 'HASH';
    my $n = scalar(keys %$manifest);
    my $i = 0;
    foreach my $km (keys %$manifest) {$i++;
        start _ sprintf('>>> Processing %d/%d "%s"', $i, $n, $km);

        # Path & SubDirectories
        my $kmf = $km;
        $kmf =~ s/PROJECTNAME/$pname/g;
        $kmf =~ s/PLATFORM/$platform/g;
        $kmf =~ s/SERVERNAMEF/$servernamef/g;
        $kmf =~ s/MANIFEST.MPM/MANIFEST/g;
        my $f_src   = $manifest->{$km};             # Источник (файл)
        my $f_dst   = CTK::catfile($tmpdir,$pname,$kmf); # Приемник (файл)
        my $dir_src = dirname($f_src);              # Источник (каталог)
        my $dir_dst = dirname($f_dst);              # Приемник (каталог)
        CTK::preparedir( $dir_dst, 0777 ) or finish("ERROR") && next;
        
        if (-B $f_src) { # Обработка двоичных файлов
            copy($f_src,$f_dst) or finish("ERROR") && say("Copy failed \"$f_src\" -> \"$f_dst\": $!") && next;
        } elsif ($km =~ /s?html?$/) { # Файлы SHTML и HTML копируем!
            copy($f_src,$f_dst) or finish("ERROR") && say("Copy failed \"$f_src\" -> \"$f_dst\": $!") && next;
        } else {
            my $f_dst_orig = $f_dst.".orig"; # Имя файла оригинала
            
            if ($km =~ /\.(conf|ht\w+)$/) { # Все файлы конфигурации должны быть сохранены!
                my $f_fd = CTK::catfile($documentroot,$kmf); # Самый конечный ресурс
                my $f_fd_old = $f_fd.".orig"; # Имя файла оригинала на конечном ресурсе
                if (-e $f_fd) {
                    # Файл конечный существует, значит есть над чем поработать!
                    if (-e $f_fd_old) {
                        # Нашелся ранее сохраненный файл оригинала. Копируем его в TMP
                        copy($f_fd_old,$f_dst_orig) or debug("Copy failed \"$f_fd_old\" -> \"$f_dst_orig\": $!");
                    } else {
                        # Никакого сохраненного ранее файл оригинала нет, 
                        # значит можем переименовать имеющийся конфигурауционный в .orig
                        copy($f_fd,$f_dst_orig) or debug("copy failed \"$f_fd\" -> \"$f_dst_orig\": $!");
                    }
                }
            }
                
            # Выполнение процессинга !!!
            try {
                my $tpl = new TemplateM(-file => $f_src, -asfile => 1, -utf8 => 1);
                $tpl->stash(%h);
                $tpl->cast_if($_,$h{$_} ? 1 : 0) foreach (qw/ServerAlias ServerStatus ServerInfo PerlStatus/);
                $tpl->cast_if('UTF8', $defaultcharset && $defaultcharset =~ /^utf\-?8/i);
                my $cbox = $tpl->start('Controllers');
                    $cbox->loop(Controller => 'Root') if $rootc;
                    $cbox->loop(Controller => 'Info') if $infoc;
                $cbox->finish;
                CTK::bsave($f_dst, $tpl->output(), 1);
            } catch {
                finish("ERROR");
                say("Processing failed \"$f_src\" -> \"$f_dst\": $_");
                next;
            };
            
        }

        finish "OK";
    }
    
    # Копирование всей структуры в папку назначения
    start _ ">>> Moving directories";
    my $dir_from = CTK::catdir($tmpdir,$pname);
    my $dir_into = $documentroot;
    if (dirmove($dir_from,$dir_into)) {
        finish "OK";
    } else {
        finish("ERROR");
        say("Can't move directory \"$dir_from\" -> \"$dir_into\": $!");
    }
    
    # Создается конфигурационный файл для MPM
    my $prjcfgf = CTK::catfile( $c->confdir, $pname . ".conf");
    start _ ">>> Creating config file \"$prjcfgf\"";
    my $prjcfg = _create_project_config($pname,%h);
    if (CTK::fsave($prjcfgf, $prjcfg)) { finish "OK" } else { finish("ERROR") }
    
    # 6. Запускается команда /usr/bin/perl Makefile.PL (см. pays для примера)

    # Запрос на выполнение команды
    if ($c->cli_prompt('Try to install the module automatically?:','yes') =~ /^\s*y/i) {
        _install($documentroot);
    } else {
        say("Your site can\'t installed! Please type following commands:\n");
        say("\tcd $documentroot");
        say("\tperl Makefile.PL");
        say("\tmake");
        say("\tmake test");
        say("\tmake install");
        say("\tmake clean");
    }
    
    say("\nOK\n");
    
    # 7. выдается поздравительное сообщение из файла SUMMARY простешировав все величины
    my $t = new TemplateM(-template => $summary);
    $t->stash(%h);
    my $summarypage = $t->output();
    say($summarypage);
    
    # 8. Отправляется письмо с текстом SUMMARY
    if ($sendreport) {
        my $mvs = CTK::sendmail(
            -to      => $serveradmin,
            -cc      => $config->{lc('MailCC')},
            -from    => $config->{lc('MailFrom')},
            -charset => $config->{lc('MailChrST')},
            -smtp    => $config->{lc('SMTP')},
            -sendmail=> $config->{lc('MailCmd')},
            -flags   => $config->{lc('MailFlag')},
            -subject => 'MPMinus report',
            -message => "Create project report\n".
                        "=====================\n".
                        "\n".$tbl->draw."\n".
                        "Message\n".
                        "=======\n".
                        "\n".$summarypage."\n",
        );
        if ($mvs) 
            { debug('Mail has been sent') } 
        else 
            { debug('Mail was NOT sent') }
    }
    
    1;
}
sub PROJECT {
    # Управление проектом
    my %cmd = @_;
    my ($pname, $pcmd, $controller) = @{$cmd{arguments}}; # Project, Command, Controller
    my $c = _generalc();
    my $config = $c->config;
    say(NOTCONFIGURED) && return 0 unless $config->{loadstatus} && $config->{httpdroot};
    my $skel = new MPMinus::Helper::Skel( -c => $c, s => $OPT{sharedir}, -url => MAINTAINER, );
    unless ($skel->checkstatus) { say(NOTBUILDED) && return 0 unless $skel && $skel->build }
    my %h;

    # Проверки на "вшивость" и определение команд/значений
    say(NOTPROJECT) && return 0 unless $pname;

    # ServerName & ServerNameF & ServerNameC
    my $pnamel = lc("$pname");
    my $sname = (value($config->{lc('ServerName')}) || 'localhost');
    my $th = hash($config, 'project', $pname);
    my $servername  = value($th, 'servername') || cleanServerName($pnamel.'.'.$sname);
    my $servernamef = cleanServerNameF($servername);
    my $servernamec = $servername; $servernamec =~ s/\:\d+$//;

    # DocumentRoot & ModperlRoot & Metafile
    my $modperlroot  = value($config->{lc('ModperlRoot')});
    my $documentroot = CTK::catdir($modperlroot || CTK::webdir, $servernamec);
    my $metaf = CTK::catfile($documentroot, "META.yml");
    unless ( $documentroot && -e $documentroot && -e $metaf) {
        $servername = cleanServerName($c->cli_prompt('Server Name (site):', $pnamel.'.'.$sname));
        $servernamef = cleanServerNameF($servername);
        $servernamec = $servername; $servernamec =~ s/\:\d+$//;
        $documentroot = CTK::catdir($modperlroot || CTK::webdir, $servernamec);
        $metaf = CTK::catfile($documentroot, "META.yml");
        unless ( $documentroot && -e $documentroot && -e $metaf) {
            $documentroot = $c->cli_prompt("Please enter DocumentRoot directory:", getcwd());
            $metaf = CTK::catfile($documentroot, "META.yml") if $documentroot && -e $documentroot;
        }
        unless ( $documentroot && -e $documentroot && -e $metaf) {
            say("Project in \"$documentroot\" not found! Operation aborted");
            return 0;
        }
    }
    
    # Operations
    my %ops; 
    $pcmd ||= '';
    foreach (@{(OPERATIONS)}) { $ops{$_->[0]} = $_ };
    my $needenter = 1;
    foreach my $k (keys %ops) {
        my $v = $ops{$k};
        if (grep { lc($pcmd) eq $_ } @$v) {
            $needenter = 0;
            $pcmd = $k;
            last;
        }
    }
    $pcmd = $c->cli_select('Please select the command:', [(sort {$a cmp $b} keys %ops)], 'exit') if $needenter;
    say("Command not found. Bye") && return 1 unless grep {$pcmd eq $_} keys %ops;
    say("Bye") && return 1 if $pcmd eq 'exit';
    
    # Чтение манифеста и метафайла
    start _ ">>> Reading MANIFEST file";
    my $manifest = $skel->readmanifest;
    if ($manifest && ref($manifest) eq 'HASH') { 
        finish "OK";
    } else {
        finish "ERROR";
        say "Cant' load file MANIFEST";
        return 0;
    }
    start _ ">>> Reading META file";
    my %meta = metadata_info($metaf);
    if (%meta && $meta{Error}) {
        finish "ERROR";
        say $meta{Error};
        return 0;
    } else {
        finish "OK";
    }
    #say Dumper($manifest);    
    #say Dumper(\%meta);

    # Формирование массива %h для стеширование и формирование данных контроллеров из META.yml
    if ( 1
            && $meta{x_mpminus} 
            && (ref($meta{x_mpminus}) eq 'HASH') 
            && ($meta{x_mpminus}{ProjectNameL} eq $pnamel)
        ) {
        %h = %{($meta{x_mpminus})};
        $pname = $meta{x_mpminus}{ProjectName} if $meta{x_mpminus}{ProjectName};
    } else {
        say "Metadata incorrect! Please rebuild the project \"$pname\"";
        return 0;
    }
    
    # Корректируем данные %h исходя из более приоритетной - конфигурационной секции!
    my $confdata = hash( $config, 'project', $pname ) || {};
    my $prjcfgf = CTK::catfile( $c->confdir, $pname . ".conf");
    my $prjcfgneed = 0;
    my $platform = $^O || 'Unix'; $platform =~ s/[^a-z0-9_]/X/ig;
    if ( -e $prjcfgf ) {
        $prjcfgneed = 1 unless $confdata->{platform} && $confdata->{platform} eq $platform;
    } else { $prjcfgneed = 1 }
    if ($prjcfgneed) {
        # Запись нового конфигурационного файла если его нет, с предварительными вопросами
        $confdata->{platform} = $platform;
        $confdata->{platformtype} = os_type($platform);
        $confdata->{servername} = cleanServerName($c->cli_prompt('Server Name (site):', $servername));
        $confdata->{servernamef} = cleanServerNameF($confdata->{servername});
        $confdata->{servernamec} = $confdata->{servername}; $confdata->{servernamec} =~ s/\:\d+$//;
        $confdata->{serveradmin} = $c->cli_prompt('Server Admin Email:', value($config->{lc('ErrorMail')}) || 'root@localhost');
        $confdata->{documentroot} = $documentroot;
        $confdata->{modperlroot} = $documentroot;
        $confdata->{namevirtualhost} = to_void(value($config->{lc('NameVirtualHost')}));
        $confdata->{includepath} = CTK::catdir($documentroot,'inc');
        $confdata->{includepath} =~ s/\\/\//g;
        $confdata->{smtp} = $c->cli_prompt('SMTP Server:', value($config->{lc('SMTP')}) || '') || '';
    }
    foreach (@ATTRIBUTES) { 
        $h{$_->[0]} = $confdata->{lc($_->[0])} if defined $confdata->{lc($_->[0])};
    }
    if ($prjcfgneed) {
        start _ ">>> Creating config file \"$prjcfgf\"";
        my $prjcfg = _create_project_config($pname, %h);
        if (CTK::fsave($prjcfgf, $prjcfg)) { finish "OK" } else { finish("ERROR") }    
    }
    # say(Dumper(\%h)) && return 1;
    
    #
    # !!! Тут начинается секция по работе с командами !!!
    #
    
    # Команда install
    if ($pcmd eq 'install') {
        _install($documentroot);
        say("Installed");
        return 1;
    }
    
    # Получение путей Index.pm, Foo.pm из манифеста
    my $index_src = $manifest->{'lib/MPM/PROJECTNAME/Index.pm'} || '';
    my $index_dst = CTK::catfile($documentroot,'lib','MPM',$pname,"Index.pm");
    my $foo_src   = $index_src; $foo_src =~ s/Index/Foo/;

    # Получение списка контроллеров из источника
    my $allowcontrollers = [];
    start _ ">>> Reading Index.pm file";    
    my $index = CTK::fload($index_dst);
    if ($index) {
        my %usebaseqw = ();
        while ($index =~ s/MPM\:\:[a-z0-9_]+\:\:([a-z0-9_]+)//i) {
            my $mtch = $1 || '';
            $usebaseqw{$1} = 1 if $mtch && $mtch !~ /^Index$/i;
        }
        unless (%usebaseqw) {
            finish "ERROR";
            say "File \"$index_dst\" Incorrect";
            return 0;
        }
        @$allowcontrollers = keys %usebaseqw;
        finish "OK";
    } else {
        finish "ERROR";
        say "Cant' load \"$index_dst\"";
        return 0;
    }

    # Команда list
    if ($pcmd eq 'list') {
        if (@$allowcontrollers) {
            say("Available controllers of project \"$pname\"\n\t", join("\n\t",@$allowcontrollers), "\n");
        } else {
            say("No controllers found");
        }
        return 1;
    }
    
    # Корректировка списков контроллеров
    my @clist;
    $controller = cleanProjectName($controller);
    unless ($controller) {
        if ($pcmd eq 'del') {
            # FOR DEL
            $controller = cleanProjectName($c->cli_select(
                    'Please select controller for removing:',
                    $allowcontrollers,
                    1,
                ));
        } else {
            # FOR ADD
            say("Already exists controllers:\n\t", join("\n\t",@$allowcontrollers), "\n");
            $controller = cleanProjectName($c->cli_prompt('Please enter new controller name:', 'Foo'));
        }
    }
    $controller =~ s/^(Index|Handlers)$//i;
    say("Controller incorrect") && return 0 unless $controller;
    $h{ControllerName} = $controller;
    
    # Типовые операции
    my $foo_dst = CTK::catfile($documentroot,'lib','MPM',$pname,$controller.".pm");
    if ($pcmd eq 'del') {
        # FOR DEL
        say("Controller \"$controller\" not exists. Operation aborted") && return 0 unless 
            grep {$_ eq $controller} @$allowcontrollers;
        
        unlink $foo_dst if (1
            && (-e $foo_dst) 
            && $c->cli_prompt("Are you sure you want delete controller file?:",'no') =~ /^\s*y/i
        );
        
        # Модифкация списка котроллеров
        @clist = grep {$_ ne $controller} @$allowcontrollers; # Удаляем
        
    } else {
        # FOR ADD
        say("Controller \"$controller\" already exists. Operation aborted") && return 0 if 
            grep {$_ eq $controller} @$allowcontrollers;
            
        # Проверка контроллера на уровне файлов
        my $overwrite = 1;
        $overwrite = 0 if (1
            && (-e $foo_dst) 
            && $c->cli_prompt("File \"$foo_dst\" already exists. Overwrite it?:",'no') !~ /^\s*y/i
        );
        
        # Модифкация списка котроллеров
        @clist = @$allowcontrollers;
        push @clist, $controller unless grep {$_ eq $controller} @clist;
        
        # Запись нового файла контроллера на диск
        start _ ">>> Writing \"$foo_dst\"";
        if ($overwrite) {
            try {
                my $tpl = new TemplateM(-file => $foo_src, -asfile => 1, -utf8 => 1);
                $tpl->stash(%h);
                CTK::bsave($foo_dst, $tpl->output(), 1);
                finish("OK");
            } catch {
                finish("ERROR");
                say("Processing \"$foo_src\" failed: $_");
            };
        } else {
            finish("SKIPPED");
        }
        
    }
    
    # Запись нового индексного файла
    start _ ">>> Writing \"$index_dst\"";
    try {
        my $itpl = new TemplateM(-file => $index_src, -asfile => 1, -utf8 => 1);
        $itpl->stash(%h);
        my $cbox = $itpl->start('Controllers');
        $cbox->loop(Controller => $_) foreach (grep {$_} @clist);
        $cbox->finish;
        CTK::bsave($index_dst, $itpl->output(), 1);
        finish("OK");
    } catch {
        finish("ERROR");
        say("Processing \"$index_src\" failed: $_");
    };
    
    # Запрос на выполнение команды
    if ($c->cli_prompt('Try to install the module automatically?:','yes') =~ /^\s*y/i) {
        _install($documentroot);
    } else {
        say("Your site can\'t installed! Please type following commands:\n");
        say("\tcd $documentroot");
        say("\tperl Makefile.PL");
        say("\tmake");
        say("\tmake test");
        say("\tmake install");
        say("\tmake clean");
    }

    say("Controller \"$controller\" was successfully added!") if $pcmd eq 'add';
    say("Controller \"$controller\" was successfully deleted!") if $pcmd eq 'del';
    
    1;
}
sub LIST {
    # Отображение списка доступных проектов и мест их расположения на диске
    my $c = _generalc();
    my $config = $c->config;
    say(NOTCONFIGURED) && return 0 unless $config->{loadstatus} && $config->{httpdroot};

    my $th = hash($config, 'project');
    my @ps = keys %$th;
    
    if (@ps) {
        my $tbl = Text::SimpleTable->new( 
            [ 3, '###' ],
            [ 25, 'PROJECT' ],
            [ 53, 'LOCATION' ],
        );
        my $i = 0;
        foreach my $p (@ps) {$i++;
            my $s = value($th, $p, 'servername') || 'SERVERNAME UNDEFINED';
            my $l = value($th, $p, 'documentroot') || 'LOCATION NOT CONFIGURED';
            $tbl->hr() if $i > 1;
            $tbl->row( $i, $p, sprintf('%s'."\n".'%s', $s,$l) )
        }
        say("Available projects:");
        say($tbl->draw);
    } else {
        say("No projects found");
    }
    
    return 1;
}

sub _generalc {
    # Общий для основных обработчиков
    my $c = new CTK ( cfgfile => $CONFFILE || CTK::CFGFILE );
    
    # Секция подготовки отвалидированнх параметров general конфигурации
    my $config = $c->config;
    $config->{general} = {
            configfile => $c->cfgfile,
            logdir     => $c->logdir,
            datadir    => $c->datadir,
            confdir    => $c->confdir,
        };
    
    return $c;
}
sub _result {
    # Процедура возвращает данные в выбранном (по типу) формате
    my $type  = shift || ''; # Тип
    my $rslth = shift || []; # Заголовки (линйный массив)
    my $rsltd = shift || []; # Данные
    
    return '' unless $type;
    return '' if $type =~ /no/i;
    return Dumper($rslth,$rsltd) if $type =~ /dump/i;
    #return Dump($rslth,$rsltd) if $type =~ /ya?ml/i;
    #return XMLout({heders => [{th=>$rslth}], data => [{td => $rsltd}]}, RootName => 'result', NoEscape => 1) if $type =~ /xml/i;;
    
    my %headers = ();
    my @headerc = ();
    my $i = 0;
    # максимумы данных
    foreach (@$rslth) {
        $headerc[$i] = length($_) || 1; # Счетчик
        $headers{$_} = $i; # КЛЮЧ -> [индекс]
        $i++;
    }
    foreach my $row (@$rsltd) {
        $i=0;
        foreach my $col (@$row) {
            $headerc[$i] = length($col) if defined($col) && length($col) > $headerc[$i];
            $i++
        }
    }
        
    # Формирование результата
    my $tbl = Text::SimpleTable->new(map {$_ = [$headerc[$headers{$_}],$_]} @$rslth);
    foreach my $row (@$rsltd) {
        my @tmp = ();
        foreach my $col (@$row) { push @tmp, (defined($col) ? $col : '') }
        $tbl->row(@tmp);
    }
    return $tbl->draw() || '';
}
sub _create_project_config {
    # Создание нового конфигурационного дампа
    my $pname = shift;
    my %ih = @_;
    
    return "<Project $pname>"
    ."\n\t"
    .join( "\n\t", map { 
            $_->[0]."\t".(defined $ih{$_->[0]} ? $ih{$_->[0]} : '') 
        } grep {$_->[1] != STATIC } @ATTRIBUTES )
    ."\n"
    ."</Project>";
}
sub _install {
    # Выполнение команды на установку проекта
    my $myroot = shift || getcwd();
    $myroot =~ s/\//\\/g if CTK::isostype('Windows');
    my $myperl = CTK::syscfg('perlpath') || 'perl';
    my $mymake = MPMinus::Helper::Skel::Backward::get_make() || 'make';
    CTK::execute(qq{cd $myroot && $myperl Makefile.PL && $mymake && $mymake test && $mymake install && $mymake clean});
}
1;

__END__

Этот код был нужен для нужд мейкфайла, но т.к. мы упразнили его то он стал автоматически не нужен

    # Перенос META.xml перед мейкингом
    if ( -e $metaf.".old" ) {
        unlink $metaf;
    } else {
        move($metaf,$metaf.".old") or debug("Move failed \"$metaf\" -> \"$metaf.old\": $!");
    }
