package Test::M3::ServerView::TestServer;

use strict;
use warnings;

use Carp qw(croak);
use File::Spec::Functions qw(canonpath catfile);
use MIME::Base64 qw(decode_base64);

use base qw(Test::HTTP::Server::Simple HTTP::Server::Simple::CGI);

sub new {
    my ($pkg, $authen) = @_;
    my $port = 16000 + int(rand(16000));
    my $self = $pkg->SUPER::new($port);
    $self->{tmst_authen} = $authen;
    return $self;
}

sub handle_request {
    my ($self, $cgi) = @_;

    if ($self->{tmst_authen}) {
        unless (exists $ENV{HTTP_AUTHORIZATION}) {
            print "HTTP/1.0 401 Unauthorized\r\n";
            return;
        }
        
        
        my ($auth) = $ENV{HTTP_AUTHORIZATION} =~ /^Basic (.*)$/;
        if (decode_base64($auth) ne $self->{tmst_authen}) {
            print "HTTP/1.0 401 Unauthorized\r\n";
            return;
        }
    }
    
    my $path = $ENV{PATH_INFO};
    $path = "/home" if $path eq "/";    
    $path .= ".html";
    
    unless ($path =~ m{/\w+\.html$}) {
        croak "Failed to get ${path}";
    }
    
    my $fp = canonpath(catfile("t", "data", $path));
    open(my $in, "<", $fp);
    my $content = do { local $/; <$in>; };
    close($in);
    print "HTTP/1.0 200 OK\r\n";
    print "X-EchoQuery: ", $ENV{QUERY_STRING}, "\r\n";
    print "Content-Type: text/html\r\nContent-length: ", length($content), "\r\n\r\n", $content;
    
    1;
}

1;