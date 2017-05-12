use Test::More;
use strict; use warnings FATAL => 'all';

use_ok( 'IRC::Toolkit::CTCP' );

ok( !ctcp_unquote("Line without CTCP"), '!unquote without ctcp ok' );
ok( !ctcp_extract("Line without CTCP"), '!extract without ctcp ok' );
ok( !ctcp_extract({
      command => 'PRIVMSG',
      params  => [ 'target', 'testing things' ],
    }), 'ref without ctcp ok'
);


my $line = ":prefix PRIVMSG target :\001ACTION does stuff\001";
my $ctcpev;
ok( $ctcpev = ctcp_extract( $line ), 'ctcp_extract ok' );
cmp_ok( $ctcpev->command, 'eq', 'ctcp_action',
  'ctcp event command looks ok'
);
cmp_ok( $ctcpev->prefix, 'eq', 'prefix',
  'ctcp event prefix looks ok'
);
cmp_ok( $ctcpev->params->[0], 'eq', 'target',
  'ctcp event target looks ok'
);
cmp_ok( $ctcpev->params->[1], 'eq', 'does stuff',
  'ctcp event params look ok'
);
undef $line; undef $ctcpev;

my $quoted;
ok( $quoted = ':prefix PRIVMSG target :' . ctcp_quote(
    "PING 1234"
  ),  'ctcp_quote ok'
);
my $newev;
ok( $newev = ctcp_extract( $quoted ), 'extract from qouted ok' );
cmp_ok( $newev->command, 'eq', 'ctcp_ping',
  'quoted event command looks ok'
);
cmp_ok( $newev->params->[1], 'eq', '1234',
  'quoted event params look ok'
);

done_testing;
