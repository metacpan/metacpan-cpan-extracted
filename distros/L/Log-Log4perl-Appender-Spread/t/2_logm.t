# -*- perl -*-
use Test::More;

use Log::Log4perl;
use Spread;

# this entire suite requires spread running on localhost, so find out if it is actually running.


# it is, continue by connecting a test mailbox to spread, to recieve test messages for comparison
my ( $testmailbox, $testprivategroup ) = 
     Spread::connect( {
			spread_name => '4803',
			private_name => 'rtest_log'
		       } );

if ( $sperrno ) {
        plan skip_all =>  "skipping tests, some spread problem [$sperrno]";
}
else {
        plan tests => 18;
}

ok( !$sperrno, "reference spread object connected to spread" );

# now that connecting is done, join the logging group.
my $joined_grp = Spread::join($testmailbox, 'LOG' );

is ( $joined_grp, '1', 'reference spread object joined grp LOG' );



# now try and pretend to be a module allready connected to spread, and feed that mailbox into 
# Log::Log4perl::Appender::Spread

my ( $pretendmailbox, $pretendprivategroup ) = 
     Spread::connect( {
			spread_name => '4803',
			private_name => 'ptest_log'
		       } );

ok( !$sperrno, "pretend spread object connected to spread" );


# Configuration in a string ... 
# This configuration has no spread mailbox, so Log::Log4perl::Appender::Spread will create one to use for logging.
# in more normal cases, where spread is used for lots of other things, the module using Log::Log4perl::Appender::Spread
# will allready have a handle on the spread bus. This is handled in a different test scenenario.
my $conf = "
           log4perl.category.Foo.Bar           = DEBUG, Logspread

           log4perl.appender.Logspread         = Log::Log4perl::Appender::Spread
           log4perl.appender.Logspread.layout  = Log::Log4perl::Layout::PatternLayout
           log4perl.appender.Logspread.layout.ConversionPattern = [%r] %F %L %m%n
           log4perl.appender.Logspread.SpreadMailbox = $pretendmailbox
";

my $init = Log::Log4perl::init( \$conf );

# init Log4perl with the conf above
ok ( defined( $init ), "init of l4p ok" );

my $log = Log::Log4perl::get_logger("Foo::Bar");
# get a logger.
ok ( defined( $log ), "got a logger" );

# log something, with ERROR priority
my $l = $log->error("logline1 from test module");

my($messsize) = -1;
my($service_type, $sender, $groups, $mess_type, $endian, $message) = (0);

while ( ( $messsize = Spread::poll( $testmailbox ) ) && !($service_type & 32) ) {
  # make the Spread reference recieve the message, and compare the messages, and types
  ($service_type, $sender, $groups, $mess_type, $endian, $message) = Spread::receive($testmailbox);
}

ok ( $message =~ "logline1 from test module", "reference object verified line from spread" );
is ( $mess_type, 4, "reference object verified message type from spread" );


# log something, with INFO priority
$l = $log->info("logline2 from test module");

($messsize) = -1;
($service_type, $sender, $groups, $mess_type, $endian, $message) = (0);

while ( ( $messsize = Spread::poll( $testmailbox ) ) && !($service_type & 32) ) {
  # make the Spread reference recieve the message, and compare the messages, and types
  ($service_type, $sender, $groups, $mess_type, $endian, $message) = Spread::receive($testmailbox);
}

ok ( $message =~ "logline2 from test module", "reference object verified line from spread" );
is ( $mess_type, 1, "reference object verified message type from spread" );

# log something, with DEBUG priority
$l = $log->debug("logline3 from test module");

($messsize) = -1;
($service_type, $sender, $groups, $mess_type, $endian, $message) = (0);

while ( ( $messsize = Spread::poll( $testmailbox ) ) && !($service_type & 32) ) {
  # make the Spread reference recieve the message, and compare the messages, and types
  ($service_type, $sender, $groups, $mess_type, $endian, $message) = Spread::receive($testmailbox);
}

ok ( $message =~ "logline3 from test module", "reference object verified line from spread" );
is ( $mess_type, 0, "reference object verified message type from spread" );

# log something, with WARN priority
$l = $log->warn("logline4 from test module");

($messsize) = -1;
($service_type, $sender, $groups, $mess_type, $endian, $message) = (0);

while ( ( $messsize = Spread::poll( $testmailbox ) ) && !($service_type & 32) ) {
  # make the Spread reference recieve the message, and compare the messages, and types
  ($service_type, $sender, $groups, $mess_type, $endian, $message) = Spread::receive($testmailbox);
}

ok ( $message =~ "logline4 from test module", "reference object verified line from spread" );
is ( $mess_type, 3, "reference object verified message type from spread" );

# log something, with FATAL priority
$l = $log->fatal("logline5 from test module");

($messsize) = -1;
($service_type, $sender, $groups, $mess_type, $endian, $message) = (0);

while ( ( $messsize = Spread::poll( $testmailbox ) ) && !($service_type & 32) ) {
  # make the Spread reference recieve the message, and compare the messages, and types
  ($service_type, $sender, $groups, $mess_type, $endian, $message) = Spread::receive($testmailbox);
}

ok ( $message =~ "logline5 from test module", "reference object verified line from spread" );
is ( $mess_type, 7, "reference object verified message type from spread" );

# disconnect retend mailbox
$r = Spread::disconnect( $pretendmailbox );
ok ( defined( $r ), "pretend object disconnected from spread" );

# disconnect reference object
my $r = Spread::leave( $testmailbox, $joined_grp );
ok ( defined( $r ), "reference object left grp 'LOG'" );

$r = Spread::disconnect( $testmailbox );
ok ( defined( $r ), "reference object disconnected from spread" );

