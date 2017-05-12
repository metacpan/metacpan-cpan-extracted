use Test::More;
use strict; use warnings FATAL => 'all';

use_ok( 'IRC::Toolkit::Parser' );
use_ok( 'IRC::Message::Object', 'ircmsg' );

my $ref = irc_ref_from_line(
  ":avenj PRIVMSG #otw :Things and stuff.",
);

ok( ref $ref eq 'HASH', 'irc_ref_from_line returned HASH' );
cmp_ok( $ref->{prefix}, 'eq', 'avenj', 'prefix is avenj' );
cmp_ok( $ref->{command}, 'eq', 'PRIVMSG', 'command is PRIVMSG' );
cmp_ok( ref $ref->{params}, 'eq', 'ARRAY', 'params isa ARRAY' );
cmp_ok( $ref->{params}->[0], 'eq', '#otw', 'first param is #otw' );

my $obj = ircmsg(%$ref);

my $line = irc_line_from_ref($ref);
cmp_ok( $line, 'eq', ':avenj PRIVMSG #otw :Things and stuff.',
  'irc_line_from_ref round-trip ok'
);

my $line2 = irc_line_from_ref($obj);
cmp_ok( $line2, 'eq', ':avenj PRIVMSG #otw :Things and stuff.',
  'irc_line_from_ref obj roundtrip ok'
);

done_testing;
