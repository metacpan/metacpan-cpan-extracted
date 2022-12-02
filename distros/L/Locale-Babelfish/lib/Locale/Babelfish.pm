package Locale::Babelfish;

# ABSTRACT: Perl I18n using https://github.com/nodeca/babelfish format.

our $VERSION = '2.10'; # VERSION


use utf8;
use strict;
use warnings;
use Data::Dumper;

use Carp qw/ confess /;
use File::Find qw( find );
use File::Spec ();

use YAML::SyckWrapper qw( load_yaml );
use Locale::Babelfish::Phrase::Parser ();
use Locale::Babelfish::Phrase::Compiler ();


use parent qw( Class::Accessor::Fast );

use constant {
    MTIME_INDEX => 9,
};

__PACKAGE__->mk_accessors( qw(
    dictionaries
    fallbacks
    fallback_cache
    dirs
    suffix
    default_locale
    watch
    watchers
) );

my $parser = Locale::Babelfish::Phrase::Parser->new();
my $compiler = Locale::Babelfish::Phrase::Compiler->new();


sub _built_config {
    my ( $cfg ) = @_;
    return {
        dictionaries   => {},
        fallbacks      => {},
        fallback_cache => {},
        suffix         => $cfg->{suffix} // 'yaml',
        default_locale => $cfg->{default_locale} // 'en_US',
        watch          => $cfg->{watch} || 0,
        watchers       => {},
        %{ $cfg // {} },
    };
}

sub new {
    my ( $class, $cfg ) = @_;

    my $self = bless {
        _cfg => $cfg,
        %{ _built_config( $cfg ) },
    }, $class;

    $self->load_dictionaries;
    $self->locale( $self->{default_locale} );

    return $self;
}


sub locale {
    my $self = shift;
    return $self->{locale}  if scalar(@_) == 0;
    $self->{locale} = $self->detect_locale( $_[0] );
}


sub on_watcher_change {
    my ( $self ) = @_;
    delete $self->{keys %$self};
    my %new_cfg = %{ _built_config( $self->{_cfg} ) };
    while( my ( $key, $value ) = each %new_cfg ) {
        $self->{$key} = $value;
    }
    $self->load_dictionaries;
    $self->locale( $self->{default_locale} );
}


sub look_for_watchers {
    my ( $self ) = @_;
    return  unless $self->{watch};
    my $ok = 1;
    while ( my ( $file, $mtime ) = each %{ $self->watchers } ) {
        my $new_mtime = (stat($file))[MTIME_INDEX];
        if ( !defined( $mtime ) || !defined( $new_mtime ) || $new_mtime != $mtime ) {
            $ok = 0;
            last;
        }
    }
    return  if $ok;
    $self->on_watcher_change();
}


sub t_or_undef {
    my ( $self, $dictname_key, $params, $custom_locale ) = @_;


    confess 'No dictname_key' unless $dictname_key;
    # запрещаем ключи не ASCII
    confess("wrong dictname_key: $dictname_key")  if $dictname_key =~ m/\P{ASCII}/;

    my $locale = $custom_locale ? $self->detect_locale( $custom_locale ) : $self->{locale};

    my $r = $self->{dictionaries}->{$locale}->{$dictname_key};

    if ( defined $r ) {
        if ( ref( $r ) eq 'SCALAR' ) {
            $self->{dictionaries}->{$locale}->{$dictname_key} = $r = $compiler->compile(
                $parser->parse( $$r, $locale ),
            );
        }
        elsif ( ref( $r ) eq 'ARRAY' ) {
            $self->{dictionaries}{$locale}{$dictname_key} = $r
                                                          = _process_list_items( $r, $locale );
        }
    }
     # fallbacks
    else {
        $self->{fallback_cache}->{$locale} //= {};
        # в кэше может быть undef, чтобы не пробегать локали для несуществующих ключей повторно.
        if ( exists $self->{fallback_cache}->{$locale}->{$dictname_key} ) {
            $r = $self->{fallback_cache}->{$locale}->{$dictname_key};
        }
        else {
            my @fallback_locales = @{ $self->{fallbacks}->{$locale} // [] };
            for ( @fallback_locales ) {
                $r = $self->{dictionaries}->{$_}->{$dictname_key};
                if ( defined $r ) {
                    if ( ref( $r ) eq 'SCALAR' ) {
                        $self->{dictionaries}->{$_}->{$dictname_key} = $r = $compiler->compile(
                            $parser->parse( $$r, $_ ),
                        );
                    }
                    elsif ( ref( $r ) eq 'ARRAY' ) {
                        $self->{dictionaries}{$locale}{$dictname_key} = $r
                                                                      = _process_list_items( $r, $locale );
                    }
                    last;
                }
            }
            $self->{fallback_cache}->{$locale}->{$dictname_key} = $r;
        }
    }

    if ( ref( $r ) eq 'CODE' ) {
        my $flat_params = {};
        # Переводим хэш параметров в "плоскую форму" так как в babelfish они имеют вид params.key.subkey
        if ( defined($params) ) {
            # переданный скаляр превращаем в хэш { count, value }.
            if ( ref($params) eq '' ) {
                $flat_params = {
                    count => $params,
                    value => $params,
                };
            }
            else {
                _flat_hash_keys( $params, '', $flat_params );
            }
        }

        return $r->( $flat_params );
    }

    return $r;
}


sub t {
    my $self = shift;

    return $self->t_or_undef( @_ ) || "[$_[0]]";
}


sub has_any_value {
    my ( $self, $dictname_key, $custom_locale ) = @_;

    # запрещаем ключи не ASCII
    confess("wrong dictname_key: $dictname_key")  if $dictname_key =~ m/\P{ASCII}/;

    my $locale = $custom_locale ? $self->detect_locale( $custom_locale ) : $self->{locale};

    return 1  if $self->{dictionaries}->{$locale}->{$dictname_key};

    $self->{fallback_cache}->{$locale} //= {};
    return ( ( defined $self->{fallback_cache}->{$locale}->{$dictname_key} ) ? 1 : 0 )
        if exists $self->{fallback_cache}->{$locale}->{$dictname_key};

    my @fallback_locales = @{ $self->{fallbacks}->{$locale} // [] };
    for ( @fallback_locales ) {
        return 1  if defined $self->{dictionaries}->{$_}->{$dictname_key};
    }

}


sub load_dictionaries {
    my $self = shift;

    for my $dir ( @{$self->dirs} ) {
        my $fdir = File::Spec->rel2abs( $dir );
        find( {
            follow   => 1,
            no_chdir => 1,
            wanted   => sub {
                my $file = File::Spec->rel2abs( $File::Find::name );
                return unless -f $file;
                my ( $volume, $directories, $base ) = File::Spec->splitpath( $file );

                my @tmp = split m/\./, $base;

                my $cur_suffix = pop @tmp;
                return unless $cur_suffix eq $self->suffix;
                my $lang = pop @tmp;

                pop @tmp  if $tmp[-1] eq 'tt'; # словари вида formatting.tt.ru_RU.yaml - имеют имя formatting
                if ( $tmp[-1] eq 'js') {
                    # словари .js перекрывают одноимённые словари без суффикса
                    # если это нежелательное поведение - словарь с суффиксом .tt перекроет одноимённый .js, и будет доступен только на сервере
                    pop @tmp; # словари вида formatting.js.ru_RU.yaml - имеют имя formatting
                    # и не загружаются, если есть аналогичный tt.
                    return  if -f File::Spec->catpath( $volume, $directories, join('.', @tmp). ".tt.$lang.$cur_suffix" );
                }
                my $dictname = join('.', @tmp);
                my $subdir = File::Spec->catpath( $volume, $directories, '' );
                if ( $subdir =~ m/\A\Q$fdir\E[\\\/](.+)\z/ ) {
                    $dictname = "$1$dictname";
                }

                $self->load_dictionary($dictname, $lang, $file);
            },
        }, $dir );
    }
    $self->prepare_to_compile;
}


sub load_dictionary {
    my ( $self, $dictname, $lang, $file ) = @_;

    $self->dictionaries->{$lang} //= {};

    my $yaml = load_yaml( $file );

    _flat_hash_keys( $yaml, "$dictname.", $self->dictionaries->{$lang} );

    return  unless $self->watch;

    $self->watchers->{$file} = (stat($file))[MTIME_INDEX];
}


sub phrase_need_compilation {
    my ( undef, $phrase, $key ) = @_;
    die "L10N: $key is undef"  unless defined $phrase;
    return 1
        && ref($phrase) eq ''
        && $phrase =~ m/ (?: \(\( | \#\{ | \\\\ )/x
        ;
}



sub prepare_to_compile {
    my ( $self ) = @_;
    while ( my ($lang, $dic) = each(%{ $self->{dictionaries} }) ) {
        while ( my ($key, $value) = each(%$dic) ) {
            if ( $self->phrase_need_compilation( $value, $key ) ) {
                $dic->{$key} = \$value; # отложенная компиляция
                #my $ast = $parser->parse($value, $lang);
                #$dic->{$key} = $compiler->compile( $ast );
            }
        }
    }
    return 1;
}


sub detect_locale {
    my ( $self, $locale ) = @_;
    return $locale  if $self->dictionaries->{$locale};
    my @alt_locales = grep { $_ =~ m/\A\Q$locale\E[\-_]/i } keys %{ $self->dictionaries };
    confess "only one alternative locale allowed: ", join ',', @alt_locales
        if @alt_locales > 1;

    my $alt_locale = $alt_locales[0];
    if ( $alt_locale && $self->dictionaries->{$alt_locale} ) {
        # сделаем locale dictionary ссылкой на alt locale dictinary.
        # это ускорит работу всех t с указанием языка типа "ru" вместо локали "ru_RU".
        $self->dictionaries->{$locale} = $self->dictionaries->{$alt_locale};

        $self->fallback_cache->{$locale} = $self->fallback_cache->{$alt_locale}
            if exists $self->fallback_cache->{$alt_locale};

        $self->fallbacks->{$locale} = $self->fallbacks->{$alt_locale}
            if exists $self->fallbacks->{$alt_locale};

        return $locale;
    }
    return $self->{default_locale}  if $self->dictionaries->{ $self->{default_locale} };
    confess "bad locale: $locale and bad default_locale: $self->{default_locale}.";
}


sub set_fallback {
    my ( $self, $locale, @fallback_locales ) = @_;
    return  unless scalar( @fallback_locales );

    $locale = $self->detect_locale( $locale );

    @fallback_locales = @{ $fallback_locales[0] }  if 1
        && scalar( @fallback_locales ) == 1
        && ref( $fallback_locales[0] ) eq 'ARRAY'
        ;

    $self->fallbacks->{ $locale } = \@fallback_locales;
    delete $self->{fallback_cache}->{ $locale };

    return 1;
}


sub _flat_hash_keys {
    my ( $hash, $prefix, $store ) = @_;
    while ( my ($key, $value) = each(%$hash) ) {
        if (ref($value) eq 'HASH') {
            _flat_hash_keys( $value, "$prefix$key.", $store );
        } else {
            $store->{"$prefix$key"} = $value;
        }
    }
    return 1;
}


sub _process_list_items {
    my ( $r, $locale ) = @_;

    my @compiled_items;
    for my $item ( @{ $r } ) {
        if ( ref $item eq 'HASH' ) {
            push @compiled_items, _process_nested_hash_item( $item, $locale );
        }
        elsif ( ref $item ne 'HASH' && defined $item ) {
            push @compiled_items, $compiler->compile( $parser->parse( $item, $locale ) );
        }
        else {
            push @compiled_items, $item;
        }
    }

    return sub {
        my $results = [];

        for my $item ( @compiled_items )  {
            if ( ref( $item ) eq 'CODE' ) {
                push @{ $results }, $item->(@_);
            }
            # Нужно скомпилить значения в хэшрефе
            elsif ( ref( $item ) eq 'HASH' ) {
                while ( my ( $key, $value ) = each ( %$item ) ) {
                    if ( ref ($value) eq 'CODE' ) {
                        $item->{$key}  = $value->(@_);
                    }
                }
                push @{ $results }, $item;
            }
            else {
                push @{ $results }, $item;
            }
        }

        return $results;
    };
}

sub _process_nested_hash_item {
    my ( $hashref, $locale ) = @_;

    while ( my ( $key, $value ) = each ( %$hashref ) ) {
        my $compiled_value = $compiler->compile( $parser->parse( $value, $locale ) );
        $hashref->{$key}   = $compiled_value;
    }

    return $hashref;
}


1;

__END__

=pod

=encoding utf-8

=head1 NAME

Locale::Babelfish - Perl I18n using https://github.com/nodeca/babelfish format.

=head1 VERSION

version 2.10

=head1 DESCRIPTION

Библиотека локализации.

=head1 NAME

Locale::Babelfish

=head1 SYNOPSYS

    package Foo;

    use Locale::Babelfish ();

    my $bf = Locale::Babelfish->new( { dirs => [ '/path/to/dictionaries' ] } );
    print $bf->t('dictionary.firstkey.nextkey', { foo => 'bar' } );

More sophisticated example:

    package Foo::Bar;

    use Locale::Babelfish ();

    my $bf = Locale::Babelfish->new( {
        # configuration
        dirs         => [ '/path/to/dictionaries' ],
        default_locale => [ 'ru_RU' ], # By default en_US
    } );

    # using default locale
    print $bf->t( 'dictionary.akey' );
    print $bf->t( 'dictionary.firstkey.nextkey', { foo => 'bar' } );

    # using specified locale
    print $bf->t( 'dictionary.firstkey.nextkey', { foo => 'bar' }, 'by_BY' );

    # using scalar as count or value variable
    print $bf->t( 'dictionary.firstkey.nextkey', 90 );
    # same as
    print $bf->t( 'dictionary.firstkey.nextkey', { count => 90, value => 90 } );

    # set locale
    $bf->locale( 'en_US' );
    print $bf->t( 'dictionary.firstkey.nextkey', { foo => 'bar' } );

    # Get current locale
    print $bf->locale;

=head1 DICTIONARIES

=head2 Phrases Syntax

#{varname} Echoes value of variable
((Singular|Plural1|Plural2)):variable Plural form
((Singular|Plural1|Plural2)) Short plural form for "count" variable

Example:

    I have #{nails_count} ((nail|nails)):nails_count

or short form

    I have #{count} ((nail|nails))

or with zero and onу plural forms:

    I have ((=0 no nails|=1 a nail|#{nails_count} nail|#{nails_count} nails)):nails_count

=head2 Dictionary file example

Module support only YAML format. Create dictionary file like: B<dictionary.en_US.yaml> where
C<dictionary> is name of dictionary and C<en_US> - its locale.

    profile:
        apps:
            forums:
                new_topic: New topic
                last_post:
                    title : Last message
    demo:
        apples: I have #{count} ((apple|apples))
        list:
            - some content #{data}
            - some other content #{data}

=head1 DETAILS

Словари грузятся при создании экземпляра, сразу в плоской форме
$self->{dictionaries}->{ru_RU}->{dictname_key}...

Причем все скалярные значения, при необходимости (есть спецсимволы Babelfish),
преобразуются в ссылки на скаляры (флаг - "нужно скомпилировать").

Метод t_or_undef получает значение по указанному ключу.

Если это ссылка на скаляр, то парсит и компилирует строку.

Если это ссылка на массив, то работаем со всеми элементами массива как со скалярами,
собираем полученные результаты компиляции в новый массив и возвращаем ссылку на этот массив.

Результат компиляции либо ссылка на подпрограмму, либо просто строка.

Если это ссылка на подпрограмму, мы просто вызываем ее с плоскими параметрами.

Если просто строка, то возвращаем её as is.

Поддерживается опция watch.

=head1 METHODS

=over

=item locale

Если указана локаль, устанавливет её. Если нет - возвращает.

=item on_watcher_change

Перечитывает все словари.

=item look_for_watchers

Обновляет словари оп мере необходимости, через L</on_watcher_change>.

=item t_or_undef

    $self->t_or_undef( 'main.key.subkey' , { paaram1 => 1 , param2 => 'test' } , 'ru' );

Локализация по ключу.

первой частью в ключе $key должен идти словарь, например, main.key
параметр языка не обязательный.

$params - хэш параметров

=item t

    $self->t( 'main.key.subkey' , { paaram1 => 1 , param2 => 'test' } , 'ru' );

Локализация по ключу.

первой частью в ключе $key должен идти словарь, например, main.key
параметр языка не обязательный.

$params - хэш параметров

=item has_any_value

    $self->has_any_value( 'main.key.subkey' );

Проверяет есть ли ключ в словаре

первой частью в ключе должен идти словарь, например, main.

=item load_dictionaries

Загружает все yaml словари с диска

=item load_dictionary

Загружает один yaml словарь с диска

=item phrase_need_compilation

    $self->phrase_need_compilation( $phrase, $key )
    $class->phrase_need_compilation( $phrase, $key )

Определяет, требуется ли компиляция фразы.

Используется также при компиляции плюралов (вложенные выражения).

=item prepare_to_compile

    $self->prepare_to_compile()

Либо маркирует как refscalar строки в словарях, требующие компиляции,
либо просто компилирует их.

=item detect_locale

    $self->detect_locale( $locale );

Определяем какой язык будет использован.
приоритет $locale, далее default_locale.

=item set_fallback

    $self->set_fallback( 'by_BY', 'ru_RU', 'en_US');
    $self->set_fallback( 'by_BY', [ 'ru_RU', 'en_US' ] );

Для указанной локали устанавливает список локалей, на которые будет производится откат
в случае отсутствия фразы в указанной.

Например, в вышеуказанных примерах при отсутствии фразы в
белорусской локали будет затем искаться фраза в русской локали,
затем в англоамериканской.

=item _flat_hash_keys

    _flat_hash_keys( $hash, '', $result );

Внутренняя, рекурсивная.
Преобразует хэш любой вложенности в строку, где ключи хешей разделены точками.

=item _process_list_items

    _process_list_items( $dictionary_values);

Обрабатывает ключи словарей содержащие списки, и оборачивает в функцию для компиляции списка.
Поддерживаются вложенные в список плоские хэшрефы

=back

=head1 AUTHORS

=over 4

=item *

Akzhan Abdulin <akzhan@cpan.org>

=item *

Igor Mironov <grif@cpan.org>

=item *

Victor Efimov <efimov@reg.ru>

=item *

REG.RU LLC

=item *

Kirill Sysoev <k.sysoev@me.com>

=item *

Alexandr Tkach <tkach@reg.ru>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by REG.RU LLC.

This is free software, licensed under:

  The MIT (X11) License

=cut
