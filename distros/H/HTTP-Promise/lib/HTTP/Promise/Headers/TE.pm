##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/TE.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/05/08
## Modified 2022/05/08
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Headers::TE;
BEGIN
{
    use strict;
    use warnings;
    use warnings::register;
    use parent qw( HTTP::Promise::Headers::Accept );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'TE' );
    return( $self );
}

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::TE - TE Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::TE;
    my $te = HTTP::Promise::Headers::TE->new || 
        die( HTTP::Promise::Headers::TE->error, "\n" );
    my $e = $te->add( 'gzip' );
    # Set deflate with a weight of 0.5
    my $e1 = $te->add( 'deflate' => 0.5 );
    my $e2 = $te->get( $e1 );
    # $e1 and $e2 are the same
    my $e2 = $te->get( 'deflate' );
    say $e2->value; # 0.5
    $e2->value(0.7); # Change it to 0.7
    say "$te";
    # gzip, deflate;q=0.7

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class inherits all its features from L<HTTP::Promise::Headers::Accept>

The following description is taken from Mozilla documentation.

Example:

    TE: deflate
    TE: gzip
    TE: trailers

    # Multiple directives, weighted with the quality value syntax:
    TE: trailers, deflate;q=0.5

=head1 METHODS

See L<HTTP::Promise::Headers::Accept>

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

See also L<rfc7230, section 4.3|https://tools.ietf.org/html/rfc7230#section-4.3> and L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/TE>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
