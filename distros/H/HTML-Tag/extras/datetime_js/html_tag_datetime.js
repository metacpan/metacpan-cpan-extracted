/* Main javascript for HTML::Tag::Date and HTML::Tag::Datetime */

var MonthDays = new Array(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
var MonthNames = new Array('Gennaio','Febbraio','Marzo','Aprile','Maggio',
'Giugno','Luglio','Agosto','Settembre','Ottobre','Novembre','Dicembre');

var ver4 = (document.layers || document.all) ? 1 : 0;
var justKeyPressed;

var append_func = new Array(append_years,append_months,append_days,append_hours,
	append_minutes);

window.onload = onLoad;

function onLoad() {
	var elements = document.getElementsByTagName('input');
	for (var i=0; i<elements.length; i++) {
		var element = elements[i];
		var type = '';
		if (element.getAttribute('htmltag')) 
			type = element.getAttribute('htmltag').toLowerCase();
		if ((type  == 'date') || (type == 'time') || (type == 'datetime')) {
			createHtmlTagElement(element,type);
		}
	}
}

function createHtmlTagElement(element, type) {
	var id 				= randomId(8);
	var name		 	= element.name;
	var hTE_id 		= name + '_' + id;
	var value			= element.value;
	var htmlTag, button;

	// create container
	htmlTagEl 		= document.createElement("SPAN")
	htmlTagEl.id	= hTE_id + '_span';

	// add real hidden field
	htmlTagEl.appendChild(getHidden(name,hTE_id,value));

	// replace original element with the HTMLTag Element
	element.parentNode.replaceChild(htmlTagEl,element);


	if ((type == 'date') || (type == 'datetime')) {
		createDateElements(htmlTagEl, hTE_id);
		var haveTime = (type == 'datetime') ? 24 : null;
		// button
		button 		= getButton(hTE_id,haveTime);
		// oh my god....for attach onclick handler to button in IE :-(
		if (button.attachEvent) {
			// for IE
			var format  = (typeof haveTime == "number") ? '%Y-%m-%d %H:%M' : '%Y-%m-%d';
			eval("button.onclick = function() {return showCalendar(this,'" + hTE_id + "', '" +
				format + "', " + 
				haveTime  + ", true)}");
		}
	}

	if (type == 'datetime') {
		htmlTagEl.appendChild(spanText('&nbsp;'));
	}

	if ((type == 'time') || (type == 'datetime')) {
		createTimeElements(htmlTagEl,hTE_id);
	}
	
	if (button) htmlTagEl.appendChild(button);
	syncVisible(hTE_id);
}

function createDateElements(htmlTagEl,hTE_id) {
	// create day,month,year SELECT elements
	
	// day 
	var day_s 		= getSelect();
	day_s.id			= '2_' + hTE_id;
	htmlTagEl.appendChild(day_s);
	append_days(day_s);
	if (day_s.attachEvent) {
		// for IE
		attachEventForIE(day_s);
	}
	// space
	htmlTagEl.appendChild(spanText('&nbsp;'));

	// month 
	var day_m 		= getSelect();
	day_m.id			= '1_' + hTE_id;
	htmlTagEl.appendChild(day_m);
	append_months(day_m);
	if (day_m.attachEvent) {
		// for IE
		attachEventForIE(day_m);
	}
	// space
	htmlTagEl.appendChild(spanText('&nbsp;'));

	// year 
	var day_y 		= getSelect();
	day_y.id			= '0_' + hTE_id;
	htmlTagEl.appendChild(day_y);
	append_years(day_y);
	if (day_y.attachEvent) {
		// for IE
		attachEventForIE(day_y);
	}
	// space
	htmlTagEl.appendChild(spanText('&nbsp;'));
}

function createTimeElements(htmlTagEl,hTE_id) {
	// create hours, minutes SELECT elements
	
	// hour 
	var hour_s 		= getSelect();
	hour_s.id			= '3_' + hTE_id;
	htmlTagEl.appendChild(hour_s);
	append_hours(hour_s);
	if (hour_s.attachEvent) {
		// for IE
		attachEventForIE(hour_s);
	}
	// space
	htmlTagEl.appendChild(document.createTextNode(':'));
	// hour 
	var min_s 		= getSelect();
	min_s.id			= '4_' + hTE_id;
	htmlTagEl.appendChild(min_s);
	append_minutes(min_s);
	if (min_s.attachEvent) {
		// for IE
		attachEventForIE(min_s);
	}
	// space
}

function getSelect() {
	var ret = document.createElement("SELECT");
	ret.setAttribute("size","1");
	ret.setAttribute("onblur","datetime_keydown(event)");
	ret.setAttribute("onkeydown","datetime_keydown(event)");
	return ret;
}

function getInput() {
	var ret = document.createElement("INPUT");
	ret.type="text";
	ret.setAttribute("size","2");
	ret.setAttribute("maxlength","2");
	ret.setAttribute("onblur","datetime_keydown(event)");
	ret.setAttribute("onkeydown","datetime_keydown(event)");
	return ret;
}

function getHidden(name, id, value) {
	var ret = document.createElement("INPUT");
	ret.type = 'hidden';
	ret.name = name;
	ret.id 	 = id;
	ret.value = value;
	return ret;
}

function getButton(id,haveTime) {
	var ret			= document.createElement("BUTTON");
	var format 	= (typeof haveTime == "number") ? '%Y-%m-%d %H:%M' : '%Y-%m-%d';	
	Element.update(ret,'...');
	ret.setAttribute('onclick',"return showCalendar(this,'" + id + "', '" 
		+ format + "', " + haveTime + ", true)");
	return ret;
}

       
function datetime_keydown(DnEvents) {
	if (justKeyPressed) return ;
	justKeyPressed = true;
	var uevent = (ver4) ? window.event : DnEvents;
	k = (ver4) ?  window.event.keyCode : DnEvents.which ;
	eventType = (ver4) ? event.type : DnEvents.type;
	visibleElement = (ver4) ?  window.event.srcElement : DnEvents.currentTarget ;
	hiddenElement = $(visibleElement.id.slice(2));
	// special keys
	// Ins
	if (k == 45) {
		setToday(hiddenElement);
		justKeyPressed = false;
		return;
	}
	
	var visibleType = visibleElement.tagName.toUpperCase();
	var visibleDateItem = visibleElement.id.substr(0,1);
	var mustSwicth	= 0;
	//$('debug').innerHTML = $('debug').innerHTML + '<br>' + k + '<br>' + visibleElement.id;
	mustSwitch =
						(visibleType == 'SELECT' || (visibleElement.value == '') || datetime_validate(visibleElement,visibleDateItem)) &&
		(
			(((k>47 && k<58) ||(k>95 && k<106)) && visibleType == 'SELECT') ||
			((k == 9 || k == 0) && visibleType == 'INPUT')  ||
			(k == 13 || k == 27)
		);
	if (mustSwitch) {
		visibleType == "INPUT" ? showCombo(visibleElement,k) : showInput(visibleElement,k);
	}
	syncHidden(hiddenElement);
	justKeyPressed = false;
}

function showCombo(element,k) {
	var visibleDateItem = element.id.substr(0,1);
	var value	= element.value;
	if (visibleDateItem == 'y') {
		if (value.toString().length == 2) value = '20' + value.toString();
	} else {
		if (value.toString().length == 1) value = '0' + value.toString();
	}

	// create SELECT ELEMENT
	var el		= getSelect();
 	el.id			= element.id;
	element.parentNode.replaceChild(el,element);
	append_func[visibleDateItem](el,value);
	el.focus();
	attachEventForIE(el);
}

function showInput(element,k) {
	// get currentValue
	var value = element.value;
	var dateItem = element.id.substr(0,1);

	// create INPUT ELEMENT
	var el 		= getInput();
	if (dateItem == '0') {
		el.setAttribute("size","4");
		el.setAttribute("maxlength","4");
	}
	el.id			= element.id;

	element.parentNode.replaceChild(el,element);

	el.focus();
	el.value 	= value;
	el.select()

	attachEventForIE(el);
}

function attachEventForIE(element) {
	// IE seems not to like setAttribute("on..") to attach event to dynamic controls
	// and set correctly events only after control has been added to page
	if (element.attachEvent) {
		element.attachEvent('onblur',datetime_keydown);
		element.attachEvent('onkeydown',datetime_keydown);
	}
}

function syncHidden(hiddenElement) {
	var giorno_obj 	= $("2_" + hiddenElement.id);
	var mese_obj 		= $("1_" + hiddenElement.id);
	var anno_obj 		= $("0_" + hiddenElement.id);
	var ohour				= $('3_' + hiddenElement.id);
	var omin				= $('4_' + hiddenElement.id);

	setHidden(hiddenElement,false,anno_obj.value,mese_obj.value,giorno_obj.value,
		ohour.value,omin.value)
}

function setToday(hiddenElement) {
	var today = new Date;
	setHidden(hiddenElement,true,today.getFullYear(),today.getMonth()+1,
		today.getDate(),today.getHours(),today.getMinutes());
}

function setHidden(hiddenElement,syncV,year,month,day,hour,min) {
	var value;
	if (month.toString() != '' && (month.toString().length == 1)) month = '0' + month.toString();
	if (day.toString()  != '' && (day.toString().length == 1)) day = '0' + day.toString();
	if (hour.toString() != '' && (hour.toString().length == 1)) hour = '0' + hour.toString();
	if (min.toString()  != '' && (min.toString().length == 1)) min = '0' + min.toString();
	if (year != '') {
		value = year + '-' + month + '-' + day;
		if (hour.toString() != '') value += ' ';
	}
	if (hour.toString() != '') {
		value += hour +':'+min + ':00';
	}
	$(hiddenElement).value = value;
	if (syncV) syncVisible(hiddenElement);
}

  function syncVisible(txtHiddenElementName) {
  	var hfield  = $(txtHiddenElementName)
  	var dta		= hfield.value.split('-');
		var time;
  	if (dta.length == 3) {
			// date(time)?
			time  = dta[2].split(' ');
			if (time.length == 2) {
				// date and time
				dta[2] = time[0];
				if (dta[0] == '0000' && dta[1] == '00' && dta[2] == '00') {
					time[0] = time[1] = null;
				} else {
					time = time[1].split(':');
				}
			}
  		setDateVisibleElement(txtHiddenElementName,dta[2],dta[1],dta[0],time[0],time[1]);
  	} else if (dta.length == 1) {
			// time	
			time = hfield.value.split(':');
  		setDateVisibleElement(txtHiddenElementName,null,null,null,time[0],time[1]);
		}
  }
  
  function setDateVisibleElement(txtHiddenElementName,giorno,mese,anno,hour,min) {
  	var giorno_obj 	= $("2_" + $(txtHiddenElementName).id);
    var mese_obj 		= $("1_" + $(txtHiddenElementName).id);
    var anno_obj 		= $("0_" + $(txtHiddenElementName).id);
		var ohour				= $('3_' + $(txtHiddenElementName).id);
		var omin				= $('4_' + $(txtHiddenElementName).id);
		if (mese && mese.toString() != '' && (mese.toString().length == 1)) mese = '0' + mese.toString();
		if (giorno && giorno.toString() != '' && (giorno.toString().length == 1)) giorno = '0' + giorno.toString();
		if (hour && hour.toString() != '' && (hour.toString().length == 1)) hour = '0' + hour.toString();
		if (min  && min.toString() != '' && (min.toString().length == 1)) min = '0' + min.toString();
    if (giorno_obj) giorno_obj.value=giorno;
    if (mese_obj) mese_obj.value=mese;     
    if (anno_obj) anno_obj.value=anno;
		if (ohour) ohour.value = hour;
		if (omin) omin.value = min;

  }
  
 // This function gets called when the end-user clicks on some date.
function selected(cal, date) {
  cal.sel.value = date; // just update the date in the input field.
  if (cal.dateClicked ) {
    	var y = cal.date.getFullYear();
      var m = cal.date.getMonth();     // integer, 0..11
      var d = cal.date.getDate();      // integer, 1..31
			var h = cal.date.getHours();
			var n = cal.date.getMinutes();
      m=m+1;
      if (m.toString().length == 1) m = '0' + m;
      if (d.toString().length == 1) d = '0' + d;
      if (h.toString().length == 1) h = '0' + h;
      if (n.toString().length == 1) n = '0' + n;
      setDateVisibleElement(_dynarch_popupCalendar.sel.id,d,m,y,h,n);
      cal.callCloseHandler();
  }
}

// And this gets called when the end-user clicks on the _selected_ date,
// or clicks on the "Close" button.  It just hides the calendar without
// destroying it.
function closeHandler(cal) {
  cal.hide();                        // hide the calendar
  _dynarch_popupCalendar = null;
  
}

// This function shows the calendar under the element having the given id.
// It takes care of catching "mousedown" signals on document and hiding the
// calendar if the click was outside.
function showCalendar(button,id, format, showsTime, showsOtherMonths) {
  var el = $(id);
  if (_dynarch_popupCalendar != null) {
    // we already have some calendar created
    _dynarch_popupCalendar.hide();                 // so we hide it first.
  } else {
    // first-time call, create the calendar.
    var cal = new Calendar(1, null, selected, closeHandler);
    // uncomment the following line to hide the week numbers
    // cal.weekNumbers = false;
		if (typeof showsTime == "number") {
			cal.showsTime = true;
			cal.time24 = (showsTime == 24);
		}
    if (showsOtherMonths) {
      cal.showsOtherMonths = true;
    }
    _dynarch_popupCalendar = cal;                  // remember it in the global var
    cal.setRange(1900, 2070);        // min/max year allowed.
    cal.create();
  }
  _dynarch_popupCalendar.setDateFormat(format);    // set the specified date format
  _dynarch_popupCalendar.parseDate(el.value);      // try to parse the text in field
  _dynarch_popupCalendar.sel = el;                 // inform it what input field we use

  // the reference element that we pass to showAtElement is the button that
  // triggers the calendar.  In this example we align the calendar bottom-right
  // to the button.
  _dynarch_popupCalendar.showAtElement(button, "Br");        // show the calendar

  return false;
}

function append_days(element,checked_value) {
	var oOption = document.createElement("OPTION");
	oOption.value = '';
	oOption.text = '';
	//oOption.selected = (checked_value == '');
	element.options.add(oOption);
	for (var num=1;num<32;num++) {	
		var oOption = document.createElement("OPTION");
		element.options.add(oOption); // Don't move...IE problems else :-D
		var val = (num.toString().length == 1) ? '0' + num :  num;
		var checked = (checked_value == val || checked_value == num) ? true : false;
		oOption.value = val;
		oOption.text = val;
		if (checked) oOption.selected = checked;
	}
}

function append_months(element,checked_value) {
	var oOption = document.createElement("OPTION");
	oOption.value = '';
	oOption.text = '';
	//oOption.selected = (checked_value == '');
	element.options.add(oOption);
	for (var num=1;num<13;num++) {	
		var oOption = document.createElement("OPTION");
		element.options.add(oOption); // Don't move...IE problems else :-D
		var key = (num.toString().length == 1) ? '0' + num :  num;
		var val = MonthNames[num-1];
		var checked = (checked_value == val || checked_value == num) ? true : false;
		oOption.value = key;
		oOption.text = val;
		if (checked) oOption.selected = checked;
	}
}

function append_years(element,checked_value) {
	var cyear = (new Date()).getFullYear();
	var oOption = document.createElement("OPTION");
	oOption.value = '';
	oOption.text = '';
	//oOption.selected = (checked_value == '');
	element.options.add(oOption);
	for (var num=cyear-100;num<cyear+100;num++) {	
		var oOption = document.createElement("OPTION");
		element.options.add(oOption); // Don't move...IE problems else :-D
		var key = num.toString();
		var val = key;
		var checked = (checked_value == val || checked_value == num) ? true : false;
		oOption.value = key;
		oOption.text = val;
		if (checked) oOption.selected = checked;
	}
}

function append_hours(element,checked_value) {
	var oOption = document.createElement("OPTION");
	oOption.value = '';
	oOption.text = '';
	//oOption.selected = (checked_value == '');
	element.options.add(oOption);
	for (var num=0;num<24;num++) {	
		var oOption = document.createElement("OPTION");
		element.options.add(oOption); // Don't move...IE problems else :-D
		var key = (num.toString().length == 1) ? '0' + num :  num;
		var val = key;
		var checked = (checked_value == val || checked_value == num) ? true : false;
		oOption.value = key;
		oOption.text = val;
		if (checked) oOption.selected = checked;
	}
}

function append_minutes(element,checked_value) {
	var oOption = document.createElement("OPTION");
	oOption.value = '';
	oOption.text = '';
	//oOption.selected = (checked_value == '');
	element.options.add(oOption);
	for (var num=0;num<60;num++) {	
		var oOption = document.createElement("OPTION");
		element.options.add(oOption); // Don't move...IE problems else :-D
		var key = (num.toString().length == 1) ? '0' + num :  num;
		var val = key;
		var checked = (checked_value == val || checked_value == num) ? true : false;
		oOption.value = key;
		oOption.text = val;
		if (checked) oOption.selected = checked;
	}
}

function datetime_validate(el,dateTimeType) {
	var isValid = true;
	switch(dateTimeType)
        {
        case '2':   isValid = validate_day(el); break       
        }
  return isValid;
}

function randomId(length) {
	var chars = "0123456789";
	var randomstring = '';
	for (var i=0; i<length; i++) {
		var rnum = Math.floor(Math.random() * chars.length);
		randomstring += chars.substring(rnum,rnum+1);
	}
	return randomstring;
}

function spanText(text) {
	var ospan = document.createElement("SPAN");
	ospan.innerHTML = text;
	return ospan;
}

// From prototype.js

function $() {
  var elements = new Array();
  for (var i = 0; i < arguments.length; i++) {
    var element = arguments[i];
    if (typeof element == 'string')
      element = document.getElementById(element);

    if (arguments.length == 1)
      return element;

    elements.push(element);
  }
  return elements;
}

Object.extend = function(destination, source) {
  for (property in source) {
    destination[property] = source[property];
  }
  return destination;
}

if (!window.Element) {
  var Element = new Object();
}

Object.extend(Element, {
	update: function(element, html) {
    var iHTML = html.stripScripts();
    $(element).innerHTML = iHTML;
    /* Avoid IE bug when setting the innerHTML Property of the Select Object */
    /* Ref: http://support.microsoft.com/default.aspx?scid=kb;en-us;276228 */
    if ($(element).tagName == 'SELECT' && $(element).innerHTML.substr(0,1) != '<') {
      $(element).innerHTML = '!~~~~~~!' + iHTML;
      $(element).outerHTML = $(element).outerHTML.replace('!~~~~~~!','');
    }
    setTimeout(function() {html.evalScripts()}, 10);
  }
} );

Object.extend(String.prototype, {
  stripScripts: function() {
    return this.replace(new RegExp(this.ScriptFragment, 'img'), '');
  },
	evalScripts: function() {
    return this.extractScripts().map(eval);
  },
  ScriptFragment: '(?:<script.*?>)((\n|\r|.)*?)(?:<\/script>)',
  extractScripts: function() {
    var matchAll = new RegExp(this.ScriptFragment, 'img');
    var matchOne = new RegExp(this.ScriptFragment, 'im');
    return (this.match(matchAll) || []).map(function(scriptTag) {
      return (scriptTag.match(matchOne) || ['', ''])[1];
    });
  }
} );

