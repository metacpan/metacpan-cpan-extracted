use strict;
use Test::More;

use POSIX qw/setlocale LC_TIME/;
use Locale::Scope qw/locale_scope/;

setlocale(LC_TIME, "C")           or plan skip_all => 'locale "C"           is not defined in this system.';
setlocale(LC_TIME, "ja_JP.UTF-8") or plan skip_all => 'locale "ja_JP.UTF-8" is not defined in this system.';
setlocale(LC_TIME, "en_US.UTF-8") or plan skip_all => 'locale "en_US.UTF-8" is not defined in this system.';

plan tests => 9;
my $locale = setlocale(LC_TIME, "C");
is setlocale(LC_TIME), $locale, 'C';
{
    my $scope = locale_scope(LC_TIME, 'ja_JP.UTF-8');
    is setlocale(LC_TIME), 'ja_JP.UTF-8', 'ja_JP.UTF-8';
    {
        my $scope = locale_scope(LC_TIME, "en_US.UTF-8");
        is setlocale(LC_TIME), 'en_US.UTF-8', 'en_US.UTF-8';
    }
    is setlocale(LC_TIME), 'ja_JP.UTF-8', 'ja_JP.UTF-8';
    {
        my $scope = locale_scope(LC_TIME, "en_US.UTF-8");
        is setlocale(LC_TIME), 'en_US.UTF-8', 'en_US.UTF-8';
        {
            my $scope = locale_scope(LC_TIME, 'ja_JP.UTF-8');
            is setlocale(LC_TIME), 'ja_JP.UTF-8', 'ja_JP.UTF-8';
        }
        is setlocale(LC_TIME), 'en_US.UTF-8', 'en_US.UTF-8';
    }
    is setlocale(LC_TIME), 'ja_JP.UTF-8', 'ja_JP.UTF-8';
}
is setlocale(LC_TIME), $locale, 'C';
