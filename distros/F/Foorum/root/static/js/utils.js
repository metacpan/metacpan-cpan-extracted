$(function() {

    $(document.forms).each( function(theform) {
        
        // disabled the Submit and Reset when submit a form
        // to avoid duplicate submit
        $(theform).submit( function() {
            $('input:submit').attr( { disabled : 'disabled' } );
            $('input:reset').attr(  { disabled : 'disabled' } );
        } );
        
        // Press Ctrl+Enter to submit the form. like QQ.
        $(theform).keypress( function(evt) {
            var x = evt.keyCode;
            var q = evt.ctrlKey;
            
            if (q && (x == 13 || x == 10)) {
                theform.submit();
            }
        } );
    } );
    
    // follows are copied from datePicker/date.js
    // utility method
    var _zeroPad = function(num) {
        var s = '0'+num;
        return s.substring(s.length-2)
        //return ('0'+num).substring(-2); // doesn't work on IE :(
    };
    
   $(".date").each(function (i) {
        var s = $(this).text();
        if (! s) { return false; }

        var f = this.id; //format
        if (! f) {
            f = 'yyyy-mm-dd hh:ii:ss';
        }
        
        var d = new Date(1997, 1, 1, 1, 1, 1);
        var iY = f.indexOf('yyyy');
        if (iY > -1) {
            d.setFullYear(Number(s.substr(iY, 4)));
        }
        var iM = f.indexOf('mm');
        if (iM > -1) {
            d.setMonth(Number(s.substr(iM, 2)) - 1);
        }
        d.setDate(Number(s.substr(f.indexOf('dd'), 2)));
        d.setHours(Number(s.substr(f.indexOf('hh'), 2)));
        d.setMinutes(Number(s.substr(f.indexOf('ii'), 2)));
        d.setSeconds(Number(s.substr(f.indexOf('ss'), 2)));
        var timezoneOffset = -(new Date().getTimezoneOffset());
        d.setMinutes(d.getMinutes() + timezoneOffset);

        if (! isNaN(d.getFullYear()) && d.getFullYear() > 1997) {
            var toTime = new Date();
            var delta  = parseInt((toTime.getTime() - d.getTime()) / 1000);
            if ( $(this).hasClass('date_no_ago') ) {
                delta  = 86400 * 7;
            }
            var t;
            if (delta < 60) {
                t = 'less than a minute ago';
            } else if (delta < 120) {
                t = 'about a minute ago';
            } else if (delta < (45 * 60)) {
                t = (parseInt(delta / 60)).toString() + ' minutes ago';
            } else if (delta < (120 * 60)) {
                t = 'about an hour ago';
            } else if (delta < (24 * 60 * 60)) {
                t = 'about ' + (parseInt(delta / 3600)).toString() + ' hours ago';
            } else if (delta < (48 * 60 * 60)) {
                t = '1 day ago';
            } else {
                var days = (parseInt(delta / 86400)).toString();
                if (days > 5) {
                    t = f.split('yyyy').join(d.getFullYear())
                         .split('mm').join(_zeroPad(d.getMonth()+1))
                         .split('dd').join(_zeroPad(d.getDate()))
                         .split('hh').join(_zeroPad(d.getHours()))
                         .split('ii').join(_zeroPad(d.getMinutes()))
                         .split('ss').join(_zeroPad(d.getSeconds()));
                } else {
                    t = days + " days ago"
                }
            }

            $(this).text(t);
        }
   } );
} );

// jQuery.ui tabs() are too heavy when I only need the classes.
function tabize( ele_id, selected_id ) {
    
    // nothing is selected by default
    if ( typeof(selected_id) == 'undefined' ) selected_id = -1;
    
    $('#' + ele_id ).addClass('ftabs ui-tabs ui-widget ui-widget-content ui-corner-all');
    $('#' + ele_id + ' > ul:first').addClass('ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all');
    $('#' + ele_id + ' > div:first').addClass('ui-tabs-panel ui-widget-content ui-corner-bottom');
    
    // be smart
    $.each( $('#' + ele_id + ' > ul:first > li'), function(i) {
        if ( selected_id == i || $(this).attr('selected') == 'selected' ) {
            $(this).addClass('ui-corner-top ui-tabs-selected ui-state-active');
        } else {
            $(this).addClass('ui-state-default ui-corner-top');
        }
    } );
}