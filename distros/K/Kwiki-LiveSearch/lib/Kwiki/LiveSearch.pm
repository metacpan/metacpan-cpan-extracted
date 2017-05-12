package Kwiki::LiveSearch;
use Kwiki::Plugin -Base;
use mixin 'Kwiki::Installer';
use Kwiki ':char_classes';
our $VERSION = '0.07';

const class_id => 'livesearch';
const class_title => 'LiveSearch';
const cgi_class => 'Kwiki::LiveSearch::CGI';
const result_template => 'livesearch_result.xml';
const css_file => 'livesearch.css';

sub register {
    my $registry = shift;
    $registry->add(action => 'livesearch');
    $registry->add(widget => 'livesearch_box', 
                   template => 'livesearch_box.html',
		   show_for => 'display',
                  );
}

sub livesearch {
    $self->template_process($self->result_template,
			    pages => $self->perform_livesearch);
}

sub perform_livesearch {
    my $livesearch = $self->cgi->s;
    $livesearch =~ s/[^$WORD\ \-\.\^\$\*\|\:]//g;
    [ 
        grep {
            $_->content =~ m{$livesearch}i and 
            $_->active
        } $self->pages->all 
    ]
}

package Kwiki::LiveSearch::CGI;
use Kwiki::CGI -base;

cgi 's';

package Kwiki::LiveSearch;

__DATA__

=head1 NAME

Kwiki::LiveSearch - Search and Display pagelink on the fly!

=head1 SYNOPSIS

=head1 DESCRIPTION

B<Kwiki::LiveSearch> is a L<Kwiki> plugin that allow anyone search
the kwiki site in a fancy way. Results are displayed right after
you enter the text.

To use this plugin, simply install L<Kwiki> and this module from CPAN,
and do:

    # echo 'Kwiki::LiveSearch' >> plugins
    # kwiki -update

Currently the code of searching text is the same from
L<Kwiki::Search>, and it's not very efficient, your server will have
heavy load when there are many people using this search plugin.  In
the future the indexing algorithm should be improved to reduce the
time and load.

The code of livesearch.js come from http://blog.bitflux.ch/.
It's modified a little to fit cgi scriptname.

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 COPYRIGHT

Copyright (c) 2004. Kang-min Liu. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut
__template/tt2/livesearch_box.html__
<!-- BEGIN livesearch_box.html -->
<link rel="stylesheet" type="text/css" href="css/livesearch.css" />
<form onsubmit="return liveSearchSubmit()" style="margin: 0px;" name="searchform" method="get" action="[% script_name%]" enctype="application/x-www-form-urlencoded" >
<span>Live Search</span>
<input type="hidden" name="action" value="livesearch" />
<input name="s" id="livesearch" size="8" autocomplete="off" onkeypress="liveSearchStart();" type="text"/>
<div id="LSResult" style="display: none;"><div id="LSShadow"></div></div>
</form>
<script type="text/javascript" src="javascript/livesearch.js"></script>
<script type="text/javascript"> liveSearchInit() </script>
<!-- END livesearch_box.html -->
__template/tt2/livesearch_result.xml__
<?xml version='1.0' encoding='utf-8'  ?><div class='LSRes'>[% IF pages.0
 %][% FOR page = pages %]<div class="LSRow">[% page.kwiki_link %]</div>[% END %][%
 ELSE %]<div class="LSRow"><a>No Pages Found</a></div>[% END %]</div>
__css/livesearch.css__
  #livesearch {
  display: block;
  }
  
  #LSHighlight {
      background-color: lightgreen;
  }

  .LSRow a:hover {
	text-decoration: underline;
  }

  .LSRow {
    margin: 0px;
    line-height: 1.2em;
	padding-top: 0.2em;
	padding-bottom: 0.2em;
    text-indent: -1em; 
    padding-left: 1em; 
    line-height: 1.2em; 
    padding-right: 1em;
  }
 
  .LSRow:before {
    content: '>';
  }
  #LSResult {    
      position: absolute;
      background-color: #ccc; 
      min-width: 96px; 
      margin-left: 4px;
      margin-top: 4px;
  }
  
  #LSShadow {
      position: relative;
      bottom: 2px;
      right: 2px;
      background-color: #666; /*shadow color*/
      color: inherit;
  }
  
  .LSRes {
      position: relative;
      bottom: 2px;
	  right: 2px;
      background-color: white;
      border: black 1px dotted;
  }

__javascript/livesearch.js__
/*
// +----------------------------------------------------------------------+
// | Copyright (c) 2004 Bitflux GmbH                                      |
// +----------------------------------------------------------------------+
// | Licensed under the Apache License, Version 2.0 (the "License");      |
// | you may not use this file except in compliance with the License.     |
// | You may obtain a copy of the License at                              |
// | http://www.apache.org/licenses/LICENSE-2.0                           |
// | Unless required by applicable law or agreed to in writing, software  |
// | distributed under the License is distributed on an "AS IS" BASIS,    |
// | WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or      |
// | implied. See the License for the specific language governing         |
// | permissions and limitations under the License.                       |
// +----------------------------------------------------------------------+
// | Author: Bitflux GmbH <devel@bitflux.ch>                              |
// +----------------------------------------------------------------------+

*/
var liveSearchReq = false;
var t = null;
var liveSearchLast = "";
var isIE = false;
// on !IE we only have to initialize it once
if (window.XMLHttpRequest) {
	liveSearchReq = new XMLHttpRequest();
}

function liveSearchInit() {
	
	if (navigator.userAgent.indexOf("Safari") > 0) {
		document.getElementById('livesearch').addEventListener("keydown",liveSearchKeyPress,false);
	} else if (navigator.product == "Gecko") {
		document.getElementById('livesearch').addEventListener("keypress",liveSearchKeyPress,false);
		
	} else {
		document.getElementById('livesearch').attachEvent('onkeydown',liveSearchKeyPress);
		isIE = true;
	}

}

function liveSearchKeyPress(event) {
	if (event.keyCode == 40 )
	//KEY DOWN
	{
		highlight = document.getElementById("LSHighlight");
		if (!highlight) {
			highlight = document.getElementById("LSResult").firstChild.firstChild.firstChild;
		} else {
			highlight.removeAttribute("id");
			highlight = highlight.nextSibling;
		}
		if (highlight) {
			highlight.setAttribute("id","LSHighlight");
		} 
		if (!isIE) { event.preventDefault(); }
	} 
	//KEY UP
	else if (event.keyCode == 38 ) {
		highlight = document.getElementById("LSHighlight");
		if (!highlight) {
			highlight = document.getElementById("LSResult").firstChild.firstChild.lastChild;
		} 
		else {
			highlight.removeAttribute("id");
			highlight = highlight.previousSibling;
		}
		if (highlight) {
				highlight.setAttribute("id","LSHighlight");
		}
		if (isGecko) 
		if (!isIE) { event.preventDefault(); }
	} 
	//ESC
	else if (event.keyCode == 27) {
		highlight = document.getElementById("LSHighlight");
		if (highlight) {
			highlight.removeAttribute("id");
		}
		document.getElementById("LSResult").style.display = "none";
	} 
}
function liveSearchStart() {
	if (t) {
		window.clearTimeout(t);
	}
	t = window.setTimeout("liveSearchDoSearch()",200);
}

function liveSearchDoSearch() {
	if (liveSearchLast != document.forms.searchform.s.value) {
	if (liveSearchReq && liveSearchReq.readyState < 4) {
		liveSearchReq.abort();
	}
	if ( document.forms.searchform.s.value == "") {
		document.getElementById("LSResult").style.display = "none";
		highlight = document.getElementById("LSHighlight");
		if (highlight) {
			highlight.removeAttribute("id");
		}
		return false;
	}
	if (window.XMLHttpRequest) {
	// branch for IE/Windows ActiveX version
	} else if (window.ActiveXObject) {
		liveSearchReq = new ActiveXObject("Microsoft.XMLHTTP");
	}
	liveSearchReq.onreadystatechange= liveSearchProcessReqChange;
	liveSearchReq.open("GET", "?action=livesearch&s=" + document.forms.searchform.s.value);
	liveSearchLast = document.forms.searchform.s.value;
	liveSearchReq.send(null);
	}
}

function liveSearchProcessReqChange() {
	
	if (liveSearchReq.readyState == 4) {
		var  res = document.getElementById("LSResult");
		res.style.display = "block";
		res.firstChild.innerHTML = liveSearchReq.responseText;
		 
	}
}

function liveSearchSubmit() {
	var highlight = document.getElementById("LSHighlight");
	if (highlight && highlight.firstChild) {
		window.location = highlight.firstChild.getAttribute("href");
		return false;
	} 
	else {
		return true;
	}
}


