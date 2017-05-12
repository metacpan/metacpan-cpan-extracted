#!/usr/bin/env perl
use lib 'lib';
use Test::More tests => 2;
use I18N::Handle;

$h = I18N::Handle->new( po => 't/i18n/po' , no_global_loc => 1)->speak('zh-tw');
ok( $h );
eval {
    _('Hello');
};
ok( $@ );
