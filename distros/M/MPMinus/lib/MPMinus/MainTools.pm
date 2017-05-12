package MPMinus::MainTools; # $Id: MainTools.pm 128 2013-05-08 12:35:26Z minus $
use strict;

=head1 NAME

MPMinus::MainTools - The main function without the support of the configuration

=head1 VERSION

Version 1.24

=head1 SYNOPSIS

    use MPMinus::MainTools;

=head1 DESCRIPTION

The module works with the main functions without the support of the configuration

=over 8

=item B<correct_loginpass>

    my $login = correct_loginpass( "anonymous" ); # 'anonymous'
    my $password = correct_loginpass( "{MOON}" ); # ''

Correcting a login or password. Issued lc () format username / password thatmust not contain 
characters other than those listed:

    a-zA-Z0-9.,-_!@#$%^&*+=/\~|:;

Otherwise, it returns an empty value''

=item B<getHiTime>

See function L<Time::HiRes/gettimeofday>

=item B<getSID>

    my $sid = getSID( $length, $chars );
    my $sid = getSID( 16, "m" ); # 16 successful chars consisting of MD5 hash
    my $sid = getSID( 20 ); # 20 successful chars consisting of a set of chars 0-9A-Z
    my $sid = getSID(); # 16 successful chars consisting of a set of chars 0-9A-Z

Function returns Session-ID (SID)

$chars - A string containing a collection of characters or code:

    d - characters 0-9
    w - characters A-Z
    h - HEX characters 0-9A-F
    m - Digest::MD5 function from Apache::Session::Generate::MD5
      - default characters 0-9A-Z

=item B<geturl>

    my $data = geturl( "http://www.example.com" );
    my $data = geturl( "http://www.example.com", "login", "password" );

Getting a remote location or a simple authentication method in the argument. 
If the page is not then return empty ('').

=item B<msoconf2args>

Converting MSO configuration section to MultiStore -mso arguments

    my %args = msoconf2args($m->conf('store'));
    my $mso = new MPMinus::Store::MultiStore(
        -m   => $m,
        -mso => \%args,
    );

In conf/mso.conf:

    <store foo>
        dsn   DBI:mysql:database=NAME;host=HOST
        user  login
        pass  password
        <Attr>
            mysql_enable_utf8 1
            RaiseError        0
            PrintError        0
        </Attr>
    </store>

    <store bar>
        dsn   DBI:Oracle:SID
        user  login
        pass  password
        <Attr>
            RaiseError        0
            PrintError        0
        </Attr>
    </store>

=item B<current_datetime, localtime2datetime and tagRestore>

Deprecated functions

=back

=head1 HISTORY

=over 8

=item B<1.00 / 28.02.2008>

Init version on base mod_main 1.00.0002

=item B<1.01 / 12.01.2009>

Fixed bugs in functions *datatime*

=item B<1.10 / 27.02.2009>

Module is merged into the global module level

=item B<1.20 / 28.04.2011>

Binary file's mode supported

=item B<1.21 / 14.05.2011>

modified functions tag and slash

=item B<1.22 / 19.10.2011>

Added function datetime2localtime and localtime2datetime as alias for localtime2date_time.

Added alias current_datetime for current_date_time

=item B<1.23 / Wed Apr 24 14:53:38 2013 MSK>

General refactoring

=item B<1.24 / Wed May  8 15:37:02 2013 MSK>

Added function msoconf2args

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

use Exporter;
use vars qw($VERSION);
$VERSION = 1.24;

use base qw/Exporter/;
our @EXPORT = qw(
        tagRestore current_datetime localtime2datetime
        correct_loginpass
        getHiTime
        getSID
        geturl
        msoconf2args
    );
our @EXPORT_OK = @EXPORT;

use Time::HiRes qw(gettimeofday);
use Digest::MD5;
use LWP::Simple;
use HTTP::Request;
use LWP::UserAgent;
use HTTP::Headers;
use CTK::Util qw/current_date_time localtime2date_time tag_create/;
use CTK::ConfGenUtil qw/hash/;

sub correct_loginpass {
    # процедура корректировки логина/пароля. Выдаётся lc() формат логина/пароля
    my $v = shift || '';
    return "" if $v =~ /[^a-zA-Z0-9.,-_!@#\$%^&*+=\/\\~|]|[:;]/g;
    return lc($v);
}
sub getHiTime { 
    return gettimeofday() 
}
sub getSID {
    # Процедура возвращает Session-ID (SID) для контроля состояния сессий
    # IN: 
    #  $length - Количество символов
    #  $chars  - Строка символов набора или код:
    #        d - символы 0-9
    #        w - символы A-Z
    #        h - шеснадцатиричные символы 0-9A-F
    #        m - Digest::MD5 function from Apache::Session::Generate::MD5
    #          - По умолчанию символы 0-9A-Z
    # OUT:
    #  SID
    my $length = shift || 16; # Количество символов в случайной последовательности
    my $chars    = shift || "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"; # Строка символов

    # Copyright(c) 2000, 2001 Jeffrey William Baker (jwbaker@acm.org)
    # Distribute under the Perl License
    # Source: Apache::Session::Generate::MD5
    return substr(
        Digest::MD5::md5_hex(
            Digest::MD5::md5_hex(
                time() . {} . rand() . $$
            )
        ), 0, $length) if $chars =~ /^\s*m\s*$/i;

    $chars = "0123456789" if $chars =~ /^\s*d\s*$/i;
    $chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ" if $chars =~ /^\s*w\s*$/i;
    $chars = "0123456789ABCDEF" if $chars =~ /^\s*h\s*$/i;
    
    my @rows = split //, $chars;
    
    my $retv = '';
    for (my $i=0; $i<$length; $i++) {
        $retv .= $rows[int(rand(length($chars)-1))]
    }
    
    return "$retv"
}
sub geturl {
    #
    # Получение ресурса простым или аутентификационным способом в зависимости от аргумента.
    # Если страницы нет то возвращается пусто
    #
    my $url = shift || return ''; # URL (адрес файла)
    my $login = shift || ''; # Логин Apache авторизации клиента. Иначе авторизация не производится
    my $password = shift || ''; # Пароль Apache авторизации клиента
    
    if ($login eq '' ) {
        return get($url);
    } else {
        my $ua  = new LWP::UserAgent; 
        my $req = new HTTP::Request(GET => $url);
        $req->authorization_basic($login, $password); 
        my $res = $ua->request($req);
        return $res->is_success ? $res->content : '';
    }
}
sub msoconf2args {
    #
    # Преобразование структуры конфигурации MSO в структуру для интерфейса MultiStore
    #
    my $mso_conf = shift;
    my @stores = $mso_conf && ref($mso_conf) eq 'HASH' ? keys(%$mso_conf) : ();
    my %args = ();
    for (@stores) {
        my $store = hash($mso_conf, $_);
        $args{$_} = {};
        while (my ($key, $value) = each %$store) {
            $args{$_}{"-".$key} = $value
        }
    }
    return %args;
}

# Неофициальные функции для обратной совместимости проектов suffit, mnshome.info и share.mnshome.info
sub tagRestore { &tag_create(@_) }
sub current_datetime { &current_date_time(@_) }
sub localtime2datetime { &localtime2date_time(@_) }

1;

