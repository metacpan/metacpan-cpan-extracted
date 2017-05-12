#! /usr/bin/perl 

use strict ; 
use warnings ; 

use JQuery::Demo ;

package main ;
my $tester =  new JQuery::Demo ; 
$tester->run ; 

package JQuery::Demo ;
use JQuery::Taconite ; 

sub start {
    my $my = shift ;
    $my->{info}{TITLE} = "Taconite Example" ;
    my $env ;
    for (sort keys %ENV) { 
	$env .= "$_ = $ENV{$_}<br />\n" ; 
    } 
    my $q = new CGI ;
    my $params = $q->Vars;
    my $par ;
    for (sort keys %$params) { 
	$par .= "$_ = $params->{$_}<br />\n" ;
    } 


    my $jquery = $my->{jquery} ; 
    JQuery::Taconite->new(id => 'ex6', remoteProgram => '/cgi-bin/jquery_taconite2.pl', rm => 'reply', addToJQuery => $jquery) ; 

    my $html =<<EOD; 
                <h1>Demo</h1>
                This page demonstrates many updates at once.
                <p />
                <input id="ex6" type="button" value="Run Example 6" />
                <input id="wireMe" type="button" value="Not Wired Yet" />
                                                        
                <hr />
                   <div id="appendDiv">Text will be appended</div>
                   <div class="deleteDiv">This div will be removed</div>
                   <div class="deleteDiv">This one too</div>
                   <div id="afterDiv">Append radio buttons</div>
                   <div id="beforeDiv">Append before this</div>
                   <div id="setAttrDiv">Set the attribute to green</div>     
                   <div class="wrapMe">Wrap this text with a style</div>
                   <div id="evalTarget">Eval Target</div>

EOD
    
    $my->{info}{BODY} =  "<h1>START OF TACONITE EXAMPLE</h1>$html<h1>END OF EXAMPLE</h1>" ;
}

sub reply { 
    my $my = shift ; 

    my $result=<<EOD;

<taconite>
    <hide select="#hideMe" />
    
    <remove select=".deleteDiv" />

    <append select="#appendDiv">
        <span class="newContent">This span was appended to the APPEND div</span>
    </append>

    <prepend select="#prependDiv">
        <span class="newContent">This span was prepended to the PREPEND div</span>
    </prepend>

    <after select="#afterDiv">
        <p class="newContent">This paragraph element was inserted after the AFTER div</p>
        <div class="newContent">
            Note that we can have multiple elements here.
            <div>Any XHTML can be used!</div>
            <p> Radios follow:
                <input type="radio" name="1" value="1" />
                <input type="radio" name="1" value="2" />
                <input type="radio" name="1" value="3" />
            </p>
        </div>
    </after>

    <before select="#beforeDiv">
        <span class="newContent">This span was inserted before the BEFORE div</span>
    </before>

    <replace select="#replaceDiv">
        <div class="newContent">This is <span style="font-weight:bold">new</span> content that includes a table.</div>
        <table border="1" cellpadding="3" class="newContent">
            <thead><tr><th>Header 1</th><th>Header 2</th></tr></thead>
            <tbody>
                <tr><td>row 1 col 1</td><td>row 1 col 2</td></tr>
                <tr><td>row 2 col 1</td><td>row 2 col 2</td></tr>
            </tbody>
        </table>
    </replace>

    <replaceContent select="#replaceContentsDiv">
        <div class="newContent">This is <span style="font-weight:bold">new</span> content that replaced the old content.</div>
        <p class="newContent"> Checkboxes follow:
            <input type="checkbox" name="1" value="1" />
            <input type="checkbox" name="2" value="2" />
            <input type="checkbox" name="3" value="3" />
        </p>
    </replaceContent>

    <attr select="#setAttrDiv" name="class" value="green" />

    <after select="#tr">
        <tr class="newContent"><td>The</td><td>new</td><td>row</td></tr>
    </after>

    <wrap select=".wrapMe">
        <div style="border:3px solid red; padding: 2px"><div style="border:3px solid blue; padding: 2px"></div></div>
    </wrap>

    <!-- script test  -->
    <append select="head">
        <script type="text/javascript">
            // wire up the 'wireMe' button on the fly
            \$('#wireMe').click(function() {
                alert('Button clicked!');
            }).val("Wired!");
        </script>
    </append>

    <eval>
        \$('#evalTarget').html("This text came from an eval command");
    </eval>

</taconite>

EOD
    $my->{info}{AJAX} = $result ; 
}
