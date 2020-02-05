use strict;
use warnings;
use Test::More;

use Duadua;

{
    my $d = Duadua->new;

    is $d->name, 'UNKNOWN', 'blank';
    is $d->ua, '';
    ok !$d->is_bot;
    ok !$d->is_ios;
    ok !$d->is_android;
    ok !$d->is_linux;
    ok !$d->is_windows;
    ok !$d->is_chromeos;
    ok !$d->version;
}

{
    my $d = Duadua->new(0);

    is $d->name, 'UNKNOWN', '0';
    is $d->ua, '0';
    ok !$d->is_bot;
    ok !$d->is_ios;
    ok !$d->is_android;
    ok !$d->is_linux;
    ok !$d->is_windows;
    ok !$d->is_chromeos;
}

{
    my $d = Duadua->new('-');

    is $d->name, 'UNKNOWN', '-';
    is $d->ua, '-';
    ok !$d->is_bot;
    ok !$d->is_ios;
    ok !$d->is_android;
    ok !$d->is_linux;
    ok !$d->is_windows;
    ok !$d->is_chromeos;
}

{
    my $d = Duadua->new('~');

    is $d->name, 'UNKNOWN', '~';
    is $d->ua, '~';
    ok !$d->is_bot;
    ok !$d->is_ios;
    ok !$d->is_android;
    ok !$d->is_linux;
    ok !$d->is_windows;
    ok !$d->is_chromeos;
}

{
    local $ENV{'HTTP_USER_AGENT'} = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)';
    my $d = Duadua->new;

    is $d->name, 'Googlebot', 'from ENV';
    ok $d->is_bot;
    ok !$d->is_ios;
    ok !$d->is_android;
    ok !$d->is_linux;
    ok !$d->is_windows;
    ok !$d->is_chromeos;
}

{
    local $ENV{'HTTP_USER_AGENT'} = 0;
    my $d = Duadua->new;

    is $d->name, 'UNKNOWN', 'from ENV "0"';
    is $d->ua, '0';
    ok !$d->is_bot;
    ok !$d->is_ios;
    ok !$d->is_android;
    ok !$d->is_linux;
    ok !$d->is_windows;
    ok !$d->is_chromeos;
}

{
    my $d = Duadua->new(
        'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)',
        { version => 1 }
    );

    is $d->name, 'Googlebot', 'version';
    ok $d->opt_version;
    ok $d->is_bot;
    ok !$d->is_ios;
    ok !$d->is_android;
    ok !$d->is_linux;
    ok !$d->is_windows;
    ok !$d->is_chromeos;
    is $d->version, '2.1';
}

{
    my $d = Duadua->new(
        'DoCoMo/2.0 N905i(c100;TB;W24H16) (compatible; Googlebot-Mobile/2.1; +http://www.google.com/bot.html)',
        { skip => ['Duadua::Parser::Bot::GooglebotMobile', 'Duadua::Parser::FeaturePhone::FeaturePhone'] }
    );

    is $d->name, 'DoCoMo', 'skip';
    ok $d->is_bot;
    ok !$d->is_ios;
    ok !$d->is_android;
    ok !$d->is_linux;
    ok !$d->is_windows;
    ok !$d->is_chromeos;
    is $d->version, '2.0';
}

{
    my $d = Duadua::parse('Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)');

    is $d->name, 'Googlebot', 'function call';
    ok $d->is_bot;
    ok !$d->is_ios;
    ok !$d->is_android;
    ok !$d->is_linux;
    ok !$d->is_windows;
    ok !$d->is_chromeos;
}

{
    my $d = Duadua::parse('Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', { version => 1 });

    is $d->name, 'Googlebot', 'function call with option';
    ok $d->is_bot;
    ok !$d->is_ios;
    ok !$d->is_android;
    ok !$d->is_linux;
    ok !$d->is_windows;
    ok !$d->is_chromeos;
    is $d->version, '2.1';
}

{
    my $d = Duadua->parse('Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)');

    is $d->name, 'Googlebot', 'method call';
    ok $d->is_bot;
    ok !$d->is_ios;
    ok !$d->is_android;
    ok !$d->is_linux;
    ok !$d->is_windows;
    ok !$d->is_chromeos;
}

{
    my $d = Duadua->parse('Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)', { version => 1 });

    is $d->name, 'Googlebot', 'method call with option';
    ok $d->is_bot;
    ok !$d->is_ios;
    ok !$d->is_android;
    ok !$d->is_linux;
    ok !$d->is_windows;
    ok !$d->is_chromeos;
    is $d->version, '2.1';
}

done_testing;
