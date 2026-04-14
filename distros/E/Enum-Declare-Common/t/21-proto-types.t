#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Object::Proto }
        or plan skip_all => 'Object::Proto not installed';
}

use Object::Proto;
use Enum::Declare::Common::HTTP qw(:StatusCode :Method);
use Enum::Declare::Common::LogLevel qw(:Level);
use Enum::Declare::Common::Calendar qw(:WeekdayFlag);
use Enum::Declare::Common::Bool qw(:YesNo);

subtest 'integer enum type' => sub {
    object 'HTTPResponse',
        'status:StatusCode:required',
        'body:Str:default()',
    ;

    my $res = new HTTPResponse status => OK;
    is($res->status, OK, 'status is OK');
    ok(defined $res->status, 'status is defined');

    eval { new HTTPResponse status => 9999 };
    like($@, qr/StatusCode/, 'rejects invalid status code');
};

subtest 'string enum type' => sub {
    object 'HTTPRequest',
        'method:Method:required',
        'path:Str:required',
    ;

    my $req = new HTTPRequest method => GET, path => '/api';
    is($req->method, GET, 'method is GET');

    eval { new HTTPRequest method => 'INVALID', path => '/' };
    like($@, qr/Method/, 'rejects invalid method');
};

subtest 'flags enum type' => sub {
    object 'Schedule',
        'days:WeekdayFlag:required',
    ;

    my $s = new Schedule days => Mon | Wed | Fri;
    ok($s->days & Mon, 'has Mon');
    ok($s->days & Wed, 'has Wed');
    ok(!($s->days & Tue), 'no Tue');
};

subtest 'enum with default' => sub {
    object 'Logger',
        'level:Level:default(' . Warn . ')',
    ;

    my $log = new Logger;
    is($log->level, Warn, 'default level is Warn');

    my $log2 = new Logger level => Error;
    is($log2->level, Error, 'can set level to Error');
};

subtest 'bool enum type' => sub {
    object 'Feature',
        'enabled:YesNo:required',
        'name:Str:required',
    ;

    my $feat = new Feature name => 'dark_mode', enabled => Yes;
    is($feat->enabled, Yes, 'enabled is Yes');

    eval { new Feature name => 'test', enabled => 'maybe' };
    like($@, qr/YesNo/, 'rejects invalid YesNo value');
};

subtest 'enum coercion' => sub {
    my $res = new HTTPResponse status => 200;
    is($res->status, OK, 'coerces 200 to OK');
};

subtest 'multiple enum types in one object' => sub {
    object 'APICall',
        'method:Method:required',
        'status:StatusCode',
        'log_level:Level:default(' . Info . ')',
    ;

    my $call = new APICall method => POST;
    is($call->method, POST, 'method set');
    is($call->log_level, Info, 'default log_level');

    $call->status(Created);
    is($call->status, Created, 'status set to Created');
};

done_testing();
