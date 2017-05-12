package HTTPTest;
use base qw/HTTP::Server::Simple::CGI/;

my $answer;

sub answer{
    $answer = $_[1];
    print "\n$answer\n";
}

sub handle_request{
    my $self = shift;
    my $cgi  = shift;

    print "HTTP/1.0 200 OK\r\n";
    print $cgi->header, $answer;
}

sub setup { }

1;
