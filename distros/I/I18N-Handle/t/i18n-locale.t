#!/usr/bin/env perl
use warnings;
use strict;
use lib 'lib';
use utf8;
use Test::More tests => 6;
BEGIN {
    use_ok 'I18N::Handle';
}
{
    my $hl = I18N::Handle->new( locale => 't/i18n/locale' );
    ok( $hl );

    is( _(' pt') , ' pt' , 'default' );

    $hl->speak( 'zh-tw' );
    is( _(' pt') , ' 分' , 'zh-tw' );

    $hl->speak( 'zh_TW' );
    is( _(' pt') , ' 分' , 'zh_TW' );

    $hl->speak( 'en' );
    is( _(' pt') , ' pt' , 'en' );
}
