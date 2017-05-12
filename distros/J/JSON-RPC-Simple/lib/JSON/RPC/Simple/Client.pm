package JSON::RPC::Simple::Client;

use strict;
use warnings;

use Carp qw(croak);
use LWP::UserAgent;
use JSON qw();
use URI::Escape qw();

require JSON::RPC::Simple;

use constant DEFAULT_TIMEOUT => 180;
use constant JSON_RPC_HTTP_HEADERS => (
    Content_Type        => "application/json; charset=UTF-8",
    Accept              => 'application/json',
);

sub new {
    my ($pkg, $uri, $attrs) = @_;
    
    $attrs = {} unless ref $attrs eq "HASH";
    
    my $agent = delete $attrs->{agent} || "JSON::RPC::Simple " . 
                                          JSON::RPC::Simple->VERSION;
                                        
    my $ua = LWP::UserAgent->new(
        agent   => $agent,
        timeout => (
            exists $attrs->{timeout} ? 
                delete $attrs->{timeout} : 
                DEFAULT_TIMEOUT
        ),
    );
    
    my $get = $attrs->{GET};

    # Since the last component in GET call is the method name make sure we have a separator
    $uri .= "/" if $get && substr($uri, -1, 1) ne '/';
    
    my $self = bless {
        json => JSON->new->utf8,
        %$attrs,
        ua  => $ua,
        uri => $uri,
        GET => $get,
    }, $pkg;

    return $self;
}

sub DESTROY {
    # or AUTOLOAD will pick this up
}

my $next_request_id = 0;

our $AUTOLOAD;
sub AUTOLOAD {
    my ($self, $params) = @_;

    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    
    my $id = ++$next_request_id;
    
    my $r;

    my $sent = '';
    unless ($self->{GET}) {
        my $content = $self->{json}->encode({
            version => "1.1",
            method  => $method,
            params  => $params,
            id      => $id,
        });
        $sent = $content;

        $r = $self->{ua}->post(
            $self->{uri},
            JSON_RPC_HTTP_HEADERS,
            Content => $content,
        );
    }
    else {
        croak "GET only supports named parameters" if $params && ref $params ne 'HASH';
        $params = {} unless $params;
            
        my $params = join "&", map { "$_=" . URI::Escape::uri_escape_utf8($params->{$_}) } keys %$params;

        my $request_uri = $self->{uri} . $method . '?' . ${params};
    
        $r = $self->{ua}->get(
            $request_uri,
            JSON_RPC_HTTP_HEADERS,            
        );
    }
    
    if ($r->is_success) {
        if ($r->content_type !~ /application\/json/) {
            croak("Bad response. Response was not type 'application/json'\n\nResponse:\n" . $r->decoded_content);
        }
    }
    else {
        croak $r->decoded_content unless $r->content_type =~ m{^application/json};        
    }
  
    my $result;
    eval {
        my $content = $r->decoded_content;

        if ($self->{debug}) {
            print STDERR "RPC-Server: " . $self->{uri} . "\n\n";
            print STDERR "Sent: $sent\n";
            print STDERR "Recv: " . $r->decoded_content . "\n";
            print STDERR "\n";
        }

        $result = $self->{json}->decode($r->decoded_content);
    };
    croak $@ if $@;
    croak "Didn't get a JSON object back" unless ref $result eq "HASH";
    croak $result->{error}->{message} if $result->{error};

    return $result->{result};
}

1;
__END__

=head1 NAME

JSON::RPC::Simple::Client - JSON-RPC 1.1 WD client

=head1 SYNOPSIS

  use JSON::RPC::Simple::Client;
  
  my $c = JSON::RPC::Simple::Client->new("https://www.example.com/json-rpc");
  
  my $results = $c->echo("foo");
  
=head1 USAGE

This class uses an AUTOLOAD subroutine so that any method calls are sent to 
the target JSON-RPC service.

To create a new client either use the C<new> method in directly or via the 
helper function C<JSON::RPC::Simple->connect>.

=over 4

=item new (URL)

=item new (URL, \%OPTIONS) 

Creates a new client whos endpoint is given in I<URL>.

Valid options:

=over 4

=item GET

Set this to a true value to do calls via HTTP GET instead of POST as some services 
apparently think this is a good idea.

=item agent

What to send as HTTP User-Agent, defaults to "JSON::RPC::Simple <version>" 
where version is the current version number of the JSON::RPC::Simple package.

=item timeout

Timeout for how long the call may take. Is passed to LWP::UserAgent which is 
used to make the request by default. Defaults to 180 sec

=item json

The JSON encoder/decoder to use. Defaults to JSON->new->utf8. The supplied 
object/class must respond to C<encode> and C<decode>.

=item debug

Turn on debugging which prints to STDERR.

=back

=back

=head1 Using another transporter than LWP::UserAgent

By default this class uses LWP::UserAgent. If you wish to use something else 
such as for example WWW::Curl simply replace the C<ua> member of the instance 
with something that provides a LWP::UserAgent compatible API for C<post>. The 
returned object from the C<post> method is expected to provide C<is_success>, 
C<decoded_content> and C<content_type>.

=pod
