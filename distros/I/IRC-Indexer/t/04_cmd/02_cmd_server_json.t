use Test::More tests => 2;
use Test::Cmd;
use strict; use warnings;

my $cmd = new_ok( 'Test::Cmd' => [
   workdir => '',
   prog    => 'blib/script/ircindexer-server-json',
 ],
);

is( $cmd->run(args => '--help'), 0, 'server-json exit 0' );
