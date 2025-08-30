##----------------------------------------------------------------------------
## Asynchronous HTTP Request and Promise - ~/lib/HTTP/Promise/Headers/ContentSecurityPolicy.pm
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
package HTTP::Promise::Headers::ContentSecurityPolicy;
BEGIN
{
    use strict;
    use warnings;
    warnings::register_categories( 'HTTP::Promise' );
    use parent qw( HTTP::Promise::Headers::Generic );
    our $VERSION = 'v0.1.0';
};

use strict;
use warnings;

sub init
{
    my $self = shift( @_ );
    $self->{params} = [];
    $self->{properties} = {};
    @_ = () if( @_ == 1 && $self->_is_a( $_[0] => 'Module::Generic::Null' ) );
    if( @_ )
    {
        my $this = shift( @_ );
        my $ref = $self->_is_array( $this ) ? $this : [split( /(?<!\\)[[:blank:]\h]*\;[[:blank:]\h]*/, $this )];
        my $params = $self->params;
        my $props = $self->properties;
        foreach my $pair ( @$ref )
        {
            my( $prop, $val ) = split( /[[:blank:]\h]+/, $pair, 2 );
            $props->{ $prop } = $val;
            $params->push( $prop );
        }
    }
    $self->{_init_strict_use_sub} = 1;
    $self->SUPER::init( @_ ) || return( $self->pass_error );
    $self->_field_name( 'Content-Security-Policy' );
    return( $self );
}

sub as_string { return( shift->_set_get_properties_as_string( sep => ';', equal => ' ' ) ); }

sub base_uri { return( shift->_set_get_property_value( 'base-uri', @_ ) ); }

sub block_all_mixed_content { return( shift->_set_get_property_boolean( 'block-all-mixed-content', @_ ) ); }

sub child_src { return( shift->_set_get_property_value( 'child-src', @_ ) ); }

sub connect_src { return( shift->_set_get_property_value( 'connect-src', @_ ) ); }

sub default_src { return( shift->_set_get_property_value( 'default-src', @_ ) ); }

sub font_src { return( shift->_set_get_property_value( 'font-src', @_ ) ); }

sub form_action { return( shift->_set_get_property_value( 'form-action', @_ ) ); }

sub frame_ancestors { return( shift->_set_get_property_value( 'frame-ancestors', @_ ) ); }

sub frame_src { return( shift->_set_get_property_value( 'frame-src', @_ ) ); }

sub img_src { return( shift->_set_get_property_value( 'img-src', @_ ) ); }

sub manifest_src { return( shift->_set_get_property_value( 'manifest-src', @_ ) ); }

sub media_src { return( shift->_set_get_property_value( 'media-src', @_ ) ); }

sub navigate_to { return( shift->_set_get_property_value( 'navigate-to', @_ ) ); }

sub params { return( shift->_set_get_array_as_object( 'params', @_ ) ); }

sub properties { return( shift->_set_get_hash_as_mix_object( 'properties', @_ ) ); }

sub object_src { return( shift->_set_get_property_value( 'object-src', @_ ) ); }

sub plugin_types { return( shift->_set_get_property_value( 'plugin-types', @_ ) ); }

sub prefetch_src { return( shift->_set_get_property_value( 'prefetch-src', @_ ) ); }

sub referrer { return( shift->_set_get_property_value( 'referrer', @_ ) ); }

sub report_to { return( shift->_set_get_property_value( 'report-to', @_ ) ); }

sub report_uri { return( shift->_set_get_property_value( 'report-uri', @_ ) ); }

sub require_sri_for { return( shift->_set_get_property_value( 'require-sri-for', @_ ) ); }

sub require_trusted_types_for { return( shift->_set_get_property_value( 'require-trusted-types-for', @_ ) ); }

sub sandbox { return( shift->_set_get_property_value( 'sandbox', @_, { maybe_boolean => 1 } ) ); }

sub script_src { return( shift->_set_get_property_value( 'script-src', @_ ) ); }

sub script_src_elem { return( shift->_set_get_property_value( 'script-src-elem', @_ ) ); }

sub script_src_attr { return( shift->_set_get_property_value( 'script-src-attr', @_ ) ); }

sub style_src { return( shift->_set_get_property_value( 'style-src', @_ ) ); }

sub style_src_attr { return( shift->_set_get_property_value( 'style-src-attr', @_ ) ); }

sub style_src_elem { return( shift->_set_get_property_value( 'style-src-elem', @_ ) ); }

sub trusted_types { return( shift->_set_get_property_value( 'trusted-types', @_, { maybe_boolean => 1 } ) ); }

sub upgrade_insecure_requests { return( shift->_set_get_property_boolean( 'upgrade-insecure-requests', @_ ) ); }

sub worker_src { return( shift->_set_get_property_value( 'worker-src', @_ ) ); }

1;
# NOTE: POD
__END__

=encoding utf-8

=head1 NAME

HTTP::Promise::Headers::ContentSecurityPolicy - Content-Security-Policy Header Field

=head1 SYNOPSIS

    use HTTP::Promise::Headers::ContentSecurityPolicy;
    my $csp = HTTP::Promise::Headers::ContentSecurityPolicy->new || 
        die( HTTP::Promise::Headers::ContentSecurityPolicy->error, "\n" );

=head1 VERSION

    v0.1.0

=head1 DESCRIPTION

The following description is taken from Mozilla documentation.

The HTTP Content-Security-Policy response header allows web site administrators to control resources the user agent is allowed to load for a given page. With a few exceptions, policies mostly involve specifying server origins and script endpoints. This helps guard against cross-site scripting attacks (Cross-site_scripting). 

    Content-Security-Policy: default-src 'self'
    Content-Security-Policy: default-src 'self' trusted.com *.trusted.com
    Content-Security-Policy: default-src 'self'; img-src *; media-src media1.com media2.com; script-src userscripts.example.com
    Content-Security-Policy: default-src https://onlinebanking.example.com
    Content-Security-Policy: default-src 'self'; report-uri http://reportcollector.example.com/collector.cgi

=head1 METHODS

All the methods below follow the same usage. You can pass a value to set it, whatever it is. It is up to you to proceed and set a value according to standards. The value will be added in order. To completely remove a property, simply pass C<undef> as a value. If nothing is provided, the current value is returned, or an empty string, but not C<undef>, if nothing is set yet.

If you want to modify a value, you probably want to first fetch it, and set it back, unless you already what it should contain.

    $h->default_src( "'self'" ); # now: default-src 'self'
    $h->default_src( "'self' trusted.com *.trusted.com ); # now: default-src 'self' trusted.com *.trusted.com
    my $value = $h->default_src;
    # Remove it
    $h->default_src( undef );

You can get all the properties set by calling L</params>, which returns an L<array object|Module::Generic::Array>

=head2 as_string

Returns a string representation of this header field value.

=head2 base_uri

Restricts the URLs which can be used in a document's <base> element.

Example:

    Content-Security-Policy: base-uri https://example.com/
    Content-Security-Policy: base-uri https://example.com/ https://dev.example.com/

=head2 block_all_mixed_content

You can still use this, but know its use is deprecated.

Prevents loading any assets using HTTP when the page is loaded using HTTPS.

Example:

    Content-Security-Policy: block-all-mixed-content;

=head2 child_src

Defines the valid sources for web workers and nested browsing contexts loaded using elements such as <frame> and <iframe>. 

Example:

    Content-Security-Policy: child-src https://example.com/
    Content-Security-Policy: child-src https://example.com/ https://dev.example.com/

=head2 connect_src

Restricts the URLs which can be loaded using script interfaces.

Example:

    Content-Security-Policy: connect-src https://example.com/

=head2 default_src

Serves as a fallback for the other fetch directives.

Example:

    Content-Security-Policy: default-src 'self'

=head2 font_src

Specifies valid sources for fonts loaded using @font-face.

Example:

    Content-Security-Policy: font-src https://example.com/

=head2 form_action

Restricts the URLs which can be used as the target of a form submissions from a given context.

Example:

    Content-Security-Policy: form-action https://example.com/;
    Content-Security-Policy: form-action https://example.com/ https://dev.example.com/;

=head2 frame_ancestors

Specifies valid parents that may embed a page using C<frame>, C<iframe>, C<object>, C<embed>, or C<applet>.

Example:

    Content-Security-Policy: frame-ancestors https://example.com/;
    Content-Security-Policy: frame-ancestors https://example.com/ https://dev.example.com/;

=head2 frame_src

Specifies valid sources for nested browsing contexts loading using elements such as <frame> and <iframe>.

Example:

    Content-Security-Policy: frame-src https://example.com/

=head2 img_src

Specifies valid sources of images and favicons.

Example:

    Content-Security-Policy: img-src https://example.com/
    Content-Security-Policy: img-src 'self' img.example.com;

=head2 manifest_src

Specifies valid sources of application manifest files.

Example:

    Content-Security-Policy: manifest-src https://example.com/

=head2 media_src

Specifies valid sources for loading media using the C<audio> , C<video> and C<track> elements.

Example:

    Content-Security-Policy: media-src https://example.com/

=head2 navigate_to

Restricts the URLs to which a document can initiate navigation by any means, including <form> (if form-action is not specified), <a>, window.location, window.open, etc.

Example:

    Content-Security-Policy: navigate-to https://example.com/;
    Content-Security-Policy: navigate-to https://example.com/ https://dev.example.com/;

=head2 object_src

Specifies valid sources for the C<object>, C<embed>, and C<applet> elements.

Example:

    Content-Security-Policy: object-src https://example.com/

=head2 params

Returns the L<array object|Module::Generic::Array> used by this header field object containing all the properties set.

=head2 plugin_types

You can still use this, but know its use is deprecated.

Restricts the set of plugins that can be embedded into a document by limiting the types of resources which can be loaded.

Example:

    Content-Security-Policy: plugin-types application/x-shockwave-flash

=head2 prefetch_src

Specifies valid sources to be prefetched or prerendered.

Example:

    Content-Security-Policy: prefetch-src https://example.com/

=head2 properties

Sets or gets an hash or hash reference ot property-value pairs.

=head2 referrer

You can still use this, but know its use is deprecated and it is non-standard.

Used to specify information in the Referer (sic) header for links away from a page. Use the C<Referrer-Policy> header instead.

Example:

    Content-Security-Policy: referrer "none";

You can set whatever value you want, but know that, according to rfc, the standard possible values are:

=over 4

=item C<no-referrer>

The Referer header will be omitted entirely. No referrer information is sent along with requests.

=item C<none-when-downgrade>

This is the user agent's default behavior if no policy is specified. The origin is sent as referrer to a-priori as-much-secure destination (HTTPS->HTTPS), but is not sent to a less secure destination (HTTPS->HTTP).

=item C<origin>

Only send the origin of the document as the referrer in all cases. The document https://example.com/page.html will send the referrer https://example.com/.

=item C<origin-when-cross-origin> / C<origin-when-crossorigin>

Send a full URL when performing a same-origin request, but only send the origin of the document for other cases.

=item C<unsafe-url>

Send a full URL (stripped from parameters) when performing a same-origin or cross-origin request. This policy will leak origins and paths from TLS-protected resources to insecure origins. Carefully consider the impact of this setting.

=back

=head2 report_to

Fires a SecurityPolicyViolationEvent.

Example:

    Report-To: { "group": "csp-endpoint",
                  "max_age": 10886400,
                  "endpoints": [
                    { "url": "https://example.com/csp-reports" }
                  ] },
                { "group": "hpkp-endpoint",
                  "max_age": 10886400,
                  "endpoints": [
                    { "url": "https://example.com/hpkp-reports" }
                  ] }
    Content-Security-Policy: ...; report-to csp-endpoint

=head2 report_uri

Instructs the user agent to report attempts to violate the Content Security Policy. These violation reports consist of JSON documents sent via an HTTP POST request to the specified URI. 

Example:

    Content-Security-Policy: default-src https:; report-uri /csp-violation-report-endpoint/
    Content-Security-Policy: default-src https:; report-uri /csp-violation-report-endpoint/ https://dev.example.com/report;

=head2 require_sri_for

Requires the use of SRI for scripts or styles on the page.

Example:

    Content-Security-Policy: require-sri-for script;
    Content-Security-Policy: require-sri-for style;
    Content-Security-Policy: require-sri-for script style;

=head2 require_trusted_types_for

Enforces Trusted Types at the DOM XSS injection sinks.

Example:

    Content-Security-Policy: require-trusted-types-for 'script';

=head2 sandbox

Enables a sandbox for the requested resource similar to the C<iframe> sandbox attribute.

This can be set as a boolean or with a string value:

    # This will add 'sandbox' (without surrounding quotes) as a property
    $h->sandbox(1);
    # Returns true.
    my $rv = $h->sandbox;
    $h->sandbox(0);
    # Returns false.
    my $rv = $h->sandbox;
    # Removes it
    $h->sandbox( undef );
    # Will set sandbox to 'allow-downloads' (without surrounding quotes)
    $h->sandbox( 'allow-downloads' );

It takes an optional value, such as:

=over 4

=item C<allow-downloads>

Allows for downloads after the user clicks a button or link.

=item C<allow-downloads-without-user-activation>

This is reportedly an experimental value.

Allows for downloads to occur without a gesture from the user.

=item C<allow-forms>

Allows the page to submit forms. If this keyword is not used, this operation is not allowed.

=item C<allow-modals>

Allows the page to open modal windows.

=item C<allow-orientation-lock>

Allows the page to disable the ability to lock the screen orientation.

=item C<allow-pointer-lock>

Allows the page to use the Pointer Lock API.

=item C<allow-popups>

Allows popups (like from window.open, target="_blank", showModalDialog). If this keyword is not used, that functionality will silently fail.

=item C<allow-popups-to-escape-sandbox>

Allows a sandboxed document to open new windows without forcing the sandboxing flags upon them. This will allow, for example, a third-party advertisement to be safely sandboxed without forcing the same restrictions upon the page the ad links to.

=item C<allow-presentation>

Allows embedders to have control over whether an iframe can start a presentation session.

=item C<allow-same-origin>

Allows the content to be treated as being from its normal origin. If this keyword is not used, the embedded content is treated as being from a unique origin.

=item C<allow-scripts>

Allows the page to run scripts (but not create pop-up windows). If this keyword is not used, this operation is not allowed.

=item C<allow-storage-access-by-user-activation>

This is reportedly an experimental value.

Lets the resource request access to the parent's storage capabilities with the Storage Access API.

=item C<allow-top-navigation>

Allows the page to navigate (load) content to the top-level browsing context. If this keyword is not used, this operation is not allowed.

=item C<allow-top-navigation-by-user-activation>

Lets the resource navigate the top-level browsing context, but only if initiated by a user gesture.

=back

Example:

    Content-Security-Policy: sandbox;
    Content-Security-Policy: sandbox allow-scripts;

=head2 script_src

Specifies valid sources for JavaScript.

Example:

    Content-Security-Policy: script-src https://example.com/
    Content-Security-Policy: script-src 'self' js.example.com;

=head2 script_src_elem

Specifies valid sources for JavaScript <script> elements.

Example:

    Content-Security-Policy: script-src-elem https://example.com/
    Content-Security-Policy: script-src-elem https://example.com/ https://dev.example.com/

=head2 script_src_attr

Specifies valid sources for JavaScript inline event handlers.

Example:

    Content-Security-Policy: script-src-attr https://example.com/
    Content-Security-Policy: script-src-attr https://example.com/ https://dev.example.com/

=head2 style_src

Specifies valid sources for stylesheets.

Example:

    Content-Security-Policy: style-src https://example.com/
    Content-Security-Policy: style-src https://example.com/ https://dev.example.com/
    Content-Security-Policy: style-src 'self' css.example.com;

=head2 style_src_attr

Specifies valid sources for inline styles applied to individual DOM elements.

Example:

    Content-Security-Policy: style-src-attr https://example.com/
    Content-Security-Policy: style-src-attr https://example.com/ https://dev.example.com/

=head2 style_src_elem

Specifies valid sources for stylesheets <style> elements and <link> elements with rel="stylesheet".

Example:

    Content-Security-Policy: script-src-elem https://example.com/
    Content-Security-Policy: script-src-elem https://example.com/ https://dev.example.com/

=head2 trusted_types

Used to specify an allow-list of Trusted Types policies. Trusted Types allows applications to lock down DOM XSS injection sinks to only accept non-spoofable, typed values in place of strings.

Just like L</sandbox>, this can be set as a boolean or with a string value.

Example:

    # Set it as a boolean value
    $h->trusted_types(1);
    Content-Security-Policy: trusted-types;
    # Set it as a string value
    # You need to set the surrounding single quotes yourself
    $h->trusted_types( "'none'" );
    Content-Security-Policy: trusted-types 'none';
    # Set it to foo
    $h->trusted_types( 'foo' );
    Content-Security-Policy: trusted-types foo;
    Content-Security-Policy: trusted-types foo bar 'allow-duplicates';

=head2 upgrade_insecure_requests

Instructs user agents to treat all of a site's insecure URLs (those served over HTTP) as though they have been replaced with secure URLs (those served over HTTPS). This directive is intended for web sites with large numbers of insecure legacy URLs that need to be rewritten.

Example:

    Content-Security-Policy: upgrade-insecure-requests;

=head2 worker_src

Specifies valid sources for Worker, SharedWorker, or ServiceWorker scripts.

Example:

    Content-Security-Policy: worker-src https://example.com/
    Content-Security-Policy: worker-src https://example.com/ https://dev.example.com/

=head1 THREAD-SAFETY

This module is thread-safe for all operations, as it operates on per-object state and uses thread-safe external libraries.

=head1 AUTHOR

Jacques Deguest E<lt>F<jack@deguest.jp>E<gt>

=head1 SEE ALSO

L<Mozilla documentation|https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Security-Policy> and L<Mozilla on CSP|https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP>

L<https://content-security-policy.com/>

L<HTTP::Promise>, L<HTTP::Promise::Request>, L<HTTP::Promise::Response>, L<HTTP::Promise::Message>, L<HTTP::Promise::Entity>, L<HTTP::Promise::Headers>, L<HTTP::Promise::Body>, L<HTTP::Promise::Body::Form>, L<HTTP::Promise::Body::Form::Data>, L<HTTP::Promise::Body::Form::Field>, L<HTTP::Promise::Status>, L<HTTP::Promise::MIME>, L<HTTP::Promise::Parser>, L<HTTP::Promise::IO>, L<HTTP::Promise::Stream>, L<HTTP::Promise::Exception>

=head1 COPYRIGHT & LICENSE

Copyright(c) 2022 DEGUEST Pte. Ltd.

All rights reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
