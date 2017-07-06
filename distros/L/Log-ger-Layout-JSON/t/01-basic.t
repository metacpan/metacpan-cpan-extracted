#!perl

use strict;
use warnings;
use Test::More 0.98;

use JSON::MaybeXS;
use Log::ger::Layout ();

use vars '$ary'; BEGIN { $ary = [] }
use Log::ger::Output 'Array', array => $ary;

package My::P1;
use Log::ger;

sub x {
    log_warn("warnmsg");
}

package My::P2;
use Log::ger::Format;
Log::ger::Format->set_for_current_package('None');
use Log::ger;

sub x {
    log_warn({k1=>'v1', k2=>'v2', foo=>'bar'});
}

package main;

subtest "basics (with default formatter)" => sub {
    Log::ger::Layout->set(JSON => ());
    splice @$ary;
    My::P1::x();
    is_deeply($ary, [q({"message":"warnmsg"})]);
};

subtest "basics (with None formatter)" => sub {
    Log::ger::Layout->set(JSON => ());
    splice @$ary;
    My::P2::x();
    is_deeply($ary, [q({"foo":"bar","k1":"v1","k2":"v2"})]);
};

subtest "conf:delete_fields" => sub {
    Log::ger::Layout->set(JSON => (delete_fields => ['k2', qr/fo./]));
    splice @$ary;
    My::P2::x();
    is_deeply($ary, [q({"k1":"v1"})]);
};

subtest "conf:add_fields" => sub {
    Log::ger::Layout->set(JSON => (add_fields => {k3=>"v3"}));
    splice @$ary;
    My::P2::x();
    is_deeply($ary, [q({"foo":"bar","k1":"v1","k2":"v2","k3":"v3"})]);
};

subtest "conf:add_special fields" => sub {
    splice @$ary, 0;
    Log::ger::Layout->set(
        'JSON',
        add_special_fields=>{
            map { $_ => $_ } qw(
                                   Category
                                   Class
                                   Date_Local
                                   Date_GMT
                                   File
                                   Hostname
                                   Location
                                   Line
                                   Message
                                   Method
                                   Level
                                   PID
                                   Elapsed_Start
                                   Elapsed_Last
                                   Stack_Trace
                           )
        });
    My::P1::x();
    my $res = JSON::MaybeXS->new->decode($ary->[0]);
    #diag explain $res;
    is($res->{Category}, 'My::P1');
    is($res->{Class}, 'main');
    like($res->{Date_GMT}, qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\z/); # XXX test actual time
    like($res->{Date_Local}, qr/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\z/); # XXX test actual time
    like($res->{Elapsed_Start}, qr/\d/); # XXX test actual elapsed time
    like($res->{Elapsed_Last}, qr/\d/); # XXX test actual elapsed time
    like($res->{File}, qr/\w/); # XXX test actual file name
    like($res->{Hostname}, qr/\w/); # XXX test actual hostname
    is($res->{Level}, 'warn');
    is($res->{Line}, 17);
    like($res->{Location}, qr/\AMy::P1::x \(.+?:17\)\z/);
    is($res->{Message}, 'warnmsg');
    is($res->{Method}, 'x');
    is($res->{PID}, $$);
    like($res->{Stack_Trace}, qr/\A\w+::/); # XXX test stack trace more

    # XXX test unknown special field -> die
};

done_testing;
