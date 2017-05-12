package HTTP::Response::Maker::PSGI;
use strict;
use warnings;
use parent 'HTTP::Response::Maker::Base';

sub _make_response {
    my ($class, $code, $message, $headers, $content) = @_;
    return [ $code, $headers, [ $content ] ];
}

1;

__END__

=head1 NAME

HTTP::Response::Maker::PSGI - HTTP::Response::Maker implementation for PSGI

=head1 DESCRIPTION

This module provides functions to make an L<PSGI>-response ARRAY.

=cut
