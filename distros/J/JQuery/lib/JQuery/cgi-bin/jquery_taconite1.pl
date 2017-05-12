#! /usr/bin/perl -w

use strict ; 

use JQuery::Demo ;

package main ;
my $tester =  new JQuery::Demo ; 
$tester->run ; 

package JQuery::Demo ;
use JQuery::Taconite ; 

sub start {
    my $my = shift ;
    $my->{info}{TITLE} = "Taconite Example" ;

    my $jquery = $my->{jquery} ; 
    JQuery::Taconite->new(id => 'ex1', remoteProgram => '/cgi-bin/jquery_taconite_results1.pl', addToJQuery => $jquery) ; 

    my $html =<<EOD; 
                <h1>Demo 1</h1>
                This page demonstrates many updates at once.
                <p />
                <input id="ex1" type="button" value="Run Example 6" />
                <hr />
                <table border="1" cellpadding="10">
                    <tr><th>Test</th><th>Description</th><th>Target</th></tr>

                    <tr>
                        <td><code>remove</code></td>
                        <td><div>Content to the right will be removed</div></td>
                        <td><div class="deleteDiv">This div will be removed</div>
                            <div class="deleteDiv">This one too</div>
                        </td>
                    </tr>

                    <tr>
                        <td><code>append</code></td>
                        <td><div>Content to the right will be appended to</div></td>
                        <td><div id="appendDiv">This is the APPEND div</div></td>
                    </tr>
                    <tr>
                        <td><code>prepend</code></td>

                        <td><div>Content to the right will be prepended to</div></td>
                        <td><div id="prependDiv">This is the PREPEND div</div></td>
                    </tr>
                    <tr>
                        <td><code>after</code></td>
                        <td><div>Content to the right will have new contents placed after it</div></td>
                        <td><div id="afterDiv">This is the AFTER div</div></td>

                    </tr>
                    <tr>
                        <td><code>before</code></td>
                        <td><div>Content to the right will have new contents placed before it</div></td>
                        <td><div id="beforeDiv">This is the BEFORE div</div></td>
                    </tr>
                    <tr>

                        <td><code>replace</code></td>
                        <td><div>Content to the right will be completely replaced
                            (note that the target div has a solid green border)</div></td>
                        <td><div id="replaceDiv" style="border: 2px solid green">This is the REPLACE div</div></td>
                    </tr>
                    <tr>
                        <td><code>replaceContent</code></td>
                        <td><div>Content to the right will have its contents replaced
                            (note that the target div has a solid green border)</div></td>

                        <td><div id="replaceContentsDiv" style="border: 2px solid green">This is the REPLACE-CONTENTS div
                            (<span>contents</span>
                            <span>contents</span>
                            <span>contents</span>)
                            </div>
                        </td>
                    </tr>
                    <tr>

                        <td><code>attr</code></td>
                        <td><div>Content to the right will have its 'class' attribute changed</div></td>
                        <td><div id="setAttrDiv">This text should turn green</div></td>
                    </tr>

                    <tr>
                        <td>Table Row insertion</td>

                        <td><div>Table to the right will have a new row inserted between rows one and two</div></td>
                        <td>
                            <table border="1" cellpadding="3">
                            <tr id="tr"><td>one</td><td>one</td><td>one</td></tr>
                            <tr><td>two</td><td>two</td><td>two</td></tr>

                            </table>
                        </td>
                    </tr>
                    <tr>
                        <td><code>wrap</code></td>
                        <td><div>Text to the right should be wrapped in two bordered divs</div></td>
                        <td><div class="wrapMe">Wrap me in bordered divs</div></td>

                    </tr>
                    <tr>
                        <td><code>&lt;script&gt;</code></td>
                        <td>
                            <div>The button to the right will get a click handler via a dynamically added script element</div>
                        </td>
                        <td><input type="button" value="This button has no click handler (yet)" id="wireMe" /></td>
                    </tr>

                    <tr>
                        <td><code>hide</code></td>
                        <td><div>Content to the right will be hidden</div></td>
                        <td><div id="hideMe">HIDE ME</div></td>
                    </tr>
                    <tr>
                        <td><code>eval</code></td>

                        <td><div>Evaluating the contents of this command should insert text to the right </div></td>
                        <td><div id="evalTarget"></div></td>
                    </tr>
                </table>

            </div>
    </div>

EOD
    
    $my->{info}{BODY} =  "<h1>HELLO</h1>$html<h1>END OF EXAMPLE</h1>" ;
}

