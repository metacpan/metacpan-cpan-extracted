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



    RG.SVG.Funnel = function (conf)
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
        this.layers          = {}; // MUST be before the SVG element is created!
        this.svg             = RG.SVG.createSVG({object: this,container: this.container});
        this.isRGraph        = true;
        this.width           = Number(this.svg.getAttribute('width'));
        this.height          = Number(this.svg.getAttribute('height'));
        this.data            = RG.SVG.arrayClone(conf.data);
        this.originalData    = RG.SVG.arrayClone(conf.data);
        this.type            = 'funnel';
        this.coords          = [];
        this.colorsParsed    = false;
        this.originalColors  = {};
        this.gradientCounter = 1;
        this.nodes           = [];
        this.shadowNodes     = [];
        this.max             = 0;
        this.redraw          = false;
        this.highlight_node  = null;
        
        // Add this object to the ObjectRegistry
        RG.SVG.OR.add(this);
        
        // Set the DIV container to be inline-block
        this.container.style.display = 'inline-block';
        
        // Determine the maximum value by going thru the data
        var obj = this;
        this.data.forEach(function (val, key, arr)
        {
            obj.max = ma.max(obj.max, val);
        });






        this.properties =
        {
            gutterLeft:    35,
            gutterRight:   35,
            gutterTop:     35,
            gutterBottom:  35,
            
            backgroundbars: false,
            backgroundBarsOpacity: 0.25,
            backgroundBarsColors: null,

            strokestyle: 'white',
            colors: ['red', 'black', 'orange', 'green', '#6ff', '#ccc', 'pink', 'orange', 'cyan', 'maroon', 'olive', 'teal'],
            colorsOpacity: 1,
            
            textColor:  'black',
            textFont:   'sans-serif',
            textSize:   12,
            textBold:   false,
            textItalic: false,

            labels:       [],
            labelsFont:   null,
            labelsSize:   null,
            labelsColor:  null,
            labelsBold:   null,
            labelsItalic: null,
            labelsBackground: null,
            labelsAlign: 'center',
            labelsPosition: 'section', // This can be section or edge

            linewidth: 1,
            
            tooltips:         null,
            tooltipsOverride: null,
            tooltipsEffect:   'fade',
            tooltipsCssClass: 'RGraph_tooltip',
            tooltipsEvent:    'click',
            
            highlightStroke: 'rgba(0,0,0,0)',
            // Lighter than usual because the backgroundBars option can
            // mean highlight segments fade into the background
            highlightStroke: 'rgba(0,0,0,0)',
            highlightFill: 'rgba(255,255,255,0.7)',
            highlightLinewidth: 1,
            
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









            // Should the first thing that's done inthe.draw() function
            // except for the onbeforedraw event
            this.width  = Number(this.svg.getAttribute('width'));
            this.height = Number(this.svg.getAttribute('height'));












            // Reset the data back to the original values
            this.data = RG.SVG.arrayClone(this.originalData);



            // Reset the coords array to stop it growing
            this.coords = [];





            // Create the defs tag if necessary
            RG.SVG.createDefs(this);



            this.graphWidth  = this.width - prop.gutterLeft - prop.gutterRight;
            this.graphHeight = this.height - prop.gutterTop - prop.gutterBottom;

            /**
            * Add the data to the .originalData array and work out the max value
            * 
            * 2/5/14 Now also use this loop to ensure that the data pieces
            *        are numbers
            */

            // Convert strings to numbers
            for (var i=0,len=this.data.length; i<len; ++i) {
                if (typeof this.data[i] === 'string') {
                    this.data[i] = RG.SVG.stringsToNumbers(this.data[i]);
                }
            }












            // Parse the colors for gradients
            RG.SVG.resetColorsToOriginalValues({object:this});
            this.parseColors();


            

            // Draw the chart
            this.drawFunnel();
            
            
            
            // Draw the background bars
            this.drawBackgroundBars();






            // Draw the labels
            this.drawLabels();



            // Draw the title and subtitle
            RG.SVG.drawTitle(this);






            // Draw the key
            if (typeof prop.key !== null && RG.SVG.drawKey) {
                RG.SVG.drawKey(this);
            } else if (!RGraph.SVG.isNull(prop.key)) {
                alert('The drawKey() function does not exist - have you forgotten to include the key library?');
            }



            // Create the shadow definition if needed
            //if (prop.shadow) {
            //    RG.SVG.setShadow({
            //        object:  this,
            //        offsetx: prop.shadowOffsetx,
            //        offsety: prop.shadowOffsety,
            //        blur:    prop.shadowBlur,
            //        opacity: prop.shadowOpacity,
            //        id:      'dropShadow'
            //    });
            //}



            // Add the event listener that clears the highlight if
            // there is any. Must be MOUSEDOWN (ie before the click event)
            var obj = this;
            doc.body.addEventListener('mousedown', function (e)
            {
                obj.hideHighlight(obj);
            }, false);



            // Fire the draw event
            RG.SVG.fireCustomEvent(this, 'ondraw');



            return this;
        };








        //
        // Draws the radar.
        //
        //@param opt object Options for the function (if any)
        //
        this.drawFunnel = function (opt)
        {
            // This is the center of the Funnel ONLY - not the whole chart
            var centerx = prop.gutterLeft + (this.graphWidth / 2);

            // This first loop calculates the coordinates only - it DOES NOT
            // draw the Funnel on to the scene
            for (var i=0; i<(this.data.length - 1); ++i) {

                var value      = this.data[i],
                    nextValue  = this.data[i+1],
                    maxWidth   = this.graphWidth,
                    width      = (value / this.max) * this.graphWidth,
                    height     = this.graphHeight / (this.data.length - 1), // The heights are equal
                    nextWidth  = (nextValue / this.max) * this.graphWidth,
                    nextHeight = height;

                // The coordinates
                var x1 = centerx - (width / 2),
                    y1 = prop.gutterTop + (height * i),
                    x2 = centerx + (width / 2),
                    y2 = prop.gutterTop + (height * i);
                    x3 = centerx + (nextWidth / 2),
                    y3 = prop.gutterTop + (height * (i+1)),
                    x4 = centerx - (nextWidth / 2),
                    y4 = prop.gutterTop + (height * (i+1));

                // Store the coords
                this.coords.push({
                    x1: x1,
                    y1: y1,
                    x2: x2,
                    y2: y2,
                    x3: x3,
                    y3: y3,
                    x4: x4,
                    y4: y4,
                    widthTop: x2 - x1,
                    widthBottom: x3 - x4,
                    height: y3 - y2,
                    object: this
                    
                });
            }




            // Now go thru the coods and draw the shapes
            for (var i=0,len=this.coords.length,sequentialIndex=0; i<len; ++i,++sequentialIndex) {

                if (i < len) {
                    var coords = this.coords[i];
    
                    var path = RG.SVG.create({
                        svg: this.svg,
                        type: 'path',
                        parent: this.svg.all,
                        attr: {
                            d: 'M {1} {2} L {3} {4} L {5} {6} L {7} {8} z'.format(
                                coords.x1,
                                coords.y1,
                                coords.x2,
                                coords.y2,
                                coords.x3,
                                coords.y3,
                                coords.x4,
                                coords.y4
                            ),
                            stroke: prop.strokestyle,
                            fill: prop.colors[i],
                            'stroke-width': prop.linewidth,
                            'data-value': this.data[i],
                            'data-index': i
                        }
                    });





                    // Store a reference to the SVG path object just created
                    coords.element = path;












                    // Install tooltips event listener

                    // Add the tooltip data- attribute
                    if (!RG.SVG.isNull(prop.tooltips) && prop.tooltips[i]) {

                        var obj = this;

                        //
                        // Add tooltip event listeners
                        //
                        (function (idx, seq)
                        {
                            path.addEventListener(prop.tooltipsEvent.replace(/^on/, ''), function (e)
                            {
                                obj.removeHighlight();

                                // Show the tooltip
                                RG.SVG.tooltip({
                                    object: obj,
                                    index: idx,
                                    group: null,
                                    sequentialIndex: seq,
                                    text: prop.tooltips[seq],
                                    event: e
                                });
                                
                                // Highlight the rect that has been clicked on
                                obj.highlight(e.target);
                            }, false);

                            path.addEventListener('mousemove', function (e)
                            {
                                e.target.style.cursor = 'pointer'
                            }, false);
                        })(i, sequentialIndex);

                    } // end if
                } // end if
            } // end for
        };








        //
        // Redraws the chart if required
        //
        this.redrawFunnel = function ()
        {
        };
        
        //
        // Draws the background bars. This is called AFTER the .draw() function
        // and manages to draw the background bars behind the funnel by utilising
        // the background layers (or one of them at least)
        //
        this.drawBackgroundBars = function ()
        {
            if (prop.backgroundBars) {

                for (var i=0; i<this.coords.length; ++i) {

                    var coords = this.coords[i];

                    RG.SVG.create({
                        svg: this.svg,
                        type: 'rect',
                        parent: this.layers.background1,
                        attr: {
                            x: 0,
                            y: coords.y1,
                            width: this.width,
                            height: coords.y3 - coords.y2,
                            fill: prop.backgroundBarsColors && typeof prop.backgroundBarsColors === 'object' && typeof prop.backgroundBarsColors[i] === 'string' ? prop.backgroundBarsColors[i] : prop.colors[i],
                            'fill-opacity': prop.backgroundBarsOpacity
                        }
                    });
                }
            }
        };








        //
        // Draw the labels
        //
        this.drawLabels = function ()
        {
            // Create the group that the labels are added to
            var labelsGroup = RG.SVG.create({
                svg: this.svg,
                parent: this.svg.all,
                type: 'g'
            });
            
            // Determine the alignment
            if (prop.labelsHalign === 'left') {
                var x      = 15;
                var halign = 'left';
            
            } else if (prop.labelsHalign === 'right') {
                var x      = this.width - 15;
                var halign = 'right';
            
            } else {
                var x      = this.width / 2;
                var halign = 'center';
            }


            if (prop.labels && prop.labels.length) {
                if (prop.labelsPosition === 'section') {
                    
                    var sectionHeight = this.graphHeight / prop.labels.length;
                    
                    for (var i=0; i<prop.labels.length; ++i) {

                        RG.SVG.text({
                            object:     this,
                            svg:        this.svg,
                            parent:     labelsGroup,
                            tag:        'labels',
                            text:       typeof prop.labels[i] === 'string' || prop.labels[i] === 'number' ? prop.labels[i].toString() : '',
                            size:       parseInt(prop.labelsSize),
                            x:          x,
                            y:          prop.gutterTop + (sectionHeight / 2) + (i * sectionHeight),
                            halign:     halign,
                            valign:     'center',
                            background: prop.labelsBackground || 'rgba(255,255,255,0.5)',
                            padding:    2,
                            color:      prop.labelsColor  || prop.textColor || 'black',
                            bold:       RG.SVG.isNull(prop.labelsBold) ? prop.textBold : prop.labelsBold,
                            italic:     RG.SVG.isNull(prop.labelsItalic) ? prop.labelsItalic : prop.textItalic,
                            font:       prop.labelsFont  || prop.textFont
                        });
                    }

                // edge Positioning
                } else {

                    for (var i=0; i<prop.labels.length; ++i) {
                        RG.SVG.text({
                            object:     this,
                            svg:        this.svg,
                            parent:     labelsGroup,
                            tag:        'labels',
                            text:       typeof prop.labels[i] === 'string' || prop.labels[i] === 'number' ? prop.labels[i].toString() : '',
                            size:       parseInt(prop.labelsSize),
                            x:          x,
                            y:          prop.gutterTop + ((this.graphHeight / (prop.labels.length - 1) ) * i),
                            halign:     halign,
                            valign:     'center',
                            background: prop.labelsBackground || 'rgba(255,255,255,0.5)',
                            padding:    2,
                            color:      prop.labelsColor  || prop.textColor || 'black',
                            bold:       RG.SVG.isNull(prop.labelsBold) ? prop.textBold : prop.labelsBold,
                            italic:     RG.SVG.isNull(prop.labelsItalic) ? prop.labelsItalic : prop.textItalic,
                            font:       prop.labelsFont  || prop.textFont
                        });
                    }
                }
            }
        };








        /**
        * This function can be used to highlight a segment on the chart
        * 
        * @param object circle The circle to highlight
        */
        this.highlight = function (path)
        {
            var path = path.getAttribute('d');

            var highlight = RG.SVG.create({
                svg: this.svg,
                parent: this.svg.all,
                type: 'path',
                attr: {
                    d: path,
                    fill: prop.highlightFill,
                    stroke: prop.highlightStroke,
                    'stroke-width': prop.highlightLinewidth
                },
                style: {
                    pointerEvents: 'none'
                }
            });


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
                    colors:               RG.SVG.arrayClone(prop.colors),
                    highlightFill:        RG.SVG.arrayClone(prop.highlightFill),
                    backgroundBarsColors: RG.SVG.arrayClone(prop.backgroundBarsColors)
                }
            }
            
            
            // colors
            var colors = prop.colors;

            if (colors) {
                for (var i=0; i<colors.length; ++i) {
                    colors[i] = RG.SVG.parseColorLinear({
                        object: this,
                        color: colors[i],
                        direction:'horizontal'
                    });
                }
            }
            
            // backgroundBarsColors
            if (prop.backgroundBarsColors && prop.backgroundBarsColors.length) {
                for (var i=0; i<prop.backgroundBarsColors.length; ++i) {
                    prop.backgroundBarsColors[i] = RG.SVG.parseColorLinear({
                        object: this,
                        color: prop.backgroundBarsColors[i],
                        direction:'horizontal'
                    });
                }
            }
            
            // Highlight fill
            prop.highlightFill = RG.SVG.parseColorLinear({
                object: this,
                color: prop.highlightFill
            });
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
        // Removes the tooltip highlight from the chart
        //
        this.removeHighlight =
        this.hideHighlight   = function ()
        {

            var highlight = RG.SVG.REG.get('highlight');

            if (highlight) {
                highlight.setAttribute('fill','transparent');
                highlight.setAttribute('stroke','transparent');
                
                RG.SVG.REG.set('highlight', null);
            }
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