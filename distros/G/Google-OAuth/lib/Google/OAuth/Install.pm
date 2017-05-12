package Google::OAuth::Install ;

use 5.008009;
use strict;
use warnings;
use vars qw( %INC ) ;

use Google::OAuth ;
use File::Copy ;

require Exporter;

our @ISA = qw( Exporter ) ;

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Google::OAuth ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw() ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;

our @EXPORT = qw( config settings grantcode test install ) ;

our $VERSION = '0.01';

my $config ;

sub testdb {
	Google::OAuth->setclient ;

	my @ok = () ;
	eval {
		## Probably not generic enough
		@ok = Google::OAuth->dsn->rows_array( 
				'SELECT COUNT(*) FROM %s' ) ;
		} ;

	return @ok ;
	}

sub config {
	return print STDERR <<'eof' unless @ARGV ;
Usage: perl -MGoogle::OAuth::Install -e config outputfile
eof

	my $configfile = shift @ARGV ;
	my $fh ;

	return print STDERR <<eof unless open $fh, "> $configfile" ;
Cannot open $configfile for writing
eof

	print $fh $config ;
	printf <<eof ;
Please edit $configfile 
Installation instructions are described within

Then run
  perl -MGoogle::OAuth::Install -e settings $configfile
eof
	}

sub init {
	my $function = shift ;
	return 0 & print STDERR <<eof unless @ARGV ;
Usage: perl -MGoogle::OAuth::Install -e $function configfile
eof

	my $configfile = shift @ARGV ;

	my $error = <<eof ;
Missing or invalid configfile: $configfile
  Run: perl -MGoogle::OAuth::Install -e config $configfile
eof

	return 0 & print STDERR $error unless -f $configfile ;

	do $configfile or return 0 & print STDERR $error ;
	return 0 & print STDERR $error 
			unless $Google::OAuth::Config::VERSION eq '1.00' ;
	return $configfile ;
	}

sub settings {
	return unless @_ || init('settings') ;

	my %client = Google::OAuth::Config->setclient ;

	print join( "\n  ", 'Settings:', %client ), "\n\n" unless @_ ;
	$client{client_secret} ||= 'undefined' ;

	my @client = grep $_, %client ;
	return print STDERR <<'eof' unless @client == 8 ;
Configuration is incomplete- run settings
eof

	Google::OAuth->setclient ;
	my $dsn = Google::OAuth->dsn ;
	my $ok = ref $dsn && $dsn->[0] && $dsn->dbconnected ;
	return print STDERR <<'eof' unless $ok ;
Missing data source
eof

	return 0 ;
	}

sub grantcode {
	return unless init('grantcode') ;
	return if settings(1) ;

	Google::OAuth->setclient ;
	my $link = Google::OAuth::Client->new->scope(
			'calendar.readonly' )->token_request ;
	printf '<a href="%s">Get Grant Code</a>%s', $link, "\n" ;
	}

sub test {
	init('test') unless @_ ;
	return if settings(1) ;

	my $code = $Google::OAuth::Config::test{grantcode} ;
	return print STDERR <<'eof' unless $code ;
Generate a URL to acquire Grant Code from Google
  perl -MGoogle::OAuth::Install -e grantcode configfile
eof

	my %client = Google::OAuth::Config->setclient ;
	$client{dsn}->loadschema unless &testdb ;
	return print STDERR <<'eof' unless &testdb ;
Unable to open database dsn
eof

	Google::OAuth->setclient ;

	my @ok = Google::OAuth->token_list ;
	return print join( "\n  ", "Successfully found tokens:", @ok ), "\n"
			if @ok ;

	my $response = Google::OAuth->grant_code( $code ) ;

	return 0 & printf "Token successfully generated for %s\n", 
			$response->{emailkey} if $response->{emailkey} ;

	print "Unknown Error.  Here's what Google has to say:\n" ;
	print ref $response? join( "\n  ", '', %$response ): "  $response" ;
	return print "\n" ;
	}

sub install {
	return unless my $ok = init('install') ;
	Google::OAuth->setclient ;
	return if Google::OAuth->token_list == 0 && test( 1 ) ;
	copy( $ok, $INC{'Google/OAuth/Config.pm'} ) ;

	printf "Updated %s\n", $INC{'Google/OAuth/Config.pm'} ;
	}

$config = <<'eof' ;
package Google::OAuth::Config ;

my %client ;
our %test ;

###############################################################################
#                                                                             #
#  Step 1 - Specify a NoSQL::PL2SQL database driver                           #
#                                                                             #
#  NoSQL::PL2SQL is ideal for the amorphous data structures used in           #
#  Google API's and other web services.  In order to use NoSQL::PL2SQL,       #
#  you must install one of the NoSQL::PL2SQL::DBI drivers appropriate for     #
#  your installation.  Specify the driver below.                              #
#                                                                             #
#  The only driver currently available is NoSQL::PL2SQL::DBI::MySQL.  Please  #
#  contact jim@tqis.com for information about other drivers.                  #
#                                                                             #
###############################################################################

## Step 1 - Specify a NoSQL::PL2SQL database driver

# use NoSQL::PL2SQL::DBI::MySQL ;	## Uncomment


###############################################################################
#                                                                             #
#  Step 2 - Specify Google API credentials                                    #
#                                                                             #
#  If you haven't already, you must register an application to access the     #
#  Google API.  Here is the link to register:                                 #
#    https://code.google.com/apis/console/                                    #
#                                                                             #
#  Once you've registered, the values required below can be displayed by      #
#  clicking the "API Access" tab in the upper left navigation.                #
#                                                                             #
#  Warning:  The client_secret and dsn access will be available to            #
#  everyone in a shared environment.  Refer to "SECURE INSTALLATION"
#  in the manual.                                                             #
#                                                                             #
###############################################################################

## Step 2 - Specify Google API credentials

$client{redirect_uri} = '' ;
$client{client_id} = '' ;
$client{client_secret} = '' ;	## May be left blank


###############################################################################
#                                                                             #
#  Step 3 - Define the NoSQL::PLSQL dsn                                       #
#                                                                             #
#  A NoSQL:PL2SQL data source (DSN) is defined as a single table.  Perldoc    #
#  NoSQL::PL2SQL:DBI:                                                         #
#  http://search.cpan.org/~tqisjim/NoSQL-PL2SQL-1.20/lib/NoSQL/PL2SQL/DBI.pm  #
#                                                                             #
#  The table will be built as part of this installation process.              #
#                                                                             #
###############################################################################

## Step 3 - Define the NoSQL::PLSQL dsn
##          Refer to "SECURE INSTALLATION" before connecting the database

# $client{dsn} = NoSQL::PL2SQL::DBI::MySQL->new( $tablename ) ;
# $client{dsn}->connect( 'DBI:mysql:'.$dbname, @login ) ;


###############################################################################
#                                                                             #
#  Step 4 - Acquire a Grant Code                                              #
#                                                                             #
#  Before proceeding, you may test your settings as follows:                  #
#    perl -MGoogle::OAuth::Install settings configfile                        #
#                                                                             #
#  In order to test your settings, you'll need to acquire a "Grant Code"      #
#  from Google using a web browser.  The link is dynamically generated        #
#  using Google::OAuth.  The easiest way to access this link is by email      #
#  as follows:                                                                #
#                                                                             #
#    perl -MGoogle::OAuth::Install grantcode configfile | mail you@yours.com  #
#                                                                             #
#  This process is effectively the same as what your users will experience.   #
#                                                                             #
#    1.  Use the Google::OAuth library to generate a link                     #
#    2.  The link will prompt users to log in and authorize your app          #
#    3.  After authorization, the user is redirected to your specified        #
#        redirect_uri                                                         #
#    4.  Google will append a grant code to your url as a query_string        #
#        argument.                                                            #
#                                                                             #
#  You'll need to capture the grant code and enter it below:                  #
#                                                                             #
###############################################################################

## Step 4 - Acquire a Grant Code

$test{grantcode} = '' ;


###############################################################################
#                                                                             #
#  Step 5 - Test your configuration                                           #
#                                                                             #
#    perl -MGoogle::OAuth::Install test configfile                            #
#                                                                             #
#  Google::OAuth effectively performs two tests:  First it uses the           #
#  Grant Code to create an Access Token and Refresh Token.  Second,           #
#  it uses the Access Token to query Google for a user id.                    #
#                                                                             #
#  If the test succeeds, the email address used in Step 4 will print out,     #
#  and proceed to installation:                                               #
#                                                                             #
#    perl -MGoogle::OAuth::Install install configfile                         #
#                                                                             #
#  One common failure is an "Invalid Grant Code".  Google may throw           #
#  this error even though everything is configured correctly, because:        #
#    1.  A Grant Code can only be used once                                   #
#    2.  A Grant Code is invalid after another Grant Code is issued           #
#    3.  A Grant Code is only valid for a short period of time                #
#    4.  Google will issue invalid Grant Codes if requests are made too       #
#        frequently.                                                          #
#                                                                             #
#  This problem may be resolved by repeating step 4 after a brief wait        #
#  period.                                                                    #
#                                                                             #
###############################################################################

###############################################################################
#                                                                             #
#  Facebook OAUTH                                                             #
#                                                                             #
#  Conceptually, Facebook OAUTH is similar, although the implementation is    #
#  much simpler.  So most of the same methods can be applied for Facebook.    #
#  To utilize the overlapping functionality, as well as providing a token     #
#  persistence solution, a sample Facebook subclass is included in this       #
#  distro.                                                                    #
#                                                                             #
#  One major difference is that Facebook uses only one token.  This token     #
#  can be renewed indefinitely unless allowed to expire.  After expiration,   #
#  however, the entire token request process must be repeated.                #
#                                                                             #
###############################################################################

my %facebook ;

$facebook{client_id} = '' ;
$facebook{client_secret} = '' ;
$facebook{redirect_uri} = '' ;


############################# END OF INSTRUCTIONS #############################

BEGIN {
	use 5.008009;
	use strict;
	use warnings;
	
	require Exporter;
	
	our @ISA = qw( Exporter ) ;
	
	our %EXPORT_TAGS = ( 'all' => [ qw() ] );
	our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } ) ;
	our @EXPORT = qw() ;
	our $VERSION = '1.01';
	}

sub setclient {
	return %client ;
	}

sub facebookclient {
	return %facebook ;
	}

1;
eof

1;
__END__
