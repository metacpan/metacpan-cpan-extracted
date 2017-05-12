use strict;
use warnings;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use Test::More 0.88;

use MockCollectd;

use_ok 'Collectd::Plugin::Write::Message::Passing';
use_ok 'Collectd::Plugin::Read::Message::Passing';
use_ok 'Message::Passing::Collectd';

done_testing;

