package MPMinus::Dispatcher; # $Id: Dispatcher.pm 146 2013-05-29 09:07:40Z minus $
use strict;

=head1 NAME

MPMinus::Dispatcher - URL Dispatching

=head1 VERSION

Version 1.03

=head1 SYNOPSIS

    package MPM::foo::Handlers;
    use strict;

    use MPMinus::Dispatcher;

    sub handler {
        my $r = shift;
        my $m = MPMinus->m;
    
        $m->set(
                disp => new MPMinus::Dispatcher($m->conf('project'),$m->namespace)
            ) unless $m->disp;
    
        ...

        return Apache2::Const::OK;
    }

=head1 DESCRIPTION

URL Dispatching

=head1 METHODS

=over 8

=item B<new>

    my $disp = new MPMinus::Dispatcher(
            $m->conf('project'),
            $m->namespace)
        );

=item B<get>

    my $drec = $disp->get(
            -uri => $m->conf('request_uri')
        );

=item B<set>

    package MPM::foo::test;
    use strict;
    
    ...

    $disp->set(
            -uri    => ['locarr','test',
                        ['/test.mpm',lc('/test.mpm')]
                       ],
            -init     => \&init,
            -response => \&response,
            -cleanup  => \&cleanup,
            
            ... and other handlers's keys , see later ...
            
            -meta     => {}, # See MPMinus::Transaction
            
        );

=back

=head1 HANDLERS AND KEYS

Supported handlers:

    -postreadrequest
    -trans
    -maptostorage
    -init
    -headerparser
    -access
    -authen
    -authz
    -type
    -fixup
    -response
    -log
    -cleanup

See L<MPMinus::BaseHandlers/"HTTP PROTOCOL HANDLERS"> for details

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
$VERSION = 1.03;

use Apache2::Const;
use CTK::Util qw/ :API /; # Утилитарий

sub new {
    my $class = shift;
    my @in = read_attributes([
          ['PROJECT','PRJ','SITE','PROJECTNAME','NAME'],
          ['NAMESPACE', 'NS']
        ],@_);

    # Основные атрибуты
    my $namespace = $in[1] || '';
    my %args = (
            project   => $in[0] || '', # Имя проекта
            namespace => $namespace,   # пространство имен для определения проектного модуля Index
            records   => {},           # Записи (URIs)
        );

    my $self = bless \%args, $class;
   
    # Первая запись. Запись по умолчанию (NOT_FOUND)
    $self->set('default');

    # Принимаем проектную единицу
    eval "
        use $namespace\::Index;
        $namespace\::Index\::init(\$self);
    "; 
    croak("Error initializing the module $namespace\::Index\: $@") if $@;
    
    return $self;
}
sub set {
    # Установщик данных для указанной записи
    my $self = shift;
    my @in = read_attributes([
          ['URI','URL','REQUEST','KEY'], # 0
          
          # HTTP Protocol Handlers
          ['POSTREADREQUEST','HPOSTREADREQUEST','POSTREADREQUESTHANDLER'],  # 1
          ['TRANS','HTRANS','TRANSHANDLER'],                                # 2
          ['MAPTOSTORAGE','HMAPTOSTORAGE','MAPTOSTORAGEHANDLER'],           # 3
          ['INIT','HINIT','INITHANDLER'],                                   # 4
          ['HEADERPARSER','HHEADERPARSER','HEADERPARSERHANDLER'],           # 5
          ['ACCESS','HACCESS','ACCESSHANDLER'],                             # 6
          ['AUTHEN','HAUTHEN','AUTHENHANDLER'],                             # 7
          ['AUTHZ','HAUTHZ','AUTHZHANDLER'],                                # 8
          ['TYPE','HTYPE','TYPEHANDLER'],                                   # 9
          ['FIXUP','HFIXUP','FIXUPHANDLER'],                                # 10
          ['RESPONSE','HRESPONSE','RESPONSEHANDLER'],                       # 11
          ['LOG','HLOG','LOGHANDLER'],                                      # 12
          ['CLEANUP','HCLEANUP','CLEANUPHANDLER'],                          # 13
          
          ['ACTION','ACTIONS','META'], # 14
          
        ],@_);

    # Устанавливаем запись
    my $uri = $in[0];
    my $uniqname;
    my $type = 'location';
    my %params;
    if (ref($uri) eq 'ARRAY') {
        # Не простая диспетчерезация
        croak("Invalid URI in the definition section of the called module") unless $uri->[0];
        if (lc($uri->[0]) eq 'regexp') {
            $type     = 'regexp';
            $uniqname = $uri->[1] || 'undefined'; # Уникальное имя
            %params = (
                regexp => $uri->[2] || qr/^undefined$/
            )
        } elsif (lc($uri->[0]) eq 'locarr') {
            $type     = 'locarr';
            $uniqname = $uri->[1] || 'undefined'; # Уникальное имя
            %params = (
                locarr => $uri->[2] || []
            )
        } elsif (lc($uri->[0]) eq 'mixarr') {
            $type     = 'mixarr';
            $uniqname = $uri->[1] || 'undefined'; # Уникальное имя
            %params = (
                mixarr => $uri->[2] || []
            )            
        } else {
            croak("Wrong type dispatch called module!")
        }
    } else {
        # Простая диспетчеризация
        $uniqname = $uri;
    }
    
    $self->{records}->{$uniqname} = {
            Postreadrequest => $in[1] || sub { Apache2::Const::OK },
            Trans           => $in[2] || sub { Apache2::Const::OK },
            Maptostorage    => $in[3] || sub { Apache2::Const::OK },
            Init            => $in[4] || sub { Apache2::Const::OK },
            headerparser    => $in[5] || sub { Apache2::Const::OK },
            Access          => $in[6] || sub { Apache2::Const::OK },
            Authen          => $in[7] || sub { Apache2::Const::OK },
            Authz           => $in[8] || sub { Apache2::Const::OK },
            Type            => $in[9] || sub { Apache2::Const::OK },
            Fixup           => $in[10] || sub { Apache2::Const::OK },
            Response        => $in[11] || \&default, # Самый главный обработчик!
            Log             => $in[12] || sub { Apache2::Const::OK },
            Cleanup         => $in[13] || sub { Apache2::Const::OK },
            
            type     => $type,         # Тип диспетчеризации
            params   => {%params},     # Параметры (внутренние)
            actions  => $in[14] || {}, # События
        };
    
}
sub get {
    # возвращаем обработчик
    my $self = shift;
    my @in = read_attributes([
          ['URI','URI','REQUEST','KEY'],
        ],@_);
    my $uri = $in[0] || 'default';
    my $ret = $uri;
    
    # Процесс определения соответствующего хэндлера состоит из ступеней.
    # Каждая ступень выполняется если не найдено искомое в предыдущей!
    
    # ступень 1
    # поиск по конкретному location
    $ret = 'default' unless grep {$_ eq $uri} keys %{$self->{records}};
    
    # ступень 2
    # поиск по массиву многих location
    if ($ret eq 'default') {
        # поиск результативного ключа
        my @locarr_keys = grep {$self->{records}->{$_}->{type} eq 'locarr'} keys %{$self->{records}};
        foreach my $key (@locarr_keys) {
            $ret = $key if grep {$uri eq $_} @{$self->{records}->{$key}->{params}->{locarr}};
        }
        $ret ||= 'default';
    }

    # ступень 3
    # поиск по массиву многих location и Regexp
    if ($ret eq 'default') {
        # поиск результативного ключа
        my @mixarr_keys = grep {$self->{records}->{$_}->{type} eq 'mixarr'} keys %{$self->{records}};
        foreach my $key (@mixarr_keys) {
            $ret = $key if grep {
                        if (ref $_ && lc(ref $_) eq 'regexp') {
                            $uri =~ $_
                        } else {
                            $uri eq $_
                        }
                    }
                    @{$self->{records}->{$key}->{params}->{mixarr}};
        }
        $ret ||= 'default';
    }

    
    # ступень 4
    # поиск по regexp
    if ($ret eq 'default') {
        my @regexp_keys = grep {$self->{records}->{$_}->{type} eq 'regexp'} keys %{$self->{records}};
        if (@regexp_keys) {
            ($ret) = grep {$uri =~ $self->{records}->{$_}->{params}->{regexp}} @regexp_keys;
            $ret ||= 'default';
        }
    }
   
    return $self->{records}->{$ret};
}
sub default { Apache2::Const::NOT_FOUND };

1;
