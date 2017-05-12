#!/usr/bin/perl
use strict;
use warnings;
use HTTP::Proxy::Builder;
use HTTP::Proxy::HeaderFilter::simple;

# the anonymising filter
$proxy->push_filter(
    mime    => undef,
    request => HTTP::Proxy::HeaderFilter::simple->new(
        sub {
            $_[1]->remove_header(
                qw( User-Agent From Referer Cookie Cookie2 ) );
        }
    ),
    response => HTTP::Proxy::HeaderFilter::simple->new(
        sub { $_[1]->remove_header(qw( Set-Cookie Set-Cookie2 )) }
    )
);

