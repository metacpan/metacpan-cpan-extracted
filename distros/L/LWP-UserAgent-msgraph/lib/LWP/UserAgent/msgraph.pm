package LWP::UserAgent::msgraph;

use strict;
use warnings;

our $VERSION = '0.12';

use parent 'LWP::UserAgent';

use JSON;
use Storable;
use Data::UUID;
use File::Spec;
use Storable;
use Carp;
use URI;
use HTTP::Request::Common;
use Net::EmptyPort qw(listen_socket empty_port check_port);

sub new($%) {

   my %internals;

   my $class=shift();
   
   my %args=@_;

   #This are our lwp-extended options
   for (qw(appid secret grant_type scope persistent sid base store redirect_uri tenant local_port)) {
      if (exists $args{$_}) {
         $internals{$_}= $args{$_};
         delete $args{$_};
      }
   }

   #Some defaults
   unless (exists $internals{sid} && defined $internals{sid}) {
      my $guid=Data::UUID->new;
      $internals{sid}=$guid->create_str();
   }

   my $sid=$internals{sid};

   $internals{base}='https://graph.microsoft.com/v1.0' unless(exists $internals{base}); 
   $internals{base} =~ s/\/$//;

   $internals{console}=0 unless (exists $internals{console});

   $internals{expires}=0;
   $internals{local_port}=8081 unless ($internals{local_port});

   #complain about missing options
   for (qw(appid grant_type tenant)) {
      croak "Missing mandatory option $_" unless (exists $internals{$_});
   }

   #Now the persistent thing
   $internals{persistent}=1 if (exists $internals{store} && ! exists $internals{persistent});
   $internals{persistent}=0 unless (exists $internals{persistent});

   if ($internals{persistent} && ! exists $internals{store}) {
      my $tmpdir = File::Spec->tmpdir();
      $internals{store}="$tmpdir/$sid.tmp";
   }

   #We retrieve previous stored runtime data if we persist
   if ($internals{persistent} && -r $internals{store}) {
      my $stored=retrieve($internals{store});
      croak 'Mismatch persistent session' unless ($stored->{sid} eq $sid);
      for (keys %$stored) {
         $internals{$_}=$stored->{$_};
      }
   }
   
   my $self=$class->SUPER::new(%args);
   for (keys %internals) {
      $self->{$_} = $internals{$_};
   }

   #We adopt a previous token if there was any
   $self->default_header('Authorization' => "Bearer ".$internals{access_token}) if ($internals{persistent} && exists $internals{access_token} );

   return $self;

}

sub storedata($) {

   my $self=shift();
   my $data={};

   #This is a subset of the runtime data. It's important that the secret is out
   for (qw(access_token expires expires_in refresh_token token_type scope appid sid redirect_uri console)) {
      $data->{$_}=$self->{$_};
   }

   return $data;
}

sub session_dump($) {
   
   my $self=shift();

   return to_json($self->storedata());
}

sub session_restore($$) {

   my $self=shift();
   my $json=shift();

   my $data=from_json($json);

   for (qw(access_token expires expires_in refresh_token token_type scope appid sid redirect_uri console)) {
      $self->{$_}=$data->{$_};
   }

   $self->default_header('Authorization' => "Bearer ".$self->{access_token});
   return $self;
}

sub writestore($) {
   
   my $self=shift();

   croak 'Wrong writestore call on non-persistant client' unless ($self->{persistent});

   return store $self->storedata(), $self->{store};
}

sub refreshtoken($) {

   my $self=shift();

   my $ua = LWP::UserAgent->new;
   my $r=$ua->post('https://login.microsoftonline.com/organizations/oauth2/v2.0/token',
      [client_id=>$self->{appid},
       scope=>$self->{scope},
       refresh_token=>$self->{refresh_token},
       redirect_uri=> $self->{redirect_uri},
       grant_type=>'refresh_token',
       client_secret=>$self->{secret} ]);
   if ($r->is_success) {
      my $data=decode_json($r->decoded_content);
      my $token=$data->{access_token};      

      for (keys %$data) {
         $self->{$_}=$data->{$_};
      }

      $self->{expires}=(time + $data->{expires_in});
      $self->writestore() if ($self->{presistent});
      $self->default_header('Authorization' => "Bearer ".$token);
  
      $self->writestore() if ($self->{persistent});
      return $token;
    } else {
      croak "Refresh token auth fail";
    }      
}

sub newtoken($) {

   my $self=shift();

   if ($self->{refresh_token}) {
      return $self->refreshtoken;
   } else {
      return $self->auth();
   }
}

sub request {

   my ($self,$method, $url, $payload)=@_;

   $url =~ s/^\///;

   my $abs_uri=URI->new_abs($url, $self->{base}.'/');

   if ($self->{expires} < time()) {
      $self->newtoken();
   }

   my $req=HTTP::Request->new($method,"$abs_uri");
   $req->header('Content-Type' => 'application/json');
   $req->header('Accept' => 'application/json');
   $req->content(to_json($payload)) if ($payload);

   my $res=LWP::UserAgent::request($self,$req);

   #Response code is a keeper
   $self->{code}=$res->code;

   if ($res->is_success) {
      if ($res->header('content-type') =~ /^application\/json/) {
         
         my $data=from_json($res->decoded_content);

         #Here we save the nextLink for further use
         if (exists $data->{'@odata.nextLink'}) {
            $self->{nextLink}=$data->{'@odata.nextLink'};
         } else {
            $self->{nextLink}=0;
         }
         return $data;
     } else {
        return 0;
     }
   } else {
      croak $res->decoded_content
   }
}

sub code($) {

   my $self=shift();
   return $self->{code};
}

sub next($) {

   my $self=shift();

   if ($self->{nextLink}) {
      return $self->request('GET' => $self->{nextLink});
   } else {
      return 0;
   }
}

sub authendpoint($) {

   my $self=shift();

   #This is an ugly url. Must be used as a GET or a redirect location, so can't be done as POST
   my $url=URI->new("https://login.microsoftonline.com/".$self->{tenant}."/oauth2/v2.0/authorize");

   #query_param_append comes handy, but was introduced in URI 5.16
   $url->query_param_append('client_id'     => $self->{appid});
   $url->query_param_append('response_type' => 'code');
   $url->query_param_append('redirect_uri'  => $self->{redirect_uri});
   $url->query_param_append('response_mode' => 'query');
   $url->query_param_append('scope'         => $self->{scope});
   $url->query_param_append('state'         => $self->{sid});
   return "$url";
}

sub tokenendpoint($) {

   my $self=shift();
   return "https://login.microsoftonline.com/".$self->{tenant}."/oauth2/v2.0/token";
}

sub sid($) {
   my $self=shift();
   return $self->{sid};
}

sub consolecode($) {

   my $self=shift();

   my $port=$self->{local_port};
   my $web=LWP::UserAgent::msgraph::srvauth->new($port);

   #Even if it's local, this redirect_uri must be Azure-registered
   $self->{redirect_uri}="http://localhost:$port/auth";

   #In order to setup a well-behaved http mini-server, we launch the server as a separate background
   #process using the HTTP::Server::Simple module.
   #Since this will be a separate process, and we need the authorization code value, we setup a 
   #private listening socket so the child process can upload the code to us
   my $socket=listen_socket();
   $web->setcaller($self, $socket->sockport);
   my $pid=$web->background();

   my $client=$socket->accept();
   my $data="";
   $client->recv($data,1024);

   my ($id,$code)=split /\s/, $data;

   #Our session id is sent as the optional 'state' parameter
   #This value comes back to us along with the authorization code
   #Here, we honour the state value validation. If the state value
   #is not a match, the authorization code is discarded
  if ($id && $id eq $self->sid) {
      print "Authorization code received. You can close the browser now\n";
      return $code;
   } else {
      return 0;
   }
}

sub auth {

   my $self=shift();

   my $post;

   #Here comes the authentication handshake with the MS Graph platform
   #This is all spoken in application/x-www-form-urlencoded, so we use
   #the standard simple_request and HTTP::Request approach

   #Client-credentials for user-less anonymous connection
   if ($self->{grant_type} eq 'client_credentials') {

      $post=HTTP::Request::Common::POST($self->tokenendpoint(),
         [client_id => $self->{appid},
          scope => $self->{scope},
          client_secret=> $self->{secret},
          grant_type => $self->{grant_type}
      ]);

   #Delegated authorization for user-oriented interaction
   } elsif ($self->{grant_type} eq 'authorization_code') {

      my $code=shift();
      $code=$self->consolecode() unless ($code || ! $self->{console});
      croak 'Missing or invalid authorization code' unless ($code);

      #print "Using scope ".$self->{scope}."\n";
      $post=HTTP::Request::Common::POST($self->tokenendpoint(),
         [client_id => $self->{appid},
          scope => $self->{scope},
          code => $code,
          redirect_uri => $self->{redirect_uri},
          client_secret=> $self->{secret},
          grant_type => $self->{grant_type}
      ]);

   } else {
      croak 'Missing or unsupported grant_type';
   }

   croak 'Authentication scheme error' unless ($post);
   
   my $r=$self->simple_request($post);
   unless ($r->is_success) {
      croak "Authentication failure ".$r->decoded_content;
   }

   my $data=from_json($r->decoded_content);
   for (keys %$data) {
      $self->{$_}=$data->{$_};
   }

   $self->{expires}=(time + $data->{expires_in});
   $self->writestore() if ($self->{presistent});
   $self->default_header('Authorization' => "Bearer ".$self->{access_token});
  
   $self->writestore() if ($self->{persistent});

   return $data->{access_token};
}

sub get {

   my ($self,@params)=@_;

   return $self->request('GET',@params);
}

sub post {
   my ($self,@params)=@_;

   return $self->request('POST',@params);

}

sub head {
   my ($self,@params)=@_;

   return $self->request('HEAD',@params);

}

sub patch {
   my ($self,@params)=@_;

   return $self->request('PATCH',@params);

}

sub put {
   my ($self,@params)=@_;

   return $self->request('PUT',@params);

}

sub delete {
   my ($self,@params)=@_;

   return $self->request('DELETE',@params);

}

package LWP::UserAgent::msgraph::srvauth;
use base 'HTTP::Server::Simple::CGI';
use HTTP::Server::Simple::CGI;
use IO::Socket qw(AF_INET AF_UNIX SOCK_STREAM SHUT_WR);

sub valid_http_method($$) {

   my ($self,$method)=@_;
   return ($method eq 'GET');
}
sub setcaller($$$) {
   
   my $self=shift();
   my $ms=shift();
   my $port=shift();

   $self->{'code_uri'}=$ms->authendpoint();
   $self->{'callerport'}=$port;
   return 1;
}

sub sendcode($$$) {

   my ($self,$code,$state)=@_;

   my $client =  IO::Socket->new(
    Domain => AF_INET,
    Type => SOCK_STREAM,
    proto => 'tcp',
    PeerPort => $self->{callerport},
    PeerHost => '127.0.0.1',
       ) || die "Can't open socket: $IO::Socket::errstr";

    $client->send($state.' '.$code);
    $client->shutdown(SHUT_WR);
    $client->close();
}

#Here we setup a minimal web server response behavior
#The only verbs allowed are:
#   GET /start  ==> does a 302 redirect to the MS authorization platform
#   GET /auth   ==> receives the authorization code in the query string
#
# This two methods performs an MS challenge to the end-user
#
# Note that depending on your particular browser state, there could be 
# a valid MS tenant session already logged in with this app previously
# authorized. In that case, the user doesn't get the login challenge
# and the only thing the browser performs is a series of redirects
# In that case, the authorization code get to us in a blink-you-missed-it
# fashion
sub handle_request {
    my $self = shift;
    my $cgi  = shift;
   
    my $path = $cgi->request_uri();
 
    if ($path =~  "^/auth" ) {
        print "HTTP/1.0 200 OK\r\n";
        my $msg="Authentication ok. You can close this window now.\n";
        print $cgi->header(-type=>'text/plain', -Content_length => length($msg));
        my $code=$cgi->param('code');
        my $state=$cgi->param('state');
        $self->sendcode($code,$state);
        print $msg;
         
        exit 0;
    } elsif ($path =~  "^/start" ) {
        print "HTTP/1.0 302 Redirected\r\n";
        print $cgi->redirect($self->{'code_uri'});
    } 
    else {
        print "HTTP/1.0 404 Not found\r\n";
        print $cgi->header,
              $cgi->start_html('Not found'),
              $cgi->h1('Not found'),
              $cgi->end_html;
    }
}

sub print_banner($) {
   my $self=shift();

   my $url="http://localhost:".$self->port()."/start";
   print "Authentication required.\nOpen your browser at $url\n";

}



1;

=pod

=encoding UTF-8

=head1 NAME

LWP::UserAgent::msgraph

=head1 VERSION

version 0.12

=head1 SYNOPSIS

   use LWP::UserAgent::msgraph;

   #The XXXX, YYYY and ZZZZ are from your Azure App Registration

   #Application Permission version
   $ua = LWP::UserAgent::msgraph->new(
      appid => 'XXXX',
      secret => 'YYYY',
      tenant => 'ZZZZ',
      grant_type => 'client_credentials');

   #Delegated authentication version
   $ua = LWP::UserAgent::msgraph->new(   
      appid => 'XXXX',
      secret => 'YYYY',
      tenant => 'ZZZZ',
      grant_type=> 'authorization_code',
      scope => 'openid user.read');
    $ua->auth($code_obtained_from_challenge);

   $joe = $ua->request(GET => '/users/jdoe@some.com');
   $dn = $joe->{displayName};

=head1 DESCRIPTION  

This module allows the interaction between Perl and the MS Graph API service.
Therefore, a MS Graph application can be built using Perl. The application must
be correctly registered within Azure with the proper persmissions.

This module has the glue for the needed authentication scheme and the JSON
serialization so a conversation can be established with MS Graph. This is just
middleware. No higher level object abstraction is provided for the MS Graph
object data.

=head1 CONSTRUCTOR

   my $ua=LWP::UserAgent->new(%options);

This method constructs a new L<LWP::UserAgent::msgraph> object.
key/value pairs must be supplied in order to setup the object
properly. Missing mandatory options will result in error

   KEY              MEANING
   -------          -----------------------------------
   appid            Application (client) ID
   secret           shared secret needed for handshake
   tenant           Tenant id
   grant_type       Authorizations scheme (client_credentials,authorization_code)
   scope            List of permissions requested as in 'perm1 perm2 perm3...'
   console          Indicates whether interaction with a user is possible
   redirect_uri     Redirect URI for delegated auth challenge
   local_port       tcp port for mini http server. Defaults to 8081
   sid              Session id. Defaults to a random UUID
   persistent       Whether to keep the session data between runs
   store            Filename for session data. Defaults to a temp file
   base             Base URL for MS Graph calls. Defaults to https://graph.microsoft.com/v1.0

=head1 auth

   my $token = $ua->auth;             #For app credentiales            
   my $token = $ua->auth($challenge); #For delegated authentication

This method performs the authentication handshake sequence with the MS
Graph platform. The optional parameter is the authorization code obtained
from a challenge with the impersonated user. If this is an application 
non-delegated client, then the $challenge is not needed.

The challenge code is not kept, but the token is. The token is saved for future requests. 
This method returns the token obtained.

If used in a web application, you should have redirected the user to the authendpoint() location
and then capture the resulting code listening for the redirect_uri.

A special tweak is supplied for console applications with delegated authentication. In that case,
if the code is missing, an http localhost miniserver is launched so the
user can trigger the challenge himself. This behavior is activated via the console constructor option.
The http miniserver is destroyed as soon as the authorization code arrives.
In this case, the redirect_uri is automatically set. The miniserver listens by default on http://localhost:8081. 
Please note that MS Graph allows
the use of localhost in the redirect_uri and in that case SSL is not enforced. But still the
localhost URL must be registered in Azure.

=head1 request

   my $object=$ua->request(GET => '/me');
   $ua->request(PATCH => '/me', {officeLocation => $mynewoffice});

The request method makes a call to a MS Graph endpoint url and returns the
corresponding response object as a perl structure. An optional perl structure might be
supplied as the payload (body) for the request.

The MS Graph has a rich set of API calls for different operations. Check the
EXAMPLES section for more tips.

You should call request() only after a successful auth() call. If a refresh_token
is issued by MS Graph, then request() will handle the token refresh transparently.

=head1 get

   my $me=$ua->get('/me');
   print "Hello $me->{displayName}";

Issues a GET request to the MS Graph endpoint and returns the response as a perl structure.

=head1 post

   my $folder=$ua->post('/me/drive/root/children', {name => 'newfolder', folder => {}});

Issues a POST request to the MS Graph endpoint and returns the response as a perl structure.
The second parameter is the payload for the POST request, as a perl reference.


=head1 code

   print "It worked" if ($ua->code == 201);

A code() method is supplied as a convenient way of getting the last HTTP response
code. This mitht be important, since the original HTTP::Respone is lost in the
normal operations. You may check L<HTTP::Status> for the meaning and further
processing of the codes.  

=head1 next

   $more=$ua->next();

The next() method will request additional response content after a previous
request if a pagination result set happens.

=head1 authendpoint

   $location=$ua->authendpoint()

Returns the authentication endpoint as an url string, full with the query part. In a delegated
authentication mode, you should point the user to this url via a browser in order to get the proper
authorization. This is on offline method, the resulting uri is computed from the constructor options

=head1 tokenendpoint

   $location=$ua->tokenendpoint()

Returns the oauth 2.0 token endpoint as an url string. This url is used internally to get
the authentication token. This is an offline method.

=head1 It's not persistance, it's no cookie. It's Session data

MS Graph implements an OAuth 2.0 authentication scheme. This means that the application asks
for an authentication token first and then uses this token for further requests. If you are
building a backend application that offers several services, this means that you must keep the token between runs.
In a backend for a web application, in theory the token could be kept in the browser local storage, but that's
not the approach of LWP::UserAgent::msgraph.

The approach is to store the token under the backend application realm. This is done by the persistent
option.

=head2 sid

   $sid=$ua->sid();

Returns the session id. This is a random UUID by default. This is used as a key for the session data. If you are building
a backend application, you may send this back to the client side in order to keep the session data between runs.
Once the sid is created, you can use it in further calls.

   my $sid=<something from the client side>;
   my $ua=LWP::UserAgent->new(sid => $sid, persistent => 1);

By default, UUID based sid are provided. You can use your own sid scheme, but you must ensure that it's unique.   

=head2 store

   my $sid=<something from the client side>
   my $ua=LWP::UserAgent->new(sid => $sid, persistent => 1, store => "some clever app data location/$sid");

The store option is used to set the filename for the session data. This is a Storable file. If the store option is not
set, a temporary file is used. The store option is used in conjunction with the persistent option. The OAuth token
is kept in this store. The Application's shared secret is not.

=head1 Changes from the default LWP::UserAgent behavior

This class inherits from L<LWP::UserAgent>, but some changes apply. If you are used to
LWP::UserAgent standard tweaks and shortcuts, you should read this.

The request() method accepts a perl structure which will be sent 
as a JSON body to the MS Graph endoint. Instead of an L<HTTP::Response>
object, request() will return whatever object is returned by the
MS Graph method, as a perl structure. The L<JSON> module is used as
a serialization engine. The HTTP::Response object is not kept. 
The code() method is provided to check the HTTP response code.

request() will use the right Authorization header based on the initial handshake.
The get(), post(), patch(), delete(), put(), delete() methods are setup so
they call the LWP::UserAgent::msgraph version of request(). That is, they would
return a perl structure according to the MS Graph method. 
In particular, post() and patch() accepts a perl structure
as the body. All the binding with the L<HTTP::Request::Common> module has been broken.

The simple_request() method is kept unchanged, but will use the
right Bearer token authentication. So, if you need more control over the request, you can use
this method. You must add the JSON serialization, though.

Also note that in d LWP, an URL starting with a '/' is considered a root-relative URL. In LWP::UserAgent::msgraph,
it's considered relative to the base URL. This is a convenience for MS Graph calls, since MS Graph documentation
often uses this convention. simple_request() retains the original root-relative behavior. This is why $ua->get('/me') works.

=head1 Requirements

This module requires the following modules:

=over

=item L<LWP::UserAgent> for all the base HTTP operations.

=item L<JSON> for the JSON serialization/deserialization.

=item L<Storable> for the session data storage.

=item L<Data::UUID> for the session id generation.

=item L<HTTP::Server::Simple::CGI> and L<Net::EmptyPort> for the http localhost miniserver feature

=item L<HTTP::Request::Common> is used for the handshake, since it's still multipart/form-data based

=back


=head1 TO-DO

This module is a work in progress. The following features are planned:

=over 

=item Certificate based authentication

=item Allow for a custom storable mechanism, so the session data can be kept in a database or in an encrypted form

=item Provide useful samples for the most common MS Graph operations

=back

=cut
