#!/usr/bin/env perl

use 5.10.1;
use strict;
use warnings;

use FindBin     qw( $Bin );
use File::Temp  qw( tempfile );
use Test::More  import => [qw( is ok plan )];

if ( require IPC::Run ) {
  plan tests => 3;
  my $script = do { local $/ = undef; <DATA> };
  my ($out, $err) = ('') x 2;
  ok(IPC::Run::run([$^X, -I => "$Bin/../lib", -e => $script],
                   \'', \$out, \$err),
     'run');
  is $out, '', 'expected output ($out)';
  is $err, "sallie\n", 'expected output ($err)';
} else {
  plan skip_all => 'IPC::Run not available';
}


__DATA__
use strict;
use warnings;

use Log::Info  qw( :DEFAULT :log_levels :default_channels );

Log(CHAN_INFO, LOG_INFO, 'bob');

Log::Info::enable_file_channel(CHAN_INFO, 1, 'verbose', SINK_STDERR);
Log::Info::set_channel_out_level(CHAN_INFO, LOG_INFO);

Log(CHAN_INFO, LOG_INFO, 'sallie');
