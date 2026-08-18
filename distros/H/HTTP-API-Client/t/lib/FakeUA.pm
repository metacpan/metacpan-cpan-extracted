package FakeUA;

use strict;
use warnings;
use HTTP::Response;
use HTTP::Request;

sub new { bless { code => $_[1], calls => 0 }, $_[0] }
sub agent {}
sub timeout {}

sub request {
    my ($self) = @_;
    $self->{calls}++;
    my $r = HTTP::Response->new($self->{code});
    $r->request(HTTP::Request->new(GET => "http://x/"));
    return $r;
}

1;
