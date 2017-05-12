#!/usr/bin/perl

# Copyright (C) 2004  Joshua Hoblitt
#
# $Id: get.pl,v 1.1.1.1 2004/07/18 07:12:55 jhoblitt Exp $

use strict;
use warnings;

use lib "../lib/";

require HTTP::Range;
require HTTP::Request;
require LWP::UserAgent;
require LWP::Parallel::UserAgent;
use File::Basename qw( basename );

my $url = shift;
my $segments = 2;

my $head_request = HTTP::Request->new( HEAD => $url );
my $head_response = LWP::UserAgent->new->request( $head_request );
my $get_request = HTTP::Request->new( GET => $head_request->uri );

my @requests = HTTP::Range->split(
        request     => $get_request,
        length      => $head_response->header( 'Content-Length' ),
        segments    => $segments,
    );

my $pua = LWP::Parallel::UserAgent->new;
$pua->register( $_ ) foreach @requests;
my $entries = $pua->wait;
my @responses;
push( @responses, $entries->{ $_ }->response ) foreach keys %$entries;

my $res = HTTP::Range->join(
        responses   => \@responses,
        length      => $head_response->header( 'Content-Length' ),
        segments    => $segments,
    );

my $filename = basename( $res->base->path );
$filename = $filename || "index.html";

open( FILE, ">$filename" ) || die "can't open file: $!";
print FILE $res->content;
close( FILE ) || die "can't close file: $!";

print "saved as: $filename\n";
