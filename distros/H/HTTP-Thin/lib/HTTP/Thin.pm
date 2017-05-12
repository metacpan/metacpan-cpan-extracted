package HTTP::Thin;
$HTTP::Thin::VERSION = '0.006';
use warnings;

#ABSTRACT: A Thin Wrapper around HTTP::Tiny to play nice with HTTP::Message

use parent qw(HTTP::Tiny);
use Safe::Isa;
use Class::Method::Modifiers;
use HTTP::Response;
use Hash::MultiValue;



around request => sub {
        my ($next, $self, @args) = @_;
        if (@args == 1 && $args[0]->$_isa('HTTP::Request')) {
                my $req = shift @args;
                my @headers;
                $req->headers->scan(sub { push @headers, @_ });
                        
                my $options = {};
                $options->{headers} = Hash::MultiValue->new(@headers)->mixed if @headers;
                $options->{content} = $req->content if length($req->content);
                @args = ( 
                        $req->method,
                        $req->uri,
                        ( keys %$options ? $options : () ),
                );
        }
        my $res =  $self->$next(@args);
        return HTTP::Response->new(
                $res->{status},
                $res->{reason},
                [ Hash::MultiValue->from_mixed($res->{headers})->flatten ],
                $res->{content},
        );
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Thin - A Thin Wrapper around HTTP::Tiny to play nice with HTTP::Message

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use 5.12.1;
    use HTTP::Request::Common;
    use HTTP::Thin;

    say HTTP::Thin->new()->request(GET 'http://example.com')->as_string;

=head1 DESCRIPTION

WARNING: This module is untested beyond the very basics. The implementation is simple enough that it shouldn't do evil things but, yeah it's still not approved for use by small children.

C<HTTP::Thin> is a thin wrapper around L<HTTP::Tiny> adding the ability to pass in L<HTTP::Request> objects and get back L<HTTP::Response> objects. The maintainers of L<HTTP::Tiny>, justifiably, don't want to have to maintain compatibility but many other projects already consume the L<HTTP::Message> objects. This is just glue code doing what it does best.

=head1 METHODS

=head2 request

In addition to the parameters documented in L<HTTP::Tiny>, C<HTTP::Thin> takes L<HTTP::Request> objects as well. 

The return value is an L<HTTP::Response> object.

=head1 WHY?

A conversation on IRC lead to C<mst>, C<ether>, and I agreeing that this would be a useful module but probably not worth the effort. I wrote it anyway to get it out of my head. 

=head1 AUTHOR

Chris Prather <chris@prather.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Chris Prather.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

=over 4

=item *

Aran Deltac <aran@ziprecruiter.com>

=item *

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

=back

=cut
