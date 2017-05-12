use Test::More;
use strict; use warnings FATAL => 'all';

BEGIN { use_ok( 'IRC::Toolkit::ISupport' ) }

### Feeding raw lines
my @lines = (
   ':eris.oppresses.us 005 meh CHANLIMIT=#&:25 CHANNELLEN=50 ' .
   'CHANMODES=eIqdb,kX,l,cimnpstCMRS AWAYLEN=160 KNOCK ELIST=CTU SAFELIST ' .
   'EXCEPTS=e INVEX=I EXTBAN=$,gnp :are supported by this server',

   ':eris.oppresses.us 005 meh CALLERID CASEMAPPING=rfc1459 DEAF=D ' .
   'KICKLEN=160 MODES=4 NICKLEN=30 PREFIX=(ohv)@%+ STATUSMSG=@%+ ' .
   'TOPICLEN=390 NETWORK=blackcobalt MAXLIST=bdeI:80 ' .
   'TARGMAX=NAMES:1,LIST:1,KICK:1,WHOIS:1,PRIVMSG:4,NOTICE:4,ACCEPT:,MONITOR: '.
   'CHANTYPES=#& :are supported by this server',
);

my $isup = parse_isupport(@lines);

## can()
ok !$isup->can('nonexistant'), 'negative can() ok';
my $cref = $isup->can('callerid');
ok ref $cref eq 'CODE', 'can() returned coderef ok';
ok $isup->$cref, 'can() coderef looks ok';

## Bool-type
ok( $isup->callerid, 'callerid() ok' );
ok( !$isup->nonexistant, 'nonexistant key is negative' );

## Numeric-type
cmp_ok( $isup->channellen, '==', 50, 'channellen() ok' );
cmp_ok( $isup->awaylen, '==', 160, 'awaylen() ok' );
cmp_ok( $isup->kicklen, '==', 160, 'kicklen() ok' );
cmp_ok( $isup->modes, '==', 4, 'modes() ok' );
cmp_ok( $isup->nicklen, '==', 30, 'nicklen() ok' );

## String-type
cmp_ok( $isup->excepts, 'eq', 'e', 'excepts() ok' );
cmp_ok( $isup->invex, 'eq', 'I', 'invex() ok' );
cmp_ok( $isup->network, 'eq', 'blackcobalt', 'network() ok' );

## Specials

# chanlimit()
is_deeply( $isup->chanlimit,
  { '#' => 25, '&' => 25 },
  'chanlimit() HASH ok'
);
cmp_ok( $isup->chanlimit('#'), '==', 25, 'chanlimit() OBJ ok' );
ok( !$isup->chanlimit('+'), 'chanlimit ne compare' );

# chanmodes()
is_deeply( $isup->chanmodes,
  {
    list    => [ split '', 'eIqdb' ],
    always  => [ split '', 'kX' ],
    whenset => [ 'l' ],
    bool    => [ split '', 'cimnpstCMRS' ],
  },
  'chanmodes() HASH ok'
);
isa_ok( $isup->chanmodes->list, 'List::Objects::WithUtils::Array' );
is_deeply( $isup->chanmodes->list,
  [ split '', 'eIqdb' ],
  'chanmodes->list() ok'
);
is_deeply( $isup->chanmodes->always,
  [ 'k', 'X' ],
  'chanmodes->always() ok'
);
is_deeply( $isup->chanmodes->whenset,
  [ 'l' ],
  'chanmodes->whenset() ok'
);
is_deeply( $isup->chanmodes->bool,
  [ split '', 'cimnpstCMRS' ],
  'chanmodes->bool() ok'
);
cmp_ok( $isup->chanmodes->as_string, 'eq',
  'eIqdb,kX,l,cimnpstCMRS',
  'chanmodes->as_string() ok'
);

use IRC::Toolkit::Modes 'mode_to_array';
is_deeply( 
  mode_to_array( '+klX-t',
    params => [ 'key', 10, 'foo' ],
    isupport_chanmodes => $isup->chanmodes
  ),
  [
    [ '+', 'k', 'key' ],
    [ '+', 'l', 10    ],
    [ '+', 'X', 'foo' ],
    [ '-', 't' ],
  ],
  'mode_to_array with isupport->chanmodes ok'
);


# chantypes()
is_deeply( $isup->chantypes,
  +{ '#' => 1, '&' => 1 },
  'chantypes() HASH ok'
);
ok( $isup->chantypes('#'), 'chantypes() OBJ ok' );
ok( !$isup->chantypes('+'), 'chantypes ne compare' );

# elist()
is_deeply( $isup->elist,
  +{ map {; $_ => 1 } split '', 'CTU' },
  'elist() HASH ok'
);
ok( $isup->elist('C'), 'elist() OBJ ok' );
ok( !$isup->elist('M'), 'elist ne compare' );

# extban()
is_deeply( $isup->extban,
  +{ prefix => '$', flags => [ split '', 'gnp' ] },
  'extban() HASH ok'
);
cmp_ok( $isup->extban->prefix, 'eq', '$', 'extban->prefix() ok' );
isa_ok( $isup->extban->flags, 'List::Objects::WithUtils::Array' );
is_deeply( $isup->extban->flags,
  [ split '', 'gnp' ],
  'extban->flags() ok'
);
cmp_ok( $isup->extban->as_string, 'eq', '$,gnp',
  'extban->as_string() ok'
);

# maxlist()
is_deeply( $isup->maxlist,
  +{ map {; $_ => 80 } qw/ b d e I / },
  'maxlist() HASH ok'
);
cmp_ok( $isup->maxlist('d'), '==', 80, 'maxlist OBJ ok' );
ok( !$isup->maxlist('f'), 'maxlist ne compare' );

# prefix()
is_deeply( $isup->prefix,
  +{ o => '@', h => '%', v => '+' },
  'prefix() HASH ok'
);
cmp_ok( $isup->prefix('o'), 'eq', '@', 'prefix() OBJ ok' );
ok( !$isup->prefix('a'), 'prefix ne compare' );

# statusmsg()
is_deeply( $isup->statusmsg,
  +{ '+' => 1, '%' => 1, '@' => 1 },
  'statusmsg() HASH ok'
);
ok( $isup->statusmsg('@'), 'statusmsg() OBJ ok' );
ok( !$isup->statusmsg('!'), 'statusmsg ne compare' );

# targmax()
cmp_ok( $isup->targmax('names'), '==', 1, 'targmax(names) == 1' );
cmp_ok( $isup->targmax('privmsg'), '==', 4, 'targmax(privmsg) == 4' );
ok( !$isup->targmax('accept'), 'targmax for unlimited returns false' );

### Feeding objs
use IRC::Message::Object 'ircmsg';
my @objs = map {; ircmsg($_) } @lines;
undef $isup; $isup = parse_isupport(@objs);
cmp_ok( $isup->awaylen, '==', 160, '2 awaylen() ok' );
cmp_ok( $isup->kicklen, '==', 160, '2 kicklen() ok' );

done_testing;
