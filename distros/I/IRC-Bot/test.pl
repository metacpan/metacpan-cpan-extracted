use Test::Simple tests => 6;

use IRC::Bot;
use IRC::Bot::Auth;
use IRC::Bot::Seen;
use IRC::Bot::Help;
use IRC::Bot::Log;
use IRC::Bot::Quote;

my $bot = IRC::Bot->new( Debug    => 0,
                         Nick     => 'TestBot',
                         Server   => 'irc.testirc.net',
                         Pass     => '',
                         Port     => '6667',
                         Username => 'TestBot',
                         Ircname  => 'TestBot',
                         Admin    => 'testuser',
                         Apass    => 'testpass',
                         Channels => [ '#test' ]
                        );

my $auth = IRC::Bot::Auth->new();
my $seen = IRC::Bot::Seen->new();
my $help = IRC::Bot::Help->new();
my $log  = IRC::Bot::Log->new();
my $quote = IRC::Bot::Quote->new();

ok( defined($bot)  and ref $bot eq 'IRC::Bot', 'Bot->new() passed' );
ok( defined($auth) and ref $auth eq 'IRC::Bot::Auth', 'Auth->new() passed' );
ok( defined($seen) and ref $seen eq 'IRC::Bot::Seen', 'Seen->new() passed' );
ok( defined($help) and ref $help eq 'IRC::Bot::Help', 'Help->new() passed' );
ok( defined($log)  and ref $log eq 'IRC::Bot::Log', 'Log->new() passed' );
ok( defined($quote) and ref $quote eq 'IRC::Bot::Quote', 'Quote->new() passed' );
