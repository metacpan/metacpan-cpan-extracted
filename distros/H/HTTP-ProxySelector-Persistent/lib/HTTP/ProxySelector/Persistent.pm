package HTTP::ProxySelector::Persistent;

use warnings;
use strict;
use integer;
use LWP::UserAgent;
use BerkeleyDB;
use vars qw( %h );
use Date::Manip;

# rand() is used, let's try to make the most of it...
srand;

=head1 NAME

HTTP::ProxySelector::Persistent - Locally cache and use a list of proxy servers for high volume, proxied LWP::UserAgent transactions

=head1 VERSION

Version 0.02

=cut

our $VERSION = '0.02';

=head1 SYNOPSIS

This module is a fork from HTTP::ProxySelector (written by Eyal Udassin) that is modified to:

=over 1

=item * Require less trips to look up proxy lists by caching them locally (bandwidth economy and speed).

=item * Almost always set your useragent to a valid proxy (reliability).

=item * Ensure that you never retry a failed proxy in a subsequent proxy selection call (minimum # of timeouts possible).

=item * Leave the cache of proxy servers in place after execution for the next call to use (persistence).

=back

  use HTTP::ProxySelector;
  use LWP::UserAgent;

  # Instantiate
  my $selector = HTTP::ProxySelector::Persistent->new( db_file => "/tmp/proxy_cache.bdb" );
  my $ua = LWP::UserAgent->new();

  # Assign a _ proxy to the UserAgent object.
  $selector->set_proxy($ua) or die $selector->error();
  
  # Just in case you need to know the chosen proxy
  print 'Selected proxy: ',$selector->get_proxy(),"\n";

  # Perform a quick proxied get.  Lets you skip the useragent stuff.
  my $html = $selector->proxied_get( url => "http://www.google.com" ) or die $selector->error();

=head1 PREREQUISITES

HTTP::ProxySelector::Persistent requires you to have these perl modules installed:

=over 1

=item * BerkeleyDB 

=item * LWP::UserAgent

=item * Date::Manip

=back

=head1 PUBLIC METHODS

=head2 new()

B<new> is the constructor for HTTP::ProxySelector::Persistent objects.  

Returns a new HTTP::ProxySelector::Persistent object.

Accepts a key-value list of options as arguments.  The option keys are:

=head3 db_file

The full path and filename for the proxy cache database file.  You must have permission to write in this directory.  This option is mandatory, it has no default!

=head4 Example : 

  $select = HTTP::ProxySelector::Persistent->new( db_file => "/tmp/proxy_cache.bdb" );

=head3 sites

Reference to a list of sites containing the proxy lists.

=head4 Example : 

  $select = HTTP::ProxySelector::Persistent->new( sites => ['http://www.proxylist.com/list.htm'] );

=head4 Default:

  [ 'http://hidemyass.com/free_proxy_lists.php?sort=DESC&country=1&limit=100' ]

=head3 update_interval

How often to update the cached list of proxy servers.  Must be readable by Date::Manip.

=head4 Example: 

  $select = HTTP::ProxySelector::Persistent->new( update_interval => "20 minutes" )
	    or die "Couldn't create proxyselector!";

=head4 Default

  "15 minutes"

=head3 testsite

Destination site to test the proxy with.

=head4 Example : 

  $select = HTTP::ProxySelector::Persistent->new( testsite => 'http://yahoo.com' );

=head4 Default

  http://www.google.com 

=cut

# Constructor. Enables Inheritance
sub new {
  my $this = shift;
  my $class = ref($this) || $this;
  my $self = {};
  bless $self, $class;
  my $status;

  if (@_) {
    my %options = @_;
    $self->{options} = \%options;
  }
  # Defaults
  unless ($self->{options}{sites}) {
    @{$self->{options}{sites}} = ('http://hidemyass.com/free_proxy_lists.php?sort=DESC&country=1&limit=100');
  }
  $self->{options}{testsite}	    ||= 'http://www.google.com';
  $self->{options}{update_interval} ||= "15 minutes";
  # See if the database file exists
  return "Error: please provide a database file to use as an argument to the new() function." unless ( $self->{options}{db_file} );
  ( $self->{options}{db_file} ) = ( $self->{options}{db_file} =~ /(.*)/s ); # untaint the database filename so I can delete it later
  if ( -e $self->{options}{db_file} ) {
    # If it does exist, see if the data is still valid (check the date)
    tie %h, "BerkeleyDB::Hash",
                -Filename => $self->{options}{db_file},
                -Flags    => DB_CREATE
        or die "Cannot open file $self->{options}{db_file}: $! $BerkeleyDB::Error\n" ;
    if ( exists $h{"date"} ) { # cache file contains a date stamp
      if ( Date_Cmp( $h{"date"}, DateCalc( "today", "-" . $self->{options}{update_interval} ) ) < 0 ) { 
	# It's too old, fetch new data
	# removing the whole database file first prevents database files from getting too huge
	untie %h;	
	unlink( $self->{options}{db_file} );
	$status = $self->_fetch_proxies();
      }
      else { # The cache is good and current enough to be used
	untie %h;
	$status = 1;
      }
    }
    else { # cache database file exists, but is malformed, let's rebuild it
      untie %h;
      unlink( $self->{options}{db_file} );
      $status = $self->_fetch_proxies();
    }
  }
  else {  # If it doesn't exist, create and populate it
    $status = $self->_fetch_proxies();
  }
  ( $status ) ? return $self : return $status;  
}

=head2 set_proxy()

Chooses a proxy at random from the cache database and sets it as the proxy for a LWP::UserAgent.  Automatically tests the proxy.  If the proxy fails the test, it removes the proxy from the cache and chooses another one until it finds a working proxy.  If necessary, this sub will try every proxy in the cache database.

Arguments: A LWP::Useragent object

Returns:  1 (success) or undef upon failure (sets an error).

=head3 Example:

  $select->set_proxy( $ua ) or die $select->error();

=cut

# Accept a proxy
sub set_proxy {
  my ($self, $ua) = @_;
  # Open the cache database
  tie %h, "BerkeleyDB::Hash", -Filename => $self->{options}{db_file}, 
    or $self->error( "Cannot open file $self->{options}{db_file}: $! $BerkeleyDB::Error" ) and return undef ;
  my $proxytest = 0;
  do {
    # Select a random proxy from the cache
    my $proxy;
    my @proxies = keys( %h );
    do { $proxy = $proxies[ int( rand( scalar( @proxies ) ) ) ]; } until ( $proxy ne "date" );
    $self->{selected_proxy} = $proxy;
    $ua->proxy(['http', 'ftp'], 'http://' . $self->{selected_proxy});
    # Test the proxy
    $proxytest = $self->test_proxy( $ua );
    # Delete the proxy if it failed the test
    delete $h{ $proxy } unless ( $proxytest );
  } until ( $proxytest || ( scalar( keys( %h ) ) <= 1 ) );
  untie %h;
  if ( $proxytest ) {
    return 1;
  }
  else {
    # delete the proxy file to force the next new() call to create a new cache
    unlink $self->{options}{db_file};
    $self->error( 'All proxies were bad' ) and return undef;
  }
}

=head2 get_proxy()

Arguments: none.

Returns: a scalar string containing the address of the selected proxy.

=head3 Example:

  $proxy_address = $select->get_proxy();

=cut

sub get_proxy {
  my $self = shift;
  return $self->{selected_proxy};
}


=head2 test_proxy()

Tests the proxy by trying to access a site (specified using the "testsite" option when constructing an HTTP::ProxySelector::Persistent object).  It temporarily sets the timeout to be 1/2 of the timeout set in the useragent that's passed to it.  If the useragent that's passed doesn't have a timeout set, it defaults to 5 seconds.

Arguments:  an LWP::UserAgent object.

Returns:  1 for success or undef for failure (sets an error).

Example: 

  ( $select->test_proxy( $ua ) ) ? print "Good test\n" : die $select->error();

=cut

sub test_proxy {
  my ($self, $ua) = @_;
  my ( $original_timeout, $test_timeout ) = ( $ua->timeout(), int( $ua->timeout() / 2 ) );
  $test_timeout = 5 if ( $original_timeout == 180 ); 
  $test_timeout = 1 if ( $test_timeout == 0 ); # prevent 0 second timeouts

  $ua->timeout( $test_timeout );
  my $response = $ua->get($self->{options}{testsite});
  $ua->timeout( $original_timeout );
  
  return 1 if ( $response->is_success() );  # successful exit
  
  # Error out
  $response->is_error() ? $self->error( $response->error_as_HTML() ) : $self->error( "Unknown error while testing proxy" );
  return undef;
}

=head2 proxied_get()

Selects a proxy and attempts to download the URL passed to this function as an argument.  If the download fails, it will remove the proxy from the cache, select another one, and retry until the download succeeds.  When it does succeed, this function returns the content of the response.  If all you need to do is download one webpage one time, this should take about half as long as manually setting a useragent and then using that useragent to do a second grab after the automatic proxy test.

If all you're doing is a single HTTP get in your script and that's it, this is a faster way to do it.  Setting the useragent proxy involves at least one mandatory test before the module even gives you a proxy to make your real get with.  This way uses your actual HTTP get instead of testing first.  It just persistently attempts to make your get and doesn't quit until it either runs out of proxies or succeeds in the HTTP get.

Each call to this method chooses a new proxy server from the cache.  Using two calls to proxied_get() in the same script will most likely use two completely different proxy servers.

=head3 Arguments are options in a single hash with these keys:

=over 1

=item B<url> - a scalar URL to be downloaded.  Mandatory.

=item B<timeout> - a scalar integer number of how many seconds to allow before declaring the attempt a failure and trying a new proxy.  Optional, defaults to 2.

=item B<ua> - An LWP::UserAgent that you'd like to use for the transaction.  Optional.  This sub constructs a default LWP useragent if you don't provide one.

=back

=head3 Returns:

The content of the page located at $url upon success, or undef upon failure (sets an error).

=head3 Example

  my $html = $selector->proxied_get( url => $url, timeout => 5 ) or die $selector->error();

=cut

sub proxied_get {
  my ( $self, %options ) = @_;
  $options{timeout} ||= 2;  # Set default timeout
  my $ua = $options{ua} || LWP::UserAgent->new( timeout => $options{timeout} );
  $self->error( "Did not provide a URL to proxied_get" ) and return undef unless defined $options{url};

  # Open the cache database
  tie %h, "BerkeleyDB::Hash", -Filename => $self->{options}{db_file}
    or $self->error( "Cannot open file $self->{options}{db_file}: $! $BerkeleyDB::Error" ) and return undef;
  my $response;
  do {
    # Select a random proxy from the cache
    my $proxy;
    my @proxies = keys( %h );
    do { $proxy = $proxies[ int( rand( scalar( @proxies ) ) ) ]; } until ( $proxy ne "date" );
    $self->{selected_proxy} = $proxy;
    $ua->proxy(['http', 'ftp'], 'http://' . $self->{selected_proxy});
    $response = $ua->get( $options{url} ); # Download using the proxy
    delete $h{ $proxy } unless ( $response->is_success() );   # Delete the proxy if it failed to download
  } until ( $response->is_success() || ( scalar( keys( %h ) ) <= 1 ) );
  untie %h;
  if ( $response->is_success() ) {
    return $response->content();
  }
  else {
    # delete the proxy file to force the next new() call to create a new cache
    unlink $self->{options}{db_file};
    $self->error( "All proxies were bad" ) and return undef;
  }
}

=head2 error()

If any portion of the module encounters an error, calling this function will return a string describing the last error.  Read-only.  No arguments.

=head3 Example

  my $html = $selector->proxied_get( $url_that_doesnt_exist ) or die $selector->error();

=cut

sub error {
  my ( $self, $msg ) = @_;
  if ( !defined($msg) or ! $self->isa(__PACKAGE__) ) {
    my $error = $self->{error};
    $self->{error} = undef;
    return $error;
  }
  else {
    $self->{error} = $msg;
  }
}

=head1 PRIVATE FUNCTIONS

=head2 _fetch_proxies()

Retrieves the proxy lists, extracts the proxy servers and caches them locally in a BerkeleyDB.  This sub assumes that the cache database file does not exist.  If this function were called before the cache database file were deleted, you would have duplicate entries in the cache and a bunch of old, potentially inoperative proxies stored in the cache.  You should never have to call this method yourself.  The B<new()> method of the HTTP::ProxySelector::Persistent object uses this sub when the proxy cache database is either expired, malformed, empty or missing.

=head3 Arguments: none.

=head3 Returns: 

1 upon success, or undef upon failure.

=cut

sub _fetch_proxies {
  my $self = shift;
  tie %h, "BerkeleyDB::Hash",
             -Filename => $self->{options}{db_file},
             -Flags    => DB_CREATE
    or self->error("_fetch_proxies: Cannot open file $self->{options}{db_file}: $! $BerkeleyDB::Error") and return undef;

  # Fetch the proxy lists
  my $ua = LWP::UserAgent->new;
  my $proxytext = "";
  foreach my $page ( @{ $self->{options}{sites} } ) {
    my $response = $ua->get( $page );
    $proxytext .= $response->content();
  }
  # Extract the proxies from the downloaded web pages
  # Strip any HTML from the proxylists
  $proxytext =~ s#</?p.*?>|<br ?/?>|</?li>#\n#gis;
  $proxytext =~ s#<.+?>##gis;
  $proxytext =~ s#\n+#\n#gs;
  # Standardize port annotation
  $proxytext =~ s#((?:[\w\-]+\.)+[\w\-]+):?\s+(\d{1,5})\s*#$1:$2\n#gs;
  my @proxy_list = $proxytext =~ m#(?:\w+://)?((?:[\w\-]+\.)+[\w\-]+:\d{1,5})#g; # text or IP addresses of proxy servers
  unless (@proxy_list) { $self->error( "_fetch_proxies: Couldn't find any proxies" ) and return undef; }
  $h{"date"} = ParseDate( "today" );
  foreach my $proxy ( @proxy_list ) { $h{ $proxy } = 1; }
  untie %h;
  return 1;
}

=head1 TODO

=over 2

=item * Need to find better proxylists for the test scripts.  By and large, the free proxylists I found had a bunch of bad proxy servers in them.  This makes my tests look bad because 'garbage in = garbage out.'

=back

=head1 AUTHOR

Michael Trowbridge, C<< <michael.a.trowbridge at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-http-proxyselector-persistent at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-ProxySelector-Persistent>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::ProxySelector::Persistent

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-ProxySelector-Persistent>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-ProxySelector-Persistent>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-ProxySelector-Persistent>

=item * Search CPAN

L<http://search.cpan.org/dist/HTTP-ProxySelector-Persistent>

=back

=head1 ACKNOWLEDGEMENTS

This module is a fork from HTTP::ProxySelector v0.02.  HTTP::ProxySelector v0.02 is copyright 2003 Eyal Udassin.

Error method was written by Allen Day and borrowed from Geo::Google.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Michael Trowbridge, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of HTTP::ProxySelector::Persistent
