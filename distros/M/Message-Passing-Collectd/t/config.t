use strict;
use warnings;
no warnings 'once';

use FindBin qw/ $Bin /;
use lib "$Bin/lib";
use MockCollectd;
use JSON qw/ encode_json decode_json /;
use Test::More;

use_ok 'Collectd::Plugin::Write::Message::Passing';

open(my $fh, '<', "$Bin/example_config.json") or die $!;

my $line = <$fh>;
my $data = decode_json $line;
Collectd::Plugin::Write::Message::Passing::config(@$data);
close($fh);

is_deeply \%Collectd::Plugin::Write::Message::Passing::CONFIG, {
          'OutputClass' => 'Quux',
          'OutputClassOptions' => {
                                    'Foo' => 'Bar'
                                  }
        };

done_testing;

