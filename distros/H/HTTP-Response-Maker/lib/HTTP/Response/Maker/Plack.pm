package HTTP::Response::Maker::Plack;
use strict;
use warnings;
use parent 'HTTP::Response::Maker::Base';
use Class::Load qw(load_class);

sub _make_response {
    my ($class, $code, $message, $headers, $content, $option) = @_;
    my $response_class = $option->{class} || 'Plack::Response';
    load_class $response_class;
    return $response_class->new($code, $headers, $content);
}

1;

__END__

=head1 NAME

HTTP::Response::Maker::Plack - HTTP::Response::Maker implementation for Plack

=head1 DESCRIPTION

This module provides functions to make an L<Plack::Response>.

=head1 IMPORT OPTIONS

=over 4

=item class => I<$classname>

Use I<$classname> instead of Plack::Response.

=cut
