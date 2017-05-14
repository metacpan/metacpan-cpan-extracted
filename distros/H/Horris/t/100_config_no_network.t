use strict;
use lib "lib";
use Test::More (tests => 1);
use App::Horris;

local @ARGV = qw(--configfile t/100_config_no_network.conf);
my $app = App::Horris->new_with_options();

eval {
    my $horris = Horris->new({ config => $app->config });
	$horris->run;
};
like($@, qr/No network specified for connection 'test'/);
