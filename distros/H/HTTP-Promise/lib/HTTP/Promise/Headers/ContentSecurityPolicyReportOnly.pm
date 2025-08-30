##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/ContentSecurityPolicyReportOnly.pm
## Version v0.1.0
## Copyright(c) 2022 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2022/05/07
## Modified 2022/05/07
## All rights reserved.
## 
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package HTTP::Promise::Headers::ContentSecurityPolicyReportOnly;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'HTTP::Promise' );
    use parent qw( HTTP::Promise::Headers::ContentSecurityPolicy );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Content-Security-Policy-Report-Only' );
    return( $self );
}

sub report_uri { return( shift->_set_get_property_value( 'report-uri', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::ContentSecurityPolicyReportOnly - Content-Security-Policy-Report-Only Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::ContentSecurityPolicyReportOnly;
    my $this = HTTP::Promise::Headers::ContentSecurityPolicyReportOnly->new || die( HTTP::Promise::Headers::ContentSecurityPolicyReportOnly->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The following description is taken from Mozilla documentation.

This class inherits all the method from L<HTTP::Promise::Headers::ContentSecurityPolicy> and implements the additional following ones.

The CSP L</report_uri> method should be used with this header, otherwise this class will be an expensive no-op interface.

    Content-Security-Policy-Report-Only: default-src https:; report-uri /csp-violation-report-endpoint/

=head1 METHODS

=head2 report_uri

This takes an uri where the report will be sent. See L<this Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/report-uri> for an example php script to use to get those reports.

=head1 THREAD-SAFETY

This module is thread-safe for all operations, as it operates on per-object state and uses thread-safe external libraries.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy-Report-Only> and also L<this documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy/report-uri>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
