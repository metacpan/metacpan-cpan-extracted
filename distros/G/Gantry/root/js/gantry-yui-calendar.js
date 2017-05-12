/*
Copyright (c) 2007, Tim Keefer. All rights reserved.
Code licensed under the Perl License:
version: .001
*/

/*

Synopsis 

<script type="text/javascript" 
    src="[% self.doc_rootp %]/js/yui/build/yahoo/yahoo.js"></script>
<script type="text/javascript" 
    src="[% self.doc_rootp %]/js/yui/build/event/event.js" ></script>
<script type="text/javascript" 
    src="[% self.doc_rootp %]/js/yui/build/dom/dom.js" ></script>
<script type="text/javascript" 
    src="[% self.doc_rootp %]/js/yui/build/calendar/calendar.js"></script>

<link type="text/css" rel="stylesheet" 
    href="[% self.doc_rootp %]/js/yui/build/calendar/assets/calendar.css">

<script type="text/javascript">

function init() {
    
    YAHOO.gantry.calendar.helper.init( 'date1', 
        {   fieldId: 'date1',
            mindate: "1/1/2001", 
            maxdate: "12/31/2020",
            title: 'date1',
            containerClass: 'date-container', 
            iframe: false 
        }    
    );

    YAHOO.gantry.calendar.helper.init( 'date1', 
        {   fieldId: 'date1',
            mindate: "1/1/2001", 
            maxdate: "12/31/2020",
            title: 'date1',
            containerClass: 'date-container', 
            iframe: false 
        }    
    );
    
}

YAHOO.util.Event.addListener(window, "load", init);

</script>
</head>
<body>

<input type='text' id="date1" name="date1" 
    value="4/19/2008" />

<br />

<input type='text' id="date2" name="date2" 
    value="2/19/2008" />

</body>

Requires

The YAHOO javascript libraries
http://developer.yahoo.com/yui

*/

YAHOO.namespace("gantry.calendar");
YAHOO.namespace("gantry.calendar.helper");

YAHOO.gantry.calendar.helper.show = function ( e, obj ) {
    
    var tg;    
    if ( e.target ) {        
        tg = e.target;    
    }    
    else {        
        tg = e.srcElement;    
    }
    
    YAHOO.gantry.calendar.helper.updateCal( 
        YAHOO.gantry.calendar[tg.id] 
    );
    
    YAHOO.gantry.calendar[tg.id].show();
}

YAHOO.gantry.calendar.helper.createHelperNodes = function ( obj ) {
    
    var fieldNode     = document.getElementById( obj.fieldId );
    var containerNode = document.getElementById( obj.containerId );
    
    if ( ! containerNode ) {
        var container = document.createElement('div');
        container.setAttribute( 'id', obj.containerId );
        container.setAttribute( 'class', obj.containerClass );

        fieldNode.parentNode.appendChild( container );

        
        var parts = obj.containerStyle.split(';');
    	for ( var i=0; i < parts.length; ++i ) {            
            if ( parts[i] ) {
    		    var style = parts[i].split(':');
                YAHOO.util.Dom.setStyle( container, style[0], style[1] );    		
            }
    	}
    	
    	if ( obj.containerStyle == '' ) {
            YAHOO.util.Dom.setStyle( container, 'display', 'none' );
            YAHOO.util.Dom.setStyle( container, 'position', 'absolute' );
            YAHOO.util.Dom.setStyle( container, 'top', '-16px' );
            YAHOO.util.Dom.setStyle( container, 'z-index', '2' );
            YAHOO.util.Dom.setStyle( container, 'left', '15px' );
            YAHOO.util.Dom.setStyle( container, 'overflow', 'hidden' );
    	}
    }

}

YAHOO.gantry.calendar.helper.updateCal = function ( obj ) {
	var txtDate1 = document.getElementById( obj.fieldId );

	if (txtDate1.value != "") {
		obj.select(txtDate1.value);

		var firstDate = obj.getSelectedDates()[0];
		obj.cfg.setProperty(
		    "pagedate", 
		    (firstDate.getMonth()+1) + "/" + firstDate.getFullYear()
		);

		obj.render();
	}
} 

YAHOO.gantry.calendar.helper.handleSelect = function (type,args,obj) {
	var dates   = args[0]; 
	var date    = dates[0];
	var year    = date[0], month = date[1], day = date[2];

    var txtDate1 = document.getElementById( obj.fieldId );
	txtDate1.value = month + "/" + day + "/" + year;

    YAHOO.util.Dom.setStyle(obj.containerId, 'display', 'none' );
}

YAHOO.gantry.calendar.helper.init = function ( field, opts ) {

    this.fieldId    = field;
    this.mindate    = '1/1/2002';
    this.maxdate    = '12/31/2020';
    this.close      = true;
    this.containerId    = this.fieldId + "-container";
    this.containerClass = '';
    this.containerStyle = '';

    this.buttonId     = this.fieldId + "-button";
    this.title      = 'select a date';
    this.iframe     = false;
    this.pages      = 1;
    
    if (opts) {
        for(var param in opts) {
            this[param] = opts[param];
        }
    }
     
    YAHOO.gantry.calendar.helper.createHelperNodes( this );
    
    var calWidget = this.pages > 1 ? 'CalendarGroup' : 'Calendar';

    YAHOO.gantry.calendar[this.fieldId] = new YAHOO.widget[calWidget](
	    this.buttonId, this.containerId, 
	    { 
	        mindate: this.mindate,
			maxdate: this.maxdate,
			close:   this.close, 
	        iframe:  this.iframe,
	        title:   this.title,
	        pages:   this.pages
		}
	);        

	YAHOO.gantry.calendar[this.fieldId].fieldId     = this.fieldId;
	YAHOO.gantry.calendar[this.fieldId].containerId = this.containerId;
	YAHOO.gantry.calendar[this.fieldId].buttonId    = this.buttonId;
 
    // why is there a scoping problem with this ? alway contains the last prop 
    // YAHOO.gantry.calendar[this.fieldId].prop = this;
    
	YAHOO.gantry.calendar[this.fieldId].selectEvent.subscribe(
	    YAHOO.gantry.calendar.helper.handleSelect, 
	    YAHOO.gantry.calendar[this.fieldId]
	);
	
	YAHOO.gantry.calendar[this.fieldId].render();
    
    YAHOO.util.Event.addListener(
        document.getElementById( this.fieldId ), 
        "click", 
        YAHOO.gantry.calendar.helper.show,
        YAHOO.gantry.calendar[this.fieldId]
    );	

}
