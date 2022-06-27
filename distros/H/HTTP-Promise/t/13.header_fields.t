#!/usr/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test2::V0;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

subtest 'accept' => sub
{
    use ok( 'HTTP::Promise::Headers::Accept' );
    my $accept = 'text/html, application/xhtml+xml, application/xml;q=0.9, image/webp, */*;q=0.8';
    my $h = HTTP::Promise::Headers::Accept->new( $accept );
    is( $h->elements->length, 5 );
    is( $h->elements->first->element, 'text/html' );
    is( $h->elements->third->element, 'application/xml' );
    is( $h->elements->third->value, 0.9 );
    is( $h->elements->fifth->element, '*/*' );
    is( $h->elements->fifth->value, 0.8 );
    is( "$h", $accept );
    my $e = $h->get( 'application/xml' );
    isa_ok( $e => ['HTTP::Promise::Field::QualityValue'] );
    is( $e->element, 'application/xml' );
    my $e2 = $h->get( $e );
    is( $e2->element, $e->element );
    $h->remove( 'application/xhtml+xml' );
    is( $h->as_string, 'text/html, application/xml;q=0.9, image/webp, */*;q=0.8' );
    is( $h->elements->first->value, undef );
    $h->sort;
    is( $h->as_string, 'text/html, image/webp, application/xml;q=0.9, */*;q=0.8' );
};

subtest 'accept-encoding' => sub
{
    use ok( 'HTTP::Promise::Headers::AcceptEncoding' );
    my $str = q{deflate, gzip;q=1.0, *;q=0.5};
    my $h = HTTP::Promise::Headers::AcceptEncoding->new( $str );
    is( $h->elements->length, 3 );
    is( $h->elements->first->element, 'deflate' );
    is( $h->elements->third->value, 0.5 );
};

subtest 'accept-language' => sub
{
    use ok( 'HTTP::Promise::Headers::AcceptLanguage' );
    my $str = q{fr-FR, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5};
    my $h = HTTP::Promise::Headers::AcceptLanguage->new( $str );
    is( $h->elements->length, 5 );
    is( $h->elements->first->element, 'fr-FR' );
    is( $h->elements->first->value, undef );
    is( $h->elements->fourth->element, 'de' );
    is( $h->elements->fourth->value, 0.7 );
    is( $h->elements->last->element, '*' );
};

subtest 'alt-svc' => sub
{
    use ok( 'HTTP::Promise::Headers::AltSvc' );
    my $str = q{h2="alt.example.com:443"; ma=2592000; persist=1};
    my $h = HTTP::Promise::Headers::AltSvc->new( $str );
    is( $h->protocol, 'h2' );
    is( $h->authority, 'alt.example.com:443' );
    is( "$h", $str );
    # example taken from rfc7838
    # <https://tools.ietf.org/html/rfc7838#section-3>
    my $h2 = HTTP::Promise::Headers::AltSvc->new( ['w=x:y#z', 'new.example.org:443'] );
    is( $h2->protocol, 'w=x:y#z' );
    is( $h2->authority, 'new.example.org:443' );
    is( "$h2", q{w%3Dx%3Ay#z="new.example.org:443"} );
};

subtest 'cache-control' => sub
{
    use ok( 'HTTP::Promise::Headers::CacheControl' );
    my $str = q{public, max-age=604800, immutable};
    my $h = HTTP::Promise::Headers::CacheControl->new( $str );
    is( "$h", $str );
    is( $h->public, 1 );
    is( $h->max_age, 604800 );
    is( $h->immutable, 1 );
    $h->max_age( undef );
    is( "$h", q{public, immutable} );
    # Setting this to true should not change anything since it is already set.
    $h->immutable(1);
    is( "$h", q{public, immutable} );
    $h->property( 'community' => 'UCI' );
    is( "$h", q{public, immutable, community="UCI"} );
    my $v = $h->property( 'community' );
    is( $v => 'UCI' );
    $h->property( community => undef );
    is( "$h", q{public, immutable} );
};

subtest 'clear-site-data' => sub
{
    use ok( 'HTTP::Promise::Headers::ClearSiteData' );
    my $str = q{"cache", "cookies", "storage", "executionContexts"};
    my $h = HTTP::Promise::Headers::ClearSiteData->new( $str );
    is( "$h", $str );
    $h->wildcard(1);
    is( "$h", qq{${str}, "*"} );
    $h->cache(0);
    is( "$h", q{"cookies", "storage", "executionContexts", "*"} );
    $h->cache(1);
    is( "$h", q{"cookies", "storage", "executionContexts", "*", "cache"} );
};

subtest 'content-disposition' => sub
{
    use utf8;
    use ok( 'HTTP::Promise::Headers::ContentDisposition' );
    my $str = q{inline};
    my $h = HTTP::Promise::Headers::ContentDisposition->new( $str );
    is( "$h", $str );
    is( $h->disposition, 'inline' );
    $str = q{attachment};
    $h = HTTP::Promise::Headers::ContentDisposition->new( $str );
    is( $h->disposition, 'attachment' );
    $str = q{attachment; filename="filename.jpg"};
    $h = HTTP::Promise::Headers::ContentDisposition->new( $str );
    is( $h->disposition, 'attachment' );
    is( $h->filename, 'filename.jpg' );
    $str = q{form-data; name="fieldName"};
    $h = HTTP::Promise::Headers::ContentDisposition->new( $str );
    is( $h->disposition, 'form-data' );
    is( $h->name, 'fieldName' );
    $str = q{form-data; name="fieldName"; filename="filename.jpg"};
    $h = HTTP::Promise::Headers::ContentDisposition->new( $str );
    is( $h->disposition, 'form-data' );
    is( $h->name, 'fieldName' );
    is( $h->filename, 'filename.jpg' );
    $str = q{form-data; name="fieldName"; filename="filename.jpg"};
    # perl -MEncode -MURI::Escape -lE 'say URI::Escape::uri_escape_utf8( Encode::decode_utf8( "ファイル.txt" ) )'
    $str = q{attachment; filename*="UTF-8'ja-JP'%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt"};
    $h = HTTP::Promise::Headers::ContentDisposition->new( $str );
    is( $h->filename, 'ファイル.txt' );
    is( $h->filename_charset, 'UTF-8' );
    is( $h->filename_lang, 'ja-JP' );
    $h = HTTP::Promise::Headers::ContentDisposition->new;
    $h->disposition( 'form-data' );
    $h->name( 'someField' );
    is( $h->name, 'someField' );
    $h->filename( 'マイファイル.txt', 'ja-JP' );
    is( "$h", q{form-data; name=someField; filename*=UTF-8'ja-JP'%E3%83%9E%E3%82%A4%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB.txt} );
};

subtest 'content-range' => sub
{
    use utf8;
    use ok( 'HTTP::Promise::Headers::ContentRange' );
    my $str = q{bytes 0-499/1234};
    my $h = HTTP::Promise::Headers::ContentRange->new( $str );
    is( "$h", $str );
    is( $h->unit, 'bytes' );
    is( $h->range_start, 0 );
    is( $h->range_end, 499 );
    is( $h->size, 1234 );

    $str = q{bytes */1234};
    $h = HTTP::Promise::Headers::ContentRange->new( $str );
    is( "$h", $str );
    is( $h->unit, 'bytes' );
    is( $h->range_start, undef, 'range_start' );
    is( $h->size, 1234 );
    
    $str = q{bytes 42-1233/*};
    $h = HTTP::Promise::Headers::ContentRange->new( $str );
    is( "$h", $str , 'as_string' );
    is( $h->unit, 'bytes' );
    is( $h->range_start, 42 );
    is( $h->range_end, 1233 );
    is( $h->size, '*' );
};

subtest 'content-security-policy' => sub
{
    use ok( 'HTTP::Promise::Headers::ContentSecurityPolicy' );
    my $str = q{default-src 'self'};
    my $h = HTTP::Promise::Headers::ContentSecurityPolicy->new( $str );
    is( "$h", $str );
    is( $h->default_src, "'self'" );
    $str = q{default-src 'self' trusted.com *.trusted.com};
    $h = HTTP::Promise::Headers::ContentSecurityPolicy->new( $str );
    is( "$h", $str );
    is( $h->default_src, q{'self' trusted.com *.trusted.com} );
    $str = q{base-uri https://example.com/; block-all-mixed-content; child-src https://example.com/ https://dev.example.com/; connect-src https://example.com/; default-src 'self'; font-src https://example.com/; form-action https://example.com/ https://dev.example.com/; frame-ancestors https://example.com/ https://dev.example.com/; frame-src https://example.com/; img-src 'self' img.example.com; manifest-src https://example.com/; media-src https://example.com/; navigate-to https://example.com/ https://dev.example.com/; object-src https://example.com/; plugin-types application/x-shockwave-flash; prefetch-src https://example.com/; referrer "no-referrer"; report-to csp-endpoint; report-uri /csp-violation-report-endpoint/ https://dev.example.com/report; require-sri-for script style; require-trusted-types-for 'script'; sandbox; script-src 'self' js.example.com; script-src-elem https://example.com/; script-src-attr https://example.com/; style-src https://example.com/; style-src-attr https://example.com/; style-src-elem https://example.com/; trusted-types; upgrade-insecure-requests; worker-src https://example.com/};
    $h = HTTP::Promise::Headers::ContentSecurityPolicy->new( $str );
    is( "$h", $str );
    is( $h->base_uri, 'https://example.com/' );
    is( $h->block_all_mixed_content, 1 );
    is( $h->child_src, 'https://example.com/ https://dev.example.com/' );
    is( $h->connect_src, 'https://example.com/' );
    is( $h->default_src, "'self'" );
    is( $h->font_src, 'https://example.com/' );
    is( $h->form_action, 'https://example.com/ https://dev.example.com/' );
    is( $h->frame_ancestors, 'https://example.com/ https://dev.example.com/' );
    is( $h->frame_src, 'https://example.com/' );
    is( $h->img_src, q{'self' img.example.com} );
    is( $h->manifest_src, 'https://example.com/' );
    is( $h->media_src, 'https://example.com/' );
    is( $h->navigate_to, 'https://example.com/ https://dev.example.com/' );
    is( $h->object_src, 'https://example.com/' );
    is( $h->plugin_types, 'application/x-shockwave-flash' );
    is( $h->prefetch_src, 'https://example.com/' );
    is( $h->referrer, '"no-referrer"' );
    is( $h->report_to, 'csp-endpoint' );
    is( $h->report_uri, '/csp-violation-report-endpoint/ https://dev.example.com/report' );
    is( $h->require_sri_for, 'script style' );
    is( $h->require_trusted_types_for, "'script'" );
    is( $h->sandbox, 1 );
    is( $h->script_src, q{'self' js.example.com} );
    is( $h->script_src_elem, 'https://example.com/' );
    is( $h->script_src_attr, 'https://example.com/' );
    is( $h->style_src, 'https://example.com/' );
    is( $h->style_src_attr, 'https://example.com/' );
    is( $h->style_src_elem, 'https://example.com/' );
    is( $h->trusted_types, 1 );
    is( $h->upgrade_insecure_requests, 1 );
    is( $h->worker_src, 'https://example.com/' );
    $h->block_all_mixed_content(0);
    is( $h->block_all_mixed_content, 0 );
};

subtest 'content-type' => sub
{
    use ok( 'HTTP::Promise::Headers::ContentType' );
    my $str = q{text/html; charset=UTF-8};
    my $h = HTTP::Promise::Headers::ContentType->new( $str );
    is( "$h", $str );
    is( $h->type, 'text/html' );
    is( $h->charset, 'UTF-8' );

    $str = q{application/octet-stream};
    $h = HTTP::Promise::Headers::ContentType->new( $str );
    is( "$h", $str );
    is( $h->type, 'application/octet-stream' );
    
    $str = q{multipart/form-data; boundary=something};
    $h = HTTP::Promise::Headers::ContentType->new( $str );
    is( "$h", $str );
    is( $h->type, 'multipart/form-data' );
    is( $h->boundary, 'something' );
    
    $str = q{application/x-www-form-urlencoded};
    $h = HTTP::Promise::Headers::ContentType->new( $str );
    is( "$h", $str );
    is( $h->type, 'application/x-www-form-urlencoded' );
    
    $str = q{multipart/byteranges};
    $h = HTTP::Promise::Headers::ContentType->new( $str );
    is( "$h", $str );
    is( $h->type, 'multipart/byteranges' );
    
    $h = HTTP::Promise::Headers::ContentType->new;
    $h->type( 'text/plain' );
    $h->charset( 'utf-8' );
    is( "$h", 'text/plain; charset=utf-8' );
};

subtest 'expect-ct' => sub
{
    use ok( 'HTTP::Promise::Headers::ExpectCT' );
    my $str = q{max-age=86400, enforce, report-uri="https://foo.example.com/report"};
    my $h = HTTP::Promise::Headers::ExpectCT->new( $str );
    is( "$h", $str );
    is( $h->max_age, 86400 );
    is( $h->enforce, 1 );
    is( $h->report_uri, 'https://foo.example.com/report' );
};

subtest 'forwarded' => sub
{
    use ok( 'HTTP::Promise::Headers::Forwarded' );
    my $str = q{for=192.0.2.60; proto=http; by=203.0.113.43};
    my $h = HTTP::Promise::Headers::Forwarded->new( $str );
    is( "$h", $str );
    is( $h->for, '192.0.2.60' );
    is( $h->proto, 'http' );
    is( $h->by, '203.0.113.43' );
};

subtest 'keep-alive' => sub
{
    use ok( 'HTTP::Promise::Headers::KeepAlive' );
    my $str = q{timeout=5, max=1000};
    my $h = HTTP::Promise::Headers::KeepAlive->new( $str );
    is( "$h", $str );
    is( $h->timeout, 5 );
    is( $h->max, 1000 );
};

subtest 'link' => sub
{
    use utf8;
    use ok( 'HTTP::Promise::Headers::Link' );
    my $str = q{<https://example.com>; rel=preconnect};
    my $h = HTTP::Promise::Headers::Link->new( $str );
    is( "$h", $str );
    is( $h->link, 'https://example.com' );
    is( $h->rel, 'preconnect' );
    
    $h = HTTP::Promise::Headers::Link->new;
    $h->link( 'https://dev.example.org' );
    $h->rel( 'next' );
    $h->title( '別に', 'ja-JP' );
    $h->anchor( '#baz' );
    is( "$h" => q{<https://dev.example.org>; rel=next; title*=UTF-8'ja-JP'%E5%88%A5%E3%81%AB; anchor=#baz} );
};

subtest 'range' => sub
{
    use ok( 'HTTP::Promise::Headers::Range' );
    my $str = q{bytes=200-1000, 1001-2000, 2001-3000};
    my $h = HTTP::Promise::Headers::Range->new( $str );
    is( "$h", $str );
    is( $h->ranges->first->start, 200 );
    is( $h->ranges->first->end, 1000 );
    is( $h->ranges->second->start, 1001 );
    is( $h->ranges->second->end, 2000 );
    is( $h->ranges->third->start, 2001 );
    is( $h->ranges->third->end, 3000 );
    
    $str = q{bytes=200-};
    $h = HTTP::Promise::Headers::Range->new( $str );
    is( "$h", $str );
    is( $h->ranges->first->start, 200 );
    is( $h->ranges->first->end, undef );
    
    $str = q{bytes=-4321};
    $h = HTTP::Promise::Headers::Range->new( $str );
    is( "$h", $str );
    is( $h->ranges->first->start, undef );
    is( $h->ranges->first->end, 4321 );
};

subtest 'server-timing' => sub
{
    use ok( 'HTTP::Promise::Headers::ServerTiming' );
    my $str = q{cache; desc="Cache Read"; dur=23.2};
    my $h = HTTP::Promise::Headers::ServerTiming->new( $str );
    is( "$h", $str );
    
    $h = HTTP::Promise::Headers::ServerTiming->new;
    $h->name( 'db' );
    $h->dur( 3.2 );
    $h->desc( 'Some database' );
    is( "$h", 'db; desc="Some database"; dur=3.2' );
};

subtest 'strict-transport-security' => sub
{
    use ok( 'HTTP::Promise::Headers::StrictTransportSecurity' );
    my $str = q{max-age=63072000; includeSubDomains; preload};
    my $h = HTTP::Promise::Headers::StrictTransportSecurity->new( $str );
    is( "$h", $str );
    is( $h->max_age, 63072000 );
    is( $h->include_subdomains, 1 );
    is( $h->preload, 1 );
    $h->include_subdomains( undef );
    is( "$h",  q{max-age=63072000; preload} );
    
    $h = HTTP::Promise::Headers::StrictTransportSecurity->new;
    $h->include_subdomains(1);
    $h->max_age(63072000);
    $h->preload(1);
    $h->property_boolean( 'something_else' => 1 );
    is( "$h",  q{includeSubDomains; max-age=63072000; preload; something_else} );
    is( $h->max_age, 63072000 );
    is( $h->preload, 1 );
};

subtest 'te' => sub
{
    use ok( 'HTTP::Promise::Headers::TE' );
    my $str = q{trailers, deflate;q=0.5};
    my $h = HTTP::Promise::Headers::TE->new( $str );
    is( "$h", $str );
    my $e = $h->get( 'trailers' );
    isa_ok( $e => ['HTTP::Promise::Field::QualityValue'] );
    is( $e->element, 'trailers' );
    is( $e->value, undef );
    my $e2 = $h->get( 'deflate' );
    isa_ok( $e2 => ['HTTP::Promise::Field::QualityValue'] );
    is( $e2->element, 'deflate' );
    is( $e2->value, 0.5 );
    ok( $e2->value > $e->value );
    ok( !( $e2->value < $e->value ) );
};

subtest 'want-digest' => sub
{
    use ok( 'HTTP::Promise::Headers::WantDigest' );
    my $str = q{SHA-512;q=0.3, sha-256;q=1, md5;q=0};
    my $h = HTTP::Promise::Headers::WantDigest->new( $str );
    is( "$h", $str );
    my $e = $h->get( 'SHA-512' );
    isa_ok( $e => ['HTTP::Promise::Field::QualityValue'] );
};

subtest "new_field" => sub
{
    use ok( 'HTTP::Promise::Headers' );
    my $h = HTTP::Promise::Headers->new;
    my %tests = (
        accept_encoding     => 'HTTP::Promise::Headers::AcceptEncoding',
        accept_language     => 'HTTP::Promise::Headers::AcceptLanguage',
        accept              => 'HTTP::Promise::Headers::Accept',
        altsvc              => 'HTTP::Promise::Headers::AltSvc',
        cache_control       => 'HTTP::Promise::Headers::CacheControl',
        clear_site_data     => 'HTTP::Promise::Headers::ClearSiteData',
        content_disposition => 'HTTP::Promise::Headers::ContentDisposition',
        content_range       => 'HTTP::Promise::Headers::ContentRange',
        content_securit_ypolicy => 'HTTP::Promise::Headers::ContentSecurityPolicy',
        content_security_policy_report_only => 'HTTP::Promise::Headers::ContentSecurityPolicyReportOnly',
        content_type        => 'HTTP::Promise::Headers::ContentType',
        cookie              => 'HTTP::Promise::Headers::Cookie',
        expectct            => 'HTTP::Promise::Headers::ExpectCT',
        forwarded           => 'HTTP::Promise::Headers::Forwarded',
        generic             => 'HTTP::Promise::Headers::Generic',
        keepalive           => 'HTTP::Promise::Headers::KeepAlive',
        link                => 'HTTP::Promise::Headers::Link',
        range               => 'HTTP::Promise::Headers::Range',
        server_timing       => 'HTTP::Promise::Headers::ServerTiming',
        strict_transport_security => 'HTTP::Promise::Headers::StrictTransportSecurity',
        te                  => 'HTTP::Promise::Headers::TE',
        wantdigest          => 'HTTP::Promise::Headers::WantDigest',
    );
    foreach( sort( keys( %tests ) ) )
    {
        my $f = $h->new_field( $_ ) || do
        {
            diag( "Failed instantiating an object for \"$_\": ", $h->error ) if( $DEBUG );
            fail( $tests{ $_ } );
            next;
        };
        isa_ok( $f, [ $tests{ $_ } ] );
    }
};

done_testing();

__END__

