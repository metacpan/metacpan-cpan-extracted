#
# Example for using HTML::Embperl::Execute
#
# run this under mod_perl / Apache::Registry
# or standalone
#


use HTML::Embperl ;

my($r) = @_;

$HTML::Embperl::DebugDefault = 811005 ;


$tst1 = '<P>Here is some text</P>' ;

$r -> status (200) ;
$r -> send_http_header () ;

print "<HTML><TITLE>Test for HTML::Embperl::Execute</TITLE><BODY>\n" ;
print "<H1> 1.) Include from memory</H1>\n" ;

HTML::Embperl::Execute ({input		=> \$tst1,
						 mtime      => 1,  
						 inputfile	=> 'Some text',
						 req_rec    => $r}) ;


print "<H1> 2.) Include from memory with some Embperl code</H1>\n" ;

HTML::Embperl::Execute ({input		=> \'[- @ar = (a1, b2, c3) -]<table><tr><td>[+$ar[$col]+]</td></tr></table></P>',
						 mtime      => 1,  
						 inputfile	=> 'table',
						 req_rec    => $r}) ;

print "<H1> 3.) Include from memory with passing of variables</H1>\n" ;


$MyPackage::Interface::Var = 'Some Var' ;

HTML::Embperl::Execute ({input		=> \'<P>Transfer some vars [+ $Var +] !</P>',
						 inputfile	=> 'Var',
						 mtime      => 1,
						 'package'  => 'MyPackage::Interface',
						 req_rec    => $r}) ;

print "<H1> 4.) Change the variable, but not the code</H1>\n" ;

$MyPackage::Interface::Var = 'Do it again' ;

# code is the same, so give the same mtime and inputfile to avoid recompile
# Note you get problems is you change the code, but did not restart the server or
# change the value in mtime. So make sure if you change something also change mtime!

HTML::Embperl::Execute ({input		=> \'<P>Transfer some vars [+ $Var +] !</P>',
						 inputfile	=> 'Var2',
						 mtime      => 1,  
						 'package'  => 'MyPackage::Interface',
						 req_rec    => $r}) ;


print "<H1> 5.) Use \@param to pass parameters</H1>\n" ;


HTML::Embperl::Execute ({input		=> \'<P>Use \@param to transfer some data ([+ " @param " +]) !</P>',
						 inputfile	=> 'Param',
						 req_rec    => $r,
						 param      => [1, 2, 3, 4] }
						 ) ;


print "<H1> 6.) Use \@param to pass parameters and return it</H1>\n" ;


my @p = ('vara', 'varb') ;

print "<H3> \$p[0] is $p[0] and \$p[1] is $p[1]<H3>" ;

HTML::Embperl::Execute ({input		=> \'<P>Got data in @param ([+ "@param" +]) !</P>[- $param[0] = "newA" ; $param[1] = "newB" ; -]<P>Change data in @param to ([+ "@param" +]) !</P>',
						 inputfile	=> 'Param & Return',
						 req_rec    => $r,
						 param      => \@p }
						 ) ;

print "<H3> \$p[0] is now $p[0] and \$p[1] is now $p[1]<H3>" ;

print "<H1> 7.) Presetup \%fdat and \@ffld</H1>\n" ;

my %myfdat = ('test' => 'value',
              'fdat' => 'text') ;
              
my @myffld = sort keys %myfdat ;             

HTML::Embperl::Execute ({input		=> \'<P><table><tr><td>[+ $k = $ffld[$row] +]</td><td>[+ $fdat{$k} +]</td></tr></table></P>',
						 inputfile	=> 'fdat & ffld',
						 req_rec    => $r,
						 fdat  => \%myfdat,
						 ffld  => \@myffld}
						 ) ;


print "<H1> 8.) Inculde a file</H1>\n" ;


HTML::Embperl::Execute ({inputfile	=> '../inc.htm',
						 req_rec    => $r}) ;


print "<H1> 9.) Inculde a file and return output in a scalar</H1>\n" ;

my $out ;

HTML::Embperl::Execute ({inputfile	=> '../inc.htm',
						 output     => \$out,
						 req_rec    => $r}) ;


print "<H3>$out</H3>\n" ;

print "<H1> 10.) Done :-)</H1>\n" ;


print "</body></html>\n";
