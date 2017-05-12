package MPMinus::Helper::Util; # $Id: Util.pm 224 2017-04-04 10:27:41Z minus $
use strict;

=head1 NAME

MPMinus::Helper::Util - MPMinus Helper's utility

=head1 VERSION

Version 1.03

=head1 SYNOPSIS

    use MPMinus::Helper::Util;

=head1 DESCRIPTION

MPMinus Helper's utility

=head1 FUNCTIONS

=over 8

=item B<cleanProjectName>

    my $name = cleanProjectName( "foo" );

Returns clean name of project

=item B<cleanServerName>

    my $name = cleanServerName( "localhost:80" );

Returns clean name of server

=item B<cleanServerNameF>

    my $name = cleanServerNameF( "localhost" );

Returns clean name of server as file

=item B<getApache>, B<getApache2>

    my $hash = getApache();

Returns HTTPD_ROOT, SERVER_CONFIG_FILE, SERVER_VERSION and APACHE_VERSION as hash structure
(reference).

=item B<newconfig>

    my $config = newconfig( $c );

Returns new configuration

=item B<to_void>

    my $v = to_void( $value );

Returns '' (void) if undefined $value else - returns $value

=back

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
$VERSION = 1.03;

use base qw /Exporter/;
our @EXPORT = qw(
        getApache getApache2
        newconfig
        to_void
        cleanProjectName
        cleanServerName
        cleanServerNameF
    );

use CTK::Util qw/ :ALL /;
use CTK::ConfGenUtil;
use Try::Tiny;

sub getApache2 {
    # Процедура получения (HTTP_ROOT, SERVER_CONFIG_FILE, SERVER_VERSION, APACHE_VERSION) исходя из данных запущенного APACHE
    my $httpdata;
    my $httpdpath;
    if (isostype("Windows")) {
        $httpdpath = execute(q{pv.exe -e 2>NUL});
        if ($httpdpath =~ /^httpd.exe\s+\d+\s+\S+\s+(.+?)\s*$/m) {
            $httpdpath = $1;
            $httpdata = execute(qq{$httpdpath -V});
        } else {
            if ($httpdpath =~ /^(apache.+?)\s+\d+\s+\S+\s+(.+?)\1\s*$/im) {
                $httpdpath = catfile($2,'httpd.exe');
                $httpdata  = execute(qq{$httpdpath -V});
            } else {
                $httpdpath = '';
                $httpdata  = '';
            }
        }
    } else {
        # Fix #198
        my @err;
        foreach my $httpd (qw/httpd apache apachectl apache2ctl apache2 apache22/) {
            my $cmd = qq{$httpd -V};
            try {
                $httpdata = execute($cmd)
            } catch {
                push @err, sprintf("%s: %s", $cmd, $_)
            };
            last if $httpdata && $httpdata =~ /HTTPD_ROOT/im;
        }
        carp(join "\n", @err) if (!$httpdata) && @err
    }
    
    my $httpd_root          = $httpdata =~ /HTTPD_ROOT\="(.+?)"/m ? $1 : '';
    my $server_config_file  = $httpdata =~ /SERVER_CONFIG_FILE\="(.+?)"/m ? $1 : '';
    my $sver                = $httpdata =~ /version\:\s+[a-z]+\/([0-9.]+)/im ? $1 : '';
    my $aver                = 0;
    
    if ($sver =~ /([0-9]+)\.([0-9]+)\.([0-9]+)/) {
        $aver = $1 + ($2/100) + ($3/10000);
    } elsif ($sver =~ /([0-9]+)\.([0-9]+)/) {
        $aver = $1 + ($2/100);
    } elsif ($sver =~ /([0-9]+)/) {
        $aver = $1;
    }
    
    my $httpdconfig = '';
    if ($server_config_file && $httpd_root) {
        $httpdconfig = catfile($httpd_root,$server_config_file);
    }
    
    my $acc = '';
    unless ($httpdconfig && -e $httpdconfig) {
        foreach (split /[\/\\]/, $httpdpath) {
            $acc = $acc ? catfile($acc,$_) : $_;
            
            $httpdconfig = catfile($acc,$server_config_file);
            if ($httpdconfig && (-e $httpdconfig) && ((-f $httpdconfig) || (-l $httpdconfig))) {
                last;
            }
        }
    }
    
    return {
            HTTPD_ROOT          => $acc || $httpd_root, 
            SERVER_CONFIG_FILE  => $httpdconfig || '',
            SERVER_VERSION      => $sver,
            APACHE_VERSION      => $aver,
        };

}
sub getApache { goto &getApache2 }
sub newconfig {
    # Запрос данных конфигурации
    my $c = shift;
    my $cfg = $c->config();
    
    my %newcfg = (
            Include => 'conf/*.conf',
        );

    my ($k,$v,$d) = ('','','');
    my $apache = getApache();

    # Apache HTTPD_ROOT
    $k = "HttpdRoot";
    $newcfg{$k} = $c->cli_prompt('Apache HTTPD_ROOT:', _void(value($cfg,lc($k)) || $apache->{HTTPD_ROOT}));

    # Apache SERVER_CONFIG_FILE
    $k = "ServerConfigFile";
    $newcfg{$k} = $c->cli_prompt('Apache SERVER_CONFIG_FILE:', _void(value($cfg,lc($k)) || $apache->{SERVER_CONFIG_FILE}));
    
    # Apache configuration
    my %apacheconfig;
    if ((-e $newcfg{ServerConfigFile}) && -e $newcfg{HttpdRoot}) {
        my $apacheconf = new Config::General(
            -ConfigFile       => $newcfg{ServerConfigFile},
            -ConfigPath       => [$newcfg{HttpdRoot}],
            -ApacheCompatible => 1,
            -LowerCaseNames   => 1,
        );
        %apacheconfig = $apacheconf->getall;
    }
    
    # ModperlRoot
    $k = "ModperlRoot";
    my @mpvs = ('none', _void(webdir()), 'custom'
        );
    my $vks = value($apacheconfig{documentroot} || '');
    unshift(@mpvs,$vks) if $vks;
    $v = $c->cli_select('ModperlRoot directory:',\@mpvs,1);
    $v = $c->cli_prompt('ModperlRoot directory:',_void(value($cfg,lc($k))),) if ($v && $v eq 'custom');
    $newcfg{$k} = ($v && $v eq 'none') ? undef : $v;
    
    # NameVirtualHost
    $k = "NameVirtualHost";
    my $namevirtualhost = array($apacheconfig{namevirtualhost} || ['*:80']);
    push @$namevirtualhost, 'custom','none';
    $v = $c->cli_select('NameVirtualHost:', $namevirtualhost, 1);
    $v = $c->cli_prompt('NameVirtualHost:',_void(value($cfg,lc($k))),) if ($v && $v eq 'custom');
    $newcfg{$k} = ($v && $v eq 'none') ? undef : $v;

    # ServerName
    $k = "ServerName";
    my $servername = array($apacheconfig{servername} || ['localhost']);
    push @$servername, 'custom','none';
    $v = $c->cli_select('ServerName (host):', $servername, 1);
    $v = $c->cli_prompt('ServerName (host):',_void(value($cfg,lc($k))),) if ($v && $v eq 'custom');
    $newcfg{$k} = ($v && $v eq 'none') ? undef : $v;

    # ErrorMail
    $k = "ErrorMail";
    my $errormail = array($apacheconfig{serveradmin} || ['root@localhost']);
    push @$errormail, 'custom','none';
    $v = $c->cli_select('ErrorMail (ServerAdmin):', $errormail, 1);
    $v = $c->cli_prompt('ErrorMail: (ServerAdmin):',_void(value($cfg,lc($k))),) if ($v && $v eq 'custom');
    $newcfg{$k} = ($v && $v eq 'none') ? undef : $v;

    # SMTP
    $k = "SMTP";
    $newcfg{$k} = $c->cli_prompt('SMTP server:', _void(value($cfg,lc($k))));
    
    # MailTo
    $k = "MailTo";
    $newcfg{$k} = $c->cli_prompt('Address MailTO:', _void(value($cfg,lc($k)) || $newcfg{ErrorMail}));
    
    # MailCC
    $k = "MailCC";
    $newcfg{$k} = $c->cli_prompt('Address MailCC:', _void(value($cfg,lc($k))));
    
    # MailFrom
    $k = "MailFrom";
    $newcfg{$k} = $c->cli_prompt('Address MailFrom:', _void(value($cfg,lc($k)) || $newcfg{ErrorMail}));

    # MailCharset
    $k = "MailCharset";
    $newcfg{$k} = $c->cli_prompt('Mail Charset for translating into UTF8:', _void(value($cfg,lc($k)) || 'Windows-1251'));
    
    # MailCmd
    $k = "MailCmd";
    $newcfg{$k} = $c->cli_prompt('Mail program (sendmail):', _void(value($cfg,lc($k)) || '/usr/sbin/sendmail'));

    # MailFlag
    $k = "MailFlag";
    $newcfg{$k} = $c->cli_prompt('Mail program\'s flag:', _void(value($cfg,lc($k)) || '-t'));
    
    return { %newcfg };
}
sub to_void { goto &_void }
sub cleanProjectName {
    # Правка (чистка) имени проекта
    my $pn = _void(shift);
    $pn =~ s/[^a-z0-9_]/X/ig;
    return $pn;
}
sub cleanServerName {
    # Правка (чистка) имени сервера (сайта)
    my $sn = _void(shift);
    $sn =~ s/[^a-z0-9_\-.:]/X/ig;
    return $sn;
}
sub cleanServerNameF {
    # Правка (чистка) имени сервера (сайта) в стандарте имен файлов
    my $sn = _void(shift);
    $sn =~ s/[^a-z0-9_\-.]//ig;
    return $sn;
}

sub _void {
    # Возвращает '' (void) место undef
    my $v = shift;
    return '' unless defined $v;
    return $v;
}
1;

__END__

