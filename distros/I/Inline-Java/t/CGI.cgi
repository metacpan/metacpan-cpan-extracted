#!/usr/bin/perl

package t::CGI ;

use strict ;

use CGI ;
use CGI::Carp qw(fatalsToBrowser) ;

use Inline (
	Java => '/home/patrickl/DEV/Inline-Java/t/counter.java',
	DIRECTORY => '/home/patrickl/DEV/Inline-Java/_Inline_web_test',
	SHARED_JVM => 1,
	NAME => 't::CGI',
) ;

BEGIN {
	$t::CGI::cnt = new t::CGI::counter() ;
}

my $gnb = $t::CGI::cnt->gincr() ;
my $nb = $t::CGI::cnt->incr() ;

my $q = new CGI() ;
print "Content-type: text/html\n\n" ;
print 
	$q->start_html() .
	"Inline-Java " . $Inline::Java::VERSION . "<BR><BR>" .
	"Inline-Java says this page received $gnb hits!<BR>" .
	"Inline-Java says this CGI ($$) served $nb of those hits." .
	$q->end_html() ;		

1 ;
