
# These veriables are inside a config file because
# it's easy for me to maintain this way ;-)
# There is not reason why you can't move them in
# to the bot script if you like

# Think very carefully before changing this to be
# the port for the real game server - most of the
# functionality inside these bots is illegal on
# the real server and will get you banned
$PORT   = "2001";

$SERVER = "eternal-lands.network-studio.com";


# Example of the format the configuration
# below
# $ADMINS = "admin1,admin2";
# $OWNER  = "admin1";
# $USER   = "user";
# $PASS   = "password";

# Set these to values for your bot, see the
# example above
$ADMINS = undef;
$OWNER  = undef;
$USER   = undef;
$PASS   = undef;

defined($ADMINS) || die '$ADMINS must be set properly';
defined($OWNER)  || die '$OWNER must be set properly';
defined($USER)   || die '$USER must be set properly';
defined($PASS)   || die '$PASS must be set properly';

# The directory containing the Eternal Lands game
$ELDIR  = "/usr/local/games/el/";

1;
