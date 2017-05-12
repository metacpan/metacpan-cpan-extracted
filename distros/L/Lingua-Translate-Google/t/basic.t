#!/usr/bin/perl -w

use strict;
use warnings;
use Test::More 'no_plan';

BEGIN {

    use WWW::Google::Translate;

    no warnings 'redefine';

    *WWW::Google::Translate::new = sub {
        return bless {}, 'WWW::Google::Translate';
    };

    *WWW::Google::Translate::detect = sub {
        return {
            data => {
                detections => [
                    [
                        {
                            language   => 'ru',
                            confidence => '0.8566108',
                            isReliable => 1,
                        }
                    ]
                ]
            }
        };
    };

    *WWW::Google::Translate::translate = sub {
        my ( $self, $arg_rh ) = @_;
        my ( $source, $target ) = @{$arg_rh}{qw( source target )};
        return {
            data => {
                translations => [
                    {
                    translatedText => "$source:$target", 
                    }
                ]
           }
        };
    };

    *WWW::Google::Translate::languages = sub {
        return {
            data => {
                languages => [
                    {
                    language => 'en',
                    name     => 'English',
                    },
                    {
                    language => 'ru',
                    name     => 'Russian',
                    },
                    {
                    language => 'ja',
                    name     => 'Japanese',
                    }
                ]
            }
        };
    };
}

use_ok( 'Lingua::Translate::Google' );

# translate
{
    my $xl8r = Lingua::Translate::Google->new(
        src     => 'auto',
        dest    => 'en',
        api_key => 'mock key'
    );

    my %xl8td = $xl8r->translate('Mein Luftkissenfahrzeug ist voller Aale');

    my %expect = (
        dest   => 'en',
        q      => 'Mein Luftkissenfahrzeug ist voller Aale',
        src    => 'ru',
        result => 'ru:en'
    );
    is_deeply( \%xl8td, \%expect, 'correct translate in list context' );

    my $xl8td = $xl8r->translate('Mein Luftkissenfahrzeug ist voller Aale');

    is_deeply( $xl8td, 'ru:en', 'correct translate in scalar context' );

    $xl8r->config(
        src  => 'ja',
        dest => 'ru',
    );

    $xl8td = $xl8r->translate('Mein Luftkissenfahrzeug ist voller Aale');

    is_deeply( $xl8td, 'ja:ru', 'correct src,dest after config' );
}

__END__
