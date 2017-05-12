package LWP::Curl;

use warnings;
use strict;
use Net::Curl::Easy qw(:constants);
use Carp qw(croak);
use Data::Dumper;
use URI::Escape;

=head1 NAME

LWP::Curl - LWP methods implementation with Curl engine

=head1 VERSION

Version 0.14

=cut

our $VERSION = '0.14';

=head1 SYNOPSIS

  use LWP::Curl;
   
  my $lwpcurl = LWP::Curl->new();
  my $content = $lwpcurl->get('http://search.cpan.org','http://www.cpan.org'); 
  # get the page http://search.cpan.org passing with referer http://www.cpan.org

=head1 DESCRIPTION

LWP::Curl provides an interface similar to the LWP library, but is built on top of the Curl library.
The simple LWP-style interface means you don't have to know anything about the underlying library.

=head1 Constructor

=head2 new()

Creates and returns a new LWP::Curl object, hereafter referred to as
the "lwpcurl".

    my $lwpcurl = LWP::Curl->new()

=over 4

=item * C<< timeout => sec >>

Set the timeout value in seconds. The default timeout value is
180 seconds, i.e. 3 minutes.

=item * C<< headers => [0|1] >>

Show HTTP headers when return a content. The default is false '0'

=item * C<< user_agent => 'agent86' >>

Set the user agent string. The default is  'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)'

=item * C<< followlocation => [0|1] >>

If true, the user-agent will honor HTTP 301 (redirect) status messages. The default is 1.

=item * C<< auto_encode => [0|1] >>

If true, urls will be urlencoded for GET and POST requests. Default is 1.

=item * C<< maxredirs => number >>

Set how many redirect requests will be honored by the user-agent. The default is 3.

=item * C<< proxy => $proxyurl >>

Set the proxy in the constructor, $proxyurl will be like:  
    http://myproxy.com:3128/
    http://username:password@proxy.com:3128/

  libcurl respects the environment variables http_proxy, ftp_proxy,
  all_proxy etc, if any of those are set. The $lwpcurl->proxy option does
  however override any possibly set environment variables. 

=back

=cut

sub new {

    # Check for common user mistake
    croak("Options to LWP::Curl should be key/value pairs, not hash reference")
      if ref( $_[1] ) eq 'HASH';

    my ( $class, %args ) = @_;

    my $self = {};

    my $log = delete $args{log};

    my $timeout = delete $args{timeout};
    $timeout = 3 * 60 unless defined $timeout;

    my $headers = delete $args{headers};
    $headers = 0 unless defined $headers;

    my $user_agent = delete $args{user_agent};
    $user_agent = 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)'
      unless defined $user_agent;

    my $maxredirs = delete $args{max_redirs};
    $maxredirs = 3 unless defined $maxredirs;

    my $followlocation = delete $args{followlocation};
    $followlocation = 1 unless defined $followlocation;

    $self->{auto_encode} = delete $args{auto_encode};
    $self->{auto_encode} = 1 unless defined $self->{auto_encode};
	
	$self->{timeout} = $timeout;	
   
    my $proxy = delete $args{proxy};
    $self->{proxy} = undef unless defined $proxy;
    
    $self->{retcode} = undef;

    my $debug = delete $args{debug};
    $self->{debug} = 0 unless defined $debug;
    print STDERR "\n Hash Debug: \n" . Dumper($self) . "\n" if $debug;
    $self->{agent} = Net::Curl::Easy->new();
    $self->{agent}->setopt( CURLOPT_TIMEOUT,     $timeout );
    $self->{agent}->setopt( CURLOPT_USERAGENT,   $user_agent );
    $self->{agent}->setopt( CURLOPT_HEADER,      $headers );
    $self->{agent}->setopt( CURLOPT_AUTOREFERER, 1 );             # always true
    $self->{agent}->setopt( CURLOPT_MAXREDIRS,   $maxredirs );
    $self->{agent}->setopt( CURLOPT_FOLLOWLOCATION, $followlocation );
    $self->{agent}->setopt( CURLOPT_SSL_VERIFYPEER, 0 );
    $self->{agent}->setopt( CURLOPT_VERBOSE, 0 ); #ubuntu bug
    $self->{agent}->setopt( CURLOPT_PROXY, $proxy ) if $proxy;

    return bless $self, $class;
}

=head1 METHODS

=head2 $lwpcurl->get($url,$referer)

Get content of $url, passing $referer if defined.

    use LWP::Curl;
	my $referer = 'http://www.example.com';
	my $get_url = 'http://www.example.com/foo';
    my $lwpcurl = LWP::Curl->new();
	my $content = $lwpcurl->get($get_url, $referer); 

The C<get> method croak()'s if the request fails, so wrap an C<eval> around it if you want to
handle failure more elegantly.

=cut

sub get {
    my ( $self, $url, $referer ) = @_;
    my $agent = $self->{agent};

    if ( !$referer ) {
        $referer = "";
    }
	
	$url = uri_escape($url,"[^:./]") if $self->{auto_encode};
    $agent->setopt( CURLOPT_REFERER, $referer );
    $agent->setopt( CURLOPT_URL,     $url );
    $agent->setopt( CURLOPT_HTTPGET, 1 );

    my $content = "";
    open( my $fileb, ">", \$content );
    $agent->setopt( CURLOPT_WRITEDATA, $fileb );
    $self->{retcode} = $agent->perform;

    if ( ! defined $self->{retcode} ) {
        my $response_code = $agent->getinfo(CURLINFO_HTTP_CODE);
        if ($response_code == 200 || ($response_code == 0 && $url =~ m!^file:!)) {
            print("\nTransfer went ok\n") if $self->{debug};
            return $content;
        }
    }

    croak( "An error happened: Host $url "
              . $self->{agent}->strerror( $self->{retcode} )
              . " ($self->{retcode})\n" );
    return undef;
}

=head2 $lwpcurl->post($url,$hash_form,$referer) 
 
POST the $hash_form fields in $url, passing $referer if defined:

  use LWP::Curl;
  
  my $lwpcurl = LWP::Curl->new();
  
  my $referer = 'http://www.examplesite.com/';
  my $post_url = 'http://www.examplesite.com/post/';
  
  my $hash_form = { 
    'field1' => 'value1',
    'field2' => 'value2',
  }
  
  my $content = $lwpcurl->post($post_url, $hash_form, $referer); 

=cut

sub post {
    my ( $self, $url, $hash_form, $referer ) = @_;

    if ( !$referer ) {
        $referer = "";
    }

    if ( !$hash_form ) {
        warn(qq{POST Data not defined});
    }
    else {

        #print STDERR Dumper $hash_form;
    }

	$url = uri_escape($url,"[^:./]") if $self->{auto_encode};
    my $post_string = join '&', map {; uri_escape($_) . '=' . uri_escape($hash_form->{$_}) } keys %{ $hash_form };

    $self->{agent}->setopt( CURLOPT_POSTFIELDS, $post_string );
    $self->{agent}->setopt( CURLOPT_POST,       1 );
    $self->{agent}->setopt( CURLOPT_HTTPGET,    0 );

    $self->{agent}->setopt( CURLOPT_REFERER, $referer );
    $self->{agent}->setopt( CURLOPT_URL,     $url );
    my $content = "";
    open( my $fileb, ">", \$content );
    $self->{agent}->setopt( CURLOPT_WRITEDATA, $fileb );
    $self->{retcode} = $self->{agent}->perform;

    if ( ! defined $self->{retcode} ) {
        my $code;

        $code = $self->{agent}->getinfo(CURLINFO_HTTP_CODE);
        if ($code =~ /^2/) {
            return $content;
        }
        croak "$code request not successful\n";
    } else {
        croak(  "An error happened: Host $url "
              . $self->{agent}->strerror( $self->{retcode} )
              . " ($self->{retcode})\n" );
    }
}

=head2 $lwpcurl->timeout($sec)

Set the timeout to use for all subsequent requests, in seconds.
Defaults to 180 seconds.

=cut

sub timeout {
    my ( $self, $timeout ) = @_;
    if ( !$timeout ) {
        return $self->{timeout};
    }
	$self->{timeout} = $timeout;
    $self->{agent}->setopt( CURLOPT_TIMEOUT, $self->timeout );
}

=head2 $lwpcurl->auto_encode($value)

Turn on/off auto_encode.

=cut

sub auto_encode {
    my ( $self, $value ) = @_;
    if ( !$value ) {
        return $self->{auto_encode};
    }
    $self->{auto_encode} = $value;
}

=head2 $lwpcurl->agent_alias($alias)
   
Sets the user agent string to the expanded version from a table
of actual user strings.
I<$alias> can be one of the following:

=over 4

=item * Windows IE 6

=item * Windows Mozilla

=item * Mac Safari

=item * Mac Mozilla

=item * Linux Mozilla

=item * Linux Konqueror

=back

then it will be replaced with a more interesting one.  For instance,

  $lwpcurl->agent_alias( 'Windows IE 6' );

sets your User-Agent to

  Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)

=cut

sub agent_alias {
    my ( $self, $alias ) = @_;

    # CTRL+C from WWW::Mechanize, thanks for petdance
    # ------------
    my %known_agents = (
        'Windows IE 6' => 'Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)',
        'Windows Mozilla' =>
'Mozilla/5.0 (Windows; U; Windows NT 5.0; en-US; rv:1.4b) Gecko/20030516 Mozilla Firebird/0.6',
        'Mac Safari' =>
'Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/85 (KHTML, like Gecko) Safari/85',
        'Mac Mozilla' =>
'Mozilla/5.0 (Macintosh; U; PPC Mac OS X Mach-O; en-US; rv:1.4a) Gecko/20030401',
        'Linux Mozilla' =>
          'Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.4) Gecko/20030624',
        'Linux Konqueror' => 'Mozilla/5.0 (compatible; Konqueror/3; Linux)',
    );

    if ( defined $known_agents{$alias} ) {
        $self->{agent}->setopt( CURLOPT_USERAGENT, $known_agents{$alias} );
    }
    else {
        warn(qq{Unknown agent alias "$alias"});
    }
}

=head2 $lwpcurl->proxy($proxyurl)

Set the proxy in the constructor, $proxyurl will be like:  
    http://myproxy.com:3128/
    http://username:password@proxy.com:3128/

libcurl respects the environment variables http_proxy, ftp_proxy,
all_proxy etc, if any of those are set. The $lwpcurl->proxy option does
however override any possibly set environment variables. 

To disable proxy set $lwpcurl->proxy('');

$lwpcurl->proxy without argument, return the current proxy

=cut

sub proxy {
    my ( $self, $proxy ) = @_;
    if ( !defined $proxy ) {
        return $self->{proxy};
    }
	$self->{proxy} = $proxy;
    $self->{agent}->setopt( CURLOPT_PROXY, $self->proxy );
}

=head1 TODO

This is a small list of features I'm plan to add. Feel free to contribute with your wishlist and comentaries!

=over 4

=item * Test for the upload method

=item * Improve the Documentation and tests

=item * Support Cookies

=item * PASS in all tests of LWP

=item * Make a patch to L<WWW::Mechanize>, todo change engine, like "new(engine => 'LWP::Curl')"

=back

=head1 AUTHOR

Lindolfo Rodrigues de Oliveira Neto, C<< <lorn at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lwp-curl at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LWP-Curl>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LWP::Curl

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LWP-Curl>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LWP-Curl>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/LWP-Curl>

=item * Search CPAN

L<http://search.cpan.org/dist/LWP-Curl>

=back


=head1 ACKNOWLEDGEMENTS

Thanks to Breno G. Oliveira for the great tips.    
Thanks for the LWP and WWW::Mechanize for the inspiration.
Thanks for Neil Bowers for the patches
Thanks for Mark Allen for the patches 

=head1 COPYRIGHT & LICENSE

Copyright 2009 Lindolfo Rodrigues de Oliveira Neto, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1;    # End of LWP::Curl
