#!/usr/bin/env perl
# Device::OUI Copyright 2008 Jason Kohles
# $Id: device-oui-test-lib.pl 4 2008-01-26 18:39:31Z jason $
use strict;
use warnings;
use File::Copy;
no warnings 'redefine';
$INC{ 'LWP/Simple.pm' } = 'faked by device-oui-test-lib.pl';
sub LWP::Simple::get($) {
    my $url = shift || die "fake LWP::Simple get needs a url";
    if ( $url =~ s#^file://## ) {
        local $/;
        if ( ! -f $url ) { return undef }
        return IO::File->new( $url )->getline;
    }
    if ( $url !~ /([0-9a-f\-]{8})/i ) {
        die "fake LWP::Simple get needs a file URL or a URL that ".
            "contains an OUI ( $url )";
    }
    my $entry = oui_entry_for( $1 );
    if ( ! $entry ) {
        die "fake LWP::Simple get couldn't find a suitable ".
            "OUI entry (for $1)";
    }
    $entry =~ s{^([0-9a-f-]{8})}{<b>$1</b>}mi;
my $page =  qq{<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML//EN">
<HTML><HEAD><TITLE>Search Results: IEEE Standards OUI Public Database</TITLE>
<LINK REV=MADE HREF="mailto:nobody%40example.com">
</HEAD><BODY BGCOLOR="#fffff0"> <p>Here are the results of your search through the public section
    of the IEEE Standards OUI database report for <b>$url</b>:

<hr><p><pre>$entry
</pre></p>
    <hr><p>Your attention is called to the fact that the firms and numbers
    listed may not always be obvious in product implementation.  Some
    manufacturers subcontract component manufacture and others include
    registered firms' OUIs in their products.</p>
    <hr>

    <h5 align=center>
    <a href="/index.html">[IEEE Standards Home Page]</a> -- 
    <a href="/search.html">[Search]</a> --
    <a href="/cgi-bin/staffmail">[E-mail to Staff]</a> <br>
    <a href="/c.html">Copyright &copy; 2008 IEEE</a></h5>

</BODY></HTML>};
}
sub LWP::Simple::mirror($$) {
    my $url = shift || die "fake LWP::Simple mirror needs a url";
    if ( $url !~ s#^file://## ) {
        use Carp qw( confess );
        confess "fake LWP::Simple mirror only work with file urls ($url)";
    }
    my $file = shift || die "fake LWP::Simple mirror needs a file";
    if ( ::files_same( $url, $file ) ) { return 304 }
    File::Copy::copy( $url, $file ) && return 200;
}
sub LWP::Simple::RC_NOT_MODIFIED() { 304 }
sub LWP::Simple::is_success($) { $_[0] >= 200 && $_[0] < 300 }

1;
