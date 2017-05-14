use strict;
use lib "lib";
use Test::More (tests => 2);
use App::Horris;

local @ARGV = qw(--configfile t/101_config_override_network.conf);
my $app = App::Horris->new_with_options();

my $horris = Horris->new({ config => $app->config });

is( $horris->connections->[0]->nickname, 'overridden' );
is( $horris->connections->[0]->username, 'overridden' );
