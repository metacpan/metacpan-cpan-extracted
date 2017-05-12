package HTTP::Response::Maker::Exception;
use strict;
use warnings;
use parent 'HTTP::Response::Maker::Base';
use HTTP::Exception;
use HTTP::Status;

sub _make_response {
    my ($class, $code, $message, $headers, $content) = @_;

    my %args;
    if (is_redirect($code)) {
        my %h = @$headers;
        foreach my $key (keys %h) {
            if (lc $key eq 'location') {
                $args{location} = $h{$key};
            }
        }
    }

    HTTP::Exception->throw($code, %args);
}

1;

__END__

=head1 NAME

HTTP::Response::Maker::Exception - HTTP::Response::Maker implementation for HTTP::Exception

=head1 DESCRIPTION

This module provides functions to throw an L<HTTP::Exception>.

=cut
