# -*- perl -*-
# t/01.load.t - check module loading and create testing directory
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use Test::More qw( no_plan );
}

# To build the list of modules:
# for m in `find ./lib -type f -name "*.pm"`; do echo $m | perl -pe 's,./lib/,,' | perl -pe 's,\.pm$,,' | perl -pe 's/\//::/g' | perl -pe 's,^(.*?)$,use_ok\( ''$1'' \)\;,'; done
BEGIN
{
    use_ok( 'HTTP::Promise' );
    use_ok( 'HTTP::Promise::Exception' );
    use_ok( 'HTTP::Promise::MIME' );
    use_ok( 'HTTP::Promise::Body' );
    use_ok( 'HTTP::Promise::Stream::Base64' );
    use_ok( 'HTTP::Promise::Stream::UU' );
    use_ok( 'HTTP::Promise::Stream::QuotedPrint' );
    use_ok( 'HTTP::Promise::Stream::LZW' );
    use_ok( 'HTTP::Promise::Stream::Brotli' );
    use_ok( 'HTTP::Promise::Body::Form::Field' );
    use_ok( 'HTTP::Promise::Body::Form::Data' );
    use_ok( 'HTTP::Promise::Body::Form' );
    use_ok( 'HTTP::Promise::Stream' );
    use_ok( 'HTTP::Promise::Message' );
    use_ok( 'HTTP::Promise::Response' );
    use_ok( 'HTTP::Promise::Request' );
    use_ok( 'HTTP::Promise::IO' );
    use_ok( 'HTTP::Promise::Parser' );
    use_ok( 'HTTP::Promise::Headers::Link' );
    use_ok( 'HTTP::Promise::Headers::ClearSiteData' );
    use_ok( 'HTTP::Promise::Headers::AcceptLanguage' );
    use_ok( 'HTTP::Promise::Headers::ExpectCT' );
    use_ok( 'HTTP::Promise::Headers::ContentDisposition' );
    use_ok( 'HTTP::Promise::Headers::CacheControl' );
    use_ok( 'HTTP::Promise::Headers::Generic' );
    use_ok( 'HTTP::Promise::Headers::ContentType' );
    use_ok( 'HTTP::Promise::Headers::KeepAlive' );
    use_ok( 'HTTP::Promise::Headers::Range' );
    use_ok( 'HTTP::Promise::Headers::Forwarded' );
    use_ok( 'HTTP::Promise::Headers::AltSvc' );
    use_ok( 'HTTP::Promise::Headers::Cookie' );
    use_ok( 'HTTP::Promise::Headers::Accept' );
    use_ok( 'HTTP::Promise::Headers::AcceptEncoding' );
    use_ok( 'HTTP::Promise::Headers::StrictTransportSecurity' );
    use_ok( 'HTTP::Promise::Headers::ContentSecurityPolicyReportOnly' );
    use_ok( 'HTTP::Promise::Headers::ContentSecurityPolicy' );
    use_ok( 'HTTP::Promise::Headers::TE' );
    use_ok( 'HTTP::Promise::Headers::WantDigest' );
    use_ok( 'HTTP::Promise::Headers::ServerTiming' );
    use_ok( 'HTTP::Promise::Headers::ContentRange' );
    use_ok( 'HTTP::Promise::Entity' );
    use_ok( 'HTTP::Promise::Pool' );
    use_ok( 'HTTP::Promise::Headers' );
    use_ok( 'HTTP::Promise::Status' );
};

