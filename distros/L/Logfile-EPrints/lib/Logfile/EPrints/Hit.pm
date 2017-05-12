package Logfile::EPrints::Hit;

=pod

Logfile::EPrints::Hit - Generic 'hit' object

=head1 DESCRIPTION

This object represents a single entry in a log file and doesn't proscribe any particular schema.

This uses the 'AUTOLOAD' mechanism to allow any variable to be defined as a method.

'Hit' objects are passed between filters that may add additional functionality (e.g. by subclassing the hit object).

=head1 SYNOPSIS

	use Logfile::EPrints::Hit;

	my $hit = Logfile::EPrints::Hit->new;
	$hit->date( '2006-05-01 23:10:05' );

	print $hit->date;

=head1 CLASS METHODS

=over 4

=item Logfile::EPrints::Hit::Combined::load_country_db( FILENAME [, FLAGS ] )

Load the Maxmind country database located at FILENAME.

=item Logfile::EPrints::Hit::Combined::load_org_db( FILENAME [, FLAGS ] )

Load the Maxmind organisation database located at FILENAME.

=cut

=back

=head1 METHODS

=over 4

=item address()

IP address (or hostname if IP address could not be found).

=item hostname()

Hostname (undef if the address is an IP without a reverse DNS entry).

=item date()

Apache formatted date/time.

=item datetime()

Date/time formatted as yyyymmddHHMMSS.

=item userid_identd()

=item identd()

=item request()

Request string.

=item code()

HTTP server code.

=item size()

HTTP server response size.

=item referrer()

User agent referrer.

=item agent()

User agent string.

=item method()

Request method (GET, HEAD etc.).

=item page()

Requested page - probably won't include the virtual host!

=item version()

HTTP version requested (HTTP/1.1 etc).

=item country()

Country that the IP is probably in, must call load_country_db first.

=item organisation()

Organisation that the IP belongs to, must call load_org_db first.

=item institution()

Returns the title from the homepage()

=item homepage()

Returns the homepage for the user's network.

=back

=cut

use strict;

use POSIX qw/ strftime /;
use Date::Parse;
use Socket;

use vars qw( $AUTOLOAD %INST_CACHE );

use vars qw( $GEO_IP_CLASS $ORG_DB $COUNTRY_DB );
for(qw( Geo::IP Geo::IP::PurePerl ))
{
	eval "use $_";
	unless($@)
	{
		$GEO_IP_CLASS = $_;
		last;
	}
}

use vars qw( $UA );
require LWP::UserAgent;
$UA = LWP::UserAgent->new();
$UA->timeout(5);

sub new
{
	my( $class, %args ) = @_;
	return bless \%args, ref($class) || $class;
}

sub AUTOLOAD {
	$AUTOLOAD =~ s/.*:://;
	return if $AUTOLOAD =~ /^[A-Z]/;
	my $self = shift;
	return ref($self->{$AUTOLOAD}) ?
		&{$self->{$AUTOLOAD}}($self,@_) : 
		$self->{$AUTOLOAD};
}

# should be to_string in Perl
*toString = \&to_string;
sub to_string {
	my $self = shift;
	my $str = "===Parsed Reference===\n";
	while(my ($k,$v) = each %$self) {
		$str .= "$k=".($v||'n/a')."\n";
	}
	$str;
}

sub load_country_db
{
	my( $filename, $flags ) = @_;

	Carp::croak "Requires Geo::IP or Geo::IP::PurePerl" unless $GEO_IP_CLASS;
	Carp::croak "Missing filename argument" unless @_;

	$COUNTRY_DB = $GEO_IP_CLASS->open( @_ );

	no warnings;
	*country = \&_country;
}

sub load_org_db
{
	my( $filename, $flags ) = @_;

	Carp::croak "Requires Geo::IP or Geo::IP::PurePerl" unless $GEO_IP_CLASS;
	Carp::croak "Missing filename argument" unless @_;

	$ORG_DB = $GEO_IP_CLASS->open( @_ );

	no warnings;
	*organisation = \&_organisation;
}

sub _getipbyname
{
	my( $name, $aliases, $addrtype, $length, @addrs ) = gethostbyname($_[0]);
	return defined($addrs[0]) ? inet_ntoa($addrs[0]) : undef;
}

sub address
{
	$_[0]->{address} ||= _getipbyname( $_[0]->{hostname} ) || $_[0]->{hostname};
}

sub country
{
	Carp::croak "You must call ".__PACKAGE__."::load_country_db first";
}

sub _country
{
	$_[0]->{country} ||= $COUNTRY_DB->country_code_by_addr($_[0]->address);
}

sub organisation
{
	Carp::croak "You must call ".__PACKAGE__."::load_org_db first";
}

sub _organisation
{
	$_[0]->{organisation} ||= Encode::decode('iso-8859-1', $ORG_DB->org_by_name($_[0]->address));
}

sub hostname
{
	$_[0]->{hostname} ||= gethostbyaddr(inet_aton($_[0]->address), AF_INET);
}

sub utime
{
	$_[0]->{'utime'} ||= Date::Parse::str2time($_[0]->{date})
		or Carp::croak "Unrecognised or invalid date: $_[0]->{date}";
}

sub datetime
{
	$_[0]->{datetime} ||= _time2datetime($_[0]->utime);
}

sub _time2datetime {
	strftime("%Y%m%d%H%M%S",gmtime($_[0]));
}

sub institution
{
	my( $self ) = @_;
	return $self->{_institution} if exists($self->{_institution});
	@$self{qw(_institution _homepage)} = addr2institution($self->hostname);
	$self->{_institution};
}

sub homepage
{
	my( $self ) = @_;
	return $self->{_homepage} if exists($self->{_homepage});
	@$self{qw(_institution _homepage)} = addr2institution($self->hostname);
	$self->{_homepage};
}

sub addr2institution
{
	my( $addr ) = @_;

	# Can't do anything unless the address is defined
	return () unless defined $addr;

	# Get the domain name
	return () unless $addr =~ /([^\.]+)\.([^\.]+)\.([^\.]+)$/;
	my $uri = 'http://www.' . ((length($3) > 2 || length($2) > 3) ?
		join('.', $2, $3) :
		join('.', $1, $2, $3));
	$uri .= '/';
	return ($INST_CACHE{$uri},$uri) if defined $INST_CACHE{$uri};
	return () if exists($INST_CACHE{$uri});

	# Retrieve the home page
	$UA->max_size( 2048 );
	my $r = $UA->get($uri);
	$UA->max_size( undef );
	if( $r->is_error )
	{
		warn "Error retrieving homepage ($uri): " . $r->message;
		$INST_CACHE{$uri} = undef;
		return ();
	}

	return () unless $r->content =~ /<\s*title[^>]*>([^<]+)<\s*\/\s*title\s*>/is;
	my $title = $1;
	$title =~ s/\r\n/ /sg;
	$title =~ s/^\s+//;
	$title =~ s/(?:\-)?\s+$//;
	return ($INST_CACHE{$uri} = $title,$uri);
}

package Logfile::EPrints::Hit::Combined;

# Log file format is:
# ADDRESS IDENTD_USERID USER_ID [DATE TIMEZONE] "request" HTTP_CODE RESPONSE_SIZE "referrer" "agent"

=pod

=head1 NAME

Logfile::EPrints::Hit::Combined - Parse combined format logs like those generated from Apache

=head1 SYNOPSIS

	use Logfile::EPrints::Hit;

	my $hit = Logfile::EPrints::Hit::Combined->new($line);

	printf("%s requested %s\n",
		$hit->hostname,
		$hit->page);

=head1 AUTHOR

Tim Brody - <tdb01r@ecs.soton.ac.uk>

=cut

use strict;

use vars qw( @ISA );
@ISA = qw( Logfile::EPrints::Hit );

use vars qw( $AUTOLOAD $LINE_PARSER @FIELDS );

use Text::CSV_XS;
$LINE_PARSER = Text::CSV_XS->new({
	escape_char => '\\',
	sep_char => ' ',
});

# Fields in a single log line (as split by Text::CSV)
# !!! date is handled separately !!!
@FIELDS = qw(
	address userid_identd userid 
	request code size referrer agent
);

sub new($$)
{
	my %self = ('raw'=>$_[1]);

	# The date is contained in square-brackets
	if( $_[1] =~ s/\[([^\]]+)\]\s// ) {
		$self{date} = $1;
	}
	# Change apache escaping back to URI escaping
	$_[1] =~ s/\\x/\%/g;
	
	# Split the log file fields
	if($LINE_PARSER->parse($_[1])) {
		@self{@FIELDS} = $LINE_PARSER->fields;
	} else {
		warn "Text::CSV_XS couldn't parse: " . $LINE_PARSER->error_input;
		return;
	}

	# Split the request
	@self{qw(method page version)} = split / /, $self{'request'};
	# Look up the IP if the log file contains hostnames
	if( $self{'address'} !~ /\d$/ ) {
		$self{'hostname'} = delete $self{'address'};
	}
			
	return bless \%self, $_[0];
}

package Logfile::EPrints::Hit::arXiv;

# Log file format is:
# ADDRESS IDENTD_USERID USER_ID [DATE TIMEZONE] "request" HTTP_CODE RESPONSE_SIZE "referrer" "agent"
# But can have unescaped quotes in the request or agent field (might be just uk mirror oddity)

use strict;

use vars qw( @ISA );
@ISA = qw( Logfile::EPrints::Hit::Combined );

sub new {
	my ($class,$hit) = @_;
	my (%self, $rest);
	$self{raw} = $hit;
	(@self{qw(address userid_identd userid)},$rest) = split / /, $hit, 4;
	$rest =~ s/^\[([^\]]+)\] //;
	$self{date} = $1;
	$rest =~ s/ (\d+) (\d+|-)(?= )//; # Chop code & size out of the middle
	@self{qw(code size)} = ($1,$2);
	$rest =~ s/^\"([A-Z]+) ([^ ]+) (HTTP\/1\.[01])\" //;
	@self{qw(method page version)} = ($1,$2,$3);
	
	# Apache replaces the % in URIs with \x
	$self{page} =~ s/\\x/\%/g;
	chop($self{page}) if substr($self{page},-1) eq '"';
	
	$rest =~ s/^\"([^\"]+)\" \"(.+)\"$//;
	@self{qw(referrer agent)} = ($1,$2);
	
	# Look up the IP if the log file contains hostnames
	if( $self{'address'} !~ /\d$/ ) {
		$self{'hostname'} = delete $self{'address'};
	}

	bless \%self, $class;
}

package Logfile::EPrints::Hit::Bracket;

# Logfile format is:
#
# host ident user_id [dd/mmm/yyyy:hh:mm:ss +zone] [User Agent|email?|?|referrer] "page" code size

use strict;

our @ISA = qw( Logfile::EPrints::Hit::Combined );

sub new {
	my( $class, $hit ) = @_;
	my %self = (raw => $hit);

	@self{qw(
		hostname
		userid_identd
		userid
		date
		agent
		from
		process_time
		referrer
		method
		page
		version
		code
		size
	)} = $hit =~ /([^ ]+) ([^ ]+) ([^ ]+) \[(.{26})\] \[(.+)\|([^\|]+)\|([^\|]+)\|([^\|]+)\] "([A-Z]+) ([^ ]+) (HTTP\/1\.[01])" (\d+) (\d+|-)/
		or return undef;

	# Is an IP address rather than hostname
	if( $self{'hostname'} =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/ ) {
		$self{'address'} = delete $self{'hostname'};
	}

	return bless \%self, $class;
}

1;
