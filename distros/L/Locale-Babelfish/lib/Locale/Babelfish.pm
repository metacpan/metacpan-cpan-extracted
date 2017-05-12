package Locale::Babelfish;

# ABSTRACT: Perl I18n using github://nodeca/babelfish format.


use utf8;
use strict;
use warnings;

use Carp qw/ confess /;
use File::Find qw( find );
use File::Spec ();
use List::Util qw( first );
use YAML::Syck qw( LoadFile );

use Locale::Babelfish::Phrase::Parser ();
use Locale::Babelfish::Phrase::Compiler ();

use parent qw( Class::Accessor::Fast );

our $VERSION = '1.000000'; # VERSION

__PACKAGE__->mk_accessors( qw(
    dictionaries
    fallbacks
    fallback_cache
    dirs
    _suffix
    default_locale
    file_filter
) );

my $parser = Locale::Babelfish::Phrase::Parser->new();
my $compiler = Locale::Babelfish::Phrase::Compiler->new();


sub new {
    my ( $class, $cfg ) = @_;
    $cfg //= {};
    my $self = bless {
        dictionaries   => {},
        dirs           => [ "./locales" ],
        fallbacks      => {},
        fallback_cache => {},
        _suffix        => $cfg->{suffix} // 'yaml',
        default_locale => $cfg->{default_locale} // 'en_US',
        %{ $cfg },
    }, $class;

    $self->load_dictionaries( $self->file_filter );
    $self->locale( $self->{default_locale} );

    return $self;
}


sub locale {
    my $self = shift;
    return $self->{locale}  if scalar(@_) == 0;
    $self->{locale} = $self->detect_locale( $_[0] );
}


sub prepare_to_compile {
    my ( $self ) = @_;
    while ( my ($locale, $dic) = each(%{ $self->{dictionaries} }) ) {
        while ( my ($key, $value) = each(%$dic) ) {
            if ( $self->phrase_need_compilation( $value, $key ) ) {
                $dic->{$key} = \$value; # lazy compile
                #$dic->{$key} = $compiler->compile( $parser->parse($value, $locale) );
            }
        }
    }
    return 1;
}


sub detect_locale {
    my ( $self, $locale ) = @_;
    return $locale  if $self->dictionaries->{$locale};
    my $alt_locale = first { $_ =~ m/\A\Q$locale\E[\-_]/i } keys %{ $self->dictionaries };
    if ( $alt_locale && $self->dictionaries->{$alt_locale} ) {
        # Lets locale dictionary will refer to alt locale dictinary.
        # This speeds up all subsequent calls of t/detect/exists on this locale.
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


sub load_dictionaries {
    my ( $self, $filter ) = @_;

    for my $dir ( @{$self->dirs} ) {
        find( {
            follow   => 1,
            no_chdir => 1,
            wanted   => sub {
                my $file = File::Spec->rel2abs( $File::Find::name );
                return  unless -f $file;
                my ( $volume, $directories, $base ) = File::Spec->splitpath( $file );

                return  if $filter && !$filter->($file);

                my @tmp = split m/\./, $base;

                my $cur_suffix = pop @tmp;
                return  if $cur_suffix ne $self->_suffix;
                my $locale = pop @tmp;

                my $dictname = join('.', @tmp);
                my $subdir = File::Spec->catpath( $volume, $directories, '' );
                my $fdir = File::Spec->rel2abs( $dir );
                if ( $subdir =~ m/\A\Q$fdir\E[\\\/](.+)\z/) {
                    $dictname = "$1$dictname";
                }

                $self->_load_dictionary( $dictname, $locale, $file );
            },
        }, $dir );
    }
    $self->prepare_to_compile;
}


sub _load_dictionary {
    my ( $self, $dictname, $lang, $file ) = @_;

    $self->dictionaries->{$lang} //= {};

    local $YAML::Syck::ImplicitUnicode = 1;
    my $yaml = LoadFile( $file );

    _flat_hash_keys( $yaml, "$dictname.", $self->dictionaries->{$lang} );
}


sub phrase_need_compilation {
    my ( undef, $phrase, $key ) = @_;
    die "L10N: $key is undef"  unless defined $phrase;
    return 1
        && ref($phrase) eq ''
        && $phrase =~ m/ (?: \(\( | \#\{ | \\\\ )/x
        ;
}


sub t_or_undef {
    my ( $self, $dictname_key, $params, $custom_locale ) = @_;

    # disallow non-ASCII keys
    confess("wrong dictname_key: $dictname_key")  if $dictname_key =~ m/\P{ASCII}/;

    my $locale = $custom_locale ? $self->detect_locale( $custom_locale ) : $self->{locale};

    my $r = $self->{dictionaries}->{$locale}->{$dictname_key};

    if ( defined $r ) {
        if ( ref( $r ) eq 'SCALAR' ) {
            $self->{dictionaries}->{$locale}->{$dictname_key} = $r = $compiler->compile(
                $parser->parse( $$r, $locale ),
            );
        }
    }
     # fallbacks
    else {
        $self->{fallback_cache}->{$locale} //= {};
        #  Cache can contain undef, as unexistent value.
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
                    last;
                }
            }
            $self->{fallback_cache}->{$locale}->{$dictname_key} = $r;
        }
    }

    if ( ref( $r ) eq 'CODE' ) {
        my $flat_params = {};
        # Convert parameters hash to flat form like "key.subkey"
        if ( defined($params) ) {
            # Scalar interpreted as { count => $scalar, value => $scalar }.
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

    # disallow non-ASCII keys
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

    return 0;
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


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Locale::Babelfish - Perl I18n using github://nodeca/babelfish format.

=head1 VERSION

version 1.000000

=head1 SYNOPSIS

    package Foo;

    use Locale::Babelfish;

    my $bf = Locale::Babelfish->new( { dirs => [ '/path/to/dictionaries' ] } );
    print $bf->t('dictionary.firstkey.nextkey', { foo => 'bar' } );

More sophisticated example:

    package Foo::Bar;

    use Locale::Babelfish;

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

=head1 DESCRIPTION

Internationalisation with easy syntax

Created for using same dictionaries on Perl and JavaScript.

=head1 METHODS

=head2 new

Constructor

    my $bf = Locale::Babelfish->new( {
        dirs           => [ '/path/to/dictionaries' ], # is required
        suffix         => 'yaml', # dictionaries extension
        default_locale => 'ru_RU', # by default en_US
    } );

=head2 locale

Gets or sets current locale.

    $self->locale;
    $self->locale( 'en_GB' );

=head2 prepare_to_compile

    $self->prepare_to_compile()

Marks dictionary values as refscalars, is they need compilation.
Or simply compiles them.

=head2 detect_locale

    $self->detect_locale( $locale );

Detects locale by specified locale/language.

Returns default locale unless detected.

=head2 load_dictionaries

Loads dictionaries recursively on specified path.

    $self->load_dictionaries;
    $self->load_dictionaries( \&filter( $file_path ) );

=head2 phrase_need_compilation

    $self->phrase_need_compilation( $phrase, $key )
    $class->phrase_need_compilation( $phrase, $key )

Is phrase need parsing and compilation.

=head2 t_or_undef

Get internationalized value for key from dictionary.

    $self->t_or_undef( 'main.key.subkey' );
    $self->t_or_undef( 'main.key.subkey' , { param1 => 1 , param2 => { next_level  => 'test' } } );
    $self->t_or_undef( 'main.key.subkey' , { param1 => 1 }, $specific_locale );
    $self->t_or_undef( 'main.key.subkey' , 1 );

Where C<main> - is dictionary, C<key.subkey> - key at dictionary.

=head2 t

Get internationalized value for key from dictionary.

    $self->t( 'main.key.subkey' );
    $self->t( 'main.key.subkey' , { param1 => 1 , param2 => { next_level  => 'test' } } );
    $self->t( 'main.key.subkey' , { param1 => 1 }, $specific_locale );
    $self->t( 'main.key.subkey' , 1 );

Where C<main> - is dictionary, C<key.subkey> - key at dictionary.

Returns square bracketed key when value not found.

=head2 has_any_value

Check exist or not key in dictionary.

    $self->has_any_value( 'main.key.subkey' );

Where C<main> - is dictionary, C<key.subkey> - key at dictionary.

=head2 set_fallback

    $self->set_fallback( 'by_BY', 'ru_RU', 'en_US');
    $self->set_fallback( 'by_BY', [ 'ru_RU', 'en_US' ] );

Set fallbacks for given locale.

When `locale` has no translation for the phrase, fallbacks[0] will be
tried, if translation still not found, then fallbacks[1] will be tried
and so on. If none of fallbacks have translation,
default locale will be tried as last resort.

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

=head2 Encoding

UTF-8 (Perl internal encoding).

=head2 DETAILS

Dictionaries loaded at instance construction stage.

All scalar values will be saved as scalar refs if needs compilation
(has Babelfish control sequences).

t_or_undef method translates specified key value.

Result will be compiled when scalarref. Result of compilation is scalar or coderef.

Result will be executed when coderef.

Scalar/hashref/arrayref will be returned as is.

=for Pod::Coverage _load_dictionary

=for Pod::Coverage _flat_hash_keys

=head1 SEE ALSO

L<https://github.com/nodeca/babelfish>

=head1 AUTHORS

=over 4

=item *

Akzhan Abdulin <akzhan@cpan.org>

=item *

Igor Mironov <grif@cpan.org>

=item *

REG.RU LLC

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Akzhan Abdulin.

This is free software, licensed under:

  The MIT (X11) License

=cut
