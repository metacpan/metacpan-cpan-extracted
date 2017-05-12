package HTTP::Response::Maker::HTTPResponse;
use strict;
use warnings;
use parent 'HTTP::Response::Maker::Base';
use HTTP::Response;

sub _make_response {
    my ($class, $code, $message, $headers, $content) = @_;
    return HTTP::Response->new($code, $message, $headers, $content);
}

1;

__END__

=head1 NAME

HTTP::Response::Maker::HTTPResponse - HTTP::Response::Maker implementation for HTTP::Response

=head1 DESCRIPTION

This module provides functions to make an L<HTTP::Response>.

=cut
