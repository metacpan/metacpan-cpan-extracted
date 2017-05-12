# $Id: author.pm,v 1.2 2007-01-26 13:53:47 mike Exp $

package Keystone::Resolver::plugins::Citation::author;

use strict;
use warnings;


sub citation {
    my $class = shift();
    my($openurl) = @_;

    my($aulast, $aufirst, $date)
	= map { $openurl->rft($_) } qw(aulast aufirst date);

    $aulast  ||= "[Unspecified author]";
    $aufirst ||= $openurl->rft("auinit");
    $date    ||= "[unspecified date]";

    $aulast .= ", $aufirst" if defined $aufirst;
    $aulast =~ s/\.$//;

    return ("$aulast.  $date.", "text/html");
}


1;
