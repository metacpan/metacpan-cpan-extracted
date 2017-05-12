#!/usr/bin/perl -T
#
# usage: lighfile.cgi?f='somefile_or_url';q='some words to highlight'

use strict;
use warnings;
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser);
use File::Spec;
use HTML::HiLiter;

print header();

my $f       = param('f');
my (@q)     = param('q');
my $q       = url_enc( join ' and ', @q );    # for tagfilter()
my $docroot = '/your/document/root/here';     # prepend if local doc
my $url     = url();                          # self-reference for tagfilter()
my $burl    = url( -base => 1 );
my ($basedir) = ( $f =~ m!(.*)/! );

$f = File::Spec->catfile( $docroot, $f ) unless $f =~ m!^http://!;

my $hl = HTML::HiLiter->new(
    tag_filter => \&tagfilter,
    query      => $q
);

$hl->run($f);

#print "<p><pre>". $hl->Report . "</pre></p>";

sub url_enc {

    # filters in place and also returns
    $_[0] =~ s/([^a-zA-Z0-9_.%;&?\/\\:+=~-])/sprintf("%%%02X",ord($1))/oeg;
    return $_[0];

}

sub tagfilter {

    # alter tag attributes to preserve links and img src
    my ( $parserobj, $tag, $tagname, $offset, $length, $offset_end, $attr,
        $text )
        = @_;

    my ( $newtext, $newtag, $newattr );

    $newtext = $text;

    return $newtext if $tag =~ m!^/!;

    $newtag  = "<$tag";
    $newattr = '';

    if ( exists $attr->{href} ) {

        if ( $attr->{href} =~ m!^$burl! ) {

            # external links should open in new window
            $attr->{target} = '_blank';
        }

        unless ( $attr->{href} =~ m!^(/|#)! ) {

            # all other links should point back here
            # for recursive highlighting
            my $l = $attr->{href};

            #print "<!-- href: $l -->\n";
            #print "<!-- basedir: $basedir -->\n";
            $l = "$basedir/$l" unless $l =~ m!$basedir!;
            $attr->{href}
                = $tag =~ m!link!i
                ? $l
                : $url . "?q=$q;f=$l";
        }

    }

    if ( $tag eq 'img' ) {

        unless ( $attr->{src} =~ m!^(http://|/)! ) {

            # if img is relative to file, make it absolute
            $attr->{src} = "$basedir/$attr->{src}";

        }

    }

    $newattr .= " $_='$attr->{$_}' " for keys %$attr;

    return $newtag . $newattr . '>';

}

1;

__END__

=pod

=head1 NAME

lightfile.cgi -- highlight a file with HTML::HiLiter via the HTTP method.

=head1 DESCRIPTION

Place in your cgi-bin and set permissions appropriately. Takes two parameters:
f (for file to fetch and highlight) and q (for query to highlight).

=head1 CAUTION

This script makes no attempt at untainting variables or similar security precautions.
It's simply an example.

USE AT YOUR OWN RISK!

=cut


 ###############################################################################
 #    CrayDoc 4
 #    Copyright (C) 2004 Cray Inc swpubs@cray.com
 #
 #    This program is free software; you can redistribute it and/or modify
 #    it under the terms of the GNU General Public License as published by
 #    the Free Software Foundation; either version 2 of the License, or
 #    (at your option) any later version.
 #
 #    This program is distributed in the hope that it will be useful,
 #    but WITHOUT ANY WARRANTY; without even the implied warranty of
 #    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 #    GNU General Public License for more details.
 #
 #    You should have received a copy of the GNU General Public License
 #    along with this program; if not, write to the Free Software
 #    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 ###############################################################################
 
