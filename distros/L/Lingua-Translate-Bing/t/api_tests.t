 #!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use utf8;
use Test::More tests => 12;

use Lingua::Translate::Bing;

my $translator = Lingua::Translate::Bing->new(client_id => "BingTranslationTest", client_secret => "2hW9esAQegd7cVAylBrDEXnD1QVoWJYHSirAXMkQg40=");

use_ok('Lingua::Translate::Bing');

{
    my $token = $translator->_initAccessToken();

    ok(defined($token)); 
    ok($token eq $translator->_getAccessToken());
}

{
    my $token = $translator->_getAccessToken();

    my $updatePeriod = 2;
    $translator->_setUpdateTokenPeriod($updatePeriod);
    sleep($updatePeriod + 1);

    my $updatedToken = $translator->_getAccessToken();
    ok($token ne $updatedToken);
    ok($updatedToken eq $translator->_getAccessToken());

    $translator->_setUpdateTokenPeriod(600);
}

{
    my $languages = $translator->getLanguagesForTranslate();
    ok(defined($languages->[1]));
}

my $hello_en = "Hello";
my $hello_rus = "Привет";

{    
    ok("ru" eq $translator->detect($hello_rus));
    ok("en" eq $translator->detect($hello_en));
}

{
    ok($hello_en eq $translator->translate($hello_rus, "en"));
    ok($hello_en eq $translator->translate($hello_rus, "en", "ru"));
    ok($hello_rus eq $translator->translate($hello_en, "ru"));
    ok($hello_rus eq $translator->translate($hello_en, "ru", "en"));
}

