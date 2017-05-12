# $Id: APP.pm,v 1.2 2007-01-26 13:53:47 mike Exp $

package Keystone::Resolver::plugins::Citation::APP;

use strict;
use warnings;


sub citation {
    my $class = shift();
    my($openurl) = @_;

    my($genre, $aulast, $auinit, $date, $atitle, $jtitle, $volume,
	$spage, $epage, $btitle, $pub, $place)
	= map { $openurl->rft($_) }
	    qw(genre aulast auinit date atitle jtitle volume spage
	       epage btitle pub place);

    $aulast ||= "[Unspecified author]";
    $auinit ||= $openurl->rft("aufirst");
    $date   ||= "[unspecified date]";
    $atitle ||= "[unspecified article title]";
    $volume ||= "[unspecified volume]";

    my $name;
    if (defined $auinit) {
	$auinit =~ s/\.$//;
	$name = "$aulast, $auinit";
    } else {
	$name = "$aulast";
    }

    if (defined $genre && $genre eq "book") {
	my $text = "$name.  $date.  $btitle.";
	$text .= "  $pub." if defined $pub;
	$text .= "  $place." if defined $place;
	return ($text, "text/html");
    }

    if (!defined $jtitle) {
	my $issn = $openurl->rft("issn");
	if (defined $issn) {
	    $jtitle = "ISSN $issn";
	} else {
	    $jtitle = "[unspecified journal]";
	}
    }

    my $text = "$name.  $date.  $atitle.  <i>$jtitle</i>, $volume";
    if (defined $spage && defined $epage) {
	$text .= ": $spage-$epage";
    } elsif (defined $spage) {
	$text .= ": $spage ff.";
    } elsif (defined $epage) {
	$text .= ": to $epage";
    }

    return ("$text.", "text/html");
}


1;
