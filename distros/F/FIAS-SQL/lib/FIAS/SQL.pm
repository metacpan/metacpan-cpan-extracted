package FIAS::SQL;
$FIAS::SQL::VERSION = '0.08';
# ABSTRACT: Модуль для минимальной работы с данными из базы ФИАC https://fias.nalog.ru/FiasInfo.aspx

use strict;
use warnings;
use utf8;

use DBI;
use XBase;
use LWP::UserAgent;
use Carp qw ( confess );
use Encode qw ( decode );
use Readonly;
use v5.10;


# Описываем уровни адресных объектов в человекочитаемом виде.
# Уровень объекта может принимать только нижеперечисленные значения
# Условно выделены следующие уровни адресных объектов:
Readonly our $LEVELS => {
   # 1 – уровень региона
   region                    => '1',
   # 3 – уровень района
   district                  => '3',
   # 35 – уровень городских и сельских поселений
   settlement => '35',
   # 4 – уровень города
   town                      => '4',
   # 6 – уровень населенного пункта
   inhabitet_locality        => '6',
   # 65 – планировочная структура
   planning_structure        => '65',
   # 7 – уровень улицы
   street                    => '7',
   # 75 – земельный участок
   stead                     => '75',
   # 8 – здания, сооружения, объекта незавершенного строительства
   structure                 => '8',
   # 9 – уровень помещения в пределах здания, сооружения
   premises                  => '9'
};


sub new {
    my ( $class, %params ) = @_;

    # параметры подключения к базе
    my $db_connection = delete $params{db_connection};

    my $dsn = delete $db_connection->{dsn}
        or confess 'no dsn!';

    my $login    = delete $db_connection->{login};
    my $password = delete $db_connection->{password};

    my $self;

    $self->{dbh} =  DBI->connect( $dsn, $login, $password, $params{additional_connection_params} )
       or confess $DBI::errstr;

    bless $self, $class;

    return $self;
}

sub load_files {
    my ( $self, %params ) = @_;

    my $directory   = delete $params{directory};
    my $update_flag = delete $params{update};

    opendir( my $dh, $directory ) or confess $!;

    # Получаем все файлы из папки $directory
    my @files;
    while ( my $file = readdir( $dh ) ) {
         push @files, $file
            if $file =~ /\.[Dd][Bb][Ff]$/;
    }
    closedir( $dh );

    # хендлер базы
    my $dbh = $self->{dbh};

    # TODO надо будет в следующей версии продумать этот момент, когда обновление будем делать
    # перед заполнением базы хорошо бы её дропнуть
    #$dbh->do("DROP DATABASE IF EXISTS $basename");
    #$dbh->do("CREATE DATABASE $basename");
    #$dbh->do("USE $basename");

    # Хеш полей базы( используем при обновлении )
    my %sql_tables_names;
    # перебираем все файлы
    for my $dbf_file_name ( @files ) {

        # Получаем имя таблицы для SQL без номера региона и расширения
        # HOUSE89.DBF превращается в HOUSE
        ( my $sql_table_name = $dbf_file_name ) =~ s/\d*\.[Dd][Bb][Ff]$//;

        # Информация в данных таблицах не нужна
        next if $dbf_file_name =~ /^D/
            || $sql_table_name eq 'NORDOC'
            || $sql_table_name eq 'STEAD'
            || $sql_table_name eq 'NDOCTYPE';

        # Получаем доступ к таблице dbf
        my $table = XBase->new( "$directory/$dbf_file_name" ) or confess XBase->errstr;

        # индекс последней записи в dbf
        my $index_of_last_record  = $table->last_record;
        # массив типов записей в таблице dbf
        my @type  = $table->field_types;
        # массив имён полей в таблице dbf
        my @name  = $table->field_names;
        # массив длин полей в таблице dbf
        my @len   = $table->field_lengths;
        # массив количества знаков после запятой полей 'N' в таблице dbf
        my @dec   = $table->field_decimals;

        # сохраняем имена таблиц для последующей обработки при обновлении
        if ( $update_flag ) {
            $sql_tables_names{ lc $sql_table_name} = 1;
            $sql_table_name .= '_';
        }
        $dbh->do(_create_table( $sql_table_name, $table ) );

        # счётчик записей
        my $all_records = -1;
        # буфер записей
        my @sqldata;

        my $fields_for_insert = '(' . lc( join( ',', _get_table_fields( $sql_table_name, $table ) ) ) . ')';

        # выдёргиваем из файла по одной записи
        my $cursor = $table->prepare_select();
        while ( my $record = $cursor->fetch_hashref() ) {
            $all_records++;
            # Забираем только актуальные записи
            push @sqldata,  '('. _convert_data( $record, $table, $sql_table_name ) . ')'
                unless _check_record_actuality( $record );

            # Если есть актуальные записи и их накопилось 5000 или считали последнюю запись файла,
            # необходимо закоммитить значения в таблицу, если конечно есть что коммитить
            if ( scalar @sqldata && !( scalar @sqldata % 5000) || $all_records == $index_of_last_record ) {
                my $sql_table = lc $sql_table_name;
                $dbh->do( "REPLACE INTO $sql_table $fields_for_insert VALUES " . join(',', @sqldata ) )
                    or confess $DBI::errstr;
                undef @sqldata;
            }
        }
       print "Table $dbf_file_name copied\n";
       $table->close;
    }

    # после обработки файлов, при обновлении заменяем файлы
    if ( $update_flag ){
	   for my $table ( keys %sql_tables_names ) {
	       my $tmp_table = $table . '_';
	       $dbh->do( "DROP TABLE $table" ) or confess $DBI::errstr;
	       $dbh->do( "ALTER TABLE $tmp_table RENAME $table") or confess $DBI::errstr;
	   }
    }
    # Доработка таблиц для уменьшения и убыстрания
    # TODO перенести в функции создания таблиц
    $dbh->do('ALTER TABLE addrob DROP COLUMN nextid');
    $dbh->do('ALTER TABLE house  DROP COLUMN enddate');
    $dbh->do('ALTER TABLE room   DROP COLUMN nextid');
}

sub get_address_objects {
    my ( $self, %params ) = @_;

    my $parentguid = $params{parentguid};

    # Разрешаются только вышеперечисленные уровни
    confess 'level is incorrect'
        if $params{aolevel} && !$LEVELS->{ $params{aolevel} };

    # Забираем числовое значения уровня для выборкиж
    my $aolevel;
    $aolevel = $LEVELS->{ $params{aolevel} }
        if $params{aolevel};

    my $sqlquery = 'SELECT * FROM addrob';
    my ( @where, @binds );

    $sqlquery .= ' WHERE '
        if ( $aolevel || $parentguid);

    # Добавляем WHERE в зависимости от пришедших параметров
    if ( $aolevel ) {
        push @where, 'aolevel = ?';
        push @binds, $aolevel;
    }

    if ( $parentguid ) {
        # если приходит мультизначение
        if ( ref $parentguid eq 'ARRAY' ) {
            push @where, 'parentguid in (' . join (',', ('?') x  @$parentguid) . ')';
            push @binds, @$parentguid;
        }
        else {
            push @where, 'parentguid = ?';
            push @binds, $parentguid;
        }
    }

    $sqlquery .= join( ' AND ', @where );

    return ref $parentguid eq 'ARRAY'
           ? $self->{dbh}->selectall_arrayref( $sqlquery, undef, @binds )
           : $self->{dbh}->selectall_arrayref( $sqlquery, { Slice => {} }, @binds )
}

sub get_address_objects_guids_only {
    my ( $self, %params ) = @_;

    return [map{ $_->{aoguid} } @{ $self->get_address_objects( %params ) } ];
}


sub get_sublevels_for_objects {
    my ( $self, $parentguid ) = @_;

    # Должен быть id родительского объекта
    confess 'parentguid is empty!'
        unless $parentguid;

    my $sublevels = $self->{dbh}->selectcol_arrayref(
        'SELECT DISTINCT aolevel FROM addrob WHERE parentguid = ? ORDER BY aolevel',
        undef,  $parentguid);

    my %reversed_LEVELS = reverse %$LEVELS;

    return [ map { $reversed_LEVELS{ $_ } } @$sublevels ];
}
sub get_data_for_object_by_aoguid {
    my ( $self, $aoguid ) = @_;

    # Должен быть id  объекта
    confess 'aoguid is empty!'
        unless $aoguid;

    return $self->{dbh}->selectrow_hashref(
        'SELECT aoguid, aolevel, offname, shortname, parentguid, postalcode FROM addrob WHERE aoguid = ?',
        undef,  $aoguid );
}
sub get_data_for_object_by_aoguid_array{
    my ( $self, $aoguid ) = @_;

    # Должен быть id  объекта
    confess 'aoguid is empty!'
        unless $aoguid;

    return $self->{dbh}->selectrow_array("SELECT * FROM addrob where aoguid = '$aoguid'");
}
sub add_object_to_base {
    my ( $self, $table, @values ) = @_;

    # эскейпим данные
    $_ = "\'$_\'" for @values;

   # собираем данные региона в строку
   my $values_string = join(',', @values );

   $self->{dbh}->do( "INSERT INTO $table VALUES($values_string)")
       or confess $DBI::errstr; ;

}

sub get_houses_of_address_objects {
    my ( $self, $aoguid ) =  @_;

    my $sqlquery = 'SELECT * FROM house ';

    $sqlquery .= ' WHERE aoguid '
        if $aoguid;

    my @binds;
    if ( $aoguid ) {
        if ( ref $aoguid eq 'ARRAY' ){
            $sqlquery .= ' in (' . join (',', ('?') x @$aoguid) . ')';
            push @binds, @$aoguid;
        }
        else {

            $sqlquery .= ' = ?';
            push @binds, $aoguid;
        }
    }

    return ref $aoguid eq 'ARRAY'
           ? $self->{dbh}->selectall_arrayref( $sqlquery, undef, @binds )
           : $self->{dbh}->selectall_arrayref( $sqlquery, { Slice => {} }, @binds )

}

sub get_data_for_house_by_houseguid {
    my ( $self, $houseguid ) =  @_;

    # Должен быть id  дома
    confess 'houseguid is empty!'
        unless $houseguid;

    return $self->{dbh}->selectrow_hashref(
        'SELECT housenum, buildnum, strucnum, aoguid, houseguid, postalcode FROM house WHERE houseguid = ?',
        undef,  $houseguid );
}

sub get_houses_guids_only {
    my ( $self, %params ) = @_;

    return [map{ $_->{houseguid} } @{ $self->get_houses_of_address_objects() } ];
}

sub get_rooms_of_address_objects {
    my ( $self, $houseguid ) =  @_;

    # ID дома не может быть пустым
    confess 'houseguid is empty!' unless $houseguid;

    my $sqlquery = 'SELECT * FROM room WHERE houseguid ';

    my @binds;

    if ( ref $houseguid eq 'ARRAY' ){
        $sqlquery .= ' in (' . join (',', ('?') x @$houseguid) . ')';
        push @binds, @$houseguid;
    }
    else {

        $sqlquery .= ' = ?';
        push @binds, $houseguid;
    }

    return ref $houseguid eq 'ARRAY'
           ? $self->{dbh}->selectall_arrayref( $sqlquery, undef, @binds )
           : $self->{dbh}->selectall_arrayref( $sqlquery, { Slice => {} }, @binds );
}

sub get_data_for_room_by_roomguid {
    my ( $self, $roomguid ) =  @_;

    # Должен быть id  дома
    confess 'roomguid is empty!'
        unless $roomguid;

    return $self->{dbh}->selectrow_hashref(
        'SELECT flatnumber, flattype.shortname AS flattype, houseguid, roomguid, postalcode, roomnumber, roomtype.shortname AS roomtype FROM room
                    JOIN flattype ON flattype.fltypeid = room.flattype
                    JOIN roomtype ON roomtype.rmtypeid = room.roomtype
                    WHERE roomguid = ?',
        undef,  $roomguid );
}

sub get_data_for_table {
    my ( $self, $table_name ) =  @_;

    return $self->{dbh}->selectall_arrayref( "select * from $table_name" );
}

sub get_parent_record_chain_by_aoguid {
    my ( $self, $aoguid ) =  @_;

    # Должен быть id
    confess 'aoguid is empty!'
        unless $aoguid;

    my $levels_chain;
    my %reversed_LEVELS = reverse %$LEVELS;

    my $ao_data = $self->get_data_for_object_by_aoguid( $aoguid );
    confess 'wrong aoguid!' unless $ao_data;
    push @$levels_chain, { guid => $ao_data->{aoguid}, level => $reversed_LEVELS{ $ao_data->{aolevel} } };

    while( $reversed_LEVELS{ $ao_data->{aolevel} } ne 'region' ) {
        $ao_data = $self->get_data_for_object_by_aoguid( $ao_data->{parentguid} );
        push @$levels_chain, { guid => $ao_data->{aoguid}, level => $reversed_LEVELS{ $ao_data->{aolevel} } };
    }

    return $levels_chain;
}


sub get_parent_record_chain_by_houseguid {
    my ( $self, $houseguid ) =  @_;

    # Должен быть id
    confess 'houseguid is empty!'
        unless $houseguid;

    my $levels_chain;

    my $house_data = $self->get_data_for_house_by_houseguid( $houseguid );
    confess 'wrong houseguid' unless $house_data;
    push @$levels_chain, { guid => $house_data->{houseguid}, level => 'house' };
    push @$levels_chain, @{ $self->get_parent_record_chain_by_aoguid( $house_data->{aoguid} ) };

    return $levels_chain;
}


sub get_parent_record_chain_by_roomguid {
    my ( $self, $roomguid ) =  @_;

    # Должен быть id
    confess 'roomguid is empty!'
        unless $roomguid;

    my $levels_chain;

    my $room_data = $self->get_data_for_room_by_roomguid( $roomguid );
    confess 'wrong roomguid' unless $room_data;
    push @$levels_chain, { guid => $room_data->{roomguid}, level => 'room' };
    push @$levels_chain, @{ $self->get_parent_record_chain_by_houseguid( $room_data->{houseguid} ) };

    return $levels_chain;
}
sub set_database_version {
     my ( $self, $version ) = @_;

    # хендлер базы
    my $dbh = $self->{dbh};

    # создаём индексы
    $dbh->do( 'CREATE TABLE IF NOT EXISTS version ( database_version INT (8), restriction ENUM(\'\') PRIMARY KEY )' )
                    or confess $DBI::errstr;
    $dbh->do( "REPLACE INTO version (database_version) VALUES ( $version )" )
                    or confess $DBI::errstr;
}

sub get_database_version {
    my ( $self ) = @_;

    # хендлер базы
    my $dbh = $self->{dbh};

    return $dbh->selectrow_arrayref('SELECT database_version FROM version')->[0];
}
sub get_link_for_full_database_dbf{
    return 'http://fias.nalog.ru/Public/Downloads/Actual/fias_dbf.rar';
}
sub get_actual_base_version {
    my $ua = LWP::UserAgent->new;

    my $get = $ua->get( 'http://fias.nalog.ru/Public/Downloads/Actual/VerDate.txt', ':content_file'=>'version.txt' );

    open my $file, '<', "version.txt";
    my $firstline = <$file>;
    $firstline =~ s/\.//g;
    close $file;
    unlink 'version.txt';

    return $firstline;
}

sub clone_base_structure {
    my ( $self, $destination_object ) = @_;

    # Забираем список таблиц из ФИАС
    my @fias_tables = grep { $_ !~ /\_$/} @{ $self->show_tables() };
    # Создаём таблицы в тестовой базе
    for my $table_name ( @fias_tables ) {
        my $cr_statement = $self->{dbh}->selectcol_arrayref( "SHOW CREATE TABLE $table_name", { Columns => [2] } )->[0];
        $destination_object->{dbh}->do( $cr_statement );
    }
}

sub show_tables {
    my ( $self ) = @_;

    return $self->{dbh}->selectcol_arrayref("show tables");
}

sub _check_record_actuality {
    my ( $record ) = @_;

    # если есть поля свидетельствующие о неактуальности, то возвращаем 1.
    return 1
        if exists $record->{ACTSTATUS} && !$record->{ACTSTATUS}
        || exists $record->{LIVESTATUS} && !$record->{LIVESTATUS}
        || $record->{NEXTID}
        || exists $record->{ENDDATE} && $record->{ENDDATE} ne '20790606';

    return 0;
}

sub _get_table_fields {
    my ( $sql_table_name, $dbf_table ) = @_;

    # Изначально FIAS содержит много подробной, но не всегда необходимой информации
    # для того, чтобы не перегружать базу, записываем только необходимые поля, которые перечислены в этом хеше
    state $table_config = {
        ADDROB => {
            fields => [ qw/AOGUID AOLEVEL OFFNAME SHORTNAME PARENTGUID POSTALCODE NEXTID/ ],
            #where  => 'WHERE ACTSTATUS = 1 AND LIVESTATUS = 1 AND CURRSTATUS = 0'
        },
        HOUSE  =>{
            fields   => [ qw/HOUSENUM BUILDNUM STRUCNUM AOGUID HOUSEGUID POSTALCODE STATSTATUS STRSTATUS ENDDATE/ ]
        },
        ROOM   => {
            fields => [ qw/FLATNUMBER FLATTYPE HOUSEGUID ROOMGUID POSTALCODE ROOMNUMBER ROOMTYPE NEXTID/ ],
            #where => 'WHERE LIVESTATUS = 1',
        },
    };

    # При апдейте приходят подчёркивания, это лишннее
    $sql_table_name =~ s/\_$//a;

    # Возвращаем только необходимые поля
    return @{ $table_config->{ $sql_table_name }{fields} }
        if $table_config->{ $sql_table_name };

    # Возвращаем все поля
    return $dbf_table->field_names;
}

sub _create_table {
    my ( $sql_table_name, $dbf_table ) = @_;

    my @sqlcommand;

    # Получаем имена полей в таблице
    my @field_names = _get_table_fields( $sql_table_name, $dbf_table );

    # Выясняем для каждого поля дополнительные параметры.
    for my $name ( @field_names ) {
        # Длина поля
        my $len  = $dbf_table->field_length( $name );
        # Количество знаков после запятой для полей 'NUMERIC'
        my $dec  = $dbf_table->field_decimal( $name );
        # Тип поля
        my $type = $dbf_table->field_type( $name );
        # Переводим имя поля в нижний регистр
        $name = lc $name;

        # DBF 'C' переходит в 'CHAR'
        if ( $type eq 'C' ) {
            push @sqlcommand, "\`$name\` CHAR($len)";
        }
        # DBF 'D' переходит в 'DATE'
        elsif ( $type eq 'D' ) {
            push @sqlcommand, "\`$name\` DATE";
        }
        # DBF 'N' переходит в 'NUMERIC'
        elsif ( $type eq 'N' ) {
            push @sqlcommand, "\`$name\` NUMERIC($len, $dec)";
        }
        # Пришло что-то неизведанное!
        else { confess "unknown $type type" }
    }

    # имя таблицы тоже переводим в нижний регистр
    $sql_table_name = lc $sql_table_name;

    my $create_string = "CREATE TABLE IF NOT EXISTS $sql_table_name (" . join( ', ', @sqlcommand );

    if ( $sql_table_name =~ /^house\_?$/ ) {
	    $create_string .= ", PRIMARY KEY \`houseguid\` (\`houseguid\`), KEY \`aoguid\`(\`aoguid\`)";
    }
    elsif (  $sql_table_name =~ /^room\_?$/ ) {
	    $create_string .= ", PRIMARY KEY \`roomguid\` (\`roomguid\`), KEY \`houseguid\`(\`houseguid\`)";
    }
    elsif (  $sql_table_name =~ /^addrob\_?$/ ) {
	    $create_string .= ", PRIMARY KEY \`aoguid\` (\`aoguid\`), KEY \`aolevel\`(\`aolevel\`), KEY \`aoguid\`(\`aoguid\`)";
    }
    $create_string .=  ') MAX_ROWS=1000000000';
    return $create_string;
}

sub _convert_data {
    my ( $record, $dbf_table, $sql_table_name ) = @_;

    my @sqlcommand;

    # Получаем имена полей в таблице
    my @field_names = _get_table_fields( $sql_table_name, $dbf_table );

    # Выясняем для каждого поля дополнительные параметры.
    for my $name ( @field_names ) {
        # Тип поля
        my $type = $dbf_table->field_type( $name );
        my $cell;
        # Экранируем текст
        if ( $type eq 'C' ) {
            $cell = "'" . _get_quoted_text( $record->{ $name } ) . "'" // '\N';
        }
        # Превращаем дату DBF в дату SQL
        elsif ( $type eq 'D' ) {
            $cell =
              ( $record->{ $name } )
              ? _get_formatted_date( $record->{ $name } )
              : '\N';
        }
        # Получаем численное значение из DBF
        elsif ( $type eq 'N' ) {
            $cell = $record->{ $name } // 0;
        }

        push @sqlcommand, $cell;
   }
   # Склеиваем данные запятыми для инсёрта
   return join( ',', @sqlcommand );
}

sub _get_formatted_date {
    my ( $date )  = @_;

    $date = sprintf( '%08d', $date ) if ( length($date) < 8 );
    $date =~ s/(\d{4})(\d{2})(\d{2})/\'$1-$2-$3\'/;

    return $date;
}

sub _get_quoted_text {
    my ( $text ) = @_;

    # Экранируем
    $text =~ s/\\/\\\\/g;
    $text =~ s/\'/\\\'/g;
    # Декодируем
    $text = decode( 'cp866', $text );

    return $text;
}
1;

__END__

=pod

=encoding utf8
=head1 DESCRIPTION Модуль для минимальной работы с данными из базы ФИАC https://fias.nalog.ru/FiasInfo.aspx
=head1 NAME
FIAS::SQL
=head1 SYNOPSIS

=head1 NAME

FIAS::SQL - Модуль для минимальной работы с данными из базы ФИАC https://fias.nalog.ru/FiasInfo.aspx

=head1 VERSION

version 0.08

    # Создание объекта, подключение к базе
    my  $fias = FIAS::SQL->new(
                                db_connection => {
                                    dsn       => 'DBI:mysql:database=fias;host=localhost;port=3306';',
                                    login     => 'user',
                                    password  => 'pass',
                                },
                                # Опциональные параметры
                                additional_connection_params => {
                                    # выставляем флаг UTF-8 для нормальной работы с unicode( опционально)
                                    mysql_enable_utf8 => 1,
                                }
    );

    # автоматическое скачивание и распаковка пока не реализованы
    # файлы брать здесь https://fias.nalog.ru/Updates.aspx ( Полная БД ФИАС, DBF )

    # Загрузка базы из текущей директории
    $fias->load_files( '.' );

    # Получение всех записей первого уровня( регионов )
    my $regions   = $fias->get_address_objects( aolevel=>'region' );

    # Получение всех субъектов региона
    my $under_region = $fias->get_address_objects( parentguid => 'ee594d5e-30a9-40dc-b9f2-0add1be44ba1' );

    # Получение всех строений находящихся на адресном объекте с aoguid '00001be9-7886-4c7b-bcfe-74bdd601b81a'
    my $houses = $fias->get_houses_for_address_objects( '00001be9-7886-4c7b-bcfe-74bdd601b81a' );

    # Получение всех помещений находящихся в строении с houseid '000012ba-2754-425c-ba4a-4c35d0771045'
    my $rooms =  $fias->get_rooms_of_address_objects( '000012ba-2754-425c-ba4a-4c35d0771045' );

=head2 методы модуля

=over

=item B<new>
    Создание объекта

    %params
        db_connection -- параметры соединения к базе
            dsn         -- DBI Data Source Name
            login       -- логин для подключения к базе
            password    -- пароль для подключения к базе
            # Опционально
            additional_connection_params {
                # флаг для подключения к MySQL базе( опционально )
                mysql_enable_utf8 => 1
            }

=item B<load_files>
    Метод для загрузки dbf файлов в базу

    $directory -- папка с DBF файлами
    $update    -- флаг для обновления базы

=item B<get_address_objects>
    Получение адресных объектов по уровню и родителю

    %params
        parentguid -- id родительского объекта
        aolevel    -- уровень получаемых объектов
            Уровень объекта может принимать только нижеперечисленные значения
            соответсвия между строками и числами указаны в хеше $LEVELS
                region(1) – уровень региона
                district(3) – уровень района
                settlement(35) – уровень городских и сельских поселений
                town(4) – уровень города
                inhabitet_locality(6) – уровень населенного пункта
                planning_structure(65) – планировочная структура
                street(7) – уровень улицы
                stead(75) – земельный участок
                structure(8) – здания, сооружения, объекта незавершенного строительства
                premises(9) – уровень помещения в пределах здания, сооружения

    Функция возвращает массив из hashrefs квартир в формате
    {
        'aolevel' => '1',
        'shortname' => 'обл',
        'offname' => 'Брянская',
        'aoguid' => 'f5807226-8be0-4ea8-91fc-39d053aec1e2'
    }
    aoguid  --  Глобальный уникальный идентификатор адресного объекта
    aolevel --  Уровень адресного объекта
    offname  --  Официальное наименование
    shortname -- Краткое наименование типа объекта

=item B<get_address_objects_guids_only>
    Получение адресных объектов по уровню и родителю, возвращаются только уникальные id объекта

    %params
        parentguid -- id родительского объекта
        aolevel    -- уровень получаемых объектов
            Уровень объекта может принимать только нижеперечисленные значения
            соответствия между строками и числами указаны в хеше $LEVELS
                region(1) – уровень региона
                district(3) – уровень района
                settlement(35) – уровень городских и сельских поселений
                town(4) – уровень города
                inhabitet_locality(6) – уровень населенного пункта
                planning_structure(65) – планировочная структура
                street(7) – уровень улицы
                stead(75) – земельный участок
                structure(8) – здания, сооружения, объекта незавершенного строительства
                premises(9) – уровень помещения в пределах здания, сооружения

    Функция возвращает arrayref из aoguids

=item B<get_sublevels_for_objects>
    Получение списка уровней дочерних адресных объектов по id родителя

    parentguid -- id родительского объекта

    Функция возвращает arrayref уровней

=item B<get_data_for_object_by_aoguid>
    Получение данных адресного объекта по id

    aoguid -- id  объекта

    Функция возвращает hashref c данными адресного объекта

=item B<get_data_for_object_by_aoguid_array>
    Получение данных адресного объекта по id

    aoguid -- id  объекта

    Функция возвращает array c данными адресного объекта

=item B<add_object_to_base>
    Добавление объекта в таблицу

    table -- имя таблицы
    @values, список значений

=item B<get_houses_of_address_objects>
    Функция возвращает список домов для адресного объекта

    Функция принимает на вход
        $aoguid -- родительский объект для всех домов.
    Функция возвращает  массив из hashrefs квартир в формате
    {
          'buildnum' => '',
          'housenum' => '25',
          'strucnum' => '',
          'aoguid' => '53edf165-0dc2-42b7-81b5-6a87ab08c7df',
          'houseguid' => '65e2fbbc-72ac-4241-b5ca-fa40eb5307fe',
          'postalcode' => '241020'
    };
    housenum -- номер дома
    buildnum -- номер корпуса
    strucnum -- номер строения
    postalcode -- Почтовый индекс

=item B<get_data_for_house_by_houseguid>
    Получение данных дома по id

    houseguid -- id  дома

    Функция возвращает hashref c данными дома

=item B<get_rooms_of_address_objects>
    Функция возвращает список квартир для дома

    Функция принимает на вход
        $houseguid -- уникальный id дома

    Функция возвращает  массив из hashrefs квартир в формате
    {
        'postalcode' => '241020',
        'roomnumber' => '',
        'roomtype' => 'Не определено',
        'flatnumber' => '2',
        'flattype' => 'квартира',
        'roomguid' => '5039b82c-7975-4494-8920-22ad28cc130b',
        'houseguid' => 'cca694e2-2cf2-4f0c-8f5a-dec652833c1b'
    },
    flatnumber -- номер квартиры, офиса и прочего
    flattype   -- тип квартиры ( из справочника flattype )
    houseguid  -- Глобальный уникальный идентификатор родительского объекта (дома)
    roomguid   -- Глобальный уникальный идентификатор помещения
    postalcode -- Почтовый индекс
    roomnumber -- Номер комнаты или помещения
    roomtype   -- тип комнаты ( из справочника roomtype )

=item B<get_data_for_room_by_roomguid>
    Получение данных квартиры по id

    roomguid -- id  квартиры

    Функция возвращает hashref c данными квартиры

=item <get_parent_record_chain_by_aoguid>
    Получение цепочки элементов до верхнего уровня по aoguid

    aoguid -- id нижнего элемента
    Функция возвращает arrayref c данными записей
[
    {
        guid    "d967adce-0608-400f-983f-d64ca6e22547",
        level   "planning_structure"
    },
    {
        guid    "978c4d8c-f724-43b1-aa95-0c1fc49dc6b7",
        level   "town"
    },
    {
        aoguid    "2dd692c1-fc95-41a2-86a1-6a83f47914fe",
        level   "district"
    },
    {
        guid    "88cd27e2-6a8a-4421-9718-719a28a0a088",
        level   "region"
    }
]

=item B<get_parent_record_chain_by_houseguid>
    Получение цепочки элементов до верхнего уровня по houseguid

    houseguid -- id дома

    Функция возвращает arrayref c данными записей
[
    {
        guid    "cca694e2-2cf2-4f0c-8f5a-dec652833c1b",
        level   "house"
    },
    {
        guid    "dadfc561-e091-44b5-a07c-8d046529dfd4",
        level   "street"
    },
    {
        guid    "414b71cf-921e-4bfc-b6e0-f7395d16aaef",
        level   "town"
    },
    {
        guid    "f5807226-8be0-4ea8-91fc-39d053aec1e2",
        level   "region"
    }
]

=item B<get_parent_record_chain_by_roomguid>
    Получение цепочки элементов до верхнего уровня по  roomguid

    roomguid -- id помещения

    Функция возвращает arrayref c данными записей
[
    {
        guid    "4f13298c-e20b-4144-b90e-897ef80de2f2",
        level   "room"
    },
    {
        guid    "cca694e2-2cf2-4f0c-8f5a-dec652833c1b",
        level   "house"
    },
    {
        guid    "dadfc561-e091-44b5-a07c-8d046529dfd4",
        level   "street"
    },
    {
        guid    "414b71cf-921e-4bfc-b6e0-f7395d16aaef",
        level   "town"
    },
    {
        guid    "f5807226-8be0-4ea8-91fc-39d053aec1e2",
        level   "region"
    }
]

=item B<set_database_version>
    Сохранение версии базы

=item B<get_database_version>
    Получение версии базы

=item B<get_database_version>
    Получение линка на актуальную базу

=item B<get_database_version>
    Получение версии актуальной базы

=item B<clone_base_structure>
    создаём таблицы в базе
    $destination_object -- база назначения

=item B<show_tables>
    Список таблиц базы

=item B<_check_record_actuality>
    Проверка записи из DBF на актуальность

    $record -- запись взятая из DBF

    возвращаем 1(неактуально) или 0(актуально)

=item B<_get_table_fields>
    Функция для получения необходимых полей для записи в таблицы.

    значения полей берём из %table_config
    $sql_table_name -- имя таблицы из DBF полученное обрезанием номера региона и расширения
    HOUSE89.DBF превращается в HOUSE
    $dbf_table -- объект XBase для получения полей из файлов упомянутых в $table_config

=item B<_create_table>
    собираем комманду 'CREATE TABLE' для создания таблицы в базе

    $sql_table_name -- имя таблицы из DBF полученное обрезанием номера региона и расширения
    HOUSE89.DBF превращается в HOUSE
    $dbf_table -- объект XBase для получения параметров полей в таблице

    Для каждой таблицы получаем на выходе SQL комманду 'CREATE TABLE ...'

=item B<_convert_data>
    конвертируем данные полученные из DBF в соответствующие данные для SQL

    $record         -- запись
    $dbf_table      -- объект XBase для получения данных поля DBF файла
    $sql_table_name -- имя таблицы из DBF полученное обрезанием номера региона и расширения
    HOUSE89.DBF превращается в HOUSE

    На выходе получаем данные DBF удовлетворяющие стандарту SQL перечисленные через запятую

=item B<_get_formatted_date>
    Получаем дату для SQL из даты для DBF

    $date -- слитная дата из 8 цифр

    Возвращаем дату разделённую дефисами для нормального помещения в SQL

=item B<_get_quoted_text>
    Экранируем и декодируем полученный текст из DBF

        $text -- текст из DBF в cp866

    Возращаем удобоваримый и читаемый текст

=back

=head1 AUTHOR

Daniil Popov <popov.daniil@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017-2018 by Daniil Popov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
