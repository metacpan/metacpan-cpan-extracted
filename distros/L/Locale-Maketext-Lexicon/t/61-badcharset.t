#!/usr/bin/perl -w
use strict;
use Test::More tests => 1;

require Locale::Maketext::Lexicon;

package MyApp::I18N::i_default;
# Need below to fake the loading of the po file
our %Lexicon = ( _AUTO => 1 );

package main;

eval "
    package MyApp::I18N;
    use base 'Locale::Maketext';
    Locale::Maketext::Lexicon->import({
        'i-default' => [ 'Gettext' => 't/badcharset.po' ],
        _decode => 1,
        _encoding => undef,
    });
    ";
like( $@, qr/Unknown encoding 'CHARSET'/, "Caught bad encoding error" );
