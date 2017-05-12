#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More tests => 4;

package Hello::I18N;
use Test::More;

use_ok( base => 'Locale::Maketext' );
use_ok(
    'Locale::Maketext::Lexicon' => {
        zh_hk    => [ 'Gettext' => 't/messages.po' ],
        _preload => 1,
    },
);

package main;

my $hash;
{
    no warnings 'once';
    $hash = \%Hello::I18N::zh_hk::Lexicon;
}
ok( keys %$hash, "Ok, hash is there and has some info" );
{
    local $TODO = "No idea why hash is not tied";
    ok( tied %$hash, "hash is still tied" );
}

