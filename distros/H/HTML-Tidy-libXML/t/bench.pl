#!/usr/local/bin/perl
use strict;
use warnings;
use HTML::Tidy;
use HTML::Tidy::LibXML;
use Benchmark qw/cmpthese timethese/;

my $tidy = HTML::Tidy->new(
    {
        @_,
        doctype          => 'omit',    # important for speed!
        indent           => 0,
        numeric_entities => 1,
        output_xhtml     => 1,
        tidy_mark        => 0,
        wrap             => 0,
    }
);
my $tidy_xml = HTML::Tidy::libXML->new();

require LWP::UserAgent;
require HTTP::Response::Encoding;
my $uri = shift || die;
my $res = LWP::UserAgent->new->get($uri);
die $res->status_line unless $res->is_success;
my ( $html, $enc ) = ( $res->content, $res->encoding );

cmpthese(
    timethese(
        0,
        {
            'H::T' => sub { $tidy->clean($html) },
            'H::T::LibXML(0)' => sub { $tidy_xml->clean( $html, $enc, 0 ) },
            'H::T::LibXML(1)' => sub { $tidy_xml->clean( $html, $enc, 1 ) }
        }
    )
);
