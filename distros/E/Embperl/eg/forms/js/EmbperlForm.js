function set_grid_display(doc, elm, display)
    {
    var elements = elm.getElementsByTagName('table');
    for (var i = 0; i < elements.length ; i++)
        {
        if(elements[i].className.search('cGridTable') != -1)
            {
            elements[i].style.display = display;
            }
        }
    }

function set_display(doc, value,display)
    {
    var elm ;
    if (elm = doc.getElementById(value))
        {
        elm.style.display = display ;
        set_grid_display(doc, elm,display);
        }
    j = 10 ;
    dummy= value + j;
    while (elm = doc.getElementById(dummy) )
        {
        elm.style.display = display ;
        j++ ;
        dummy= value + j;
        }
    }

function set_class(doc, name, classval)
    {
    var obj = doc.getElementById(name) ;
    if (obj)
        obj.className = classval ;
    }

function show_id_setobj(doc, value, name)
    {
    var obj = doc.getElementById(name) ;
    if (obj)
        obj.value = value ;

    set_display(doc, value, "") ;
    }


function tab_selected(doc, value, name)
    {
    var obj = doc.getElementById(name) ;

    if (obj && obj.value)
            {
            set_display(doc, obj.value, "none") ;
            set_class(doc, '__tabs_' + obj.value, 'cTabDivOff') ;
            }

    set_class(doc, '__tabs_' + value, 'cTabDivOn') ;
    show_id_setobj(doc, value, name) ;
    }

function show_selected(doc, obj)
    {
    var i ;
    var x = obj.selectedIndex ;
    var name = obj.name ;
    var elm ;
    var baseid = name + '-'  ;
    for (i=0;i<obj.options.length;i++)
        {
        if (obj.options[i].value != '')
            {
            elm = doc.getElementById(baseid + (i + 1)) ;
            if (elm)
                {
                if (i == x)
                    {
                    elm.style.display = "" ;
                    }
                else
                    {
                    elm.style.display = "none" ;
                    }
                }
            j = 10 ;
	    dummy = baseid + i + '-' + j;
            while (elm = doc.getElementById(dummy) )
                {
                if (i == x)
                    {
                    elm.style.display = "" ;
                    }
                else
                    {
                    elm.style.display = "none" ;
                    }
                j++ ;
	        dummy = baseid + i + '-' + j;
                }
            }
        }
    }


function show_checked(doc, obj)
    {
    var i ;
    var x = obj.checked?0:1 ;
    var name = obj.name ;
    var elm ;
    var baseid = name + '-'  ;
    for (i=0;i<2;i++)
        {
        elm = doc.getElementById(baseid + i) ;
        if (elm)
            {
            if (i == x)
                {
                elm.style.display = "" ;
                }
            else
                {
                elm.style.display = "none" ;
                }
            }
        j = 10 ;
        dummy = baseid + i + '-' + j;
        while (elm = doc.getElementById(dummy) )
            {
            if (i == x)
                {
                elm.style.display = "" ;
                }
            else
                {
                elm.style.display = "none" ;
                }
            j++ ;
            dummy = baseid + i + '-' + j;
            }
        }
    }

function show_radio_checked(doc, obj,x,max)
    {
    var i ;
    var name = obj.name ;
    var elm ;
    var baseid = name + '-'  ;

    for (i=0;i<=max;i++)
        {
        elm = doc.getElementById(baseid + i) ;
        if (elm)
            {
            if (i == x)
                {
                elm.style.display = "" ;
                }
            else
                {
                elm.style.display = "none" ;
                }
            }
        j = 10 ;
        dummy = baseid + i + '-' + j;
        while (elm = doc.getElementById(dummy) )
            {
            if (i == x)
                {
                elm.style.display = "" ;
                }
            else
                {
                elm.style.display = "none" ;
                }
            j++ ;
        dummy = baseid + i + '-' + j;
            }
        }
    }
function submitvalue (form, name, value)
    {
    var e=form.ownerDocument.createElement('input');
    e.type='hidden';
    e.name=name;
    e.value=value;
    form.appendChild(e);
    form.submit()    
    }

function addremoveInitOptions (doc, src, dest, send, removesource)
    {
    var i ;
	var j ;
	var found = 0 ;
	var val ;
    var vals = send.value.split("\t") ;
    for (i = 0; i < vals.length; i++)
        {
        val = vals[i] ;
        found = 0 ;
        for (j = 0; j < src.length; j++)
            {
            if (src.options[j].value == val)
        	   {
        	   found = 1 ;
        	   break ;
        	   }
            }
        if (found)
        	{
            var newopt = doc.createElement('OPTION') ;
            var oldopt = src.options[j] ;
            newopt.text = oldopt.text ;
            newopt.value = oldopt.value ;
            dest.options.add(newopt) ;
        	}
        }
     if (removesource)
         {
         for (i = 0; i < src.length; i++)
             {
             val = src.options[i].value ;
             for (j = 0; j < vals.length; j++)
                 {
                 if (vals[j] == val)
        	         {
                     src.options[i] = null ;
        	         i-- ;
        	         break ;
        	         }
                 }
             }
         }
     }

function addremoveBuildOptions (dest, send)
    {
    var i ;
    var val = '' ;
    for (i = 0; i < dest.length; i++)
        {
        val += dest.options[i].value ;
        if (i < dest.length - 1)
            val += "\t" ;
        }
    send.value=val ;
    }

function addremoveAddOption (doc, src, dest, send, removesource)
    {
    if (src.selectedIndex >= 0)
        {
        var newopt = doc.createElement('OPTION') ;
        var oldopt = src.options[src.selectedIndex] ;
        newopt.text = oldopt.text ;
        newopt.value = oldopt.value ;
        dest.options.add(newopt) ;
        if (removesource)
            src.options[src.selectedIndex] = null ;
        addremoveBuildOptions (dest, send) ;
        }
    else
        alert ("Bitte einen Eintrag zum Hinzufügen auswählen") ;

    }

function addremoveRemoveOption (doc, src, dest, send, removesource)
    {
    if (dest.selectedIndex >= 0)
        {
        if (removesource)
			{
            var newopt = doc.createElement('OPTION') ;
            var oldopt = dest.options[dest.selectedIndex] ;
            newopt.text = oldopt.text ;
            newopt.value = oldopt.value ;
            src.options.add(newopt) ;
            }
        //dest.options.remove(dest.selectedIndex) ;
        dest.options[dest.selectedIndex] = null ;
        addremoveBuildOptions (dest, send) ;
        }
    else
        alert ("Bitte einen Eintrag zum Entfernen auswählen") ;

    }

// -----------------------------------------------------------------------------

function autocomplete_req ( request, response)
    {
    var term = request.term;

    var url=this.options.url;
    var terms = term.split (' ', 1) ;
    var i = encodeURIComponent(terms[0]);
    url=url.replace(/%term%/g, i); 
    url=url.replace(/%datasrc%/g, this.options.datasrc); 

    $.getJSON( url, request,
        function( data, status, xhr )
            {
            response( data )
            }
        );
    } ;

function autocomplete_setup (elem, opts)
    {
    function autocomplete_select (event, ui)
        {
        id = this.id ;
        ctlname = id.replace (/_inp_/, '') ;
        ctlid   = id.replace (/_inp_/, '_id_') ;
        
        document.getElementById(ctlname).value = ui.item.post ;
        document.getElementById(ctlid).value = ui.item.id ;
    
        if (opts.show_on_select)
            {
            i = encodeURIComponent(ui.item.id);
            if (opts.use_ajax)
                {
                $('#' + opts.use_ajax).doload (opts.showurl.replace(/%id%/g, i)) ;
                document.getElementById(ctlname).value = '' ;
                document.getElementById(ctlid).value = '' ;
                document.getElementById(id).value = '' ;
                return false ;
                }
            else
                location.href=opts.showurl.replace(/%id%/g, i); 
            }
    
        return true ;
        } ;




    elem.autocomplete(
        {
        source: autocomplete_req, 
        select: autocomplete_select,
        minLength: 3,
        delay:     400,
        url:    opts.datasrcurl,
        datasrc: opts.datasrc
        }) ;

    var id = elem[0].id ;
    var ctlid   = id.replace (/_inp_/, '_id_') ;

    elem.qtip(
        {
        content: {
            text: '<img style="text-align: center" src="/_appserv/css/images/ui-anim_basic_16x16.gif" alt="Loading..." />',
            ajax: {
               url: '#', // URL to the local file
               type: 'GET', // POST or GET
               once: false,
               xcache: false,
               idsrc: document.getElementById (ctlid),
               urlsrc: opts.popupurl,                                        
               urlfunc: function (opts)
                  {
                  i = encodeURIComponent(opts.idsrc.value);
                  if (i)
                        {                  
                        opts.url=opts.urlsrc.replace(/%id%/g, i);
                        return true ;
                        }
                  return false ;
                  }
               }
            },
        position: {
           at: 'bottom center', // Position the tooltip above the link
           my: 'top center',
           adjust: { screen: true } // Keep the tooltip on-screen at all times
        },
        show: {
           event: 'mouseenter',
           solo: true, // Only show one tooltip at a time
           delay: 1000
        },
        hide: {
           event: 'mouseleave click',
           fixed: true,
           delay: 300
        },   
        style: {
           classes: 'ui-tooltip-blue ui-tooltip-shadow',
           xwidget: true
        }
    });

    elem.dblclick (
        function (event)
            {
            i = encodeURIComponent(document.getElementById(ctlid).value);
            if (opts.use_ajax)
                {
                $('#' + opts.use_ajax).doload (opts.showurl.replace(/%id%/g, i)) ;
                }
            else
                location.href=opts.showurl.replace(/%id%/g, i); 
            }    
        ) ;
    }



// -----------------------------------------------------------------------------


function control_link_setup (elem, opts)
    {

    var id = elem[0].id ;
    var ctlid   = id.replace (/_inp_/, '') ;

    elem.qtip(
        {
        content: {
            text: '<img style="text-align: center" src="/_appserv/css/images/ui-anim_basic_16x16.gif" alt="Loading..." />',
            ajax: {
               url: '#', // URL to the local file
               type: 'GET', // POST or GET
               once: false,
               xcache: false,
               idsrc: document.getElementById (ctlid),
               urlsrc: opts.popupurl,                                        
               urlfunc: function (opts)
                  {
                  var id = opts.idsrc.value ;  
                  id = id.replace(/^.+@#/, '');
                  i = encodeURIComponent(id);
                  if (i)
                        {                  
                        opts.url=opts.urlsrc.replace(/%id%/g, i);
                        return true ;
                        }
                  return false ;
                  }
               }
            },
        position: {
           at: 'bottom center', // Position the tooltip above the link
           my: 'top center',
           adjust: { screen: true } // Keep the tooltip on-screen at all times
        },
        show: {
           event: 'mouseenter',
           solo: true, // Only show one tooltip at a time
           delay: 1000
        },
        hide: {
           event: 'mouseleave click',
           fixed: true,
           delay: 300
        },   
        style: {
           classes: 'ui-tooltip-blue ui-tooltip-shadow',
           xwidget: true
        }
    });

    elem.click (
        function (event)
            {
            var id = document.getElementById(ctlid).value ;  
            id = id.replace(/^.+@#/, '');
            i = encodeURIComponent(id);
            if (opts.use_ajax)
                {
                $('#' + opts.use_ajax).doload (opts.showurl.replace(/%id%/g, i)) ;
                }
            else
                location.href=opts.showurl.replace(/%id%/g, i); 
            }    
        ) ;
    }



// -----------------------------------------------------------------------------

function add_qtip (elem, url)
    {

    elem.qtip(
        {
        content: {
            text: '<img style="text-align: center" src="/_appserv/css/images/ui-anim_basic_16x16.gif" alt="Loading..." />',
            ajax: {
               url: '#', // URL to the local file
               type: 'GET', // POST or GET
               once: false,
               url: url
               }
            },
        position: {
           at: 'bottom center', // Position the tooltip above the link
           my: 'top left',
           adjust: { screen: true } // Keep the tooltip on-screen at all times
        },
        show: {
           event: 'mouseenter',
           solo: true, // Only show one tooltip at a time
           delay: 1000
        },
        hide: {
           event: 'mouseleave click',
           fixed: true,
           delay: 300
        },   
        style: {
           classes: 'ui-tooltip-blue ui-tooltip-shadow',
           xwidget: true
        }
    });

    }



// -----------------------------------------------------------------------------


// -----------------------------------------------------------------------------

function eplGrid (tableelement, rowelement, maxelement, addelement, delelement,
                  upelement, downelement, onchange)
    {
    var self = this ;

    
    $.extend(self, {   
    initialize: function (tableelement, rowelement, maxelement, addelement,
                          delelement, upelement, downelement,
                          onchange)
        {
        this.rowelement   = rowelement ;
        this.maxelement   = maxelement ;
        this.tableelement = tableelement ;
        this.onchangehandler = onchange ;
        
        tableelement.click (function(e) {self.onClick (e)});
        tableelement.focus (function(e) {self.onClick (e)});
        tableelement.keyup (function(e) {self.onClick (e)});
        if (addelement)
            addelement.click (function(e) {self.addRow ()});
        if (delelement)
            delelement.click (function(e) {self.delRow ()});
        if (upelement)
            upelement.click (function(e) {self.upRow ()});
        if (downelement)
            downelement.click (function(e) {self.downRow ()});
    
        //rows = this.tableelement.getElementsByTagName('tr');
        var rows = tableelement.find('tr') ;
        var lastrow = rows.last() ;
        var newid    = this.tableelement[0].id ;    
        newid    = newid + '-row-' ;
        var lastid   = lastrow[0].id ;
        var idlength = newid.length ;
        this.lastnum  = parseInt (lastid.substr(idlength)) ;
        if (isNaN(this.lastnum))
            this.lastnum = -1 ;
        },
    
    
    addRow: function ()
        {
        var rows = this.tableelement.find('tr'); 
        var lastrow = rows.last() ;
    
        this.lastnum  = this.lastnum + 1 ;
        var inserttext = this.rowelement.html() ;
        var newtext  = inserttext.replace (/%row%/gi, this.lastnum) ;
        newtext  = newtext.replace (/<tbody>/gi, '') ;
        newtext  = newtext.replace (/<\/tbody>/gi, '') ;
        newtext  = newtext.replace (/<x-script/gi, '<script') ;
        newtext  = newtext.replace (/<\/x-script/gi, '</script') ;
        lastrow.after (newtext) ;
        this.maxelement[0].value = this.lastnum + 1 ;
        if (this.onchangehandler)
            this.onchangehandler (this.tableelement) ;
        },

    focusRow: function ()
        {
        var next = this.currRow ;
        if (next && next.className == 'cGridRow')
            {
            next.className='cGridRowSelected' ;
            while (next && (next.tagName != 'INPUT' || next.tagName != 'SELECT'))
                {
                next = next.firstChild ;
                }
            if (next)
                next.focus() ;
            }
        },

    delRow: function (row)
        {
        if (row != undefined)
            this.currRow = row ;
        if (this.currRow)
            {
            var next = $(this.currRow).next('tr') ;
            var p = this.currRow.parentNode ;
            p.removeChild(this.currRow) ;
            this.currRow = next[0] ;
            this.focusRow () ;
            if (this.onchangehandler)
                this.onchangehandler (this.tableelement) ;
            }
        },

    
    upRow: function (row) //TODO
        {
        if (row != undefined)
            this.currRow = row ;
        if (this.currRow)
            {
            var prev = $(this.currRow).prev ()[0] ;
            if (prev && prev.className == 'cGridRow')
                {
                var currorder = this.currRow.getElementsByTagName('input'); 
                var prevorder = prev.getElementsByTagName('input'); 
                var n = currorder[0].value ;
                currorder[0].value = prevorder[0].value ;
                prevorder[0].value = n ;
    
                var p = this.currRow.parentNode ;
                var currdata = p.removeChild(this.currRow) ;
                this.currRow = p.insertBefore(currdata, prev) ;
    
                this.focusRow () ;
                if (this.onchangehandler)
                    this.onchangehandler (this.tableelement) ;
                }
            }
    },

    downRow: function (row) //TODO
        {
        if (row != undefined)
            this.currRow = row ;
        if (this.currRow)
            {
            var next = $(this.currRow).next ()[0] ;
            if (next && next.className == 'cGridRow')
                {
                var currorder = this.currRow.getElementsByTagName('input'); 
                var nextorder = next.getElementsByTagName('input'); 
                var n = currorder[0].value ;
                currorder[0].value = nextorder[0].value ;
                nextorder[0].value = n ;
    
                var next2 = $(next).next ()[0] ;
                var p = this.currRow.parentNode ;
                var currdata = p.removeChild(this.currRow) ;
                this.currRow = p.insertBefore(currdata, next2) ;
    
                this.focusRow () ;
                if (this.onchangehandler)
                    this.onchangehandler (this.tableelement) ;
                }
            }
        },


    onClick: function (e)
        {
        var elem = e.target ;
        if (e.type == 'keyup' && ((e.which && e.which == e.DOM_VK_ADD) || e.keyCode == 107) && e.altKey)
            {
            this.addRow () ;
            e.cancelBubble = true ;
            return false ;
            }
    
        var p = elem ;
        while (p && p.tagName != 'TR')
            {
            p = p.parentNode ;
            }
        if (p)
            {
            if (this.currRow)
                this.currRow.className='cGridRow' ;
            
            if (p.className == 'cGridRow')
                {
                p.className='cGridRowSelected' ;
                this.currRow=p ;
                }
            else
                {
                this.currRow=null ;
                }
            if (this.currRow && e.type == 'keyup' && ((e.which && e.which == e.DOM_VK_SUBTRACT) || e.keyCode == 109) && e.altKey)
                {
                this.delRow (this.currRow) ;
                e.cancelBubble = true ;
                return false ;
                }
            }
        //alert ('t='+elem.tagName +' p='+ p.id+' c='+p.className) ;
        }
    }) ;
  
 self.initialize(tableelement, rowelement, maxelement, addelement, delelement,
                 upelement, downelement, onchange) ;  
    
 return self ;   
 } ;
 
 
$.fn.eplgrid = function(options)
    {
    var id = this[0].id ;
    var newrowid   = '__' + id + '_newrow' ;
    var maxid      = '__' + id + '_max' ;
    
    grid = new eplGrid (this, $('#' + newrowid), $('#' + maxid), $('#' + id + '-add'),
                        $('#' + id + '-del'), $('#' + id + '-up'), $('#' + id + '-down'),
                        options?options.onchange:null) ;
        
    }

// -----------------------------------------------------------------------------

function jsonErr2Html (json)
    {
    var html ;
    var data ;
    try
        {
        data = jQuery.parseJSON (json) ;
    
        if (data.error)
            {
            var reason = data.reason.replace (/(\{\[|<<|>>|\]\}|\r)/g, '').replace(/\n|\\n/g, '<br>')  ;
                
            html = '<p>Fehler: ' + data.error + '</p><p>' + reason + '</p>' ;
            if (data.func)
                html = html + '<p>Funktion: ' + data.func + '</p>' ;
            
            }
        else
            {
                
            html = json ;   
            }
        }
     catch (e)
        {
        html = json ;    
        }
    return html ;    
    }
    
// -----------------------------------------------------------------------------

$.fn.doload = function(url, params)
    {
    var type = params?'POST':'GET' ;
    var self = this ;
    
    self.css ('cursor','wait') ;
    $(self).find(':input').css ('cursor','wait') ;

    
    jQuery.ajax(
        {
        url: url,
        type: type,
        dataType: "html",
        data: params,
        // Complete callback (responseText is used internally)
        complete: function( jqXHR, status, responseText )
            {
            // Store the response as specified by the jqXHR object
            var responseText = jqXHR.responseText;
            // If successful, inject the HTML into all the matched elements
            /*
            if ( jqXHR.isResolved() )
                {
                // #4825: Get the actual response in case
                // a dataFilter is present in ajaxSettings
                jqXHR.done(function( r )
                        {
                        responseText = r;
                        });
                }
            */
            self.css ('cursor','auto') ;
            $(self).find(':input').css ('cursor','auto') ;

            if (status == "error" || responseText.substr (0, 1) == '{')
                {
                var dlgwidth = 300 ;
                var dlgheight = 'auto' ;
                var err = jsonErr2Html(responseText) ;
                $( "#dialogmsg").html (err) ;
                $( "#dialogbox").attr ('title', jqXHR.status + " " + jqXHR.statusText) ;
                if (err.length > 300)
                    {
                    dlgwidth = 800 ;
                    dlgheight = 600 ;
                    }
                    
                $( "#dialogbox" ).dialog(
                    {
                    modal: true,
                    width: dlgwidth,
                    height: dlgheight,
                    buttons:
                        {
                            Ok: function() {
                                    $( this ).dialog( "close" );
                            }
                        }
                    });
                }
            else 
                {
                try
                    {
                    data = jQuery.parseJSON (responseText) ;    
                    if (data.redirect)
                        {
                        self.doload (data.redirect) ;
                        return ;
                        }
                    }
                catch (e)
                    {
                        
                    }
                self.html(responseText );
                }
            }
        });
    }
    
// -----------------------------------------------------------------------------


function treeLoadKeyPath (path, silent, title)
    {
    var tree =  $("#tree").dynatree("getTree") ;
    if (tree)
        {
        var root_doc = tree.options.root_doc ;
        var newtitle = title ;
        
        if (root_doc)
            path = path.replace ('/' + root_doc, '') ;
        path = path.replace (/\/$/, "") ;

        var segList = path.split(tree.options.keyPathSeparator);
        var final_key = segList[segList.length-1] ;
        var active_node = tree.getActiveNode () ;
        var active_key ;
        if (active_node)
            active_key = active_node.data.key ;
        if (active_key != final_key)
            {
            tree.loadKeyPath(path, function(node, status)
                {
                if(status == "loaded")
                    {
                    // 'node' is a parent that was just traversed.
                    // If we call expand() here, then all nodes will be expanded
                    // as we go
                    node.expand();
                    }
                else if(status == "ok")
                    {
                    // 'node' is the end node of our path.
                    // If we call activate() or makeVisible() here, then the
                    // whole branch will be exoanded now
                    if (newtitle && node.data.title != newtitle)
                        node.setTitle(newtitle) ;
                    
                    if (silent)
                        node.activateSilently();
                    else
                        node.activate();
                    }
                });
            }
        else if (active_node && newtitle && active_node.data.title != newtitle)
            active_node.setTitle(newtitle) ;

        }
    }
    
// -----------------------------------------------------------------------------

function form_changehandler ()
    {
    $('#_apply').removeAttr ('disabled') ;   
    }

function form_changehandler_add (element)
    {
    $('#_apply').removeAttr ('disabled') ;   
    if (element)
        {
        $(element).find(':input').change (form_changehandler) ;
        $(element).find(':input').keypress (form_changehandler) ;
        }
    }

// -----------------------------------------------------------------------------

function add_history (id, text)
    {
    $('#__history').prepend ('<option value="' + id + '">' + text + '</option>') ;
    $('#__history')[0].selectedIndex = 1 ;
    }