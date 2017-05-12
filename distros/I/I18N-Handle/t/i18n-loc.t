#!/usr/bin/env perl
use warnings;
use strict;
use lib 'lib';
use utf8;
use Test::More tests => 2;
use I18N::Handle;
my $hl = I18N::Handle->new(
    Gettext => {
        en => 't/i18n/po/en.po',
        zh_TW => 't/i18n/po/zh_TW.po',
    },
    loc => 'loc123',
);

ok( $hl );

$hl->speak( 'zh-tw' );
is( loc123(' pt') , ' 分' , 'zh-tw' );
