package HTTP::Client;

use 5.006;
use strict;
use warnings;
use Carp;
use HTTP::Lite;

our $VERSION = '1.57';

#array of headers sendable for requests.

my @request_headers = qw(
Accept Accept-Charset Accept-Encoding Accept-Language
Authorization Expect From Host
If-Match If-Modified-Since If-None-Match If-Range If-Unmodified-Since
Max-Forwards Proxy-Authorization Range Referer TE User-Agent
);

my $http = HTTP::Lite->new; #make new HTTP::Lite object.
#class constructor
sub new {
   my $class    = shift;
   my $self     = {}; 
   $self->{agent} = shift; #user agent
   $self->{from } = shift;
   bless $self, $class; 
} 

sub get {
   my $self = shift;
   my $uri = shift;
   $uri =~ s/#//; #get rid of fragment, according to RFC 2616
   my $request;

   $http->reset();
   $request = $http->request($uri) or croak "Can't get $uri; may be a result of a bad hostname: $!"; #get it.
   my $fullmessage = $http->status . ' ' . $http->status_message; #full status message.
   #give them the body of the request if it has a body and sent an OK response.
   return $http->body if ($http->body and $fullmessage =~ /200 OK/);
   #return the message if the message isn't 200 OK, and there is no body.
   return $fullmessage unless ($fullmessage eq '200 OK' and $http->body);
}


sub response_headers {
   my $self = shift;
   #gather all response headers.
   my @headers = $http->headers_array;
   return @headers;
}


sub agent {
   my $self  = shift;
   my $agent = shift; #user agent
   #send useragent header if they supplied one.
   $agent = $self->{agent} if ($self->{agent} and not $agent);
   $http->add_req_header('User-Agent', $agent) if ($agent); 
   #return the current one if they didn't supply the useragent.
   return $http->get_req_header('User-Agent')         unless ($agent);
}

sub from {
   my $self = shift;
   my $from = shift;
   $from = $self->{from} if ($self->{from} and not $from);
   $http->add_req_header('From', $from) if ($from); #set the from header.
   $http->get_req_header('From')        unless ($from);
}

##
## Methods to get response headers
##

sub status_message {
   my $self = shift;
   my $fullmessage = $http->status . ' ' . $http->status_message;
   return $fullmessage;
}

sub server           { my $self = shift; $http->get_header('Server')           } 
sub content_type     { my $self = shift; $http->get_header('Content-Type')     }
sub last_modified    { my $self = shift; $http->get_header('Last-Modified')    }
sub protocol         { my $self = shift; $http->protocol                       }
sub content_encoding { my $self = shift; $http->get_header('Content-Encoding') }
sub content_length   { my $self = shift; $http->get_header('Content-Length')   }
sub warning          { my $self = shift; $http->get_header('Warning')          }
sub title            { my $self = shift; $http->get_header('Title')            }
sub date             { my $self = shift; $http->get_header('Date')             }
sub host             { my $self = shift; $http->get_header('Host')             }

1;

__END__

=head1 NAME

HTTP::Client - Class for making HTTP requests

=head1 SYNOPSIS

  use HTTP::Client;
  
  my $client  = HTTP::Client->new();
  my $site    = $client->get("http://www.cpan.org");
  my @headers = $client->response_headers;
  my $agent   = $client->agent;
  print $agent . "\n";
  print $headers[$_] . "\n" foreach (0..$#headers);
  print $site;

=head1 DESCRIPTION

HTTP::Client is a class for creating
clients, that does not require
L<LWP>. It is aimed at speed.
It can send HTTP Request headers,
get HTTP response headers and get documents.

=head1 METHODS

=over 3

=item new

This is the constructor for HTTP::Client.
It can be called like this:

   my $client = HTTP::Client->new;

or this:

   my $client = new HTTP::Client ();

it can take the useragent string as
an argument like this:

   my $client = HTTP::Client->new("Bot/1.0");

If the useragent is supplied in
the constructor, but then supplied
in the C<agent()> method, the
constructor will be authoritative.
In other words, you can only override
the already specified client
name by using only C<agent> methods,
and not the constructor. (This is
actually a bug.)

=item $client->get

B<get> gets a page on the web.
It can only do http pages for now.
The URI (URL) to get is the only 
argument it takes. It returns
the body of the site if successful
(The HTTP status code is "200 OK",
or the other HTTP status code
if it is not equal to that.
For example:

   my $site = $client->get("http://www.cpan.org");
   print $site . "\n"; 

prints the source of cpan.org or the status code if 
it could not find it. It will append a trailing 
slash to the URL if it doesn't end in one.

=item $client->response_headers

B<response_headers> returns an array
of all the response headers sent by the 
server. Currently, to loop
through the array, you must
use this construct:

 my $site = $client->get("http://www.cpan.org");
 my @headers = $client->response_headers;
 foreach (0..$#headers) {
    print $headers[$_] . "\n";
 }

this is a big bug.

=item $client->agent

B<agent> sets the current User-Agent header,
thus renaming the current client.
If the agent was specified in the constructor,
even using this method will not override the
one specified in the constructor.
So, you can only override your useragent with multiple agent()s,
not with the constructor and then agent()s.
For example:

 my $client = HTTP::Client->new("Bot/1.0");
 my $site = $client->get("http://www.cpan.org");
 $client->agent("NewBot/1.0"); #Wrong! agent is still "Bot/1.0"

is wrong but this:

 my $client = HTTP::Client->new;
 my $site = $client->get("http://www.cpan.org");
 $client->agent("NewBot/1.0"); #Right! useragent is NewBot/1.0!
 $client->agent("NewNewBot/1.0"); #Right! useragent is now NewNewBot/1.0!

is right and changes the useragent after the second call.

=item $client->from

B<from> sets the From header, which should
be an email address of the person/machine that
is sending the request. If the from was
specified in the constructor, just like the
agent method, using this method will
not override the setting in the constructor.
Therefore, you can only override from headers
by using multiple from() methods, not
by using the constructor and then from methods.
For example:

 my $client = HTTP::Client->new("Bot/1.1", "nightcat\@crocker.com");
 my $site = $client->get("http://www.cpan.org");
 $client->from("au\@th.or"); #Wrong! From is still nightcat@crocker.com!

doesn't work, but this:

 my $client = HTTP::Client->new;
 my $site = $client->get("http://www.cpan.org");
 $client->from("nightcat\@crocker.com"); #Right! From is nightcat@crocker.com!
 $client->from("au\@th.or"); #Right! From is now au@th.or!

does. Note that you have to escape the at sign (@) in the
address if you are using double quotes, because otherwise
it will be interpreted as an array.

=item $client->status_message

B<status_message> returns the HTTP status message
sent by the server. It returns it in the
full form, e.g. "200 OK" or "404 Not Found".
For example:

 my $site = $client->get("http://www.cpan.org");
 print $client->status_message;

prints "200 OK". Note that
if here, and anywhere else
when getting a site,
if a bad hostname is supplies,
the program will die with the error
"Can't get (url to get); may be a result of a bad hostname: (error message in $!)"

=item $client->server

returns the value of the Server header sent by the server.

=item $client->content_type

returns the Content-Type header sent by the server.

=item $client->last_modified

returns the Last-Modified header sent by the server.

=item $client->protocol

returns the protocol sent by the server. (Usually something like
"HTTP/1.1"

=item $client->content_encoding

returns the Content-Encoding header sent by the server.

=item $client->content_length

returns the Content-Length header sent by the server.

=item $client->warning

returns the Warning header sent be the server.

=item $client->title

returns the Title header sent by the server.

Note: I<This is no longer part of the HTTP specification.>

=item $client->date

returns the Date header returned by the server.

=item $client->host

returns the Host header returned by the server.

=back

=head1 EXAMPLE

a real world example for getting documents would be:

 use HTTP::Client;
 my $client = HTTP::Client->new("GetBot/1.0");
 my $url = shift || <STDIN>;
 chomp($url);
 my $site = $client->get($url);
 print "\n" . $client->agent . " got $url successfully.";
 print "\n\nHeaders Recieved:\n";
 my @headers = $client->response_headers;
 print "$headers[$_]\n" foreach (0..$#headers);
 print "\nBody of document:\n\n";
 print $site . "\n\n";

=head1 SEE ALSO

L<http://neilb.org/reviews/http-requesters.html> - a review of CPAN modules
for making HTTP requests.

In short, you should consider one of the following modules:
L<HTTP::Tiny>, L<LWP::UserAgent>, L<Furl>, L<Mojo::UserAgent>, L<LWP::Curl>,
L<Net::Curl>.

=head1 REPOSITORY

L<https://github.com/neilbowers/HTTP-Client>

=head1 AUTHOR

As of 1.52,
this module is now maintained by Neil Bowers E<lt>neilb@cpan.orgE<gt>.

HTTP::Client was written by Lincoln Ombelets E<lt>lincdog85@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2012 Lincoln Ombelets.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
