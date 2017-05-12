#! /usr/bin/perl 

use strict ; 
use warnings ; 

use JQuery::Demo ;
use CGI ; 

package main ;
my $tester =  new JQuery::Demo ; 
$tester->run ; 

package JQuery::Demo ;
use JQuery::Taconite ; 
use JQuery::Form ; 

# This initiates the form
# Note: the hidden field "rm" to tell the program which routine to use for the reply
# The form is just a simple form, with the addition of an id
# To use Taconite (Ajax), just add register Taconite with jquery, and add the id of the form


sub start {
    my $my = shift ;
    my $q = new CGI ; 

    $my->{info}{TITLE} = "Taconite With Form Example" ;

    my $jquery = $my->{jquery} ; 
    JQuery::Form->new(id => 'myForm', addToJQuery => $jquery) ; 

    my $html =<<EOD; 
<form id="myForm" action="/cgi-bin/jquery_form.pl" method="post"> 
    Name: <input type="text" name="name" /><br/> 
    Comment: <textarea name="comment"></textarea><br/> 
    <input type="submit" value="Submit Comment" /><br/> 
    <input type=hidden name="rm" value="reply" /><br/>
</form>
    <div id="example1" style="background-color: #ffa; padding:10px; border:1px solid #ccc"> 
    This is the <span style="color:#800">structure example</span> div. 
    </div>	 
    <div id="example4" style="background-color: orange; padding:10px; border:1px solid #bbb"> </div>	 
EOD
    
    $my->{info}{BODY} =  "<h1>START OF FORM EXAMPLE</h1>$html<h1>END OF EXAMPLE</h1>" ;
}


# This updates the form
sub reply { 
    my $my = shift ;
    
    #my $params = $my->Vars;
    #my $par ;
    #for (sort keys %$params) { 
#	$par .= "$_ = $params->{$_}<br />\n" ;
 #   } 


    my $env ;
    for (sort keys %ENV) { 
	$env .= "$_ = $ENV{$_}<br />\n" ; 
    } 

    my $result=<<EOD;
    
<taconite> 
    <after select="#example1"> 
        $env
        This text will go AFTER the example div. 
    </after> 
 
    <before select="#example1"> 
        <div>This div will go BEFORE the example div.</div> 
    </before> 
 
    <wrap select="#example1 span"> 
        <span style="border: 1px dashed #00F"></span> 
    </wrap> 
 
    <append select="#example1"> 
        <div>This div is APPENDED</div> 
    </append> 

    <replaceContent select="#example4"> 
        <pre> 
        lorem ipsum dolor sit amet 
        consectetuer adipiscing elit 
        </pre> 
    </replaceContent> 
 
    <slideDown select="#example4" value="100" /> 

</taconite>

EOD
 
$my->{info}{AJAX} = $result ; 
#print $q->header(-type=>'text/xml');
#print $result ; 

} 
