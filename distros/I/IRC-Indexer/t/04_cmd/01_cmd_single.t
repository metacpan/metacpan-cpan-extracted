use Test::More tests => 5;
use Test::Cmd;
use strict; use warnings;

my $cmd = new_ok( 'Test::Cmd' => [
   workdir => '',
   prog    => 'blib/script/ircindexer-single',
 ],
);

is( $cmd->run(args => '-h'), 0, 'ircindexer-single exit 0' );

isnt( $cmd->run(args => '-s 1'), 0, 'failed() check' );
my $err;
ok( $err = $cmd->stderr, 'Got stderr' );

like( $err, qr/failed: irc_socketerr/, 'Got socketerr' );
