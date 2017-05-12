#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

use_ok 'JLogger::Config';

my $jlconfig = new_ok 'JLogger::Config';

can_ok $jlconfig, 'load', 'load_file';

my $config = $jlconfig->load(<<'YAML');
transport:
    JLogger::Transport::AnyEvent:
        host: 127.0.0.1
        port: 5526
        secret: secret
storages:
    - JLogger::Store::Dumper
filters:
    - JLogger::Filter::FieldRegexp:
        fields:
            from: "^test@jabber.org"
YAML

is_deeply $config,
  { transport => [
        'JLogger::Transport::AnyEvent' => {
            'host'   => '127.0.0.1',
            'port'   => '5526',
            'secret' => 'secret'
        }
    ],
    storages => [['JLogger::Store::Dumper']],
    filters  => [
        [   'JLogger::Filter::FieldRegexp' =>
              {fields => {from => '^test@jabber.org'}}
        ]
    ]
  }, 'Config parsed successfully';
