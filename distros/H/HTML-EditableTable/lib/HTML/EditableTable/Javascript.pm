package HTML::EditableTable::Javascript;

use strict;
use warnings;

use Carp qw(confess);

=head1 NAME

HTML::EditableTable::Javascript

=head1 VERSION

Version 0.21

=cut

our $Version = '0.21';

my $javascriptDisplayCount = 0;

my %fieldParamJavascriptMap = (
  'tooltip' => \&jsToolTip,
  'drillDownTruncate' => \&jsExpandText,
  'jsClearColumnOnEdit' => \&jsClearColumnOnEdit,
    );

my %tableParamJavascriptMap = (
  'jsSortHeader' => \&jsSortHeader,
    );

my %formElementTypeJavascriptMap = (
  'calendar' => \&jsCalendar10Setup,
    );

=head1 SYNOPSIS

This class provides all of the javascript functionality supported in EditableTable.  It is designed so that the javascript code used can be easily overridden with local .js files  See the documetation in L<HTML::EditableTable> for guidance on extending this class.

=cut

$|=1;

sub new {
  
  my $class = shift;
  my $parent = shift; # reference to parent EditableTable
  
  if (!$parent->isa('HTML::EditableTable')) { confess "parent is not an HTML::EditableTable"; }
  
  my $self= {};
  $self->{parent} = $parent;
  $self->{methods} = [];
  
  bless $self, $class;
    
  return $self;
}

sub setUid {
  my $uid = shift;
}
  
sub htmlDisplay {

  my $self = shift;

  # for multiple table case, only print these once

  print "debug displayCount = $javascriptDisplayCount<br>";

  if (!$javascriptDisplayCount) {

    # table field-level javascript support

    my @potentialJSSupportParams = keys %fieldParamJavascriptMap;
    my @potentialJSSupportFormElementTypes = keys %formElementTypeJavascriptMap; 
    my @potentialJSSupportTableParams = keys %tableParamJavascriptMap;

    # table-param-level javascript

    foreach my $param (keys %{$self->{parent}}) {
      foreach my $potentialJSSupportTableParam (@potentialJSSupportTableParams) {
	
	if (my $mp = $tableParamJavascriptMap{$param}) {
	  print $self->$mp();
	}
      }
    }
    
    foreach my $tableField (@{$self->{parent}->{tableFields}}) {
      
      # form-element-based javascript
      my @remainingJSSupportFormElementTypes = ();

      foreach my $potentialFieldFormElementType (@potentialJSSupportFormElementTypes) {	
	
	if ($tableField->{formElement} && $formElementTypeJavascriptMap{$tableField->{formElement}})  {
	  
	  my $mp = $formElementTypeJavascriptMap{$tableField->{formElement}};
	  print $self->$mp();
	}
	else {      
	  push @remainingJSSupportFormElementTypes, $potentialFieldFormElementType;
	}
      }
      @potentialJSSupportFormElementTypes = @remainingJSSupportFormElementTypes;


      # param-based javascript
      
      my @remainingJSSupportParams = ();

      foreach my $potentialFieldParam (@potentialJSSupportParams) {	
	  
	if ($tableField->{$potentialFieldParam})  {
	  my $mp = $fieldParamJavascriptMap{$potentialFieldParam};
	  print $self->$mp();
	}
	else {      
	  push @remainingJSSupportParams, $potentialFieldParam;
	}
      }
      @potentialJSSupportParams = @remainingJSSupportParams;
    }
  }    

  $javascriptDisplayCount = 1;

  # this method is unique to each table

  if ($self->{parent}->isParamSet('jsAddData')) {
    print $self->jsAddData();
  }
}

sub resetJavascriptDisplayCount {
  my $self = shift;
  
  print "reseting display count<br>";
  $javascriptDisplayCount = 0;
}

sub jsExpandText {

  my $self = shift;

  my $javascript = "<script language='javascript' type='text/javascript'>\n";
  $javascript .= <<'END_JS';

  function expandText(target_elm_id, full_text_div_id, short_text_div_id) {
    
    var target_elm = document.getElementById(target_elm_id);
    var full_text_div = document.getElementById(full_text_div_id);
    var short_text_div = document.getElementById(short_text_div_id);
    
    if (target_elm.innerHTML == full_text_div.innerHTML) {
      target_elm.innerHTML = short_text_div.innerHTML;
    }
    else {
      target_elm.innerHTML = full_text_div.innerHTML;
    }
  }  
END_JS

    $javascript .= "</script>"; 
  return $javascript; 
}

sub jsClearColumnOnEdit {

  my $self = shift;
  
  my $javascript = "<script language='javascript' type='text/javascript'>\n";
  $javascript .= <<'END_JS';

  function clearColumnOnEdit(prefix) {
    
    // iterate through fields and clear those with the regex ${prefix}_\d+
    // not real clean but should be reasonably safe
	
    var field_name_regex = new RegExp(prefix + "_" + "\\d+");
    var fields = document.getElementsByTagName("textarea");
    
    for (i=0; i<fields.length; i++) {
      
      if (fields[i].name.search(field_name_regex) != -1) {
	fields[i].value = '';
      }
    }
  }
END_JS

    $javascript .= "</script>";

    return $javascript;
}

sub jsSortHeader {
  
  my $javascript = "<script language='javascript' type='text/javascript'>\n";
  $javascript .= << 'END_JS';


//  SortTable
//  version 2
//  7th April 2007
//  Stuart Langridge, http://www.kryogenix.org/code/browser/sorttable/
//  
//  Instructions:
//  Download this file

//  Add class="sortable" to any table you'd like to make sortable
//  Click on the headers to sort
//  
//  Thanks to many, many people for contributions and suggestions.
//  Licenced as X11: http://www.kryogenix.org/code/browser/licence.html
//  This basically means: do what you want with it.
//

 
var stIsIE = /*@cc_on!@*/false;

sorttable = {
  init: function() {
    // quit if this function has already been called
    if (arguments.callee.done) return;
    // flag this function so we don't do the same thing twice
    arguments.callee.done = true;
    // kill the timer
    if (_timer) clearInterval(_timer);
    
    if (!document.createElement || !document.getElementsByTagName) return;
    
    sorttable.DATE_RE = /^(\d\d?)[\/\.-](\d\d?)[\/\.-]((\d\d)?\d\d)$/;
    
    forEach(document.getElementsByTagName('table'), function(table) {
      if (table.className.search(/\bsortable\b/) != -1) {
        sorttable.makeSortable(table);
      }
    });
    
  },
  
  makeSortable: function(table) {
    if (table.getElementsByTagName('thead').length == 0) {
      // table doesn't have a tHead. Since it should have, create one and
      // put the first table row in it.
      the = document.createElement('thead');
      the.appendChild(table.rows[0]);
      table.insertBefore(the,table.firstChild);
    }
    // Safari doesn't support table.tHead, sigh
    if (table.tHead == null) table.tHead = table.getElementsByTagName('thead')[0];
    
    if (table.tHead.rows.length != 1) return; // can't cope with two header rows
    
    // Sorttable v1 put rows with a class of "sortbottom" at the bottom (as
    // "total" rows, for example). This is B&R, since what you're supposed
    // to do is put them in a tfoot. So, if there are sortbottom rows,
    // for backwards compatibility, move them to tfoot (creating it if needed).
    sortbottomrows = [];
    for (var i=0; i<table.rows.length; i++) {
      if (table.rows[i].className.search(/\bsortbottom\b/) != -1) {
        sortbottomrows[sortbottomrows.length] = table.rows[i];
      }
    }
    if (sortbottomrows) {
      if (table.tFoot == null) {
        // table doesn't have a tfoot. Create one.
        tfo = document.createElement('tfoot');
        table.appendChild(tfo);
      }
      for (var i=0; i<sortbottomrows.length; i++) {
        tfo.appendChild(sortbottomrows[i]);
      }
      delete sortbottomrows;
    }
    
    // work through each column and calculate its type
    headrow = table.tHead.rows[0].cells;
    for (var i=0; i<headrow.length; i++) {
      // manually override the type with a sorttable_type attribute
      if (!headrow[i].className.match(/\bsorttable_nosort\b/)) { // skip this col
        mtch = headrow[i].className.match(/\bsorttable_([a-z0-9]+)\b/);
        if (mtch) { override = mtch[1]; }
	      if (mtch && typeof sorttable["sort_"+override] == 'function') {
	        headrow[i].sorttable_sortfunction = sorttable["sort_"+override];
	      } else {
	        headrow[i].sorttable_sortfunction = sorttable.guessType(table,i);
	      }
	      // make it clickable to sort
	      headrow[i].sorttable_columnindex = i;
	      headrow[i].sorttable_tbody = table.tBodies[0];
	      dean_addEvent(headrow[i],"click", function(e) {

          if (this.className.search(/\bsorttable_sorted\b/) != -1) {
            // if we're already sorted by this column, just 
            // reverse the table, which is quicker
            sorttable.reverse(this.sorttable_tbody);
            this.className = this.className.replace('sorttable_sorted',
                                                    'sorttable_sorted_reverse');
            this.removeChild(document.getElementById('sorttable_sortfwdind'));
            sortrevind = document.createElement('span');
            sortrevind.id = "sorttable_sortrevind";
            sortrevind.innerHTML = stIsIE ? '&nbsp<font face="webdings">5</font>' : '&nbsp;&#x25B4;';
            this.appendChild(sortrevind);
            return;
          }
          if (this.className.search(/\bsorttable_sorted_reverse\b/) != -1) {
            // if we're already sorted by this column in reverse, just 
            // re-reverse the table, which is quicker
            sorttable.reverse(this.sorttable_tbody);
            this.className = this.className.replace('sorttable_sorted_reverse',
                                                    'sorttable_sorted');
            this.removeChild(document.getElementById('sorttable_sortrevind'));
            sortfwdind = document.createElement('span');
            sortfwdind.id = "sorttable_sortfwdind";
            sortfwdind.innerHTML = stIsIE ? '&nbsp<font face="webdings">6</font>' : '&nbsp;&#x25BE;';
            this.appendChild(sortfwdind);
            return;
          }
          
          // remove sorttable_sorted classes
          theadrow = this.parentNode;
          forEach(theadrow.childNodes, function(cell) {
            if (cell.nodeType == 1) { // an element
              cell.className = cell.className.replace('sorttable_sorted_reverse','');
              cell.className = cell.className.replace('sorttable_sorted','');
            }
          });
          sortfwdind = document.getElementById('sorttable_sortfwdind');
          if (sortfwdind) { sortfwdind.parentNode.removeChild(sortfwdind); }
          sortrevind = document.getElementById('sorttable_sortrevind');
          if (sortrevind) { sortrevind.parentNode.removeChild(sortrevind); }
          
          this.className += ' sorttable_sorted';
          sortfwdind = document.createElement('span');
          sortfwdind.id = "sorttable_sortfwdind";
          sortfwdind.innerHTML = stIsIE ? '&nbsp<font face="webdings">6</font>' : '&nbsp;&#x25BE;';
          this.appendChild(sortfwdind);

	        // build an array to sort. This is a Schwartzian transform thing,
	        // i.e., we "decorate" each row with the actual sort key,
	        // sort based on the sort keys, and then put the rows back in order
	        // which is a lot faster because you only do getInnerText once per row
	        row_array = [];
	        col = this.sorttable_columnindex;
	        rows = this.sorttable_tbody.rows;
	        for (var j=0; j<rows.length; j++) {
	          row_array[row_array.length] = [sorttable.getInnerText(rows[j].cells[col]), rows[j]];
	        }
	        /* If you want a stable sort, uncomment the following line */
	        sorttable.shaker_sort(row_array, this.sorttable_sortfunction);
	        /* and comment out this one */
	        // row_array.sort(this.sorttable_sortfunction);
	        
	        tb = this.sorttable_tbody;
	        for (var j=0; j<row_array.length; j++) {
	          tb.appendChild(row_array[j][1]);
	        }
	        
	        delete row_array;
	      });
	    }
    }
  },
  
  guessType: function(table, column) {
    // guess the type of a column based on its first non-blank row
    sortfn = sorttable.sort_alpha;
    for (var i=0; i<table.tBodies[0].rows.length; i++) {
      text = sorttable.getInnerText(table.tBodies[0].rows[i].cells[column]);
      if (text != '') {
        if (text.match(/^-?[£$¤]?[\d,.]+%?$/)) {
          return sorttable.sort_numeric;
        }
        // check for a date: dd/mm/yyyy or dd/mm/yy 
        // can have / or . or - as separator
        // can be mm/dd as well
        possdate = text.match(sorttable.DATE_RE)
        if (possdate) {
          // looks like a date
          first = parseInt(possdate[1]);
          second = parseInt(possdate[2]);
          if (first > 12) {
            // definitely dd/mm
            return sorttable.sort_ddmm;
          } else if (second > 12) {
            return sorttable.sort_mmdd;
          } else {
            // looks like a date, but we can't tell which, so assume
            // that it's dd/mm (English imperialism!) and keep looking
            sortfn = sorttable.sort_ddmm;
          }
        }
      }
    }
    return sortfn;
  },
  
  getInnerText: function(node) {
    // gets the text we want to use for sorting for a cell.
    // strips leading and trailing whitespace.
    // this is *not* a generic getInnerText function; it's special to sorttable.
    // for example, you can override the cell text with a customkey attribute.
    // it also gets .value for <input> fields.
    
    hasInputs = (typeof node.getElementsByTagName == 'function') &&
                 node.getElementsByTagName('input').length;
   
    // getAttribute fails on FF for node type 3

    if (node.nodeType != 3 && node.getAttribute("sorttable_customkey") != null) {
        return node.getAttribute("sorttable_customkey");
    }
    
    else if (typeof node.textContent != 'undefined' && !hasInputs) {
      return node.textContent.replace(/^\s+|\s+$/g, '');
    }
    else if (typeof node.innerText != 'undefined' && !hasInputs) {
      return node.innerText.replace(/^\s+|\s+$/g, '');
    }
    else if (typeof node.text != 'undefined' && !hasInputs) {
      return node.text.replace(/^\s+|\s+$/g, '');
    }
    else {
      switch (node.nodeType) {
        case 3:
          if (node.nodeName.toLowerCase() == 'input') {
            return node.value.replace(/^\s+|\s+$/g, '');
          }
        case 4:
          return node.nodeValue.replace(/^\s+|\s+$/g, '');
          break;
        case 1:
        case 11:
          var innerText = '';
          for (var i = 0; i < node.childNodes.length; i++) {
            innerText += sorttable.getInnerText(node.childNodes[i]);
          }
          return innerText.replace(/^\s+|\s+$/g, '');
          break;
        default:
          return '';
      }
    }
  },
  
  reverse: function(tbody) {
    // reverse the rows in a tbody
    newrows = [];
    for (var i=0; i<tbody.rows.length; i++) {
      newrows[newrows.length] = tbody.rows[i];
    }
    for (var i=newrows.length-1; i>=0; i--) {
       tbody.appendChild(newrows[i]);
    }
    delete newrows;
  },
  
  /* sort functions
     each sort function takes two parameters, a and b
     you are comparing a[0] and b[0] */
  sort_numeric: function(a,b) {
    aa = parseFloat(a[0].replace(/[^0-9.-]/g,''));
    if (isNaN(aa)) aa = 0;
    bb = parseFloat(b[0].replace(/[^0-9.-]/g,'')); 
    if (isNaN(bb)) bb = 0;
    return aa-bb;
  },
  sort_alpha: function(a,b) {
    if (a[0]==b[0]) return 0;
    if (a[0]<b[0]) return -1;
    return 1;
  },
  sort_ddmm: function(a,b) {
    mtch = a[0].match(sorttable.DATE_RE);
    y = mtch[3]; m = mtch[2]; d = mtch[1];
    if (m.length == 1) m = '0'+m;
    if (d.length == 1) d = '0'+d;
    dt1 = y+m+d;
    mtch = b[0].match(sorttable.DATE_RE);
    y = mtch[3]; m = mtch[2]; d = mtch[1];
    if (m.length == 1) m = '0'+m;
    if (d.length == 1) d = '0'+d;
    dt2 = y+m+d;
    if (dt1==dt2) return 0;
    if (dt1<dt2) return -1;
    return 1;
  },
  sort_mmdd: function(a,b) {
    mtch = a[0].match(sorttable.DATE_RE);
    y = mtch[3]; d = mtch[2]; m = mtch[1];
    if (m.length == 1) m = '0'+m;
    if (d.length == 1) d = '0'+d;
    dt1 = y+m+d;
    mtch = b[0].match(sorttable.DATE_RE);
    y = mtch[3]; d = mtch[2]; m = mtch[1];
    if (m.length == 1) m = '0'+m;
    if (d.length == 1) d = '0'+d;
    dt2 = y+m+d;
    if (dt1==dt2) return 0;
    if (dt1<dt2) return -1;
    return 1;
  },
  
  shaker_sort: function(list, comp_func) {
    // A stable sort function to allow multi-level sorting of data
    // see: http://en.wikipedia.org/wiki/Cocktail_sort
    // thanks to Joseph Nahmias
    var b = 0;
    var t = list.length - 1;
    var swap = true;

    while(swap) {
        swap = false;
        for(var i = b; i < t; ++i) {
            if ( comp_func(list[i], list[i+1]) > 0 ) {
                var q = list[i]; list[i] = list[i+1]; list[i+1] = q;
                swap = true;
            }
        } // for
        t--;

        if (!swap) break;

        for(var i = t; i > b; --i) {
            if ( comp_func(list[i], list[i-1]) < 0 ) {
                var q = list[i]; list[i] = list[i-1]; list[i-1] = q;
                swap = true;
            }
        } // for
        b++;

    } // while(swap)
  }  
}

/* ******************************************************************
   Supporting functions: bundled here to avoid depending on a library
   ****************************************************************** */

// Dean Edwards/Matthias Miller/John Resig

/* for Mozilla/Opera9 */
if (document.addEventListener) {
    document.addEventListener("DOMContentLoaded", sorttable.init, false);
}

/* for Internet Explorer */
/*@cc_on @*/
/*@if (@_win32)
    document.write("<script id=__ie_onload defer src=javascript:void(0)><\/script>");
    var script = document.getElementById("__ie_onload");
    script.onreadystatechange = function() {
        if (this.readyState == "complete") {
            sorttable.init(); // call the onload handler
        }
    };
/*@end @*/

/* for Safari */
if (/WebKit/i.test(navigator.userAgent)) { // sniff
    var _timer = setInterval(function() {
        if (/loaded|complete/.test(document.readyState)) {
            sorttable.init(); // call the onload handler
        }
    }, 10);
}

/* for other browsers */
window.onload = sorttable.init;

// written by Dean Edwards, 2005
// with input from Tino Zijdel, Matthias Miller, Diego Perini

// http://dean.edwards.name/weblog/2005/10/add-event/

function dean_addEvent(element, type, handler) {
	if (element.addEventListener) {
		element.addEventListener(type, handler, false);
	} else {
		// assign each event handler a unique ID
		if (!handler.$$guid) handler.$$guid = dean_addEvent.guid++;
		// create a hash table of event types for the element
		if (!element.events) element.events = {};
		// create a hash table of event handlers for each element/event pair
		var handlers = element.events[type];
		if (!handlers) {
			handlers = element.events[type] = {};
			// store the existing event handler (if there is one)
			if (element["on" + type]) {
				handlers[0] = element["on" + type];
			}
		}
		// store the event handler in the hash table
		handlers[handler.$$guid] = handler;
		// assign a global event handler to do all the work
		element["on" + type] = handleEvent;
	}
};
// a counter used to create unique IDs
dean_addEvent.guid = 1;

function removeEvent(element, type, handler) {
	if (element.removeEventListener) {
		element.removeEventListener(type, handler, false);
	} else {
		// delete the event handler from the hash table
		if (element.events && element.events[type]) {
			delete element.events[type][handler.$$guid];
		}
	}
};

function handleEvent(event) {
	var returnValue = true;
	// grab the event object (IE uses a global event object)
	event = event || fixEvent(((this.ownerDocument || this.document || this).parentWindow || window).event);
	// get a reference to the hash table of event handlers
	var handlers = this.events[event.type];
	// execute each event handler
	for (var i in handlers) {
		this.$$handleEvent = handlers[i];
		if (this.$$handleEvent(event) === false) {
			returnValue = false;
		}
	}
	return returnValue;
};

function fixEvent(event) {
	// add W3C standard event methods
	event.preventDefault = fixEvent.preventDefault;
	event.stopPropagation = fixEvent.stopPropagation;
	return event;
};
fixEvent.preventDefault = function() {
	this.returnValue = false;
};
fixEvent.stopPropagation = function() {
  this.cancelBubble = true;
}

// Dean's forEach: http://dean.edwards.name/base/forEach.js
/*
	forEach, version 1.0
	Copyright 2006, Dean Edwards
	License: http://www.opensource.org/licenses/mit-license.php
*/

// array-like enumeration
if (!Array.forEach) { // mozilla already supports this
	Array.forEach = function(array, block, context) {
		for (var i = 0; i < array.length; i++) {
			block.call(context, array[i], i, array);
		}
	};
}

// generic enumeration
Function.prototype.forEach = function(object, block, context) {
	for (var key in object) {
		if (typeof this.prototype[key] == "undefined") {
			block.call(context, object[key], key, object);
		}
	}
};

// character enumeration
String.forEach = function(string, block, context) {
	Array.forEach(string.split(""), function(chr, index) {
		block.call(context, chr, index, string);
	});
};

// globally resolve forEach enumeration
var forEach = function(object, block, context) {
	if (object) {
		var resolve = Object; // default
		if (object instanceof Function) {
			// functions have a "length" property
			resolve = Function;
		} else if (object.forEach instanceof Function) {
			// the object implements a custom forEach method so use that
			object.forEach(block, context);
			return;
		} else if (typeof object == "string") {
			// the object is a string
			resolve = String;
		} else if (typeof object.length == "number") {
			// the object is array-like
			resolve = Array;
		}
		resolve.forEach(object, block, context);
	}
};

END_JS

    $javascript .= "</script>";

    return $javascript;
}

sub jsAddData {

  my $self = shift;

  my $tableId = $self->{parent}->getTableId();
  
  my $javascript = "<script language='javascript' type='text/javascript'>\n";
  $javascript .= <<END_JS;

  var add_data_counter = 0;
  var row_counter = 1;

  function addData() {

    add_data_counter++;
    
    var newFieldsNode = document.getElementById('readroot_$tableId').cloneNode(true);
    newFieldsNode.id = '';
    var rowFields = newFieldsNode.childNodes;

    for (var i=0;i<rowFields.length;i++) {
      var theName = rowFields[i].name; 
      var theId = rowFields[i].id;

      // special handling for the jscalendar integration
      // using id here as div tag name attribute is not supported by FF

      if (theId == "jscalsetup_$tableId") {
	// change the name of the input and span
	
	var calFields = rowFields[i].childNodes;
 	
	// hidden input field

	calFields[0].name = calFields[0].name + '_-' + add_data_counter + '_-' + add_data_counter + '_-' + add_data_counter;
	calFields[0].id = calFields[0].name;

	// text display and trigger

	calFields[2].id = calFields[2].id + '_-' + add_data_counter + '_-' + add_data_counter + '_-' + add_data_counter;
       
	// call the calendar setup

	var calSetup = { inputField : calFields[0],
			 ifFormat : "%Y-%m-%d",
			 displayArea : calFields[2],
			 daFormat : "%Y-%m-%d",
			 cache : true    
                       };
 
	Calendar.setup(calSetup);     
      }
      else if (theName) {
 	rowFields[i].name = theName + '_-' + add_data_counter + '_-' + add_data_counter + '_-' + add_data_counter;
	rowFields[i].id = rowFields[i].name;
      }     
    }
    
    // add table cells and move the nodes into them

    var newrow = document.getElementById('addData').insertRow(row_counter);
    var fieldCount = 0;

    while(rowFields.length > 0) {
      var cell = newrow.insertCell(fieldCount++);
      // note that the following method modifies the collection
      cell.appendChild(rowFields[0]);
    }
  }
END_JS

  $javascript .= "</script>";
  return $javascript;
}

sub jsCalendar10Setup {

  my $self = shift;
  my $calendarDir = $self->{parent}->getCalendarDir();

  my $javascript = "<style type='text/css'>\@import url($calendarDir/calendar-win2k-1.css);</style>\n";
  $javascript .=  "<script type='text/javascript' src='$calendarDir/calendar.js'></script>\n";
  $javascript .=  "<script type='text/javascript' src='$calendarDir/lang/calendar-en.js'></script>\n";
  $javascript .=  "<script type='text/javascript' src='$calendarDir/calendar-setup.js'></script>\n";
  
  return $javascript;
}

sub jsToolTip {

  my $self = shift;

  my $javascript = "<script language='javascript' type='text/javascript'>\n";
  $javascript .= <<'END_JS';

  // from OReilly Javascript - The Definitive Guide

  // must put in body

  var Geometry = {};
  
  // IE
      
      if (window.screenLeft) {
	Geometry.getWindowX = function() { return window.screenLeft; };
	Geometry.getWindowY = function() { return window.screenTop; };
  }
  
  // Firefox
      
      else if (window.screenX) {
	Geometry.getWindowX = function() { return window.screenX; };
	Geometry.getWindowY = function() { return window.screenY; };
  }
  
  
  // all but IE
      
      if (window.innerWidth) {
	
	Geometry.getViewportWidth = function() { return window.innerWidth; };
	Geometry.getViewportHeight = function() { return window.innerHeight; };
	Geometry.getHorizontalScroll = function() { return window.pageXOffset; };
	Geometry.getVerticalScroll = function() { return window.pageYOffset; };
  }
  
  // IE 6 w DOCTYPE
      
      else if (document.documentElement && document.documentElement.clientWidth) {
	
	Geometry.getViewportWidth = function() { return document.documentElement.clientWidth; };
	Geometry.getViewportHeight = function() { return document.documentElement.clientHeight; };
	Geometry.getHorizontalScroll = function() { return document.documentElement.scrollLeft; };
	Geometry.getVerticalScroll = function() { return document.documentElement.scrollTop; };
  }
  
  // all other IE (not sure about 7)
      
      else {
	
	Geometry.getViewportWidth = function() { return document.body.clientWidth; };
	Geometry.getViewportHeight = function() { return document.body.clientHeight; };
	Geometry.getHorizontalScroll = function() { return document.body.scrollLeft; };
	Geometry.getVerticalScroll = function() { return document.body.scrollTop; };
  }
  
  // document size
      
      if (document.documentElement && document.documentElement.scrollWidth) {
	Geometry.getDocumentWidth = function() { return document.documentElement.scrollWidth; };
	Geometry.getDocumentHeight = function() { return document.documentElement.scrollHeight; };
  }
  
  else if (document.body.scrollWidth) {
    Geometry.getDocumentWidth = function() { return document.body.scrollWidth; };
    Geometry.getDocumentHeight = function() { return document.body.scrollHeight; };
  }
  
  // tooltips from Javascript, the Definitive Guide
      
  function Tooltip()  {
    
    this.tooltip = document.createElement('div');
    this.tooltip.style.position = 'absolute';
    this.tooltip.style.visibility = 'hidden';
    //   this.tooltip.className = 'tooltipShadow';
    
    this.content = document.createElement('div');
    this.content.style.position = 'relative';
//    this.content.className = 'tooltipContent';
   
    // default properties

    this.content.style.backgroundColor = '#ff0';
    this.content.style.padding = '5px';
    this.content.style.border = 'solid black 1px';
    
    this.tooltip.appendChild(this.content);   
  }
  
  Tooltip.prototype.show = function(text, x, y) {
    this.content.innerHTML = text;
    this.tooltip.style.left = x + 'px';
    this.tooltip.style.top = y + 'px';
    this.tooltip.style.visibility = 'visible';

    if (this.tooltip.parentNode != document.body) document.body.appendChild(this.tooltip);
  };

  // hide it

  Tooltip.prototype.hide = function() {
     this.tooltip.style.visibility = 'hidden';
  }

  Tooltip.X_OFFSET = 25; // pixels right
  Tooltip.Y_OFFSET = 15; // pixels down
  Tooltip.DELAY = 500; // msec

  Tooltip.prototype.schedule = function(target, e) {
    
    var text = target.getAttribute('tooltip');
    if(!text) return;
    
    var x = e.clientX + Geometry.getHorizontalScroll();
    var y = e.clientY + Geometry.getVerticalScroll();

    x += Tooltip.X_OFFSET;
    y += Tooltip.Y_OFFSET;

    var self = this;
    
    var timer = window.setTimeout(function() { self.show(text, x, y); }, Tooltip.DELAY);
    
    if(target.addEventListener) target.addEventListener('mouseout', mouseout, false);
    else if (target.attachEvent) target.attachEvent('onmouseout', mouseout);
    else target.onmouseout = mouseout;

    function mouseout() {
	
	self.hide();
	window.clearTimeout(timer);
	if (target.removeEventListener) target.removeEventListener('mouseout', mouseout, false);
	else if (target.detachEvent) target.detachEvent('onmouseout', mouseout);
	else target.onmouseout = null;
    }
}

// global tooltip

Tooltip.tooltip = new Tooltip();
Tooltip.schedule = function(target, e) { Tooltip.tooltip.schedule(target, e); }
END_JS
    
    $javascript .= "</script>";

    return $javascript;
}

=head1 COPYRIGHT & LICENSE

Copyright 2010 Freescale Semiconductor, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of HTML::EditableTable::JavaScript
