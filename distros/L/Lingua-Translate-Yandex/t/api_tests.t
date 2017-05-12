#
#===============================================================================
#
#         FILE: api_tests.t
#
#  DESCRIPTION: :
#
#        FILES: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Milovidov Mikhail (), milovidovwork@yandex.ru
# ORGANIZATION: 
#      VERSION: 1.0
#      CREATED: 25.12.2012 23:08:24
#     REVISION: ---
#===============================================================================

use strict;
use warnings;
use utf8;

use Lingua::Translate::Yandex;

use Test::More tests => 2;                      # last test to print


my $translator = Lingua::Translate::Yandex->new();

my $hello_rus = "Привет";
utf8::encode($hello_rus);

my $hello_en = "Hi";
utf8::encode($hello_en);

ok($hello_rus eq $translator->translate($hello_en, "ru"));
ok($hello_en eq $translator->translate($hello_rus, "en"));

