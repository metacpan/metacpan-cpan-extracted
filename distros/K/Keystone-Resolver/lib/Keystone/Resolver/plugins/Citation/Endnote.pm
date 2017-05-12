# $Id: Endnote.pm,v 1.2 2007-01-26 13:53:47 mike Exp $

package Keystone::Resolver::plugins::Citation::Endnote;

use strict;
use warnings;


# I haven't read a specification for Endnote citation format, so this
# code will probably need refining.  I am working entirely from a
# single example that I captured from a 1CATE services menu, which is
# stored at "../../../samples/citations/1kofkfks"

sub citation {
    my $class = shift();
    my($openurl) = @_;

    # Maps Endnote citations fields to OpenURL 1.0 referent fields.  Where
    # the RHS begins with an asterisk, it's a special-case recipe.
    #
    my @map = (
	       TY => "*format",
	       AU => "*author",
	       TI => "atitle",
	       JO => "jtitle",
	       PY => "date",
	       VL => "volume",
	       IS => "issue",
	       SN => "issn",
	       UR => "*url",
	       ### spage?
	       ### epage?
	       # ER => ??? Not given in the example, not sure what it is
	       );

    my $text = "";
    while (@map) {
	my $key = shift @map;
	my $field = shift @map;
	my $val;
	if ($field =~ s/^\*//) {
	    $val = _special($openurl, $field);
	} else {
	    $val = $openurl->rft($field);
	}
	$val = "" if !defined $val;
	$text .= "$key  - $val\n";
    }

    return ("$text", "application/x-research-info-systems");
}


sub _special {
    my($openurl, $special) = @_;

    if ($special eq "format") {
	my $format = $openurl->descriptor("rft")->superdata1("val_fmt");
	# It should be something like "info:ofi/fmt:kev:mtx:journal"
	$format =~ s/.*://;
	return $format;
    } elsif ($special eq "author") {
	my $last = $openurl->rft("aulast");
	return undef if !defined $last;
	my $first = $openurl->rft("aufirst");
	if (!defined $first) {
	    $first = $openurl->rft("auinit");
	    return $last if !defined $first;
	    $first .= "." if $first !~ /\.$/;
	}
	return "$last, $first";
    } elsif ($special eq "url") {
	return $openurl->v10url("svc_dat");
    }

    return "[UNKNOWN SPECIAL $special]";
}


1;
