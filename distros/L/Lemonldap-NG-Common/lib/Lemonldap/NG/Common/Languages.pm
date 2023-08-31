package Lemonldap::NG::Common::Languages;

use strict;
use Exporter 'import';

our @EXPORT = qw(langName);

use constant langName => {
    ar    => 'العربية',
    de    => 'Deutsch',
    en    => 'English',
    es    => 'Español',
    fi    => 'Suomi',
    fr    => 'Français',
    he    => 'עברית',
    it    => 'Italiano',
    pl    => 'Polski',
    pt    => 'Português',
    pt_BR => 'Português (Brasil)',
    ru    => 'Русский',
    tr    => 'Türkçe',
    vi    => 'Tiếng Việt',
    zh    => '中文',
    zh_TW => '台湾华文',
};

1;
