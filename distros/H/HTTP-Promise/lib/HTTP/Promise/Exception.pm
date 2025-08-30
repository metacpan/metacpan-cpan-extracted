##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Exception.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/03/25
## Modified 2022/03/25
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Exception;
BEGIN
{
    use strict;
    use warnings;
    use parent qw( Module::Generic::Exception );
    our $VERSION = 'v0.1.0';
};

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Exception - HTTP Exception

=head1 SYNOPSIS

    use HTTP::Promise::Exception;
    my $this = HTTP::Promise::Exception->new( $error_message ) || 
        die( HTTP::Promise::Exception->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

This class inherits all its methods from L<Module::Generic::Exception>

=head1 METHODS

Plese see L<Module::Generic::Exception> for details.

=head1 THREAD SAFETY

This module is thread-safe.

It inherits from L<Module::Generic::Exception>, and each instance of L<Module::Generic::Exception> is self-contained and immutable once created and does not share any mutable state across threads.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Module::Generic::Exception>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
