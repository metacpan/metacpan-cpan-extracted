# -*- perl -*-
# t/01.load.t - check module loading and create testing directory
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test2::V0;
};

# To build the list of modules:
# find ./lib -type f -name "*.pm" -print | xargs perl -lE 'my @f=sort(@ARGV); for(@f) { s,./lib/,,; s,\.pm$,,; s,/,::,g; substr( $_, 0, 0, q{use ok( ''} ); $_ .= q{'' );}; say $_; }'
BEGIN
{
    use ok( 'HTTP::Promise' );
    use ok( 'HTTP::Promise::Body' );
    use ok( 'HTTP::Promise::Body::Form' );
    use ok( 'HTTP::Promise::Body::Form::Data' );
    use ok( 'HTTP::Promise::Body::Form::Field' );
    use ok( 'HTTP::Promise::Entity' );
    use ok( 'HTTP::Promise::Exception' );
    use ok( 'HTTP::Promise::Headers' );
    use ok( 'HTTP::Promise::Headers::Accept' );
    use ok( 'HTTP::Promise::Headers::AcceptEncoding' );
    use ok( 'HTTP::Promise::Headers::AcceptLanguage' );
    use ok( 'HTTP::Promise::Headers::AltSvc' );
    use ok( 'HTTP::Promise::Headers::CacheControl' );
    use ok( 'HTTP::Promise::Headers::ClearSiteData' );
    use ok( 'HTTP::Promise::Headers::ContentDisposition' );
    use ok( 'HTTP::Promise::Headers::ContentRange' );
    use ok( 'HTTP::Promise::Headers::ContentSecurityPolicy' );
    use ok( 'HTTP::Promise::Headers::ContentSecurityPolicyReportOnly' );
    use ok( 'HTTP::Promise::Headers::ContentType' );
    use ok( 'HTTP::Promise::Headers::Cookie' );
    use ok( 'HTTP::Promise::Headers::ExpectCT' );
    use ok( 'HTTP::Promise::Headers::Forwarded' );
    use ok( 'HTTP::Promise::Headers::Generic' );
    use ok( 'HTTP::Promise::Headers::KeepAlive' );
    use ok( 'HTTP::Promise::Headers::Link' );
    use ok( 'HTTP::Promise::Headers::Range' );
    use ok( 'HTTP::Promise::Headers::ServerTiming' );
    use ok( 'HTTP::Promise::Headers::StrictTransportSecurity' );
    use ok( 'HTTP::Promise::Headers::TE' );
    use ok( 'HTTP::Promise::Headers::WantDigest' );
    use ok( 'HTTP::Promise::IO' );
    use ok( 'HTTP::Promise::MIME' );
    use ok( 'HTTP::Promise::Message' );
    use ok( 'HTTP::Promise::Parser' );
    use ok( 'HTTP::Promise::Pool' );
    use ok( 'HTTP::Promise::Request' );
    use ok( 'HTTP::Promise::Response' );
    use ok( 'HTTP::Promise::Status' );
    use ok( 'HTTP::Promise::Stream' );
    use ok( 'HTTP::Promise::Stream::Base64' );
    use ok( 'HTTP::Promise::Stream::Brotli' );
    use ok( 'HTTP::Promise::Stream::LZW' );
    use ok( 'HTTP::Promise::Stream::QuotedPrint' );
    use ok( 'HTTP::Promise::Stream::UU' );
};

done_testing();

__END__

