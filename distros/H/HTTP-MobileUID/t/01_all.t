use strict;
use Test::More tests => 55;
use HTTP::MobileAgent;
use HTTP::MobileUID;

my $uid;

$ENV{HTTP_USER_AGENT} = q{DoCoMo/1.0/P502i/c10};
$uid = HTTP::MobileUID->new(HTTP::MobileAgent->new);
is $uid->uid         , undef;
is $uid->id          , undef;
is $uid->convert_uid , undef;
ok not $uid->has_uid;
ok     $uid->no_uid;

$ENV{HTTP_USER_AGENT}   = q{DoCoMo/1.0/P503i/c10};
$ENV{HTTP_X_DOCOMO_UID} = q{00QQWWEERRTT};
$uid = HTTP::MobileUID->new(HTTP::MobileAgent->new);
is $uid->uid         , '00QQWWEERRTT';
is $uid->id          , '00QQWWEERRTT';
is $uid->convert_uid , 'QQWWEERRTT';
ok     $uid->has_uid;
ok not $uid->no_uid;

$ENV{HTTP_USER_AGENT}   = q{DoCoMo/1.0/P503i/c10};
$ENV{HTTP_X_DOCOMO_UID} = q{NULLGWDOCOMO};
$uid = HTTP::MobileUID->new(HTTP::MobileAgent->new);
is $uid->uid         , undef;
is $uid->id          , undef;
is $uid->convert_uid , undef;
ok not $uid->has_uid;
ok     $uid->no_uid;

$ENV{HTTP_USER_AGENT}   = q{DoCoMo/1.0/P503i/c10};
$ENV{HTTP_X_DOCOMO_UID} = q{hogehoge};
$uid = HTTP::MobileUID->new(HTTP::MobileAgent->new);
is $uid->uid         , undef;
is $uid->id          , undef;
is $uid->convert_uid , undef;
ok not $uid->has_uid;
ok     $uid->no_uid;

$ENV{HTTP_USER_AGENT}   = q{J-PHONE/2.0/J-DN02};
$uid = HTTP::MobileUID->new(HTTP::MobileAgent->new);
is $uid->uid         , undef;
is $uid->id          , undef;
is $uid->convert_uid , undef;
ok not $uid->has_uid;
ok     $uid->no_uid;

$ENV{HTTP_USER_AGENT}   = q{Vodafone/1.0/V702NK/NKJ001 Series60/2.6 Profile/MIDP-2.0 Configuration/CLDC-1.1};
$ENV{HTTP_X_JPHONE_UID} = q{IUIDUIDUIDUIDUID};
$uid = HTTP::MobileUID->new(HTTP::MobileAgent->new);
is $uid->uid         , 'IUIDUIDUIDUIDUID';
is $uid->id          , 'IUIDUIDUIDUIDUID';
is $uid->convert_uid , 'UIDUIDUIDUIDUID';
ok     $uid->has_uid;
ok not $uid->no_uid;

$ENV{HTTP_USER_AGENT}   = q{Vodafone/1.0/V702NK/NKJ001 Series60/2.6 Profile/MIDP-2.0 Configuration/CLDC-1.1};
$ENV{HTTP_X_JPHONE_UID} = q{hogehoge};
$uid = HTTP::MobileUID->new(HTTP::MobileAgent->new);
is $uid->uid         , undef;
is $uid->id          , undef;
is $uid->convert_uid , undef;
ok not $uid->has_uid;
ok     $uid->no_uid;

$ENV{HTTP_USER_AGENT} = q{UP.Browser/3.01-HI01 UP.Link/3.4.5.2};
$uid = HTTP::MobileUID->new(HTTP::MobileAgent->new);
is $uid->uid         , undef;
is $uid->id          , undef;
is $uid->convert_uid , undef;
ok not $uid->has_uid;
ok     $uid->no_uid;

$ENV{HTTP_USER_AGENT} = q{UP.Browser/3.01-HI01 UP.Link/3.4.5.2};
$ENV{HTTP_X_UP_SUBNO} = q{000_subno.hoge};
$uid = HTTP::MobileUID->new(HTTP::MobileAgent->new);
is $uid->uid         , '000_subno.hoge';
is $uid->id          , '000_subno.hoge';
is $uid->convert_uid , '000_subno.hoge';
ok     $uid->has_uid;
ok not $uid->no_uid;

$ENV{HTTP_USER_AGENT} = q{UP.Browser/3.01-HI01 UP.Link/3.4.5.2};
$ENV{HTTP_X_UP_SUBNO} = q{hogehoge};
$uid = HTTP::MobileUID->new(HTTP::MobileAgent->new);
is $uid->uid         , undef;
is $uid->id          , undef;
is $uid->convert_uid , undef;
ok not $uid->has_uid;
ok     $uid->no_uid;

$ENV{HTTP_USER_AGENT} = q{hogehoge};
$uid = HTTP::MobileUID->new(HTTP::MobileAgent->new);
is $uid->uid         , undef;
is $uid->id          , undef;
is $uid->convert_uid , undef;
ok not $uid->has_uid;
ok     $uid->no_uid;

