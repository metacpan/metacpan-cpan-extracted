// version: 2017-11-25
    /**
    * o--------------------------------------------------------------------------------o
    * | This file is part of the RGraph package - you can learn more at:               |
    * |                                                                                |
    * |                          http://www.rgraph.net                                 |
    * |                                                                                |
    * | RGraph is licensed under the Open Source MIT license. That means that it's     |
    * | totally free to use and there are no restrictions on what you can do with it!  |
    * o--------------------------------------------------------------------------------o
    */

    RGraph     = window.RGraph || {isRGraph: true};
    RGraph.SVG = RGraph.SVG || {};

// Module pattern
(function (win, doc, undefined)
{
    var RG  = RGraph,
        ua  = navigator.userAgent,
        ma  = Math,
        win = window,
        doc = document;



    RG.SVG.Pie = function (conf)
    {
        //
        // A setter that the constructor uses (at the end)
        // to set all of the properties
        //
        // @param string name  The name of the property to set
        // @param string value The value to set the property to
        //
        this.set = function (name, value)
        {
            if (arguments.length === 1 && typeof name === 'object') {
                for (i in arguments[0]) {
                    if (typeof i === 'string') {
                    
                        var ret = RG.SVG.commonSetter({
                            object: this,
                            name:   i,
                            value:  arguments[0][i]
                        });
                        
                        name  = ret.name;
                        value = ret.value;

                        this.set(name, value);
                    }
                }
            } else {
                    
                var ret = RG.SVG.commonSetter({
                    object: this,
                    name:   name,
                    value:  value
                });
                
                name  = ret.name;
                value = ret.value;

                this.properties[name] = value;

                // If setting the colors, update the originalColors
                // property too
                if (name === 'colors') {
                    this.originalColors = RG.SVG.arrayClone(value);
                    this.colorsParsed = false;
                }
            }

            return this;
        };








        this.id              = conf.id;
        this.uid             = RG.SVG.createUID();
        this.container       = document.getElementById(this.id);
        this.layers          = {}; // MUST be before the SVG tag is created!
        this.svg             = RG.SVG.createSVG({object: this,container: this.container});
        this.isRGraph        = true;
        this.width           = Number(this.svg.getAttribute('width'));
        this.height          = Number(this.svg.getAttribute('height'));
        this.data            = conf.data;
        this.type            = 'pie';
        this.angles          = [];
        this.colorsParsed    = false;
        this.originalColors  = {};
        this.gradientCounter = 1;
        this.nodes           = [];
        this.shadowNodes     = [];
        
        // Add this object to the ObjectRegistry
        RG.SVG.OR.add(this);
        
        // Set the DIV container to be inline-block
        this.container.style.display = 'inline-block';

        this.properties =
        {
            centerx: null,
            centery: null,
            radius:  null,
            
            gutterLeft:    35,
            gutterRight:   35,
            gutterTop:     35,
            gutterBottom:  35,
            
            colors: [
                '#f66', '#6f6', '#66f', '#ff6', '#6ff', '#ccc',
                'pink', 'orange', 'cyan', 'maroon', 'olive', 'teal'
            ],
            strokestyle:      'rgba(0,0,0,0)',
            
            margin:        3,
            
            textColor: 'black',
            textFont: 'sans-serif',
            textSize: 12,
            textBold: false,
            textItalic: false,
            labels: [],
            labelsSticks: true,
            labelsSticksHlength: 50,

            linewidth: 1,
            
            tooltips: null,
            tooltipsOverride: null,
            tooltipsEffect: 'fade',
            tooltipsCssClass: 'RGraph_tooltip',
            tooltipsEvent: 'click',
            
            highlightStroke: 'rgba(0,0,0,0)',
            highlightFill: 'rgba(255,255,255,0.7)',
            highlightLinewidth: 1,
            highlightStyle: 'normal',
            highlightStyleOutlineWidth: 7,
            
            title: '',
            titleSize: 16,
            titleX: null,
            titleY: null,
            titleHalign: 'center',
            titleValign: null,
            titleColor:  'black',
            titleFont:   null,
            titleBold:   false,
            titleItalic: false,
            
            titleSubtitle: null,
            titleSubtitleSize: 10,
            titleSubtitleX: null,
            titleSubtitleY: null,
            titleSubtitleHalign: 'center',
            titleSubtitleValign: null,
            titleSubtitleColor:  '#aaa',
            titleSubtitleFont:   null,
            titleSubtitleBold:   false,
            titleSubtitleItalic: false,
            
            shadow: false,
            shadowOffsetx: 2,
            shadowOffsety: 2,
            shadowBlur: 2,
            shadowOpacity: 0.25,
            
            exploded: 0,
            roundRobinMultiplier: 1,
            
            donut:              false,
            donutWidth:         75,

            key:            null,
            keyColors:      null,
            keyOffsetx:     0,
            keyOffsety:     0,
            keyTextOffsetx: 0,
            keyTextOffsety: -1,
            keyTextSize:    null,
            keyTextBold:    null,
            keyTextItalic:  null
        };




        //
        // Copy the global object properties to this instance
        //
        RG.SVG.getGlobals(this);





        /**
        * "Decorate" the object with the generic effects if the effects library has been included
        */
        if (RG.SVG.FX && typeof RG.SVG.FX.decorate === 'function') {
            RG.SVG.FX.decorate(this);
        }




        var prop = this.properties;








        //
        // The draw method draws the Bar chart
        //
        this.draw = function ()
        {
            // Fire the beforedraw event
            RG.SVG.fireCustomEvent(this, 'onbeforedraw');













            //(Re)set this so it doesn't grow endlessly
            this.angles = [];











            // Should the first thing that's done inthe.draw() function
            // except for the onbeforedraw event
            this.width  = Number(this.svg.getAttribute('width'));
            this.height = Number(this.svg.getAttribute('height'));















            // Create the defs tag if necessary
            RG.SVG.createDefs(this);




            this.graphWidth  = this.width - prop.gutterLeft - prop.gutterRight;
            this.graphHeight = this.height - prop.gutterTop - prop.gutterBottom;



            // Work out the center point
            this.centerx = (this.graphWidth / 2) + prop.gutterLeft;
            this.centery = (this.graphHeight / 2) + prop.gutterTop;
            this.radius  = ma.min(this.graphWidth, this.graphHeight) / 2;



            // Allow the user to override the calculated centerx/y/radius
            this.centerx = typeof prop.centerx === 'number' ? prop.centerx : this.centerx;
            this.centery = typeof prop.centery === 'number' ? prop.centery : this.centery;
            this.radius  = typeof prop.radius  === 'number' ? prop.radius  : this.radius;
            
            //
            // Allow the centerx/centery/radius to be a plus/minus
            //
            if (typeof prop.radius === 'string' && prop.radius.match(/^\+|-\d+$/) )   this.radius  += parseFloat(prop.radius);
            if (typeof prop.centerx === 'string' && prop.centerx.match(/^\+|-\d+$/) ) this.centerx += parseFloat(prop.centerx);
            if (typeof prop.centery === 'string' && prop.centery.match(/^\+|-\d+$/) ) this.centery += parseFloat(prop.centery);


            // Parse the colors for gradients
            // Must be after the cx/cy/r calculations
            RG.SVG.resetColorsToOriginalValues({object:this});
            this.parseColors();


            // Go through the data and work out the maximum value
            this.max   = RG.SVG.arrayMax(this.data);
            this.total = RG.SVG.arraySum(this.data);

            // Set the explosion to be an array if it's a number
            if (typeof prop.exploded === 'number' && prop.exploded > 0) {
                var val = prop.exploded;
    
                prop.exploded = [];
    
                for (var i=0; i<this.data.length; ++i) {
                    prop.exploded[i] = val;
                }
            }

            

            // Draw the segments
            this.drawSegments({shadow: true});



            // Draw the title and subtitle
            RG.SVG.drawTitle(this);



            // Draw the labels
            if (prop.labelsSticks) {
                this.drawLabelsSticks();
            } else {
                this.drawLabels();
            }
            
            
            //
            // Draw the ingraph labels if required
            //
            this.drawIngraphLabels();




            // Draw the key
            if (typeof prop.key !== null && RG.SVG.drawKey) {
                RG.SVG.drawKey(this);
            } else if (!RGraph.SVG.isNull(prop.key)) {
                alert('The drawKey() function does not exist - have you forgotten to include the key library?');
            }

            



            // Add the event listener that clears the highlight if
            // there is any. Must be MOUSEDOWN (ie before the click event)
            var obj = this;
            document.body.addEventListener('mousedown', function (e)
            {
                RG.SVG.removeHighlight(obj);
            }, false);



            // Fire the draw event
            RG.SVG.fireCustomEvent(this, 'ondraw');



            return this;
        };








        //
        // Draws the segments
        //
        // @param bool     Whether or not this is a redraw. If this is a redraw
        //                 shadows are omitted
        //
        this.drawSegments = function (opt)
        {
            var start   = 0,
                end     = 0,
                angle   = 0,
                sum     = RG.SVG.arraySum(this.data),
                segment = 0;




            // Work out the start and end angles for the data
            for (var i=0,len=this.data.length; i<len; ++i) {
            
                var value = this.data[i] * prop.roundRobinMultiplier;

                start   = angle;
                segment = ((value / sum) * RG.SVG.TRIG.TWOPI);
                end     = start + segment;

                var explosion = RG.SVG.TRIG.getRadiusEndPoint({
                    angle: start + (segment / 2),
                    r: prop.exploded[i]
                });

                var explosionX = explosion[1],
                    explosionY = explosion[0];


                this.angles[i] = {
                    start:   start,
                    end:     end,
                    angle:   end - start,
                    halfway: ((end - start) / 2) + start,
                    cx:      this.centerx + (parseFloat(explosionX) || 0),
                    cy:      this.centery - (parseFloat(explosionY) || 0),
                    radius:  this.radius,
                    object: this
                };

                // Increase the angle at which we start drawing the next segment at
                angle += (end - start);
            }



            if (opt.shadow) {
                RG.SVG.setShadow({
                    object:  this,
                    offsetx: prop.shadowOffsetx,
                    offsety: prop.shadowOffsety,
                    blur:    prop.shadowBlur,
                    opacity: prop.shadowOpacity,
                    id:      'dropShadow'
                });
            }


            //
            // This loop goes thru the angles that were
            // generated above and adds them to the
            // scene
            //
            for (var i=0; i<this.angles.length; ++i) {

                var path = RG.SVG.TRIG.getArcPath({
                    cx:    this.angles[i].cx,
                    cy:    this.angles[i].cy,
                    r:     this.radius,
                    start: this.angles[i].start,
                    end:   this.angles[i].end
                });





                // Donut
                if (prop.donut) {
                
                    var donutWidth = prop.donutWidth;
                
                    var donut_path = RG.SVG.TRIG.getArcPath3({
                        cx:     this.angles[i].cx,
                        cy:     this.angles[i].cy,
                        r:      this.radius - donutWidth,
                        start:  this.angles[i].end,
                        end:    this.angles[i].start,
                        moveto: false,
                        anticlockwise: true
                    });

                    var xy = RG.SVG.TRIG.getRadiusEndPoint({
                        angle: this.angles[i].end - RG.SVG.TRIG.HALFPI,
                        r:     this.radius - donutWidth
                    });
                    
                
                
                
                    path =   path
                           + " L {1} {2} ".format(xy[0] + this.angles[i].cx, xy[1] + this.angles[i].cy)
                           + donut_path
                           + " Z";
                
                
                } else {
                
                    path = path + " L {1} {2} ".format(
                        this.angles[i].cx,
                        this.angles[i].cy
                    ) + " Z"
                }



                var arc = RG.SVG.create({
                    svg: this.svg,
                    parent: this.svg.all,
                    type: 'path',
                    attr: {
                        d: path,
                        fill: prop.colors[i],
                        stroke: prop.strokestyle,
                        'stroke-width': prop.linewidth,
                        'data-tooltip': (!RG.SVG.isNull(prop.tooltips) && prop.tooltips.length) ? prop.tooltips[i] : '',
                        'data-index': i,
                        'data-value': value,
                        'data-start-angle': this.angles[i].start,
                        'data-end-angle': this.angles[i].end,
                        'data-radius': this.radius,
                        filter: (prop.shadow && opt.shadow) ? 'url(#dropShadow)' : ''
                    }
                });

                // Store the path with the relevant entry in the obj.angles array
                this.angles[i].element = arc;
                

                // Store a reference to the node
                if (prop.shadow && opt.shadow) {
                    this.shadowNodes[i] = arc;
                } else {
                    this.nodes[i] = arc;
                }

                if (prop.tooltips && prop.tooltips[i] && (!opt.shadow || !prop.shadow)) {
                
                    // Make the tooltipsEvent default to click
                    if (prop.tooltipsEvent !== 'mousemove') {
                        prop.tooltipsEvent = 'click';
                    }

                    (function (index, obj)
                    {
                        arc.addEventListener(prop.tooltipsEvent, function (e)
                        {
                            // If the event for tooltips is mousemove and the
                            // tooltip is already visible then do nothing
                            var tooltip = RG.SVG.REG.get('tooltip');
                            if (tooltip && prop.tooltipsEvent === 'mousemove' && index === tooltip.__index__) {
                                return;
                            }





                            obj.removeHighlight();

                            // Show the tooltip
                            RG.SVG.tooltip({
                                object: obj,
                                index: index,
                                sequentialIndex: index,
                                text: prop.tooltips[index],
                                event: e
                            });
                            
                            // Highlight the rect that has been clicked on
                            obj.highlight(e.target);
                            
                            var highlight = RG.SVG.REG.get('highlight');
                            
                            if (prop.tooltipsEvent === 'mousemove') {
                                highlight.style.cursor = 'pointer';
                            }
                            
                        }, false);

                        // Install the event listener that changes the
                        // cursor if necessary
                        if (prop.tooltipsEvent === 'click') {
                            arc.addEventListener('mousemove', function (e)
                            {
                                e.target.style.cursor = 'pointer';
                            }, false);
                        }
                        
                    }(i, this));
                }
            }

            //
            // Redraw the segments if necessary so that they're on
            // top of any shadow
            //
            if (prop.shadow && opt.shadow) {
                this.redrawSegments();
            }
        };








        //
        // Redraw the Bars o that the bars appear above any shadow
        //
        this.redrawSegments = function ()
        {
            this.drawSegments({shadow: false});
        };








        //
        // Draw the labels
        //
        this.drawLabels = function ()
        {
            var angles = this.angles,
                prop   = this.properties,
                labels = prop.labels;

            for (var i=0; i<angles.length; ++i) {
                
                var endpoint = RG.SVG.TRIG.getRadiusEndPoint({
                    angle: angles[i].halfway - RG.SVG.TRIG.HALFPI,
                    r: angles[i].radius + 15
                });
                
                var x = endpoint[0] + angles[i].cx,
                    y = endpoint[1] + angles[i].cy,
                    valign,
                    halign;

                // Figure out the valign and halign based on the quadrant
                // the the center of the sgement is in.
                if (angles[i].halfway > 0 && angles[i].halfway < RG.SVG.TRIG.HALFPI) {
                    halign = 'left';
                    valign = 'bottom';
                } else if (angles[i].halfway > RG.SVG.TRIG.HALFPI && angles[i].halfway < RG.SVG.TRIG.PI) {
                    halign = 'left';
                    valign = 'top';
                } else if (angles[i].halfway > RG.SVG.TRIG.PI && angles[i].halfway < (RG.SVG.TRIG.HALFPI + RG.SVG.TRIG.PI)) {
                    halign = 'right';
                    valign = 'top';
                } else if (angles[i].halfway > (RG.SVG.TRIG.HALFPI + RG.SVG.TRIG.PI) && angles[i].halfway < RG.SVG.TRIG.TWOPI) {
                    halign = 'right';
                    valign = 'top';
                }

                RG.SVG.text({
                    object: this,
                    parent: this.svg.all,
                    tag:    'labels',
                    text:   typeof labels[i] === 'string' ? labels[i] : '',
                    font:   prop.textFont,
                    size:   prop.textSize,
                    x:      x,
                    y:      y,
                    valign: valign,
                    halign: halign,
                    bold:   prop.textBold,
                    italic: prop.textItalic,
                    color:  prop.textColor
                });
            }
        };








        //
        // Draws the ingraph labels
        //
        this.drawIngraphLabels = function ()
        {
            if (prop.labelsIngraph) {

                for (var i=0; i<this.angles.length; ++i) {
    
                    // Some defaults
                    var halign   = prop.labelsIngraphHalign || 'center',
                        valign   = prop.labelsIngraphValign || 'center',
                        font     = prop.labelsIngraphFont   || prop.textFont,
                        size     = prop.labelsIngraphSize   || prop.textSize,
                        italic   = typeof prop.labelsIngraphItalic === 'boolean' ? prop.labelsIngraphItalic : prop.textItalic,
                        bold     = typeof prop.labelsIngraphBold   === 'boolean' ? prop.labelsIngraphBold   : prop.textBold,
                        color    = prop.labelsIngraphColor       || prop.textColor,
                        bgcolor  = prop.labelsIngraphBackground  || 'transparent',
                        decimals = prop.labelsIngraphDecimals    || 0,
                        padding  = typeof prop.labelsIngraphBackground === 'string' ? 3 : 0;

                    // Work out the coordinates
                    var xy = RG.SVG.TRIG.getRadiusEndPoint({
                        angle: this.angles[i].halfway - RG.SVG.TRIG.HALFPI,
                            r: this.angles[i].radius * (typeof prop.labelsIngraphRadiusPos === 'number' ? prop.labelsIngraphRadiusPos : 0.5)
                    });
                    
                    if (typeof prop.labelsIngraphSpecific === 'object' && prop.labelsIngraphSpecific) {
                        if (typeof prop.labelsIngraphSpecific[i] === 'string') {
                            var str = prop.labelsIngraphSpecific[i];
                        } else {
                            var str = '';
                        }
                    } else {
                        if (typeof prop.labelsIngraphFormatter === 'function') {
                            var str = prop.labelsIngraphFormatter({
                                object: this,
                                number: this.data[i].toFixed(decimals)
                            })
                        } else {

                            var str = RG.SVG.numberFormat({
                                prepend:  prop.labelsIngraphUnitsPre,
                                append:   prop.labelsIngraphUnitsPost,
                                point:    prop.labelsIngraphPoint,
                                thousand: prop.labelsIngraphThousand,
                                num:      this.data[i].toFixed(decimals),
                                object: this
                            });
                        }
                    }
    
                    //Draw the text
                    RG.SVG.text({
                        object:     this,
                        parent:     this.svg.all,
                        tag:        'labels.ingraph',
                        x:          this.angles[i].cx + xy[0],
                        y:          this.angles[i].cy + xy[1],
                        text:       str,
                        halign:     halign,
                        valign:     valign,
                        font:       font,
                        size:       size,
                        bold:       bold,
                        italic:     italic,
                        color:      color,
                        background: bgcolor,
                        padding:    padding
                    });
                }
            }
        };








        //
        // This function draws the labels in a list format
        //
        this.drawLabelsSticks = function ()
        {
            var labels_right  = [],
                labels_left   = [],
                labels_coords = [];

            for (var i=0; i<this.angles.length; ++i) {

                var angle          = (this.angles[i].start + ((this.angles[i].end - this.angles[i].start) / 2)) - RGraph.SVG.TRIG.HALFPI, // Midpoint
                    
                    endpoint_inner = RG.SVG.TRIG.getRadiusEndPoint({angle: angle, r: this.radius + 5}),
                    endpoint_outer = RG.SVG.TRIG.getRadiusEndPoint({angle: angle, r: this.radius + 20}),
                    
                    explosion      = [
                        (typeof prop.exploded === 'number' ? prop.exploded : prop.exploded[i]),
                        ma.cos(angle) * (typeof prop.exploded === 'number' ? prop.exploded : prop.exploded[i]),
                        ma.sin(angle) * (typeof prop.exploded === 'number' ? prop.exploded : prop.exploded[i])
                    ];
                
                // Initialise this array
                labels_coords[i] = [];
                
                // Initialise this
                var labels = {};





                // Push the label into the correct array
                if (angle > RG.SVG.TRIG.HALFPI) {
                
                    var index = labels_left.length;

                    labels_left[index]        = [];
                    labels_left[index].text   = prop.labels[i];
                    labels_left[index].halign = 'right';
                    labels                    = labels_left;

                    labels_coords[i].halign = 'right';
                } else {
                    
                    var index = labels_right.length; 

                    labels_right[index]        = [];
                    labels_right[index].text   = prop.labels[i];
                    labels_right[index].halign = 'right';
                    labels                     = labels_right;

                    labels_coords[i].halign = 'left';
                }







                endpoint_inner[0] += (explosion[1] || 0);
                endpoint_inner[1] += (explosion[2] || 0);
                
                endpoint_outer[0] += (explosion[1] || 0);
                endpoint_outer[1] += (explosion[2] || 0);
            
                var x,y;

                if (labels[index].text) {
                    var stick = RG.SVG.create({
                        svg: this.svg,
                        parent: this.svg.all,
                        type: 'path',
                        attr: {
                            d: 'M {1} {2} L {3} {4}'.format(
                                this.centerx + endpoint_inner[0],
                                this.centery + endpoint_inner[1],
                                this.centerx + endpoint_outer[0],
                                this.centery + endpoint_outer[1]
                            ),
                            stroke: '#999',
                            fill: 'rgba(0,0,0,0)'
                        }
                    });
                }
                
                // The path is altered later so this needs saving
                if (stick) {
                    labels[index].stick = stick;
                }
                
                x = (this.centerx + endpoint_outer[0] + (angle > 1.57 ? -50 : 50));
                y = (this.centery + endpoint_outer[1]);


                labels_coords[i].x      = x ;
                labels_coords[i].y      = y;
                labels_coords[i].text = prop.labels[i];
            }

            // Calculate the spacing for each side
            var vspace_right = (this.height - prop.gutterTop - prop.gutterBottom) / labels_right.length;
            var vspace_left  = (this.height - prop.gutterTop - prop.gutterBottom) / labels_left.length;

            // Reset these
            x = y = 0;





            // Loop through the RHS labels
            for (var i=0; i<labels_right.length; ++i) {
                if (labels_right[i] && labels_right[i].text) {

                    x = this.centerx + this.radius + 100;
                    y = prop.gutterTop + (vspace_right * i) + (vspace_right / 2);

                
                    // Add the label to the scene
                    RGraph.SVG.text({
                        object: this,
                        parent: this.svg.all,
                        tag:    'labels.sticks',
                        text:   typeof labels_right[i].text === 'string' ? labels_right[i].text : '',
                        font:   prop.textFont,
                        size:   prop.textSize,
                        x:      x,
                        y:      y,
                        valign: 'center',
                        halign: labels_right[i].text,
                        bold:   prop.textBold,
                        italic: prop.textItalic,
                        color:  prop.textColor
                    });
                    
                    // Now update the path of the stick
                    labels_right[i].stick.setAttribute(
                        'd',
                        labels_right[i].stick.getAttribute('d') + ' H {3} L {1} {2} '.format(
                            x - 5,
                            y,
                            this.centerx + this.radius + prop.labelsSticksHlength
                        )
                    );
                }
            }





            // Loop through the LHS labels
            for (var i=0; i<labels_left.length; ++i) {
                if (labels_left[i] && labels_left[i].text) {

                    x = this.centerx - this.radius - 100;
                    y = this.height - (prop.gutterTop + (vspace_left * i) + (vspace_left / 2));

                
                    // Add the label to the scene
                    RGraph.SVG.text({
                        object: this,
                        parent: this.svg.all,
                        tag:    'labels.sticks',
                        text:   typeof labels_left[i].text === 'string' ? labels_left[i].text : '',
                        font:   prop.textFont,
                        size:   prop.textSize,
                        x:      x - 7,
                        y:      y,
                        valign: 'center',
                        halign: labels_left[i].halign,
                        bold:   prop.textBold,
                        italic: prop.textItalic,
                        color:  prop.textColor
                    });

                    // Now update the path of the stick
                    labels_left[i].stick.setAttribute(
                        'd',
                        labels_left[i].stick.getAttribute('d') + ' H {3} L {1} {2} '.format(
                            x - 5,
                            y,
                            this.centerx - this.radius - prop.labelsSticksHlength
                        )
                    );
                }
            }
        };








        /**
        * This function can be used to highlight a segment on the chart
        * 
        * @param object segment The segment to highlight
        */
        this.highlight = function (segment)
        {
            // Outline style highlighting
            if (prop.highlightStyle === 'outline') {
                
                var index = segment.getAttribute('data-index');
            
                var path = RGraph.SVG.TRIG.getArcPath3({
                    start:          this.angles[index].start,
                    end:            this.angles[index].end,
                    cx:             this.angles[index].cx,
                    cy:             this.angles[index].cy,
                    r:              this.angles[index].radius + 2,
                    anticlockwise:  false,
                    lineto:         false
                });
            
                // Add the reverse arc
                path += RGraph.SVG.TRIG.getArcPath3({
                    start:          this.angles[index].end,
                    end:            this.angles[index].start,
                    cx:             this.angles[index].cx,
                    cy:             this.angles[index].cy,
                    r:              this.angles[index].radius + 2 + prop.highlightStyleOutlineWidth,
                    anticlockwise:  true
                });
            
                var highlight = RG.SVG.create({
                    svg: this.svg,
                    parent: this.svg.all,
                    type: 'path',
                    attr: {
                        d: path,
                        fill: prop.colors[index],
                        stroke: 'transparent'
                    },
                    style: {
                        pointerEvents: 'none'
                    }
                });
            
            // Regular highlighting
            } else {
            
                var highlight = RG.SVG.create({
                    svg: this.svg,
                    parent: this.svg.all,
                    type: 'path',
                    attr: {
                        d: segment.getAttribute('d'),
                        fill: prop.highlightFill,
                        stroke: prop.highlightStroke,
                        'stroke-width': prop.highlightLinewidth
                    },
                    style: {
                        pointerEvents: 'none'
                    }
                });
            }

            if (prop.tooltipsEvent === 'mousemove') {
                highlight.addEventListener('mouseout', function (e)
                {
                    highlight.parentNode.removeChild(highlight);
                    RG.SVG.hideTooltip();

                    RG.SVG.REG.set('highlight', null);
                }, false);
            }


            // Store the highlight rect in the registry so
            // it can be cleared later
            RG.SVG.REG.set('highlight', highlight);
        };








        /**
        * This allows for easy specification of gradients
        */
        this.parseColors = function () 
        {
            // Save the original colors so that they can be restored when the canvas is reset
            if (!Object.keys(this.originalColors).length) {
                this.originalColors = {
                    colors:        RG.SVG.arrayClone(prop.colors),
                    highlightFill: RG.SVG.arrayClone(prop.highlightFill)
                }
            }
            
            
            // colors
            var colors = prop.colors;

            if (colors) {
                for (var i=0; i<colors.length; ++i) {
                    colors[i] = RG.SVG.parseColorRadial({
                        object: this,
                        color: colors[i]
                    });
                }
            }
            
            // Highlight fill
            prop.highlightFill = RG.SVG.parseColorRadial({
                object: this,
                color: prop.highlightFill
            });
        };








        //
        // A roundRobin effect for the Pie chart
        //
        // @param object    Options for the effect
        // @param function  An optional callback function to call when
        //                  the effect is complete
        //
        this.roundRobin = function ()
        {
            var obj          = this,
                opt          = arguments[0] || {},
                data         = RG.SVG.arrayClone(this.data),
                prop         = this.properties,
                frame        = 1,
                frames       = opt.frames || 30,
                callback     = typeof opt.callback === 'function' ? opt.callback : function () {},
                dataSum      = RG.SVG.arraySum(this.data),
                textColor = prop.textColor,
                ingraph   = prop.labelsIngraph;
            
            // Set the text colors to transparent
            this.properties.textColor     = 'rgba(0,0,0,0)';
            this.properties.labelsIngraph = false;


            // Draw the chart first
            obj.draw();
            
            // Now get the resulting angles
            angles = RG.SVG.arrayClone(obj.angles);


            function iterator ()
            {
                prop.roundRobinMultiplier =  1 / frames * frame++;
                
                for (var i=0; i<obj.angles.length; ++i) {

                    var value = obj.data[i];



                    // NB This was an absolute git to work out for some reason.



                    obj.angles[i].start = angles[i].start * prop.roundRobinMultiplier;
                    obj.angles[i].end   = angles[i].end   * prop.roundRobinMultiplier;

                    //var segment = (((value * prop.roundRobinMultiplier) / dataSum) * RG.SVG.TRIG.TWOPI);
                    var segment = ((obj.angles[i].end - obj.angles[i].start) / 2);
                    var explodedX = ma.cos(obj.angles[i].start + segment - RG.SVG.TRIG.HALFPI) * (prop.exploded[i] || 0);
                    var explodedY = ma.sin(obj.angles[i].start + segment - RG.SVG.TRIG.HALFPI) * (prop.exploded[i] || 0);



                    var path = RG.SVG.TRIG.getArcPath({
                        cx:    obj.centerx + explodedX,
                        cy:    obj.centery + explodedY,
                        r:     obj.radius,
                        start: obj.angles[i].start,
                        end:   obj.angles[i].end
                    });





                    // Donut
                    if (prop.donut) {
                    
                        var donutWidth = prop.donutWidth;
                    
                        var donut_path = RG.SVG.TRIG.getArcPath({
                            cx:     obj.angles[i].cx,
                            cy:     obj.angles[i].cy,
                            r:      obj.radius - donutWidth,
                            start:  obj.angles[i].end,
                            end:    obj.angles[i].start,
                            moveto: false,
                            anticlockwise: true
                        });
                        
                        var xy = RG.SVG.TRIG.getRadiusEndPoint({
                            angle: obj.angles[i].end - RG.SVG.TRIG.HALFPI,
                            r:     obj.radius - donutWidth
                        });
                    
                        path =   path
                               + " L {1} {2} ".format(xy[0] + obj.angles[i].cx, xy[1] + obj.angles[i].cy)
                               + donut_path
                               + " Z";
                    
                    } else {
                    
                        path = path + " L {1} {2} ".format(
                            obj.angles[i].cx,
                            obj.angles[i].cy
                        ) + " Z"
                    }









                    path = path + " L {1} {2} Z".format(
                        obj.centerx + explodedX,
                        obj.centery + explodedY
                    );

                    if (obj.shadowNodes && obj.shadowNodes[i]) {
                        obj.shadowNodes[i].setAttribute('d', path);
                    }
                    obj.nodes[i].setAttribute('d', path);
                }


                if (frame <= frames) {
                    RG.SVG.FX.update(iterator);
                } else {
                    prop.textColor     = textColor;
                    prop.labelsIngraph = ingraph;

                    RG.SVG.redraw(obj.svg);

                    callback(obj);
                }
            }
            
            iterator();

            return this;
        };








        /**
        * Using a function to add events makes it easier to facilitate method
        * chaining
        * 
        * @param string   type The type of even to add
        * @param function func 
        */
        this.on = function (type, func)
        {
            if (type.substr(0,2) !== 'on') {
                type = 'on' + type;
            }
            
            RG.SVG.addCustomEventListener(this, type, func);
    
            return this;
        };








        //
        // Used in chaining. Runs a function there and then - not waiting for
        // the events to fire (eg the onbeforedraw event)
        // 
        // @param function func The function to execute
        //
        this.exec = function (func)
        {
            func(this);
            
            return this;
        };








        //
        // Remove highlight from the chart (tooltips)
        //
        this.removeHighlight = function ()
        {
            var highlight = RG.SVG.REG.get('highlight');
            if (highlight && highlight.parentNode) {
                highlight.parentNode.removeChild(highlight);
            }
            
            RG.SVG.REG.set('highlight', null);
        };








        //
        // Set the options that the user has provided
        //
        for (i in conf.options) {
            if (typeof i === 'string') {
                this.set(i, conf.options[i]);
            }
        }
    };
    
    
    
    return this;




// End module pattern
})(window, document);