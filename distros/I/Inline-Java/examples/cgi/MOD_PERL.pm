#!/usr/bin/perl

package t::MOD_PERL ;

use strict ;

use CGI ;

use Inline (
	Java => '/home/patrickl/DEV/Inline-Java/t/counter.java',
	DIRECTORY => '/home/patrickl/DEV/Inline-Java/_Inline_web_test',
	NAME => 't::MOD_PERL',
	SHARED_JVM => 1,
) ;


use Apache2::RequestRec ;
use Apache2::RequestIO ;
use Apache2::Const qw(:common) ;


my $cnt = new t::MOD_PERL::counter() ;


sub handler {
	my $r = shift ;
	
	$r->content_type('text/html') ;

	my $gnb = $cnt->gincr() ;
	my $nb = $cnt->incr() ;

	my $q = new CGI() ;
	print 
		$q->start_html() .
	    "Inline-Java " . $Inline::Java::VERSION . "<BR><BR>" .
		"Inline-Java says this page received $gnb hits!<BR>" .
		"Inline-Java says this MOD_PERL ($$) served $nb of those hits." .
		$q->end_html() ;

	return OK ;
}


1 ;

