package TestServer;
use base qw( HTTP::Server::Simple::CGI );
use strict;
use warnings;
use 5.010;

use Carp;
use Data::Dumper::Concise;
use JSON;

# load some TestServer::Plugin modules
use TestServer::IssueTypes;
use TestServer::Projects;
use TestServer::Misc;

# register one dispatch method in this module
TestServer::Plugin->register_dispatch(
    '/quit' => sub { quit(@_) },
);


sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    return $self;
}

sub print_banner {
    my $self = shift;
    my $class = ref $self;
    say "# [pid $$] $class: running on http://localhost:" . $self->port;
}

sub valid_http_method {
    my $self = shift;
    my $method = shift or return 0;
    return $method =~ /^(?:GET|POST|PUT|DELETE)$/; # not handling others
}

sub handle_request {
    my ( $self, $cgi ) = @_;

    my $uri     = $cgi->request_uri || q{};
    my $path    = $cgi->path_info;
    my $method  = $cgi->request_method;
    my $request = $method eq 'GET' ? $path
                : join q{ }, $method, $path;

    my $handler = TestServer::Plugin->DISPATCH_TABLE->{$request};

    if (ref($handler) eq "CODE") {
        print "HTTP/1.0 200 OK\r\n";
        $handler->($self, $cgi);
    }
    else {
        my $response = "HTTP/1.0 404 NOT FOUND\r\n\n$method $path";
        print $response;
    }
}

sub quit {
    my ( $server, $cgi ) = @_;
    # tell the server it shouldn't process any more requests
    $TestServer::SERVER_SHOULD_RUN = 0;
    say "# stopping server on $$ due to /quit request";

    my $content  = JSON::encode_json({ quit => 'SUCCESS' });
    my $response = "Content-Type: application/json\r\n";
    $response   .= "Content-Length: ".length($content)."\r\n";
    $response   .= "\n$content";
    print $response;
    exit;
}

1;
