package MPMinus::Transaction; # $Id: Transaction.pm 218 2013-10-01 15:22:22Z minus $
use strict;

=head1 NAME

MPMinus::Transaction - MVC SKEL transaction

=head1 VERSION

Version 1.05

=head1 SYNOPSIS

    my $q = new CGI;
    my ($actObject,$actEvent) = split /[,]/, $q->param('action') || '';
    $actObject = 'default' unless $actObject && $m->ActionCheck($actObject);
    $actEvent = $actEvent && $actEvent =~ /go/ ? 'go' : '';
    
    $r->content_type( $m->getActionRecord($actObject)->{content_type} );
    
    my $status = $m->ActionTransaction($actObject,$actEvent);
    
    my $status = $m->ActionExecute($actObject,'cdeny');

=head1 DESCRIPTION

Working with MVC SKEL transactions.

See MVC SKEL transaction C<DESCRIPTION> file or L<MPMinus::Manual> 

=head1 METHODS

=over 8

=item B<ActionTransaction>

    my $status = $m->ActionTransaction( $actObject, $actEvent );

Start MVC SKEL Transaction by $actObject and $actEvent

=item B<ActionExecute>

    my $status = $m->ActionExecute( $actObject, $handler_name );

Execute $handler_name action by $actObject.

$handler_name must be: mproc, vform, cchck, caccess, cdeny

=item B<ActionCheck>

    my $status = $m->ActionCheck( $actObject );

Check existing status of $actObject handler

=item B<getActionRecord>

    my $struct = $m->getActionRecord( $actObject );

Returns meta record of $actObject

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
$VERSION = 1.05;

use Apache2::Const;
use CTK::Util qw/ :API /;

use constant {
        HOOKS => { # Returned values of hooks / Types of hooks
                caccess => {
                        aliases => [qw/caccess access/],
                        type    => 'DUAL', # BOOL and HTTP way
                    },
                cdeny   => {
                        aliases => [qw/cdeny deny/],
                        type    => 'HTTP', # Analyzing common constants and HTTP 1.1 status codes
                    },
                cchck   => {
                        aliases => [qw/cchck chck check/],
                        type    => 'BOOL', # 0 - false / !0 - true
                    },
                mproc   => {
                        aliases => [qw/mproc proc proccess/],
                        type    => 'HTTP', # Analyzing common constants and HTTP 1.1 status codes
                    },
                vform   => {
                        aliases => [qw/vform form/],
                        type    => 'HTTP', # Analyzing common constants and HTTP 1.1 status codes
                    },
            },
    };

sub ActionTransaction {
    # Основная транзакция (возвращает код возврата)
    my $m = shift || '';
    my $key = shift || return 0;
    my $event = shift || '';
    croak("The method call is made ActionTransaction not in the style of OOP") unless ref($m) =~ /MPMinus/;
    
    my $sts = 0; 
    
    # Выполнение процедуры доступа (false - deny; true - allow)
    $sts = ActionExecute($m,$key,'caccess');
    
    # Проверка на доступ
    unless ($sts) {
        # Проверка не прошла - запуск обработчика cdeny
        $sts = ActionExecute($m,$key,'cdeny');
        return $sts;
    }
    return $sts if $sts >= 300; # Возврат если код 300 и более (анализируется результат caccess)
      
    # Запуск процесса если есть событие и удачно выполнилась проверка (валидация) параметров
    $sts = ActionExecute($m,$key,'mproc') if (($event =~ /go/i) && ActionExecute($m,$key,'cchck'));
    return $sts if $sts >= 300; # Возврат если код 300 и более
    
    # Показываем форму
    $sts = ActionExecute($m,$key,'vform'); 
    return $sts;
}
sub ActionExecute {
    # Выполнить один или несколько процедур обработчиков до первого 0-го (false) кода возврата
    my $m = shift || '';
    my $key = shift || return 0;
    my $hook = shift || return 0;
    my @params = @_;
    croak("The method call is made ActionExecute not in the style of OOP") unless ref($m) =~ /MPMinus/;

    return 0 unless ActionCheck($m,$key); # Если ключа нет -- выход
    my %hooks = %{(HOOKS)};
    return 0 unless grep {$_ eq $hook} keys %hooks; # Возврат 0 если неопределен контекст того что возвращать (default)

    # принимаем хендлер обработчика .mpm
    my $grec = $m->drec;
    my $rec = $grec->{actions}{$key}{handler};
    my $phase = _getPhaseByAlias($rec,$hook);
    
    #$m->debug("> Running $hook");
    
    #no strict 'refs'; # Добавлено для возможности доступа к ссылкам как процедурам
    if (ref($phase) eq 'CODE') {
        # Выполняем код
        #$m->debug("> -- $hook -> CODE");
        return $phase->($m,@params)
    } elsif (ref($phase) eq 'ARRAY') {
        # Выполняем каскад кодов до первой неудачи
        my $status;
        foreach (@$phase) {
            # $m->debug($_->($m,@params));
            $status = (ref($_) eq 'CODE') ? $_->($m,@params) : 0;
            #$m->debug("> $hook -> CODE[$status]");
            my $typ = $hooks{$hook}{type};
            
            if ($typ eq 'BOOL') {
                last unless $status; # Выход если хотябы кто-то вернул значение false
            } elsif ($typ eq 'HTTP') {
                # Выход если ответ >=300 (REDIRECTIONS AND ERRORS)
                last unless (($status =~ /^[+\-]?\d+$/) && $status < 300);
            } elsif ($typ eq 'DUAL') {
                last unless $status; # Выход если хотябы кто-то вернул значение false
                # Выход если ответ 0 (OK) или >=300 (REDIRECTIONS AND ERRORS)
                last unless (($status =~ /^[+\-]?\d+$/) && $status < 300);
            } else { # VOID and etc.
                $status = Apache2::Const::OK;
            }
        }
        return $status;
    } else {
        #$m->debug("> -- $hook -> VOID");
        return 0;
    }
    return 0;
}
sub ActionCheck {
    my $m = shift || '';
    my $key = shift || return 0;
    croak("The method call is made ActionCheck not in the style of OOP") unless ref($m) =~ /MPMinus/;
    return $m->drec->{actions}{$key} ? 1 : 0;
}
sub getActionRecord {
    # Прочитать метаопределения по ключу или все
    my $m = shift || '';
    my $key = shift;
    croak("The method call is made getActionRecord not in the style of OOP") unless ref($m) =~ /MPMinus/;
    my $grec = $m->drec;
    if ($key) {
        return $grec->{actions}{$key} ? $grec->{actions}{$key} : undef;
    }
    return $grec->{actions};
}
sub _getPhaseByAlias {
    my $rec = shift || {};
    my $hook = shift || '_';
    my %hooks = %{(HOOKS)};
    my $aliases = $hooks{$hook}{aliases};
    
    my $ret;
    foreach (@$aliases) {
        if ($rec->{$_} && ref($rec->{$_})) {
            $ret = $rec->{$_};
            last;
        }
    }
    
    return $ret;
}
1;
