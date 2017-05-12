#!/usr/bin/env perl
use warnings;
use strict;
use lib 'lib';
use utf8;
use Test::More tests => 9;
BEGIN {
    use_ok 'I18N::Handle';
}


{
    my $hl = I18N::Handle->new(
        Gettext => {
            en => 't/i18n/po/en.po',
            zh_TW => 't/i18n/po/zh_TW.po',
        }
    );
    # warn $hl;
    ok( $hl );

    is( _(' pt') , ' pt' , 'default' );

    $hl->speak( 'zh-tw' );
    is($hl->speaking() , 'zh-tw');
    is( _(' pt') , ' 分' , 'zh-tw' );

    $hl->speak( 'zh_TW' );
    is( _(' pt') , ' 分' , 'zh_TW' );

    $hl->speak( 'en' );
    is( _(' pt') , ' pt' , 'en' );

    my @langs = $hl->can_speak();
    ok( @langs );

    is_deeply( \@langs , [ 'en', 'zh-tw' ] , '[ en , zh-tw ]' );

    $hl->accept( 'en' );
}
