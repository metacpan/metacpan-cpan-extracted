use strict;
use warnings;

use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use MockCollectd;
use JSON qw/ encode_json decode_json /;
use Test::More;

use_ok 'Message::Passing::Filter::Encoder::JSON';
use_ok 'Message::Passing::Output::Test';
use_ok 'Collectd::Plugin::Write::Message::Passing';

open(my $fh, '<', "$Bin/example_data.json") or die $!;

$Collectd::Plugin::Write::Message::Passing::CONFIG{encoderclass} = 'Message::Passing::Filter::Encoder::JSON';
$Collectd::Plugin::Write::Message::Passing::CONFIG{outputclass} = 'Message::Passing::Output::Test';
$Collectd::Plugin::Write::Message::Passing::CONFIG{encoderoptions} = {};
$Collectd::Plugin::Write::Message::Passing::CONFIG{outputoptions} = {};

my $count = 0;
my $last_line;
while (my $line = <$fh>) {
    $last_line = $line;
    my $data = decode_json $line;
    Collectd::Plugin::Write::Message::Passing::write(@$data);
    ok $line, $line;
    $count++;
    is $Collectd::Plugin::Write::Message::Passing::OUTPUT->output_to->message_count, $count;
    my $msg = decode_json([$Collectd::Plugin::Write::Message::Passing::OUTPUT->output_to->messages]->[-1]);
    is ref($msg), 'HASH';
    ok scalar(@{$msg->{values}});
    is ref($msg->{values}->[0]), 'HASH';
}

close($fh);

my $in_one = q{["indices.get.time",[{"min":0,"max":0,"name":"indices.get.time","type":0}],{"plugin":"ElasticSearch","time":1341656031.18621,"type":"indices.get.time","values":[0],"interval":10,"host":"t0m.local"}]};

my $data = decode_json $in_one;
Collectd::Plugin::Write::Message::Passing::write(@$data);
my $msg = decode_json([$Collectd::Plugin::Write::Message::Passing::OUTPUT->output_to->messages]->[-1]);

my $exp_one = q{{
        "plugin":"ElasticSearch",
        "time":1341656031.18621,
        "values":[
            {
                "value":0,
                "min":0,
                "name":"indices.get.time",
                "max":0,
                "type":"COUNTER"
            }
        ],
        "type":"indices.get.time",
        "interval":10,
        "host":"t0m.local"
    }};

is_deeply $msg, decode_json($exp_one);


my $in_multi = q{["load", [{"min":0,"max":100,"name":"shortterm","type":1},{"min":0,"max":100,"name":"midterm","type":1},{"min":0,"max":100,"name":"longterm","type":1}],{"plugin":"load","time":1341655869.22588,"type":"load","values":[0.41,0.13,0.08],"interval":10,"host":"t0m.local"}]};

$data = decode_json $in_multi;
Collectd::Plugin::Write::Message::Passing::write(@$data);
$msg = decode_json([$Collectd::Plugin::Write::Message::Passing::OUTPUT->output_to->messages]->[-1]);

my $exp_multi = q{{
        "plugin":"load",
        "time":1341655869.22588,
        "type":"load",
        "values":[
            {
                "value":0.41,
                "min":0,
                "max":100,
                "name":"shortterm",
                "type":"GAUGE"
            },
            {
                "value":0.13,
                "min":0,
                "max":100,
                "name": "midterm",
                "type":"GAUGE"
            },
            {
                "value":0.08,
                "min":0,
                "max":100,
                "name":"longterm",
                "type":"GAUGE"
            }
        ],
        "interval":10,
        "host":"t0m.local"
    }
};

is_deeply $msg, decode_json($exp_multi);

done_testing;

