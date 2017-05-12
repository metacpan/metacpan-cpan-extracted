use strict;
use Test::Simple tests => 4;

use Log::Dispatch;
use Log::Dispatch::Jabber;

my $server   = "obelisk.net";
my $port     = 5222;
my $username = "test-netjabber";
my $password = "test";
my $resource = $$.time.qx(hostname);

eval { 
     my $logger = Log::Dispatch->new();
     ok($logger);

     my $jabber = Log::Dispatch::Jabber->new(name=>"jabber",
					     min_level=>"info",
					     login => {
						       hostname => $server,
						       port     => $port,
						       username => $username,
						       password => $password,
						       resource => $resource,
						      },
					     to => ["$username\@$server"],
					     debuglevel => 1,
				       );
     ok($jabber);

     ok($logger->add($jabber));

     ok($jabber->log_message(message=>"Hello world",level=>"debug"));
   };
