use Test::More tests => 55;

BEGIN {
  use_ok( 'IRC::Indexer::Report::Server' );
  use_ok( 'IRC::Indexer::Report::Network' );
  
  use_ok( 'IRC::Indexer::Output::JSON' );
}

## Report::Server
my $server  = new_ok( 'IRC::Indexer::Report::Server'  );

ok( $server->connectedto('irc.cobaltirc.org'), 'connectedto() set' );
is( $server->connectedto, 'irc.cobaltirc.org', 'connectedto() get' );

my $ts = time;
ok( $server->connectedat($ts), 'connectedat() set' );
is( $server->connectedat, $ts, 'connectedat() get' );

ok( $server->startedat($ts), 'startedat() set' );
is( $server->startedat, $ts, 'startedat() get' );

ok( $server->finishedat($ts), 'finishedat() set' );
is( $server->finishedat, $ts, 'finishedat() get' );

ok( $server->status('DONE'), 'status() set' );
is( $server->status, 'DONE', 'status() get' );

ok( $server->server('eris.oppresses.us'), 'server() set' );
is( $server->server, 'eris.oppresses.us', 'server() get' );

ok( $server->network('blackcobalt'), 'network() set' );
is( $server->network, 'blackcobalt', 'network() get' );

ok( $server->ircd('hybrid-7'), 'ircd() set' );
is( $server->ircd, 'hybrid-7', 'ircd() get' );

ok( $server->motd("MOTD line"), 'motd() new motd' );
ok( $server->motd("MOTD line 2"), 'motd() append' );
my $motd;
ok( $motd = $server->motd, 'motd() get' );
is_deeply( $motd,
  [
    'MOTD line',
    'MOTD line 2',
  ],
  'MOTD compare'
);

ok( $server->opers(2), 'opers() set' );
is( $server->opers, 2, 'opers() get' );

ok( $server->users(5), 'users() set' );
is( $server->users, 5, 'users() get' );


ok( $server->add_channel('#oneuser', 1, 'topic string'),
  'add_channel one' 
);
ok( $server->add_channel('#twouser', 2, 'topic string 2') ,
  'add_channel two'
);
ok( $server->add_channel('#threeuser', 3, 'topic string 3'), 
  'add_channel three'
);

my $hashchans;
my $expected_hashchans = {
    '#oneuser' => {
      Users => 1,
      Topic => 'topic string',
    },
    
    '#twouser' => {
      Users => 2,
      Topic => 'topic string 2',
    },
    
    '#threeuser' => {
      Users => 3,
      Topic => 'topic string 3',
    },
};
  
ok( $hashchans = $server->hashchans, 'hashchans() get' );
is_deeply( $hashchans, $expected_hashchans, 'hashchans compare' );

my $listchans;
my $expected_listchans = [
    [ '#threeuser', 3, 'topic string 3' ],
    [ '#twouser', 2, 'topic string 2'   ],
    [ '#oneuser', 1, 'topic string'     ],
];

ok( $listchans = $server->listchans, 'listchans() get' );
is_deeply( $listchans, $expected_listchans, 'listchans sort order' );

my $dump;
ok( $dump = $server->info, 'info()' );
ok( ref $dump eq 'HASH', 'info() is a hash' );

## Should be able to create an identical obj
my $identical = new_ok( 'IRC::Indexer::Report::Server' => [
  FromHash => $dump,
] );
is( $identical->server, 'eris.oppresses.us', 'imported server()' );

## Report::Network

my $network = new_ok( 'IRC::Indexer::Report::Network' => [ 
  ServerMOTDs => 1,
] );
ok( $network->add_server($server), 'add_server()' );

is( $network->users, 5, 'network users() compare' );
is( $network->opers, 2, 'network opers() compare' );
is( $network->connectedat, $ts, 'network connectedat() compare' );
is( $network->finishedat,  $ts, 'network finishedatat() compare' );
is( $network->lastserver, 'eris.oppresses.us', 'network lastserver() compare' );

ok( $network->motd_for('eris.oppresses.us'), 'motd_for()' );

my $servers;
ok( $servers = $network->servers, 'servers() get' );

is_deeply( $servers,
  {
    'eris.oppresses.us' => {
      MOTD => [
        'MOTD line',
        'MOTD line 2'
      ],
      
      TrawledAt => $ts,
      IRCD => 'hybrid-7',
    },
  },
  'servers() compare'
);

$hashchans = undef;
ok( $hashchans = $network->chanhash, 'network chanhash() get' );
is_deeply( $hashchans, $expected_hashchans, 'network chanhash() compare' );

my $server_json = new_ok( 'IRC::Indexer::Output::JSON' => 
  [ Input => $server->netinfo ]
);
ok( $server_json->dump, 'JSONify server hash' );

my $net_json = new_ok( 'IRC::Indexer::Output::JSON' =>
  [ Input => $network->info ]
);
ok( $net_json->dump, 'JSONify network hash' );

