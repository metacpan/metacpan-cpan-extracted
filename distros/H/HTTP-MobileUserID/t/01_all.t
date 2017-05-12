use strict;
use Test::More tests => 54;
use HTTP::MobileAgent;
use HTTP::MobileUserID;

my $userid;

$ENV{HTTP_USER_AGENT} = q{DoCoMo/1.0/P503i/c10};
$userid = HTTP::MobileUserID->new(HTTP::MobileAgent->new);
is $userid->user_id , undef;
is $userid->id      , undef;
ok     $userid->supported;
ok not $userid->unsupported;
ok not $userid->has_user_id;
ok     $userid->no_user_id;

$ENV{HTTP_USER_AGENT} = q{DoCoMo/1.0/P502i/c10};
$userid = HTTP::MobileUserID->new(HTTP::MobileAgent->new);
is $userid->user_id , undef;
is $userid->id      , undef;
ok not $userid->supported;
ok     $userid->unsupported;
ok not $userid->has_user_id;
ok     $userid->no_user_id;

$ENV{HTTP_USER_AGENT} = q{DoCoMo/1.0/P503i/c10/serAAAAADDDDDF};
$userid = HTTP::MobileUserID->new(HTTP::MobileAgent->new);
is $userid->user_id , 'AAAAADDDDDF';
is $userid->id      , 'AAAAADDDDDF';
ok     $userid->supported;
ok not $userid->unsupported;
ok     $userid->has_user_id;
ok not $userid->no_user_id;

$ENV{HTTP_USER_AGENT} = q{DoCoMo/1.0/P903i/c10/serBBBBBEEEEEI};
$userid = HTTP::MobileUserID->new(HTTP::MobileAgent->new);
is $userid->user_id , 'BBBBBEEEEEI';
is $userid->id      , 'BBBBBEEEEEI';
ok     $userid->supported;
ok not $userid->unsupported;
ok     $userid->has_user_id;
ok not $userid->no_user_id;

$ENV{HTTP_USER_AGENT}   = q{J-PHONE/2.0/J-DN02};
$userid = HTTP::MobileUserID->new(HTTP::MobileAgent->new);
is $userid->user_id , undef;
is $userid->id      , undef;
ok not $userid->supported;
ok     $userid->unsupported;
ok not $userid->has_user_id;
ok     $userid->no_user_id;

$ENV{HTTP_USER_AGENT}   = q{Vodafone/1.0/V702NK/NKJ001 Series60/2.6 Profile/MIDP-2.0 Configuration/CLDC-1.1};
$ENV{HTTP_X_JPHONE_UID} = q{UIDUIDUIDUIDUID};
$userid = HTTP::MobileUserID->new(HTTP::MobileAgent->new);
is $userid->user_id , 'UIDUIDUIDUIDUID';
is $userid->id      , 'UIDUIDUIDUIDUID';
ok     $userid->supported;
ok not $userid->unsupported;
ok     $userid->has_user_id;
ok not $userid->no_user_id;

$ENV{HTTP_USER_AGENT} = q{UP.Browser/3.01-HI01 UP.Link/3.4.5.2};
$userid = HTTP::MobileUserID->new(HTTP::MobileAgent->new);
is $userid->user_id , undef;
is $userid->id      , undef;
ok     $userid->supported;
ok not $userid->unsupported;
ok not $userid->has_user_id;
ok     $userid->no_user_id;

$ENV{HTTP_USER_AGENT} = q{UP.Browser/3.01-HI01 UP.Link/3.4.5.2};
$ENV{HTTP_X_UP_SUBNO} = q{SUBNOSUBNOSUBNOSUBNO};
$userid = HTTP::MobileUserID->new(HTTP::MobileAgent->new);
is $userid->user_id , 'SUBNOSUBNOSUBNOSUBNO';
is $userid->id      , 'SUBNOSUBNOSUBNOSUBNO';
ok     $userid->supported;
ok not $userid->unsupported;
ok     $userid->has_user_id;
ok not $userid->no_user_id;

$ENV{HTTP_USER_AGENT} = q{hogehoge};
$userid = HTTP::MobileUserID->new(HTTP::MobileAgent->new);
is $userid->user_id , undef;
is $userid->id      , undef;
ok not $userid->supported;
ok     $userid->unsupported;
ok not $userid->has_user_id;
ok     $userid->no_user_id;

