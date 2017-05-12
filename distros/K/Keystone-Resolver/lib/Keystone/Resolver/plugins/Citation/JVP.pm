# $Id: JVP.pm,v 1.2 2007-01-26 13:53:47 mike Exp $

package Keystone::Resolver::plugins::Citation::JVP;

use strict;
use warnings;


sub citation {
    my $class = shift();
    my($openurl) = @_;

    my($aulast, $auinit, $date, $atitle, $jtitle, $volume, $spage, $epage)
	= map { $openurl->rft($_) || "[UNKNOWN-$_]" }
	    qw(aulast auinit date atitle jtitle volume spage epage);

    $auinit =~ s/\.$//;
    return "$aulast, $auinit.  $date.  $atitle.  $jtitle $volume:$spage-$epage";
}


1;
