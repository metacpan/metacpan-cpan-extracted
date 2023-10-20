#!/usr/bin/perl
BEGIN
{
    use strict;
    use warnings;
    use lib './lib';
    use vars qw( $DEBUG );
    use Test2::V0;
    use Module::Generic::File qw( file );
    # use Nice::Try;
    our $DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
};

use strict;
use warnings;

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

eval "use CBOR::XS 1.86;";
our $HAS_CBOR = ( $@ ? 0 : 1 );

eval "use Sereal 4.023;";
our $HAS_SEREEAL = ( $@ ? 0 : 1 );

eval "use Storable::Improved v0.1.2;";
our $HAS_STORABLE = ( $@ ? 0 : 1 );

# NOTE: CBOR
subtest 'CBOR' => sub
{
    SKIP:
    {
        skip( "CBOR::XS is not installed. Skipping CBOR related tests.", 1 ) if( !$HAS_CBOR );
        note( "Processing tests for CBOR" );
        my $cbor = CBOR::XS->new;
        $cbor->allow_sharing(1);
        my $serial;
        # try-catch
        local $@;
        eval
        {
            my $body = HTTP::Promise::Body::File->new( '/some/where/file.txt' );
            $serial = $cbor->encode( $body );
            my $body2  = $cbor->decode( $serial );
            isa_ok( $body2 => ['HTTP::Promise::Body::File'], 'deserialised element is a HTTP::Promise::Body::File object' );
            is( $body2->filepath, $body->filepath, 'HTTP::Promise::Body::File: filepath matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Body::File test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $body = HTTP::Promise::Body::Scalar->new( 'Some data' );
            $serial = $cbor->encode( $body );
            my $body2  = $cbor->decode( $serial );
            isa_ok( $body2 => ['HTTP::Promise::Body::Scalar'], 'deserialised element is a HTTP::Promise::Body::Scalar object' );
            is( $body2->as_string, $body->as_string, 'HTTP::Promise::Body::Scalar: content matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Body::Scalar test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $form = HTTP::Promise::Body::Form->new({
                name => 'John Doe',
                location => 'Tokyo',
            });
            $serial = $cbor->encode( $form );
            my $form2  = $cbor->decode( $serial );
            isa_ok( $form2 => ['HTTP::Promise::Body::Form'], 'deserialised element is a HTTP::Promise::Body::Form object' );
            is( $form2->{name}, $form->{name}, 'HTTP::Promise::Body::Form: item "name" matches' );
            is( $form2->{location}, $form->{location}, 'HTTP::Promise::Body::Form: item "name" matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Body::Form test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $form = HTTP::Promise::Body::Form::Data->new({
                name => 'John Doe',
                location => 'Tokyo',
            });
            $serial = $cbor->encode( $form );
            my $form2  = $cbor->decode( $serial );
            isa_ok( $form2 => ['HTTP::Promise::Body::Form::Data'], 'deserialised element is a HTTP::Promise::Body::Form::Data object' );
            is( $form2->{name}, $form->{name}, 'HTTP::Promise::Body::Form::Data: item "name" matches' );
            is( $form2->{location}, $form->{location}, 'HTTP::Promise::Body::Form::Data: item "name" matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Body::Form test for CBOR: $@" );
        }
    
        # try-catch
        local $@;
        eval
        {
            my $field = HTTP::Promise::Body::Form::Field->new(
                name => 'picture',
                file => '/some/where/image.png',
                headers => [ conten_type => 'image/png' ],
            );
            $serial = $cbor->encode( $field );
            my $field2  = $cbor->decode( $serial );
            isa_ok( $field2 => ['HTTP::Promise::Body::Form::Field'], 'deserialised element is a HTTP::Promise::Body::Form::Field object' );
            is( $field2->name => $field->name, 'HTTP::Promise::Body::Form::Field field name matches' );
            is( $field2->body->file => $field->body->file, 'HTTP::Promise::Body::Form::Field body filepath matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Body::Form::Field test for CBOR: $@" );
        }
    
        # try-catch
        local $@;
        eval
        {
            my $ent = HTTP::Promise::Entity->new;
            $serial = $cbor->encode( $ent );
            my $ent2  = $cbor->decode( $serial );
            isa_ok( $ent2 => ['HTTP::Promise::Entity'], 'deserialised element is a HTTP::Promise::Entity object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Entity test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $ex = HTTP::Promise::Exception->new( code => 400, message => 'Oops' );
            $serial = $cbor->encode( $ex );
            my $ex2  = $cbor->decode( $serial );
            isa_ok( $ex2 => ['HTTP::Promise::Exception'], 'deserialised element is a HTTP::Promise::Exception object' );
            is( $ex2->code, $ex->code, 'HTTP::Promise::Exception test value #1' );
            is( $ex2->message, $ex->message, 'HTTP::Promise::Exception test value #2' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Exception test for CBOR: $@" );
        }
    
        # try-catch
        local $@;
        eval
        {
            my $h = HTTP::Promise::Headers->new(
                Content_Type => 'text/html',
                Accept_Encoding => 'brotly,bgzip2,gzip,deflate',
                Accept_Language => 'fr-FR;q=0.7, en;q=0.6, ja-JP;q=0.5',
                Connection => 'close',
            );
            $serial = $cbor->encode( $h );
            my $h2  = $cbor->decode( $serial );
            diag( "Checking deserialised object '$h2'" ) if( $DEBUG );
            isa_ok( $h2 => ['HTTP::Promise::Headers'], 'deserialised element is a HTTP::Promise::Headers object' );
            is( $h2->header( 'Content-Type' ) => $h->header( 'Content-Type' ), 'HTTP::Promise::Headers field Content-Type matches' );
            is( $h2->header( 'Accept-Encoding' ) => $h->header( 'Accept-Encoding' ), 'HTTP::Promise::Headers field Accept-Encoding matches' );
            is( $h2->header( 'Accept-Language' ) => $h->header( 'Accept-Language' ), 'HTTP::Promise::Headers field Accept-Language matches' );
            is( $h2->header( 'Conection' ) => $h->header( 'Conection' ), 'HTTP::Promise::Headers field Conection matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers test for CBOR: $@" );
        }
    
        # try-catch
        local $@;
        eval
        {
            my $accept = HTTP::Promise::Headers::Accept->new( 'text/html, application/json, application/xml;q=0.9, */*;q=0.8' );
            $serial = $cbor->encode( $accept );
            my $accept2  = $cbor->decode( $serial );
            isa_ok( $accept2 => ['HTTP::Promise::Headers::Accept'], 'deserialised element is a HTTP::Promise::Headers::Accept object' );
            is( $accept2->as_string => $accept->as_string, 'HTTP::Promise::Headers::Accept string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::Accept test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $accept = HTTP::Promise::Headers::AcceptEncoding->new( 'deflate, gzip;q=1.0, *;q=0.5' );
            $serial = $cbor->encode( $accept );
            my $accept2  = $cbor->decode( $serial );
            isa_ok( $accept2 => ['HTTP::Promise::Headers::AcceptEncoding'], 'deserialised element is a HTTP::Promise::Headers::AcceptEncoding object' );
            is( "$accept2" => "$accept", 'HTTP::Promise::Headers::AcceptEncoding string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::AcceptEncoding test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $accept = HTTP::Promise::Headers::AcceptLanguage->new( 'fr-FR, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5' );
            $serial = $cbor->encode( $accept );
            my $accept2  = $cbor->decode( $serial );
            isa_ok( $accept2 => ['HTTP::Promise::Headers::AcceptLanguage'], 'deserialised element is a HTTP::Promise::Headers::AcceptLanguage object' );
            is( "$accept2" => "$accept", 'HTTP::Promise::Headers::AcceptLanguage string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::AcceptLanguage test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $alt = HTTP::Promise::Headers::AltSvc->new( q{h2="alt.example.com:443"} );
            $serial = $cbor->encode( $alt );
            my $alt2  = $cbor->decode( $serial );
            isa_ok( $alt2 => ['HTTP::Promise::Headers::AltSvc'], 'deserialised element is a HTTP::Promise::Headers::AltSvc object' );
            is( "$alt2" => "$alt", 'HTTP::Promise::Headers::AltSvc string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::AltSvc test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $cache = HTTP::Promise::Headers::CacheControl->new( 'max-age=604800' );
            $serial = $cbor->encode( $cache );
            my $cache2  = $cbor->decode( $serial );
            isa_ok( $cache2 => ['HTTP::Promise::Headers::CacheControl'], 'deserialised element is a HTTP::Promise::Headers::CacheControl object' );
            is( "$cache2" => "$cache", 'HTTP::Promise::Headers::CacheControl string matches' );
            is( $cache2->max_age => $cache->max_age, 'HTTP::Promise::Headers::CacheControl max_age matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::CacheControl test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $clear = HTTP::Promise::Headers::ClearSiteData->new( q{"cache", "cookies", "storage", "executionContexts"} );
            $serial = $cbor->encode( $clear );
            my $clear2  = $cbor->decode( $serial );
            isa_ok( $clear2 => ['HTTP::Promise::Headers::ClearSiteData'], 'deserialised element is a HTTP::Promise::Headers::ClearSiteData object' );
            is( "$clear2" => "$clear", 'HTTP::Promise::Headers::ClearSiteData string matches' );
            is( $clear2->cache => $clear->cache, 'HTTP::Promise::Headers::CacheControl cache matches' );
            is( $clear2->cookies => $clear->cookies, 'HTTP::Promise::Headers::CacheControl cookies matches' );
            is( $clear2->storage => $clear->storage, 'HTTP::Promise::Headers::CacheControl storage matches' );
            is( $clear2->execution_contexts => $clear->execution_contexts, 'HTTP::Promise::Headers::CacheControl execution_contexts matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ClearSiteData test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $dispo = HTTP::Promise::Headers::ContentDisposition->new( q{attachment; filename="filename.jpg"} );
            $serial = $cbor->encode( $dispo );
            my $dispo2  = $cbor->decode( $serial );
            isa_ok( $dispo2 => ['HTTP::Promise::Headers::ContentDisposition'], 'deserialised element is a HTTP::Promise::Headers::ContentDisposition object' );
            is( "$dispo2" => "$dispo", 'HTTP::Promise::Headers::ContentDisposition string matches' );
            is( $dispo2->disposition => $dispo->disposition, 'HTTP::Promise::Headers::ContentDisposition disposition matches' );
            is( $dispo2->filename => $dispo->filename, 'HTTP::Promise::Headers::ContentDisposition filename matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ContentDisposition test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $range = HTTP::Promise::Headers::ContentRange->new( 'bytes 200-1000/67589' );
            $serial = $cbor->encode( $range );
            my $range2  = $cbor->decode( $serial );
            isa_ok( $range2 => ['HTTP::Promise::Headers::ContentRange'], 'deserialised element is a HTTP::Promise::Headers::ContentRange object' );
            is( "$range2" => "$range", 'HTTP::Promise::Headers::ContentRange string matches' );
            is( $range2->range_start => $range->range_start, 'HTTP::Promise::Headers::ContentRange range_start matches' );
            is( $range2->range_end => $range->range_end, 'HTTP::Promise::Headers::ContentRange range_end matches' );
            is( $range2->size => $range->size, 'HTTP::Promise::Headers::ContentRange size matches' );
            is( $range2->unit => $range->unit, 'HTTP::Promise::Headers::ContentRange unit matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ContentRange test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $policy = HTTP::Promise::Headers::ContentSecurityPolicy->new( q{default-src 'self'; img-src *; media-src media1.com media2.com; script-src userscripts.example.com} );
            $serial = $cbor->encode( $policy );
            my $policy2  = $cbor->decode( $serial );
            isa_ok( $policy2 => ['HTTP::Promise::Headers::ContentSecurityPolicy'], 'deserialised element is a HTTP::Promise::Headers::ContentSecurityPolicy object' );
            is( "$policy2" => "$policy", 'HTTP::Promise::Headers::ContentSecurityPolicy string matches' );
            is( $policy2->default_src => $policy->default_src, 'HTTP::Promise::Headers::ContentSecurityPolicy default_src matches' );
            is( $policy2->img_src => $policy->img_src, 'HTTP::Promise::Headers::ContentSecurityPolicy img_src matches' );
            is( $policy2->media_src => $policy->media_src, 'HTTP::Promise::Headers::ContentSecurityPolicy media_src matches' );
            is( $policy2->script_src => $policy->script_src, 'HTTP::Promise::Headers::ContentSecurityPolicy script_src matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ContentSecurityPolicy test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $policy = HTTP::Promise::Headers::ContentSecurityPolicyReportOnly->new( q{default-src https:; report-uri /csp-violation-report-endpoint/} );
            $serial = $cbor->encode( $policy );
            my $policy2  = $cbor->decode( $serial );
            isa_ok( $policy2 => ['HTTP::Promise::Headers::ContentSecurityPolicyReportOnly'], 'deserialised element is a HTTP::Promise::Headers::ContentSecurityPolicyReportOnly object' );
            is( "$policy2" => "$policy", 'HTTP::Promise::Headers::ContentSecurityPolicyReportOnly string matches' );
            is( $policy2->default_src => $policy->default_src, 'HTTP::Promise::Headers::ContentSecurityPolicyReportOnly default_src matches' );
            is( $policy2->report_uri => $policy->report_uri, 'HTTP::Promise::Headers::ContentSecurityPolicyReportOnly report_uri matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ContentSecurityPolicyReportOnly test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $ct = HTTP::Promise::Headers::ContentType->new( q{text/html; charset=UTF-8} );
            $serial = $cbor->encode( $ct );
            my $ct2  = $cbor->decode( $serial );
            isa_ok( $ct2 => ['HTTP::Promise::Headers::ContentType'], 'deserialised element is a HTTP::Promise::Headers::ContentType object' );
            is( "$ct2" => "$ct", 'HTTP::Promise::Headers::ContentType string matches' );
            is( $ct2->type => $ct->type, 'HTTP::Promise::Headers::ContentType type matches' );
            is( $ct2->charset => $ct->charset, 'HTTP::Promise::Headers::ContentType charset matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ContentType test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $c = HTTP::Promise::Headers::Cookie->new( q{name=value; name2=value2; name3=value3} );
            $serial = $cbor->encode( $c );
            my $c2  = $cbor->decode( $serial );
            isa_ok( $c2 => ['HTTP::Promise::Headers::Cookie'], 'deserialised element is a HTTP::Promise::Headers::Cookie object' );
            is( "$c2" => "$c", 'HTTP::Promise::Headers::Cookie string matches' );
            my $cookies = $c->cookies;
            my $cookies2 = $c2->cookies;
            is( "@$cookies2" => "@$cookies", 'HTTP::Promise::Headers::Cookie cookies matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::Cookie test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::ExpectCT->new( q{max-age=86400, enforce, report-uri="https://foo.example.com/report"} );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::ExpectCT'], 'deserialised element is a HTTP::Promise::Headers::ExpectCT object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::ExpectCT string matches' );
            is( $o2->max_age => $o->max_age, 'HTTP::Promise::Headers::ExpectCT max_age matches' );
            is( $o2->enforce => $o->enforce, 'HTTP::Promise::Headers::ExpectCT enforce matches' );
            is( $o2->report_uri => $o->report_uri, 'HTTP::Promise::Headers::ExpectCT report_uri matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ExpectCT test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::Forwarded->new( q{for=192.0.2.60;proto=http;by=203.0.113.43} );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::Forwarded'], 'deserialised element is a HTTP::Promise::Headers::Forwarded object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::Forwarded string matches' );
            is( $o2->by => $o->by, 'HTTP::Promise::Headers::Forwarded by matches' );
            is( $o2->for => $o->for, 'HTTP::Promise::Headers::Forwarded for matches' );
            is( $o2->proto => $o->proto, 'HTTP::Promise::Headers::Forwarded proto matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::Forwarded test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::KeepAlive->new( q{timeout=5, max=1000} );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::KeepAlive'], 'deserialised element is a HTTP::Promise::Headers::KeepAlive object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::KeepAlive string matches' );
            is( $o2->max => $o->max, 'HTTP::Promise::Headers::KeepAlive max matches' );
            is( $o2->timeout => $o->timeout, 'HTTP::Promise::Headers::KeepAlive timeout matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::KeepAlive test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::Link->new( q{<https://example.com>; rel="preconnect"; title="Foo"; anchor="#bar"} );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::Link'], 'deserialised element is a HTTP::Promise::Headers::Link object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::Link string matches' );
            is( $o2->anchor => $o->anchor, 'HTTP::Promise::Headers::Link anchor matches' );
            is( $o2->rel => $o->rel, 'HTTP::Promise::Headers::Link rel matches' );
            is( $o2->link => $o->link, 'HTTP::Promise::Headers::Link link matches' );
            is( $o2->title => $o->title, 'HTTP::Promise::Headers::Link title matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::Link test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::Range->new( q{bytes=200-1000, 2000-6576, 19000-} );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::Range'], 'deserialised element is a HTTP::Promise::Headers::Range object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::Range string matches' );
            is( $o2->unit => $o->unit, 'HTTP::Promise::Headers::Range unit matches' );
            my $ranges = $o->ranges;
            my $ranges2 = $o2->ranges;
            SKIP:
            {
                skip( "original range and serialised range are not the same length.", 1 ) if( $ranges->length != $ranges2->length );
                for( my $i = 0; $i < $ranges->length; $i++ )
                {
                    my $r = $ranges->[$i];
                    my $r2 = $ranges2->[$i];
                    unless( isa_ok( $r2 => ['HTTP::Promise::Headers::Range::StartEnd'] ) )
                    {
                        next;
                    }
                    ok( ( ( $r->start == $r2->start ) && 
                          (
                            ( defined( $r->end ) && defined( $r2->end ) && ( $r->end == $r2->end ) ) ||
                            ( !defined( $r->end ) && !defined( $r2->end ) )
                          )
                        ), "No $i HTTP::Promise::Headers::Range::StartEnd objects match" );
                }
            };
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::Range test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::ServerTiming->new( q{cache;desc="Cache Read";dur=23.2} );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::ServerTiming'], 'deserialised element is a HTTP::Promise::Headers::ServerTiming object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::ServerTiming string matches' );
            is( $o2->desc => $o->desc, 'HTTP::Promise::Headers::ServerTiming desc matches' );
            is( $o2->dur => $o->dur, 'HTTP::Promise::Headers::ServerTiming dur matches' );
            is( $o2->name => $o->name, 'HTTP::Promise::Headers::ServerTiming name matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ServerTiming test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::StrictTransportSecurity->new( q{max-age=63072000; includeSubDomains; preload} );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::StrictTransportSecurity'], 'deserialised element is a HTTP::Promise::Headers::StrictTransportSecurity object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::StrictTransportSecurity string matches' );
            is( $o2->max_age => $o->max_age, 'HTTP::Promise::Headers::StrictTransportSecurity max_age matches' );
            is( $o2->preload => $o->preload, 'HTTP::Promise::Headers::StrictTransportSecurity preload matches' );
            is( $o2->include_subdomains => $o->include_subdomains, 'HTTP::Promise::Headers::StrictTransportSecurity include_subdomains matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::StrictTransportSecurity test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::TE->new( q{trailers, deflate;q=0.5} );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::TE'], 'deserialised element is a HTTP::Promise::Headers::TE object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::TE string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::TE test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::WantDigest->new( q{SHA-512;q=0.3, sha-256;q=1, md5;q=0} );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::WantDigest'], 'deserialised element is a HTTP::Promise::Headers::WantDigest object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::WantDigest string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::WantDigest test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $me = file( __FILE__ );
            my $fh = $me->open || die( "Unable to open $me: ", $me->error );
            my $o = HTTP::Promise::IO->new( $fh, debug => 2 ) || die( HTTP::Promise::IO->error );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::IO'], 'deserialised element is a HTTP::Promise::IO object' );
            is( $o2->debug => $o->debug, 'HTTP::Promise::IO debug value matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::IO test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::MIME->new || die( HTTP::Promise::IO->error );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::MIME'], 'deserialised element is a HHTTP::Promise::MIME object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::MIME test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Message->new(
                [ 'Content-Type' => 'text/plain' ],
                'Hello world',
            ) || die( HTTP::Promise::Message->error );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Message'], 'deserialised element is a HTTP::Promise::Message object' );
            is( $o2->headers->content_type => $o->headers->content_type, 'HTTP::Promise::Message content_type header value matches' );
            is( $o2->decoded_content => $o->decoded_content, 'HTTP::Promise::Message decoded_content value matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Message test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Parser->new || die( HTTP::Promise::Parser->error );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Parser'], 'deserialised element is a HTTP::Promise::Parser object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Parser test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Pool->new || die( HTTP::Promise::Pool->error );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Pool'], 'deserialised element is a HTTP::Promise::Pool object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Pool test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Request->new(
                GET => 'https://example.com/some/where',
                [
                Content_Type => 'text/html; charset=utf-8',
                ],
                'Hello world',
            ) || die( HTTP::Promise::Request->error );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Request'], 'deserialised element is a HTTP::Promise::Request object' );
            is( $o2->method => $o->method, 'HTTP::Promise::Request method value matches' );
            is( $o2->uri => $o->uri, 'HTTP::Promise::Request uri value matches' );
            is( $o2->headers->content_type => $o->headers->content_type, 'HTTP::Promise::Request content_type header value matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Request test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Response->new(
                200 => 'OK',
                [
                Cache_Control => 'no-cache, no-store',
                Content_Encoding => 'gzip',
                Content_Ttype => 'text/html; charset=utf-8',
                ],
                'Hello world',
            ) || die( HTTP::Promise::Response->error );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Response'], 'deserialised element is a HTTP::Promise::Response object' );
            is( $o2->code => $o->code, 'HTTP::Promise::Response method value matches' );
            is( $o2->status => $o->status, 'HTTP::Promise::Response uri value matches' );
            is( $o2->headers->content_type => $o->headers->content_type, 'HTTP::Promise::Response Content-Type header value matches' );
            is( $o2->headers->cache_control => 'no-cache, no-store', 'HTTP::Promise::Response Cache-Control header value matches' );
            is( $o2->headers->content_encoding => 'gzip', 'HTTP::Promise::Response Content-Ttype header value matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Response test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Status->new || die( HTTP::Promise::Status->error );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Status'], 'deserialised element is a HTTP::Promise::Status object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Status test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Stream->new( __FILE__ ) || die( HTTP::Promise::Stream->error );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Stream'], 'deserialised element is a HTTP::Promise::Stream object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Stream test for CBOR: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Stream::Base64->new || die( HTTP::Promise::Stream::Base64->error );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Stream::Base64'], 'deserialised element is a HTTP::Promise::Stream::Base64 object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Stream::Base64 test for CBOR: $@" );
        }
    
        SKIP:
        {
            eval( "use IO::Compress::Brotli; use IO::Uncompress::Brotli;" );
            skip( "IO::Compress::Brotli or IO::Uncompress::Brotli is not installed on your system.", 1 ) if( $@ );
            # try-catch
            local $@;
            eval
            {
                my $o = HTTP::Promise::Stream::Brotli->new || die( HTTP::Promise::Stream::Brotli->error );
                $serial = $cbor->encode( $o );
                my $o2  = $cbor->decode( $serial );
                isa_ok( $o2 => ['HTTP::Promise::Stream::Brotli'], 'deserialised element is a HTTP::Promise::Stream::Brotli object' );
            };
            if( $@ )
            {
                fail( "Failed HTTP::Promise::Stream::Brotli test for CBOR: $@" );
            }
        };

        SKIP:
        {
            eval( "use Compress::LZW;" );
            skip( "Compress::LZW is not installed on your system.", 1 ) if( $@ );
            # try-catch
            local $@;
            eval
            {
                my $o = HTTP::Promise::Stream::LZW->new || die( HTTP::Promise::Stream::LZW->error );
                $serial = $cbor->encode( $o );
                my $o2  = $cbor->decode( $serial );
                isa_ok( $o2 => ['HTTP::Promise::Stream::LZW'], 'deserialised element is a HTTP::Promise::Stream::LZW object' );
            };
            if( $@ )
            {
                fail( "Failed HTTP::Promise::Stream::LZW test for CBOR: $@" );
            }
        };

        SKIP:
        {
            eval( "use MIME::QuotedPrint;" );
            skip( "MIME::QuotedPrint is not installed on your system.", 1 ) if( $@ );
            # try-catch
            local $@;
            eval
            {
                my $o = HTTP::Promise::Stream::QuotedPrint->new || die( HTTP::Promise::Stream::QuotedPrint->error );
                $serial = $cbor->encode( $o );
                my $o2  = $cbor->decode( $serial );
                isa_ok( $o2 => ['HTTP::Promise::Stream::QuotedPrint'], 'deserialised element is a HTTP::Promise::Stream::QuotedPrint object' );
            };
            if( $@ )
            {
                fail( "Failed HTTP::Promise::Stream::QuotedPrint test for CBOR: $@" );
            }
        };

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Stream::UU->new || die( HTTP::Promise::Stream::UU->error );
            $serial = $cbor->encode( $o );
            my $o2  = $cbor->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Stream::UU'], 'deserialised element is a HTTP::Promise::Stream::UU object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Stream::UU test for CBOR: $@" );
        }
    };
};

# NOTE: Sereal
subtest 'Sereal' => sub
{
    # NOTE: Sereal
    SKIP:
    {
        skip( "Sereal is not installed. Skipping Sereal related tests.", 1 ) if( !$HAS_SEREEAL );
        note( "Processing tests for Sereal" );
        my $enc = Sereal::get_sereal_encoder({ freeze_callbacks => 1 });
        my $dec = Sereal::get_sereal_decoder();
        my $serial;
        # try-catch
        local $@;
        eval
        {
            my $body = HTTP::Promise::Body::File->new( '/some/where/file.txt' );
            $serial = $enc->encode( $body );
            my $body2  = $dec->decode( $serial );
            isa_ok( $body2 => ['HTTP::Promise::Body::File'], 'deserialised element is a HTTP::Promise::Body::File object' );
            is( $body2->filepath, $body->filepath, 'HTTP::Promise::Body::File: filepath matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Body::File test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $body = HTTP::Promise::Body::Scalar->new( 'Some data' );
            $serial = $enc->encode( $body );
            my $body2  = $dec->decode( $serial );
            isa_ok( $body2 => ['HTTP::Promise::Body::Scalar'], 'deserialised element is a HTTP::Promise::Body::Scalar object' );
            is( $body2->as_string, $body->as_string, 'HTTP::Promise::Body::Scalar: content matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Body::Scalar test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $form = HTTP::Promise::Body::Form->new({
                name => 'John Doe',
                location => 'Tokyo',
            });
            $serial = $enc->encode( $form );
            my $form2  = $dec->decode( $serial );
            isa_ok( $form2 => ['HTTP::Promise::Body::Form'], 'deserialised element is a HTTP::Promise::Body::Form object' );
            is( $form2->{name}, $form->{name}, 'HTTP::Promise::Body::Form: item "name" matches' );
            is( $form2->{location}, $form->{location}, 'HTTP::Promise::Body::Form: item "name" matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Body::Form test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $form = HTTP::Promise::Body::Form::Data->new({
                name => 'John Doe',
                location => 'Tokyo',
            });
            $serial = $enc->encode( $form );
            my $form2  = $dec->decode( $serial );
            isa_ok( $form2 => ['HTTP::Promise::Body::Form::Data'], 'deserialised element is a HTTP::Promise::Body::Form::Data object' );
            is( $form2->{name}, $form->{name}, 'HTTP::Promise::Body::Form::Data: item "name" matches' );
            is( $form2->{location}, $form->{location}, 'HTTP::Promise::Body::Form::Data: item "name" matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Body::Form test for Sereal: $@" );
        }
    
        # try-catch
        local $@;
        eval
        {
            my $field = HTTP::Promise::Body::Form::Field->new(
                name => 'picture',
                file => '/some/where/image.png',
                headers => [ conten_type => 'image/png' ],
            );
            $serial = $enc->encode( $field );
            my $field2  = $dec->decode( $serial );
            isa_ok( $field2 => ['HTTP::Promise::Body::Form::Field'], 'deserialised element is a HTTP::Promise::Body::Form::Field object' );
            is( $field2->name => $field->name, 'HTTP::Promise::Body::Form::Field field name matches' );
            is( $field2->body->file => $field->body->file, 'HTTP::Promise::Body::Form::Field body filepath matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Body::Form::Field test for Sereal: $@" );
        }
    
        # try-catch
        local $@;
        eval
        {
            my $ent = HTTP::Promise::Entity->new;
            $serial = $enc->encode( $ent );
            my $ent2  = $dec->decode( $serial );
            isa_ok( $ent2 => ['HTTP::Promise::Entity'], 'deserialised element is a HTTP::Promise::Entity object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Entity test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $ex = HTTP::Promise::Exception->new( code => 400, message => 'Oops' );
            $serial = $enc->encode( $ex );
            my $ex2  = $dec->decode( $serial );
            isa_ok( $ex2 => ['HTTP::Promise::Exception'], 'deserialised element is a HTTP::Promise::Exception object' );
            is( $ex2->code, $ex->code, 'HTTP::Promise::Exception test value #1' );
            is( $ex2->message, $ex->message, 'HTTP::Promise::Exception test value #2' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Exception test for Sereal: $@" );
        }
    
        # try-catch
        local $@;
        eval
        {
            my $h = HTTP::Promise::Headers->new(
                Content_Type => 'text/html',
                Accept_Encoding => 'brotly,bgzip2,gzip,deflate',
                Accept_Language => 'fr-FR;q=0.7, en;q=0.6, ja-JP;q=0.5',
                Connection => 'close',
            );
            $serial = $enc->encode( $h );
            my $h2  = $dec->decode( $serial );
            diag( "Checking deserialised object '$h2'" ) if( $DEBUG );
            isa_ok( $h2 => ['HTTP::Promise::Headers'], 'deserialised element is a HTTP::Promise::Headers object' );
            is( $h2->header( 'Content-Type' ) => $h->header( 'Content-Type' ), 'HTTP::Promise::Headers field Content-Type matches' );
            is( $h2->header( 'Accept-Encoding' ) => $h->header( 'Accept-Encoding' ), 'HTTP::Promise::Headers field Accept-Encoding matches' );
            is( $h2->header( 'Accept-Language' ) => $h->header( 'Accept-Language' ), 'HTTP::Promise::Headers field Accept-Language matches' );
            is( $h2->header( 'Conection' ) => $h->header( 'Conection' ), 'HTTP::Promise::Headers field Conection matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers test for Sereal: $@" );
        }
    
        # try-catch
        local $@;
        eval
        {
            my $accept = HTTP::Promise::Headers::Accept->new( 'text/html, application/json, application/xml;q=0.9, */*;q=0.8' );
            $serial = $enc->encode( $accept );
            my $accept2  = $dec->decode( $serial );
            isa_ok( $accept2 => ['HTTP::Promise::Headers::Accept'], 'deserialised element is a HTTP::Promise::Headers::Accept object' );
            is( $accept2->as_string => $accept->as_string, 'HTTP::Promise::Headers::Accept string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::Accept test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $accept = HTTP::Promise::Headers::AcceptEncoding->new( 'deflate, gzip;q=1.0, *;q=0.5' );
            $serial = $enc->encode( $accept );
            my $accept2  = $dec->decode( $serial );
            isa_ok( $accept2 => ['HTTP::Promise::Headers::AcceptEncoding'], 'deserialised element is a HTTP::Promise::Headers::AcceptEncoding object' );
            is( "$accept2" => "$accept", 'HTTP::Promise::Headers::AcceptEncoding string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::AcceptEncoding test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $accept = HTTP::Promise::Headers::AcceptLanguage->new( 'fr-FR, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5' );
            $serial = $enc->encode( $accept );
            my $accept2  = $dec->decode( $serial );
            isa_ok( $accept2 => ['HTTP::Promise::Headers::AcceptLanguage'], 'deserialised element is a HTTP::Promise::Headers::AcceptLanguage object' );
            is( "$accept2" => "$accept", 'HTTP::Promise::Headers::AcceptLanguage string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::AcceptLanguage test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $alt = HTTP::Promise::Headers::AltSvc->new( q{h2="alt.example.com:443"} );
            $serial = $enc->encode( $alt );
            my $alt2  = $dec->decode( $serial );
            isa_ok( $alt2 => ['HTTP::Promise::Headers::AltSvc'], 'deserialised element is a HTTP::Promise::Headers::AltSvc object' );
            is( "$alt2" => "$alt", 'HTTP::Promise::Headers::AltSvc string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::AltSvc test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $cache = HTTP::Promise::Headers::CacheControl->new( 'max-age=604800' );
            $serial = $enc->encode( $cache );
            my $cache2  = $dec->decode( $serial );
            isa_ok( $cache2 => ['HTTP::Promise::Headers::CacheControl'], 'deserialised element is a HTTP::Promise::Headers::CacheControl object' );
            is( "$cache2" => "$cache", 'HTTP::Promise::Headers::CacheControl string matches' );
            is( $cache2->max_age => $cache->max_age, 'HTTP::Promise::Headers::CacheControl max_age matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::CacheControl test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $clear = HTTP::Promise::Headers::ClearSiteData->new( q{"cache", "cookies", "storage", "executionContexts"} );
            $serial = $enc->encode( $clear );
            my $clear2  = $dec->decode( $serial );
            isa_ok( $clear2 => ['HTTP::Promise::Headers::ClearSiteData'], 'deserialised element is a HTTP::Promise::Headers::ClearSiteData object' );
            is( "$clear2" => "$clear", 'HTTP::Promise::Headers::ClearSiteData string matches' );
            is( $clear2->cache => $clear->cache, 'HTTP::Promise::Headers::CacheControl cache matches' );
            is( $clear2->cookies => $clear->cookies, 'HTTP::Promise::Headers::CacheControl cookies matches' );
            is( $clear2->storage => $clear->storage, 'HTTP::Promise::Headers::CacheControl storage matches' );
            is( $clear2->execution_contexts => $clear->execution_contexts, 'HTTP::Promise::Headers::CacheControl execution_contexts matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ClearSiteData test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $dispo = HTTP::Promise::Headers::ContentDisposition->new( q{attachment; filename="filename.jpg"} );
            $serial = $enc->encode( $dispo );
            my $dispo2  = $dec->decode( $serial );
            isa_ok( $dispo2 => ['HTTP::Promise::Headers::ContentDisposition'], 'deserialised element is a HTTP::Promise::Headers::ContentDisposition object' );
            is( "$dispo2" => "$dispo", 'HTTP::Promise::Headers::ContentDisposition string matches' );
            is( $dispo2->disposition => $dispo->disposition, 'HTTP::Promise::Headers::ContentDisposition disposition matches' );
            is( $dispo2->filename => $dispo->filename, 'HTTP::Promise::Headers::ContentDisposition filename matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ContentDisposition test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $range = HTTP::Promise::Headers::ContentRange->new( 'bytes 200-1000/67589' );
            $serial = $enc->encode( $range );
            my $range2  = $dec->decode( $serial );
            isa_ok( $range2 => ['HTTP::Promise::Headers::ContentRange'], 'deserialised element is a HTTP::Promise::Headers::ContentRange object' );
            is( "$range2" => "$range", 'HTTP::Promise::Headers::ContentRange string matches' );
            is( $range2->range_start => $range->range_start, 'HTTP::Promise::Headers::ContentRange range_start matches' );
            is( $range2->range_end => $range->range_end, 'HTTP::Promise::Headers::ContentRange range_end matches' );
            is( $range2->size => $range->size, 'HTTP::Promise::Headers::ContentRange size matches' );
            is( $range2->unit => $range->unit, 'HTTP::Promise::Headers::ContentRange unit matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ContentRange test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $policy = HTTP::Promise::Headers::ContentSecurityPolicy->new( q{default-src 'self'; img-src *; media-src media1.com media2.com; script-src userscripts.example.com} );
            $serial = $enc->encode( $policy );
            my $policy2  = $dec->decode( $serial );
            isa_ok( $policy2 => ['HTTP::Promise::Headers::ContentSecurityPolicy'], 'deserialised element is a HTTP::Promise::Headers::ContentSecurityPolicy object' );
            is( "$policy2" => "$policy", 'HTTP::Promise::Headers::ContentSecurityPolicy string matches' );
            is( $policy2->default_src => $policy->default_src, 'HTTP::Promise::Headers::ContentSecurityPolicy default_src matches' );
            is( $policy2->img_src => $policy->img_src, 'HTTP::Promise::Headers::ContentSecurityPolicy img_src matches' );
            is( $policy2->media_src => $policy->media_src, 'HTTP::Promise::Headers::ContentSecurityPolicy media_src matches' );
            is( $policy2->script_src => $policy->script_src, 'HTTP::Promise::Headers::ContentSecurityPolicy script_src matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ContentSecurityPolicy test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $policy = HTTP::Promise::Headers::ContentSecurityPolicyReportOnly->new( q{default-src https:; report-uri /csp-violation-report-endpoint/} );
            $serial = $enc->encode( $policy );
            my $policy2  = $dec->decode( $serial );
            isa_ok( $policy2 => ['HTTP::Promise::Headers::ContentSecurityPolicyReportOnly'], 'deserialised element is a HTTP::Promise::Headers::ContentSecurityPolicyReportOnly object' );
            is( "$policy2" => "$policy", 'HTTP::Promise::Headers::ContentSecurityPolicyReportOnly string matches' );
            is( $policy2->default_src => $policy->default_src, 'HTTP::Promise::Headers::ContentSecurityPolicyReportOnly default_src matches' );
            is( $policy2->report_uri => $policy->report_uri, 'HTTP::Promise::Headers::ContentSecurityPolicyReportOnly report_uri matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ContentSecurityPolicyReportOnly test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $ct = HTTP::Promise::Headers::ContentType->new( q{text/html; charset=UTF-8} );
            $serial = $enc->encode( $ct );
            my $ct2  = $dec->decode( $serial );
            isa_ok( $ct2 => ['HTTP::Promise::Headers::ContentType'], 'deserialised element is a HTTP::Promise::Headers::ContentType object' );
            is( "$ct2" => "$ct", 'HTTP::Promise::Headers::ContentType string matches' );
            is( $ct2->type => $ct->type, 'HTTP::Promise::Headers::ContentType type matches' );
            is( $ct2->charset => $ct->charset, 'HTTP::Promise::Headers::ContentType charset matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ContentType test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $c = HTTP::Promise::Headers::Cookie->new( q{name=value; name2=value2; name3=value3} );
            $serial = $enc->encode( $c );
            my $c2  = $dec->decode( $serial );
            isa_ok( $c2 => ['HTTP::Promise::Headers::Cookie'], 'deserialised element is a HTTP::Promise::Headers::Cookie object' );
            is( "$c2" => "$c", 'HTTP::Promise::Headers::Cookie string matches' );
            my $cookies = $c->cookies;
            my $cookies2 = $c2->cookies;
            is( "@$cookies2" => "@$cookies", 'HTTP::Promise::Headers::Cookie cookies matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::Cookie test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::ExpectCT->new( q{max-age=86400, enforce, report-uri="https://foo.example.com/report"} );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::ExpectCT'], 'deserialised element is a HTTP::Promise::Headers::ExpectCT object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::ExpectCT string matches' );
            is( $o2->max_age => $o->max_age, 'HTTP::Promise::Headers::ExpectCT max_age matches' );
            is( $o2->enforce => $o->enforce, 'HTTP::Promise::Headers::ExpectCT enforce matches' );
            is( $o2->report_uri => $o->report_uri, 'HTTP::Promise::Headers::ExpectCT report_uri matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ExpectCT test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::Forwarded->new( q{for=192.0.2.60;proto=http;by=203.0.113.43} );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::Forwarded'], 'deserialised element is a HTTP::Promise::Headers::Forwarded object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::Forwarded string matches' );
            is( $o2->by => $o->by, 'HTTP::Promise::Headers::Forwarded by matches' );
            is( $o2->for => $o->for, 'HTTP::Promise::Headers::Forwarded for matches' );
            is( $o2->proto => $o->proto, 'HTTP::Promise::Headers::Forwarded proto matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::Forwarded test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::KeepAlive->new( q{timeout=5, max=1000} );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::KeepAlive'], 'deserialised element is a HTTP::Promise::Headers::KeepAlive object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::KeepAlive string matches' );
            is( $o2->max => $o->max, 'HTTP::Promise::Headers::KeepAlive max matches' );
            is( $o2->timeout => $o->timeout, 'HTTP::Promise::Headers::KeepAlive timeout matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::KeepAlive test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::Link->new( q{<https://example.com>; rel="preconnect"; title="Foo"; anchor="#bar"} );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::Link'], 'deserialised element is a HTTP::Promise::Headers::Link object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::Link string matches' );
            is( $o2->anchor => $o->anchor, 'HTTP::Promise::Headers::Link anchor matches' );
            is( $o2->rel => $o->rel, 'HTTP::Promise::Headers::Link rel matches' );
            is( $o2->link => $o->link, 'HTTP::Promise::Headers::Link link matches' );
            is( $o2->title => $o->title, 'HTTP::Promise::Headers::Link title matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::Link test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::Range->new( q{bytes=200-1000, 2000-6576, 19000-} );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::Range'], 'deserialised element is a HTTP::Promise::Headers::Range object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::Range string matches' );
            is( $o2->unit => $o->unit, 'HTTP::Promise::Headers::Range unit matches' );
            my $ranges = $o->ranges;
            my $ranges2 = $o2->ranges;
            SKIP:
            {
                skip( "original range and serialised range are not the same length.", 1 ) if( $ranges->length != $ranges2->length );
                for( my $i = 0; $i < $ranges->length; $i++ )
                {
                    my $r = $ranges->[$i];
                    my $r2 = $ranges2->[$i];
                    unless( isa_ok( $r2 => ['HTTP::Promise::Headers::Range::StartEnd'] ) )
                    {
                        next;
                    }
                    ok( ( ( $r->start == $r2->start ) && 
                          (
                            ( defined( $r->end ) && defined( $r2->end ) && ( $r->end == $r2->end ) ) ||
                            ( !defined( $r->end ) && !defined( $r2->end ) )
                          )
                        ), "No $i HTTP::Promise::Headers::Range::StartEnd objects match" );
                }
            };
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::Range test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::ServerTiming->new( q{cache;desc="Cache Read";dur=23.2} );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::ServerTiming'], 'deserialised element is a HTTP::Promise::Headers::ServerTiming object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::ServerTiming string matches' );
            is( $o2->desc => $o->desc, 'HTTP::Promise::Headers::ServerTiming desc matches' );
            is( $o2->dur => $o->dur, 'HTTP::Promise::Headers::ServerTiming dur matches' );
            is( $o2->name => $o->name, 'HTTP::Promise::Headers::ServerTiming name matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ServerTiming test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::StrictTransportSecurity->new( q{max-age=63072000; includeSubDomains; preload} );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::StrictTransportSecurity'], 'deserialised element is a HTTP::Promise::Headers::StrictTransportSecurity object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::StrictTransportSecurity string matches' );
            is( $o2->max_age => $o->max_age, 'HTTP::Promise::Headers::StrictTransportSecurity max_age matches' );
            is( $o2->preload => $o->preload, 'HTTP::Promise::Headers::StrictTransportSecurity preload matches' );
            is( $o2->include_subdomains => $o->include_subdomains, 'HTTP::Promise::Headers::StrictTransportSecurity include_subdomains matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::StrictTransportSecurity test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::TE->new( q{trailers, deflate;q=0.5} );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::TE'], 'deserialised element is a HTTP::Promise::Headers::TE object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::TE string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::TE test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::WantDigest->new( q{SHA-512;q=0.3, sha-256;q=1, md5;q=0} );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::WantDigest'], 'deserialised element is a HTTP::Promise::Headers::WantDigest object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::WantDigest string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::WantDigest test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $me = file( __FILE__ );
            my $fh = $me->open || die( "Unable to open $me: ", $me->error );
            my $o = HTTP::Promise::IO->new( $fh, debug => 2 ) || die( HTTP::Promise::IO->error );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::IO'], 'deserialised element is a HTTP::Promise::IO object' );
            is( $o2->debug => $o->debug, 'HTTP::Promise::IO debug value matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::IO test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::MIME->new || die( HTTP::Promise::IO->error );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::MIME'], 'deserialised element is a HHTTP::Promise::MIME object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::MIME test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Message->new(
                [ 'Content-Type' => 'text/plain' ],
                'Hello world',
            ) || die( HTTP::Promise::Message->error );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Message'], 'deserialised element is a HTTP::Promise::Message object' );
            is( $o2->headers->content_type => $o->headers->content_type, 'HTTP::Promise::Message content_type header value matches' );
            is( $o2->decoded_content => $o->decoded_content, 'HTTP::Promise::Message decoded_content value matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Message test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Parser->new || die( HTTP::Promise::Parser->error );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Parser'], 'deserialised element is a HTTP::Promise::Parser object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Parser test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Pool->new || die( HTTP::Promise::Pool->error );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Pool'], 'deserialised element is a HTTP::Promise::Pool object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Pool test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Request->new(
                GET => 'https://example.com/some/where',
                [
                Content_Type => 'text/html; charset=utf-8',
                ],
                'Hello world',
            ) || die( HTTP::Promise::Request->error );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Request'], 'deserialised element is a HTTP::Promise::Request object' );
            is( $o2->method => $o->method, 'HTTP::Promise::Request method value matches' );
            is( $o2->uri => $o->uri, 'HTTP::Promise::Request uri value matches' );
            is( $o2->headers->content_type => $o->headers->content_type, 'HTTP::Promise::Request content_type header value matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Request test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Response->new(
                200 => 'OK',
                [
                Cache_Control => 'no-cache, no-store',
                Content_Encoding => 'gzip',
                Content_Ttype => 'text/html; charset=utf-8',
                ],
                'Hello world',
            ) || die( HTTP::Promise::Response->error );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Response'], 'deserialised element is a HTTP::Promise::Response object' );
            is( $o2->code => $o->code, 'HTTP::Promise::Response method value matches' );
            is( $o2->status => $o->status, 'HTTP::Promise::Response uri value matches' );
            is( $o2->headers->content_type => $o->headers->content_type, 'HTTP::Promise::Response Content-Type header value matches' );
            is( $o2->headers->cache_control => 'no-cache, no-store', 'HTTP::Promise::Response Cache-Control header value matches' );
            is( $o2->headers->content_encoding => 'gzip', 'HTTP::Promise::Response Content-Ttype header value matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Response test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Status->new || die( HTTP::Promise::Status->error );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Status'], 'deserialised element is a HTTP::Promise::Status object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Status test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Stream->new( __FILE__ ) || die( HTTP::Promise::Stream->error );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Stream'], 'deserialised element is a HTTP::Promise::Stream object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Stream test for Sereal: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Stream::Base64->new || die( HTTP::Promise::Stream::Base64->error );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Stream::Base64'], 'deserialised element is a HTTP::Promise::Stream::Base64 object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Stream::Base64 test for Sereal: $@" );
        }
    
        SKIP:
        {
            eval( "use IO::Compress::Brotli; use IO::Uncompress::Brotli;" );
            skip( "IO::Compress::Brotli or IO::Uncompress::Brotli is not installed on your system.", 1 ) if( $@ );
            # try-catch
            local $@;
            eval
            {
                my $o = HTTP::Promise::Stream::Brotli->new || die( HTTP::Promise::Stream::Brotli->error );
                $serial = $enc->encode( $o );
                my $o2  = $dec->decode( $serial );
                isa_ok( $o2 => ['HTTP::Promise::Stream::Brotli'], 'deserialised element is a HTTP::Promise::Stream::Brotli object' );
            };
            if( $@ )
            {
                fail( "Failed HTTP::Promise::Stream::Brotli test for Sereal: $@" );
            }
        };

        SKIP:
        {
            eval( "use Compress::LZW;" );
            skip( "Compress::LZW is not installed on your system.", 1 ) if( $@ );
            # try-catch
            local $@;
            eval
            {
                my $o = HTTP::Promise::Stream::LZW->new || die( HTTP::Promise::Stream::LZW->error );
                $serial = $enc->encode( $o );
                my $o2  = $dec->decode( $serial );
                isa_ok( $o2 => ['HTTP::Promise::Stream::LZW'], 'deserialised element is a HTTP::Promise::Stream::LZW object' );
            };
            if( $@ )
            {
                fail( "Failed HTTP::Promise::Stream::LZW test for Sereal: $@" );
            }
        };

        SKIP:
        {
            eval( "use MIME::QuotedPrint;" );
            skip( "MIME::QuotedPrint is not installed on your system.", 1 ) if( $@ );
            # try-catch
            local $@;
            eval
            {
                my $o = HTTP::Promise::Stream::QuotedPrint->new || die( HTTP::Promise::Stream::QuotedPrint->error );
                $serial = $enc->encode( $o );
                my $o2  = $dec->decode( $serial );
                isa_ok( $o2 => ['HTTP::Promise::Stream::QuotedPrint'], 'deserialised element is a HTTP::Promise::Stream::QuotedPrint object' );
            };
            if( $@ )
            {
                fail( "Failed HTTP::Promise::Stream::QuotedPrint test for Sereal: $@" );
            }
        };

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Stream::UU->new || die( HTTP::Promise::Stream::UU->error );
            $serial = $enc->encode( $o );
            my $o2  = $dec->decode( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Stream::UU'], 'deserialised element is a HTTP::Promise::Stream::UU object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Stream::UU test for Sereal: $@" );
        }
    };
};

# NOTE: Storable
subtest 'Storable' => sub
{
    SKIP:
    {
        skip( "Storable::Improved is not installed. Skipping Storable related tests.", 1 ) if( !$HAS_STORABLE );
        note( "Processing tests for Storable" );
        # $Storable::forgive_me = 1;
        my $serial;
        # try-catch
        local $@;
        eval
        {
            my $body = HTTP::Promise::Body::File->new( '/some/where/file.txt' );
            $serial = Storable::Improved::freeze( $body );
            my $body2  = Storable::Improved::thaw( $serial );
            isa_ok( $body2 => ['HTTP::Promise::Body::File'], 'deserialised element is a HTTP::Promise::Body::File object' );
            is( $body2->filepath, $body->filepath, 'HTTP::Promise::Body::File: filepath matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Body::File test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $body = HTTP::Promise::Body::Scalar->new( 'Some data' );
            $serial = Storable::Improved::freeze( $body );
            my $body2  = Storable::Improved::thaw( $serial );
            isa_ok( $body2 => ['HTTP::Promise::Body::Scalar'], 'deserialised element is a HTTP::Promise::Body::Scalar object' );
            is( $body2->as_string, $body->as_string, 'HTTP::Promise::Body::Scalar: content matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Body::Scalar test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $form = HTTP::Promise::Body::Form->new({
                name => 'John Doe',
                location => 'Tokyo',
            });
            $serial = Storable::Improved::freeze( $form );
            my $form2  = Storable::Improved::thaw( $serial );
            isa_ok( $form2 => ['HTTP::Promise::Body::Form'], 'deserialised element is a HTTP::Promise::Body::Form object' );
            is( $form2->{name}, $form->{name}, 'HTTP::Promise::Body::Form: item "name" matches' );
            is( $form2->{location}, $form->{location}, 'HTTP::Promise::Body::Form: item "name" matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Body::Form test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $form = HTTP::Promise::Body::Form::Data->new({
                name => 'John Doe',
                location => 'Tokyo',
            });
            $serial = Storable::Improved::freeze( $form );
            my $form2  = Storable::Improved::thaw( $serial );
            isa_ok( $form2 => ['HTTP::Promise::Body::Form::Data'], 'deserialised element is a HTTP::Promise::Body::Form::Data object' );
            is( $form2->{name}, $form->{name}, 'HTTP::Promise::Body::Form::Data: item "name" matches' );
            is( $form2->{location}, $form->{location}, 'HTTP::Promise::Body::Form::Data: item "name" matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Body::Form test for Storable: $@" );
        }
    
        # try-catch
        local $@;
        eval
        {
            my $field = HTTP::Promise::Body::Form::Field->new(
                name => 'picture',
                file => '/some/where/image.png',
                headers => [ conten_type => 'image/png' ],
            );
            $serial = Storable::Improved::freeze( $field );
            my $field2  = Storable::Improved::thaw( $serial );
            isa_ok( $field2 => ['HTTP::Promise::Body::Form::Field'], 'deserialised element is a HTTP::Promise::Body::Form::Field object' );
            is( $field2->name => $field->name, 'HTTP::Promise::Body::Form::Field field name matches' );
            is( $field2->body->file => $field->body->file, 'HTTP::Promise::Body::Form::Field body filepath matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Body::Form::Field test for Storable: $@" );
        }
    
        # try-catch
        local $@;
        eval
        {
            my $ent = HTTP::Promise::Entity->new;
            $serial = Storable::Improved::freeze( $ent );
            my $ent2  = Storable::Improved::thaw( $serial );
            isa_ok( $ent2 => ['HTTP::Promise::Entity'], 'deserialised element is a HTTP::Promise::Entity object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Entity test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $ex = HTTP::Promise::Exception->new( code => 400, message => 'Oops' );
            $serial = Storable::Improved::freeze( $ex );
            my $ex2  = Storable::Improved::thaw( $serial );
            isa_ok( $ex2 => ['HTTP::Promise::Exception'], 'deserialised element is a HTTP::Promise::Exception object' );
            is( $ex2->code, $ex->code, 'HTTP::Promise::Exception test value #1' );
            is( $ex2->message, $ex->message, 'HTTP::Promise::Exception test value #2' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Exception test for Storable: $@" );
        }
    
        # try-catch
        local $@;
        eval
        {
            my $h = HTTP::Promise::Headers->new(
                Content_Type => 'text/html',
                Accept_Encoding => 'brotly,bgzip2,gzip,deflate',
                Accept_Language => 'fr-FR;q=0.7, en;q=0.6, ja-JP;q=0.5',
                Connection => 'close',
            );
            $serial = Storable::Improved::freeze( $h );
            my $h2  = Storable::Improved::thaw( $serial );
            diag( "Storable::Improved::thaw returned: $h2" ) if( $DEBUG );
            diag( "Checking deserialised object '$h2'" ) if( $DEBUG );
            isa_ok( $h2 => ['HTTP::Promise::Headers'], 'deserialised element is a HTTP::Promise::Headers object' );
            if( $DEBUG )
            {
                diag( "Comparing $h2 against original $h" );
                diag( "Is $h2 an HTTP::Promise::Headers object?" );
                diag( $h2->isa( 'HTTP::Promise::Headers' ) ? "Yes it is" : "No, it is not." );
                diag( "Is $h2 an HTTP::XSHeaders object?" );
                diag( $h2->isa( 'HTTP::XSHeaders' ) ? "Yes it is" : "No, it is not." );
                diag( "Is $h an HTTP::Promise::Headers object?" );
                diag( $h->isa( 'HTTP::Promise::Headers' ) ? "Yes it is" : "No, it is not." );
                diag( "\$h2->header( 'Content-Type' ) value is:" );
                diag( "'", $h2->header( 'Content-Type' ), "'" );
                diag( "\$h->header( 'Content-Type' ) value is:" );
                diag( "'", $h->header( 'Content-Type' ), "'" );
            }
            is( $h2->header( 'Content-Type' ) => $h->header( 'Content-Type' ), 'HTTP::Promise::Headers field Content-Type matches' );
            is( $h2->header( 'Accept-Encoding' ) => $h->header( 'Accept-Encoding' ), 'HTTP::Promise::Headers field Accept-Encoding matches' );
            is( $h2->header( 'Accept-Language' ) => $h->header( 'Accept-Language' ), 'HTTP::Promise::Headers field Accept-Language matches' );
            is( $h2->header( 'Conection' ) => $h->header( 'Conection' ), 'HTTP::Promise::Headers field Conection matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers test for Storable: $@" );
        }
    
        # try-catch
        local $@;
        eval
        {
            my $accept = HTTP::Promise::Headers::Accept->new( 'text/html, application/json, application/xml;q=0.9, */*;q=0.8' );
            $serial = Storable::Improved::freeze( $accept );
            my $accept2  = Storable::Improved::thaw( $serial );
            isa_ok( $accept2 => ['HTTP::Promise::Headers::Accept'], 'deserialised element is a HTTP::Promise::Headers::Accept object' );
            is( $accept2->as_string => $accept->as_string, 'HTTP::Promise::Headers::Accept string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::Accept test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $accept = HTTP::Promise::Headers::AcceptEncoding->new( 'deflate, gzip;q=1.0, *;q=0.5' );
            $serial = Storable::Improved::freeze( $accept );
            my $accept2  = Storable::Improved::thaw( $serial );
            isa_ok( $accept2 => ['HTTP::Promise::Headers::AcceptEncoding'], 'deserialised element is a HTTP::Promise::Headers::AcceptEncoding object' );
            is( "$accept2" => "$accept", 'HTTP::Promise::Headers::AcceptEncoding string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::AcceptEncoding test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $accept = HTTP::Promise::Headers::AcceptLanguage->new( 'fr-FR, fr;q=0.9, en;q=0.8, de;q=0.7, *;q=0.5' );
            $serial = Storable::Improved::freeze( $accept );
            my $accept2  = Storable::Improved::thaw( $serial );
            isa_ok( $accept2 => ['HTTP::Promise::Headers::AcceptLanguage'], 'deserialised element is a HTTP::Promise::Headers::AcceptLanguage object' );
            is( "$accept2" => "$accept", 'HTTP::Promise::Headers::AcceptLanguage string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::AcceptLanguage test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $alt = HTTP::Promise::Headers::AltSvc->new( q{h2="alt.example.com:443"} );
            $serial = Storable::Improved::freeze( $alt );
            my $alt2  = Storable::Improved::thaw( $serial );
            isa_ok( $alt2 => ['HTTP::Promise::Headers::AltSvc'], 'deserialised element is a HTTP::Promise::Headers::AltSvc object' );
            is( "$alt2" => "$alt", 'HTTP::Promise::Headers::AltSvc string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::AltSvc test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $cache = HTTP::Promise::Headers::CacheControl->new( 'max-age=604800' );
            $serial = Storable::Improved::freeze( $cache );
            my $cache2  = Storable::Improved::thaw( $serial );
            isa_ok( $cache2 => ['HTTP::Promise::Headers::CacheControl'], 'deserialised element is a HTTP::Promise::Headers::CacheControl object' );
            is( "$cache2" => "$cache", 'HTTP::Promise::Headers::CacheControl string matches' );
            is( $cache2->max_age => $cache->max_age, 'HTTP::Promise::Headers::CacheControl max_age matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::CacheControl test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $clear = HTTP::Promise::Headers::ClearSiteData->new( q{"cache", "cookies", "storage", "executionContexts"} );
            $serial = Storable::Improved::freeze( $clear );
            my $clear2  = Storable::Improved::thaw( $serial );
            isa_ok( $clear2 => ['HTTP::Promise::Headers::ClearSiteData'], 'deserialised element is a HTTP::Promise::Headers::ClearSiteData object' );
            is( "$clear2" => "$clear", 'HTTP::Promise::Headers::ClearSiteData string matches' );
            is( $clear2->cache => $clear->cache, 'HTTP::Promise::Headers::CacheControl cache matches' );
            is( $clear2->cookies => $clear->cookies, 'HTTP::Promise::Headers::CacheControl cookies matches' );
            is( $clear2->storage => $clear->storage, 'HTTP::Promise::Headers::CacheControl storage matches' );
            is( $clear2->execution_contexts => $clear->execution_contexts, 'HTTP::Promise::Headers::CacheControl execution_contexts matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ClearSiteData test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $dispo = HTTP::Promise::Headers::ContentDisposition->new( q{attachment; filename="filename.jpg"} );
            $serial = Storable::Improved::freeze( $dispo );
            my $dispo2  = Storable::Improved::thaw( $serial );
            isa_ok( $dispo2 => ['HTTP::Promise::Headers::ContentDisposition'], 'deserialised element is a HTTP::Promise::Headers::ContentDisposition object' );
            is( "$dispo2" => "$dispo", 'HTTP::Promise::Headers::ContentDisposition string matches' );
            is( $dispo2->disposition => $dispo->disposition, 'HTTP::Promise::Headers::ContentDisposition disposition matches' );
            is( $dispo2->filename => $dispo->filename, 'HTTP::Promise::Headers::ContentDisposition filename matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ContentDisposition test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $range = HTTP::Promise::Headers::ContentRange->new( 'bytes 200-1000/67589' );
            $serial = Storable::Improved::freeze( $range );
            my $range2  = Storable::Improved::thaw( $serial );
            isa_ok( $range2 => ['HTTP::Promise::Headers::ContentRange'], 'deserialised element is a HTTP::Promise::Headers::ContentRange object' );
            is( "$range2" => "$range", 'HTTP::Promise::Headers::ContentRange string matches' );

            is( $range2->range_start => $range->range_start, 'HTTP::Promise::Headers::ContentRange range_start matches' );
            is( $range2->range_end => $range->range_end, 'HTTP::Promise::Headers::ContentRange range_end matches' );
            is( $range2->size => $range->size, 'HTTP::Promise::Headers::ContentRange size matches' );
            is( $range2->unit => $range->unit, 'HTTP::Promise::Headers::ContentRange unit matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ContentRange test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $policy = HTTP::Promise::Headers::ContentSecurityPolicy->new( q{default-src 'self'; img-src *; media-src media1.com media2.com; script-src userscripts.example.com} );
            $serial = Storable::Improved::freeze( $policy );
            my $policy2  = Storable::Improved::thaw( $serial );
            isa_ok( $policy2 => ['HTTP::Promise::Headers::ContentSecurityPolicy'], 'deserialised element is a HTTP::Promise::Headers::ContentSecurityPolicy object' );
            is( "$policy2" => "$policy", 'HTTP::Promise::Headers::ContentSecurityPolicy string matches' );
            is( $policy2->default_src => $policy->default_src, 'HTTP::Promise::Headers::ContentSecurityPolicy default_src matches' );
            is( $policy2->img_src => $policy->img_src, 'HTTP::Promise::Headers::ContentSecurityPolicy img_src matches' );
            is( $policy2->media_src => $policy->media_src, 'HTTP::Promise::Headers::ContentSecurityPolicy media_src matches' );
            is( $policy2->script_src => $policy->script_src, 'HTTP::Promise::Headers::ContentSecurityPolicy script_src matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ContentSecurityPolicy test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $policy = HTTP::Promise::Headers::ContentSecurityPolicyReportOnly->new( q{default-src https:; report-uri /csp-violation-report-endpoint/} );
            $serial = Storable::Improved::freeze( $policy );
            my $policy2  = Storable::Improved::thaw( $serial );
            isa_ok( $policy2 => ['HTTP::Promise::Headers::ContentSecurityPolicyReportOnly'], 'deserialised element is a HTTP::Promise::Headers::ContentSecurityPolicyReportOnly object' );
            is( "$policy2" => "$policy", 'HTTP::Promise::Headers::ContentSecurityPolicyReportOnly string matches' );
            is( $policy2->default_src => $policy->default_src, 'HTTP::Promise::Headers::ContentSecurityPolicyReportOnly default_src matches' );
            is( $policy2->report_uri => $policy->report_uri, 'HTTP::Promise::Headers::ContentSecurityPolicyReportOnly report_uri matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ContentSecurityPolicyReportOnly test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $ct = HTTP::Promise::Headers::ContentType->new( q{text/html; charset=UTF-8} );
            $serial = Storable::Improved::freeze( $ct );
            my $ct2  = Storable::Improved::thaw( $serial );
            isa_ok( $ct2 => ['HTTP::Promise::Headers::ContentType'], 'deserialised element is a HTTP::Promise::Headers::ContentType object' );
            is( "$ct2" => "$ct", 'HTTP::Promise::Headers::ContentType string matches' );
            is( $ct2->type => $ct->type, 'HTTP::Promise::Headers::ContentType type matches' );
            is( $ct2->charset => $ct->charset, 'HTTP::Promise::Headers::ContentType charset matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ContentType test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $c = HTTP::Promise::Headers::Cookie->new( q{name=value; name2=value2; name3=value3} );
            $serial = Storable::Improved::freeze( $c );
            my $c2  = Storable::Improved::thaw( $serial );
            isa_ok( $c2 => ['HTTP::Promise::Headers::Cookie'], 'deserialised element is a HTTP::Promise::Headers::Cookie object' );
            is( "$c2" => "$c", 'HTTP::Promise::Headers::Cookie string matches' );
            my $cookies = $c->cookies;
            my $cookies2 = $c2->cookies;
            is( "@$cookies2" => "@$cookies", 'HTTP::Promise::Headers::Cookie cookies matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::Cookie test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::ExpectCT->new( q{max-age=86400, enforce, report-uri="https://foo.example.com/report"} );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::ExpectCT'], 'deserialised element is a HTTP::Promise::Headers::ExpectCT object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::ExpectCT string matches' );
            is( $o2->max_age => $o->max_age, 'HTTP::Promise::Headers::ExpectCT max_age matches' );
            is( $o2->enforce => $o->enforce, 'HTTP::Promise::Headers::ExpectCT enforce matches' );
            is( $o2->report_uri => $o->report_uri, 'HTTP::Promise::Headers::ExpectCT report_uri matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ExpectCT test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::Forwarded->new( q{for=192.0.2.60;proto=http;by=203.0.113.43} );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::Forwarded'], 'deserialised element is a HTTP::Promise::Headers::Forwarded object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::Forwarded string matches' );
            is( $o2->by => $o->by, 'HTTP::Promise::Headers::Forwarded by matches' );
            is( $o2->for => $o->for, 'HTTP::Promise::Headers::Forwarded for matches' );
            is( $o2->proto => $o->proto, 'HTTP::Promise::Headers::Forwarded proto matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::Forwarded test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::KeepAlive->new( q{timeout=5, max=1000} );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::KeepAlive'], 'deserialised element is a HTTP::Promise::Headers::KeepAlive object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::KeepAlive string matches' );
            is( $o2->max => $o->max, 'HTTP::Promise::Headers::KeepAlive max matches' );
            is( $o2->timeout => $o->timeout, 'HTTP::Promise::Headers::KeepAlive timeout matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::KeepAlive test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::Link->new( q{<https://example.com>; rel="preconnect"; title="Foo"; anchor="#bar"} );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::Link'], 'deserialised element is a HTTP::Promise::Headers::Link object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::Link string matches' );
            is( $o2->anchor => $o->anchor, 'HTTP::Promise::Headers::Link anchor matches' );
            is( $o2->rel => $o->rel, 'HTTP::Promise::Headers::Link rel matches' );
            is( $o2->link => $o->link, 'HTTP::Promise::Headers::Link link matches' );
            is( $o2->title => $o->title, 'HTTP::Promise::Headers::Link title matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::Link test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::Range->new( q{bytes=200-1000, 2000-6576, 19000-} );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::Range'], 'deserialised element is a HTTP::Promise::Headers::Range object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::Range string matches' );
            is( $o2->unit => $o->unit, 'HTTP::Promise::Headers::Range unit matches' );
            my $ranges = $o->ranges;
            my $ranges2 = $o2->ranges;
            SKIP:
            {
                skip( "original range and serialised range are not the same length.", 1 ) if( $ranges->length != $ranges2->length );
                for( my $i = 0; $i < $ranges->length; $i++ )
                {
                    my $r = $ranges->[$i];
                    my $r2 = $ranges2->[$i];
                    unless( isa_ok( $r2 => ['HTTP::Promise::Headers::Range::StartEnd'] ) )
                    {
                        next;
                    }
                    ok( ( ( $r->start == $r2->start ) && 
                          (
                            ( defined( $r->end ) && defined( $r2->end ) && ( $r->end == $r2->end ) ) ||
                            ( !defined( $r->end ) && !defined( $r2->end ) )
                          )
                        ), "No $i HTTP::Promise::Headers::Range::StartEnd objects match" );
                }
            };
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::Range test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::ServerTiming->new( q{cache;desc="Cache Read";dur=23.2} );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::ServerTiming'], 'deserialised element is a HTTP::Promise::Headers::ServerTiming object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::ServerTiming string matches' );
            is( $o2->desc => $o->desc, 'HTTP::Promise::Headers::ServerTiming desc matches' );
            is( $o2->dur => $o->dur, 'HTTP::Promise::Headers::ServerTiming dur matches' );
            is( $o2->name => $o->name, 'HTTP::Promise::Headers::ServerTiming name matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::ServerTiming test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::StrictTransportSecurity->new( q{max-age=63072000; includeSubDomains; preload} );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::StrictTransportSecurity'], 'deserialised element is a HTTP::Promise::Headers::StrictTransportSecurity object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::StrictTransportSecurity string matches' );
            is( $o2->max_age => $o->max_age, 'HTTP::Promise::Headers::StrictTransportSecurity max_age matches' );
            is( $o2->preload => $o->preload, 'HTTP::Promise::Headers::StrictTransportSecurity preload matches' );
            is( $o2->include_subdomains => $o->include_subdomains, 'HTTP::Promise::Headers::StrictTransportSecurity include_subdomains matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::StrictTransportSecurity test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::TE->new( q{trailers, deflate;q=0.5} );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::TE'], 'deserialised element is a HTTP::Promise::Headers::TE object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::TE string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::TE test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Headers::WantDigest->new( q{SHA-512;q=0.3, sha-256;q=1, md5;q=0} );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Headers::WantDigest'], 'deserialised element is a HTTP::Promise::Headers::WantDigest object' );
            is( "$o2" => "$o", 'HTTP::Promise::Headers::WantDigest string matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Headers::WantDigest test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $me = file( __FILE__ );
            my $fh = $me->open || die( "Unable to open $me: ", $me->error );
            my $o = HTTP::Promise::IO->new( $fh, debug => 2 ) || die( HTTP::Promise::IO->error );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::IO'], 'deserialised element is a HTTP::Promise::IO object' );
            is( $o2->debug => $o->debug, 'HTTP::Promise::IO debug value matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::IO test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::MIME->new || die( HTTP::Promise::IO->error );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::MIME'], 'deserialised element is a HHTTP::Promise::MIME object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::MIME test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Message->new(
                [ 'Content-Type' => 'text/plain' ],
                'Hello world',
            ) || die( HTTP::Promise::Message->error );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            diag( "Checking if deserialised object '$o2' is an HTTP::Promise::Message object." ) if( $DEBUG );
            isa_ok( $o2 => ['HTTP::Promise::Message'], 'deserialised element is a HTTP::Promise::Message object' );
            is( $o2->headers->content_type => $o->headers->content_type, 'HTTP::Promise::Message content_type header value matches' );
            is( $o2->decoded_content => $o->decoded_content, 'HTTP::Promise::Message decoded_content value matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Message test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Parser->new || die( HTTP::Promise::Parser->error );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Parser'], 'deserialised element is a HTTP::Promise::Parser object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Parser test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Pool->new || die( HTTP::Promise::Pool->error );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Pool'], 'deserialised element is a HTTP::Promise::Pool object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Pool test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Request->new(
                GET => 'https://example.com/some/where',
                [
                Content_Type => 'text/html; charset=utf-8',
                ],
                'Hello world',
            ) || die( HTTP::Promise::Request->error );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Request'], 'deserialised element is a HTTP::Promise::Request object' );
            is( $o2->method => $o->method, 'HTTP::Promise::Request method value matches' );
            is( $o2->uri => $o->uri, 'HTTP::Promise::Request uri value matches' );
            is( $o2->headers->content_type => $o->headers->content_type, 'HTTP::Promise::Request content_type header value matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Request test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Response->new(
                200 => 'OK',
                [
                Cache_Control => 'no-cache, no-store',
                Content_Encoding => 'gzip',
                Content_Ttype => 'text/html; charset=utf-8',
                ],
                'Hello world',
            ) || die( HTTP::Promise::Response->error );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Response'], 'deserialised element is a HTTP::Promise::Response object' );
            is( $o2->code => $o->code, 'HTTP::Promise::Response method value matches' );
            is( $o2->status => $o->status, 'HTTP::Promise::Response uri value matches' );
            is( $o2->headers->content_type => $o->headers->content_type, 'HTTP::Promise::Response Content-Type header value matches' );
            is( $o2->headers->cache_control => 'no-cache, no-store', 'HTTP::Promise::Response Cache-Control header value matches' );
            is( $o2->headers->content_encoding => 'gzip', 'HTTP::Promise::Response Content-Ttype header value matches' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Response test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Status->new || die( HTTP::Promise::Status->error );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Status'], 'deserialised element is a HTTP::Promise::Status object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Status test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Stream->new( __FILE__ ) || die( HTTP::Promise::Stream->error );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Stream'], 'deserialised element is a HTTP::Promise::Stream object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Stream test for Storable: $@" );
        }

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Stream::Base64->new || die( HTTP::Promise::Stream::Base64->error );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Stream::Base64'], 'deserialised element is a HTTP::Promise::Stream::Base64 object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Stream::Base64 test for Storable: $@" );
        }
    
        SKIP:
        {
            eval( "use IO::Compress::Brotli; use IO::Uncompress::Brotli;" );
            skip( "IO::Compress::Brotli or IO::Uncompress::Brotli is not installed on your system.", 1 ) if( $@ );
            # try-catch
            local $@;
            eval
            {
                my $o = HTTP::Promise::Stream::Brotli->new || die( HTTP::Promise::Stream::Brotli->error );
                $serial = Storable::Improved::freeze( $o );
                my $o2  = Storable::Improved::thaw( $serial );
                isa_ok( $o2 => ['HTTP::Promise::Stream::Brotli'], 'deserialised element is a HTTP::Promise::Stream::Brotli object' );
            };
            if( $@ )
            {
                fail( "Failed HTTP::Promise::Stream::Brotli test for Storable: $@" );
            }
        };

        SKIP:
        {
            eval( "use Compress::LZW;" );
            skip( "Compress::LZW is not installed on your system.", 1 ) if( $@ );
            # try-catch
            local $@;
            eval
            {
                my $o = HTTP::Promise::Stream::LZW->new || die( HTTP::Promise::Stream::LZW->error );
                $serial = Storable::Improved::freeze( $o );
                my $o2  = Storable::Improved::thaw( $serial );
                isa_ok( $o2 => ['HTTP::Promise::Stream::LZW'], 'deserialised element is a HTTP::Promise::Stream::LZW object' );
            };
            if( $@ )
            {
                fail( "Failed HTTP::Promise::Stream::LZW test for Storable: $@" );
            }
        };

        SKIP:
        {
            eval( "use MIME::QuotedPrint;" );
            skip( "MIME::QuotedPrint is not installed on your system.", 1 ) if( $@ );
            # try-catch
            local $@;
            eval
            {
                my $o = HTTP::Promise::Stream::QuotedPrint->new || die( HTTP::Promise::Stream::QuotedPrint->error );
                $serial = Storable::Improved::freeze( $o );
                my $o2  = Storable::Improved::thaw( $serial );
                isa_ok( $o2 => ['HTTP::Promise::Stream::QuotedPrint'], 'deserialised element is a HTTP::Promise::Stream::QuotedPrint object' );
            };
            if( $@ )
            {
                fail( "Failed HTTP::Promise::Stream::QuotedPrint test for Storable: $@" );
            }
        };

        # try-catch
        local $@;
        eval
        {
            my $o = HTTP::Promise::Stream::UU->new || die( HTTP::Promise::Stream::UU->error );
            $serial = Storable::Improved::freeze( $o );
            my $o2  = Storable::Improved::thaw( $serial );
            isa_ok( $o2 => ['HTTP::Promise::Stream::UU'], 'deserialised element is a HTTP::Promise::Stream::UU object' );
        };
        if( $@ )
        {
            fail( "Failed HTTP::Promise::Stream::UU test for Storable: $@" );
        }
    };
};

done_testing();

__END__

