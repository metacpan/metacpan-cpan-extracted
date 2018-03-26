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

    RGraph = window.RGraph || {isRGraph: true};
    RGraph.SVG = RGraph.SVG || {};

// Module pattern
(function (win, doc, undefined)
{
    var RG  = RGraph,
        ua  = navigator.userAgent,
        ma  = Math,
        win = window,
        doc = document;



    RG.SVG.Waterfall = function (conf)
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








        this.id               = conf.id;
        this.uid              = RG.SVG.createUID();
        this.container        = document.getElementById(this.id);
        this.layers          = {}; // MUST be before the SVG tag is created!
        this.svg              = RG.SVG.createSVG({object: this,container: this.container});
        this.isRGraph         = true;
        this.data             = conf.data;
        this.type             = 'waterfall';
        this.coords           = [];
        this.colorsParsed     = false;
        this.originalColors   = {};
        this.gradientCounter  = 1;
        
        // Add this object to the ObjectRegistry
        RG.SVG.OR.add(this);
        
        this.container.style.display = 'inline-block';

        this.properties =
        {
            gutterLeft:   35,
            gutterRight:  35,
            gutterTop:    35,
            gutterBottom: 35,

            backgroundColor:            null,
            backgroundImage:            null,
            backgroundImageAspect:      'none',
            backgroundImageStretch:     true,
            backgroundImageOpacity:     null,
            backgroundImageX:           null,
            backgroundImageY:           null,
            backgroundImageW:           null,
            backgroundImageH:           null,
            backgroundGrid:             true,
            backgroundGridColor:        '#ddd',
            backgroundGridLinewidth:    1,
            backgroundGridHlines:       true,
            backgroundGridHlinesCount:  null,
            backgroundGridVlines:       true,
            backgroundGridVlinesCount:  null,
            backgroundGridBorder:       true,
            backgroundGridDashed:       false,
            backgroundGridDotted:       false,
            backgroundGridDashArray:    null,
            
            // 20 colors. If you need more you need to set the colors property
            colors:               ['black', 'red', 'blue'],
            colorsSequential:     false,
            strokestyle:          '#aaa',
            strokestyleConnector: null,
            
            total:                true,
            hmargin:              5,
            linewidth:            1,

            yaxis:                true,
            yaxisTickmarks:       true,
            yaxisTickmarksLength: 5,
            yaxisColor:           'black',
            yaxisScale:           true,
            yaxisLabels:          null,
            yaxisLabelsOffsetx:   0,
            yaxisLabelsOffsety:   0,
            yaxisLabelsCount:     5,
            yaxisUnitsPre:        '',
            yaxisUnitsPost:       '',
            yaxisStrict:          false,
            yaxisDecimals:        0,
            yaxisPoint:           '.',
            yaxisThousand:        ',',
            yaxisRound:           false,
            yaxisMax:             null,
            yaxisMin:             0,
            yaxisFormatter:       null,
            yaxisTextColor:       null,
            yaxisTextBold:        null,
            yaxisTextItalic:      null,
            yaxisTextFont:        null,
            yaxisTextSize:        null,

            xaxis:                true,
            xaxisTickmarks:       true,
            xaxisTickmarksLength: 5,
            xaxisLabels:          null,
            xaxisLabelsPosition:  'section',
            xaxisLabelsPositionEdgeTickmarksCount: null,
            xaxisColor:           'black',
            xaxisLabelsOffsetx:   0,
            xaxisLabelsOffsety:   0,
            
            labelsAbove:                  false,
            labelsAboveFont:              null,
            labelsAboveSize:              null,
            labelsAboveBold:              null,
            labelsAboveItalic:            null,
            labelsAboveColor:             null,
            labelsAboveBackground:        'rgba(255,255,255,0.5)',
            labelsAboveBackgroundPadding: 2,
            labelsAboveUnitsPre:          null,
            labelsAboveUnitsPost:         null,
            labelsAbovePoint:             null,
            labelsAboveThousand:          null,
            labelsAboveFormatter:         null,
            labelsAboveDecimals:          null,
            labelsAboveOffsetx:           0,
            labelsAboveOffsety:           0,
            labelsAboveHalign:            'center',
            labelsAboveValign:            'bottom',
            labelsAboveSpecific:          null,

            labelsAboveLastFont:              null,
            labelsAboveLastBold:              null,
            labelsAboveLastItalic:            null,
            labelsAboveLastSize:              null,
            labelsAboveLastColor:             null,
            labelsAboveLastBackground:        null,
            labelsAboveLastBackgroundPadding: null,

            textColor:            'black',
            textFont:             'sans-serif',
            textSize:             12,
            textBold:             false,
            textItalic:           false,

            
            tooltips:             null,
            tooltipsOverride:     null,
            tooltipsEffect:       'fade',
            tooltipsCssClass:     'RGraph_tooltip',
            tooltipsEvent:        'click',

            highlightStroke:      'rgba(0,0,0,0)',
            highlightFill:        'rgba(255,255,255,0.7)',
            highlightLinewidth:   1,
            
            title:                null,
            titleSize:            16,
            titleX:               null,
            titleY:               null,
            titleHalign:          'center',
            titleValign:          null,
            titleColor:           'black',
            titleFont:            null,
            titleBold:            false,
            titleItalic:          false,
            
            titleSubtitle:        null,
            titleSubtitleSize:    10,
            titleSubtitleX:       null,
            titleSubtitleY:       null,
            titleSubtitleHalign:  'center',
            titleSubtitleValign:  null,
            titleSubtitleColor:   '#aaa',
            titleSubtitleFont:    null,
            titleSubtitleBold:    false,
            titleSubtitleItalic:  false,
            
            //shadow:               false,
            //shadowOffsetx:        2,
            //shadowOffsety:        2,
            //shadowBlur:           2,
            //shadowOpacity:        0.25,



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



            // Create the defs tag if necessary
            RG.SVG.createDefs(this);




            this.coords      = []; // Reset this so it doesn't grow
            this.graphWidth  = this.width - prop.gutterLeft - prop.gutterRight;
            this.graphHeight = this.height - prop.gutterTop - prop.gutterBottom;



            // Parse the colors for gradients
            RG.SVG.resetColorsToOriginalValues({object:this});
            this.parseColors();
            
            
            
            
            // Work out the sum of the data and add it to the data
            if (prop.total) {
                var sum = RG.SVG.arraySum(this.data);
                
                // Now append the sum to the data
                this.data.push(sum);
                
                // May need to append something to the labels array if prop.total
                // is enabled, so that the labels line up

                if (prop.xaxisLabels && prop.xaxisLabels.length === (this.data.length - 1)) {
                    prop.xaxisLabels.push('');
                }
            }




            for (var i=0,max=0,runningTotal=0; i<this.data.length - (prop.total ? 1 : 0); ++i) {
                runningTotal += this.data[i]
                max = ma.max(ma.abs(max), ma.abs(runningTotal));
            }

            // A custom, user-specified maximum value
            if (typeof prop.yaxisMax === 'number') {
                max = prop.yaxisMax;
            }
            
            // Set the ymin to zero if it's set mirror
            if (prop.yaxisMin === 'mirror' || prop.yaxisMin === 'middle' || prop.yaxisMin === 'center') {
                var mirrorScale = true;
                prop.yaxisMin   = 0;
            }


            //
            // Generate an appropiate scale
            //
            this.scale = RG.SVG.getScale({
                object:    this,
                numlabels: prop.yaxisLabelsCount,
                unitsPre:  prop.yaxisUnitsPre,
                unitsPost: prop.yaxisUnitsPost,
                max:       max,
                min:       prop.yaxisMin,
                point:     prop.yaxisPoint,
                round:     prop.yaxisRound,
                thousand:  prop.yaxisThousand,
                decimals:  prop.yaxisDecimals,
                strict:    typeof prop.yaxisMax === 'number',
                formatter: prop.yaxisFormatter
            });
                


            //
            // Get the scale a second time if the ymin should be mirored
            //
            // Set the ymin to zero if it's set mirror
            if (mirrorScale) {
                this.scale = RG.SVG.getScale({
                    object: this,
                    numlabels: prop.yaxisLabelsCount,
                    unitsPre:  prop.yaxisUnitsPre,
                    unitsPost: prop.yaxisUnitsPost,
                    max:       this.scale.max,
                    min:       this.scale.max * -1,
                    point:     prop.yaxisPoint,
                    round:     false,
                    thousand:  prop.yaxisThousand,
                    decimals:  prop.yaxisDecimals,
                    strict:    typeof prop.yaxisMax === 'number',
                    formatter: prop.yaxisFormatter
                });
            }

            // Now the scale has been generated adopt its max value
            this.max      = this.scale.max;
            this.min      = this.scale.min;
            prop.yaxisMax = this.scale.max;
            prop.yaxisMin = this.scale.min;




            // Draw the background first
            RG.SVG.drawBackground(this);



            // Draw the axes BEFORE the bars
            RG.SVG.drawXAxis(this);
            RG.SVG.drawYAxis(this);


            // Draw the bars
            this.drawBars();
            
            
            // Draw the labelsAbove labels
            this.drawLabelsAbove();








            
            
            // Draw the key
            if (typeof prop.key !== null && RG.SVG.drawKey) {
                RG.SVG.drawKey(this);
            } else if (!RGraph.SVG.isNull(prop.key)) {
                alert('The drawKey() function does not exist - have you forgotten to include the key library?');
            }







            // Add the attribution link. If you're adding this elsewhere on your page/site
            // and you don't want it displayed then there are options available to not
            // show it.
            RG.SVG.attribution(this);




            // Add the event listener that clears the highlight rect if
            // there is any. Must be MOUSEDOWN (ie before the click event)
            //var obj = this;
            //document.body.addEventListener('mousedown', function (e)
            //{
            //    //RG.SVG.removeHighlight(obj);
            //
            //}, false);



            // Fire the draw event
            RG.SVG.fireCustomEvent(this, 'ondraw');




            return this;
        };








        //
        // Draws the bars
        //
        this.drawBars = function ()
        {
            this.graphWidth  = this.width  - prop.gutterLeft - prop.gutterRight;
            this.graphHeight = this.height - prop.gutterTop - prop.gutterBottom;
            
            // The width of the bars
            var innerWidth = (this.graphWidth / this.data.length) - (2 * prop.hmargin),
                outerWidth = (this.graphWidth / this.data.length);


            // The starting Y coordinate
            var y     = this.getYCoord(0),
                total = 0;



            // Loop thru the data drawing the bars
            for (var i=0; i<(this.data.length); ++i) {
            
                var prevValue    = this.data[i - 1],
                    nextValue    = this.data[i + 1],
                    currentValue = this.data[i],
                    prevTotal    = total;

                total += parseFloat(this.data[i]) || 0;

                // Figure out the height
                var height = ma.abs((this.data[i] / (this.scale.max - this.scale.min) ) * this.graphHeight);










                // Work out the starting coord
                if (RG.SVG.isNull(prevValue)) {
                    
                    if (currentValue > 0) {
                        y = this.getYCoord(prevTotal) - height;
                    } else {
                        y = this.getYCoord(prevTotal);
                    }

                } else {
                    if (i == 0 && this.data[i] > 0) {
                        y = y - height;
    
                    } else if (this.data[i] > 0 && this.data[i - 1] > 0) {
                        y = y - height;
    
                    } else if (this.data[i] > 0 && this.data[i - 1] < 0) {
                        y = y + prevHeight - height;
    
                    } else if (this.data[i] < 0 && this.data[i - 1] > 0) {
                        // Nada
    
                    } else if (this.data[i] < 0 && this.data[i - 1] < 0) {
                        y = y + prevHeight;
                    }
                }
                
                //
                // Determine the color
                //
                var fill = this.data[i] > 0 ? prop.colors[0] : prop.colors[1];
                
                if (prop.colorsSequential) {
                    fill = prop.colors[i];
                }

                
                
                
                
                // The last (the total) value if required
                if (prop.total) {
                    if (i === (this.data.length - 1) && this.data[this.data.length - 1] >= 0) {
                        
                        y = this.getYCoord(0) - height;
    
                        if (!prop.colorsSequential) {
                            fill = prop.colors[2];
                        }
                    } else if (i === (this.data.length - 1) && this.data[this.data.length - 1] < 0) {
                        y    = this.getYCoord(0);
    
                        if (!prop.colorsSequential) {
                            fill = prop.colors[2];
                        }
                    }
                }





                // Calculate the X coordinate
                var x = prop.gutterLeft + (outerWidth * i) + prop.hmargin;





                // This handles an intermediate total
                if (this.data[i] === null || typeof this.data[i] === 'undefined') {
                    
                    var axisY = this.getYCoord(0);
                    
                    if (prevValue < 0) {
                        y = prevY + prevHeight;
                    } else {
                        y = prevY;
                    }

                    height = this.getYCoord(0) - this.getYCoord(total);
                    
                    // Do this if not sequential colors
                    if (!prop.colorsSequential) {
                        fill   = prop.colors[3] || prop.colors[2];
                    }
                    
                    if (height < 0) {
                        y += height;
                        height *= -1;
                    }
                }






                // Create the rect object
                var rect = RG.SVG.create({
                    svg: this.svg,
                    type: 'rect',
                    parent: this.svg.all,
                    attr: {
                        x: x,
                        y: y,
                        width: innerWidth,
                        height: height,
                        stroke: prop.strokestyle,
                        fill: fill,
                        'stroke-width': prop.linewidth,
                        'shape-rendering': 'crispEdges',
                        'data-index': i,
                        'data-original-x': x,
                        'data-original-y': y,
                        'data-original-width': innerWidth,
                        'data-original-height': height,
                        'data-original-stroke': prop.strokestyle,
                        'data-original-fill': fill,
                        'data-value': String(this.data[i])
                    }
                });
                
                // Store the coordinates
                this.coords.push({
                    object:  this,
                    element: rect,
                    x:       x,
                    y:       y,
                    width:   innerWidth,
                    height:  height
                });








                // Add the tooltips
                if (!RG.SVG.isNull(prop.tooltips) && prop.tooltips[i]) {

                    var obj = this;

                    //
                    // Add tooltip event listeners
                    //
                    (function (idx)
                    {
                        rect.addEventListener(prop.tooltipsEvent.replace(/^on/, ''), function (e)
                        {
                            obj.removeHighlight();

                            // Show the tooltip
                            RG.SVG.tooltip({
                                object: obj,
                                index: idx,
                                text: prop.tooltips[idx],
                                event: e
                            });
                            
                            // Highlight the rect that has been clicked on
                            obj.highlight(e.target);
                        }, false);

                        rect.addEventListener('mousemove', function (e)
                        {
                            e.target.style.cursor = 'pointer'
                        }, false);
                    })(i);
                }










                // Store these for the next iteration of the loop
                var prevX      = x,
                    prevY      = y,
                    prevWidth  = innerWidth,
                    prevHeight = height,
                    prevValue  = this.data[i];
            }




















            // Now draw the connecting lines
            for (var i=0; i<this.coords.length; ++i) {
            
                if (this.coords[i+1] && this.coords[i+1].element) {
                    
                    var x1 = Number(this.coords[i].element.getAttribute('x')) + Number(this.coords[i].element.getAttribute('width')),
                        y1 = parseInt(this.coords[i].element.getAttribute('y')) +          (this.data[i] > 0 ? 0 : parseInt(this.coords[i].element.getAttribute('height')) ),
                        x2 = x1 + (2 * prop.hmargin),
                        y2 = parseInt(this.coords[i].element.getAttribute('y')) +          (this.data[i] > 0 ? 0 : parseInt(this.coords[i].element.getAttribute('height')) );

                    // Handle total columns
                    if(this.coords[i].element.getAttribute('data-value') === 'null') {
                        y1 = parseFloat(this.coords[i].element.getAttribute('y'));
                        y2 = parseFloat(y1);
                    }

                    var line = RG.SVG.create({
                        svg: this.svg,
                        type: 'line',
                        parent: this.svg.all,
                        attr: {
                            x1: x1,
                            y1: y1 + 0.5,
                            x2: x2,
                            y2: y2 + 0.5,
                            stroke: prop.strokestyleConnector || prop.strokestyle,
                            'stroke-width': prop.linewidth,
                            'data-index': i,
                            'data-original-x1': x1,
                            'data-original-y1': y1 + 0.5,
                            'data-original-x2': x2,
                            'data-original-y2': y2 + 0.5
                        }
                    });
                }
            }
        };








        /**
        * This function can be used to retrieve the relevant Y coordinate for a
        * particular value.
        * 
        * @param int value The value to get the Y coordinate for
        */
        this.getYCoord = function (value)
        {
            var prop = this.properties;

            if (value > this.scale.max) {
                return null;
            }

            var y, xaxispos = prop.xaxispos;

            if (value < this.scale.min) {
                return null;
            }

            y  = ((value - this.scale.min) / (this.scale.max - this.scale.min));
            y *= (this.height - prop.gutterTop - prop.gutterBottom);

            y = this.height - prop.gutterBottom - y;

            return y;
        };








        /**
        * This function can be used to highlight a bar on the chart
        * 
        * @param object rect The rectangle to highlight
        */
        this.highlight = function (rect)
        {
            var x      = rect.getAttribute('x'),
                y      = rect.getAttribute('y'),
                width  = rect.getAttribute('width'),
                height = rect.getAttribute('height');
            
            var highlight = RG.SVG.create({
                svg: this.svg,
                type: 'rect',
                parent: this.svg.all,
                attr: {
                    stroke: prop.highlightStroke,
                    fill: prop.highlightFill,
                    x: x,
                    y: y,
                    width: width,
                    height: height,
                    'stroke-width': prop.highlightLinewidth
                },
                style: {
                    pointerEvents: 'none'
                }
            });


            //if (prop.tooltipsEvent === 'mousemove') {
                
                //var obj = this;
                
                //highlight.addEventListener('mouseout', function (e)
                //{
                //    obj.removeHighlight();
                //    RG.SVG.hideTooltip();
                //    RG.SVG.REG.set('highlight', null);
                //}, false);
            //}


            // Store the highlight rect in the rebistry so
            // it can be cleared later
            RG.SVG.REG.set('highlight', highlight);
        };








        /**
        * This allows for easy specification of gradients
        */
        this.parseColors = function () 
        {
            // Save the original colors so that they can be restored when
            // the canvas is cleared
            if (!Object.keys(this.originalColors).length) {
                this.originalColors = {
                    colors:              RG.SVG.arrayClone(prop.colors),
                    backgroundGridColor: RG.SVG.arrayClone(prop.backgroundGridColor),
                    highlightFill:       RG.SVG.arrayClone(prop.highlightFill),
                    backgroundColor:     RG.SVG.arrayClone(prop.backgroundColor)
                }
            }

            
            // colors
            var colors = prop.colors;

            if (colors) {
                for (var i=0; i<colors.length; ++i) {
                    colors[i] = RG.SVG.parseColorLinear({
                        object: this,
                        color: colors[i]
                    });
                }
            }

            prop.backgroundGridColor = RG.SVG.parseColorLinear({object: this, color: prop.backgroundGridColor});
            prop.highlightFill       = RG.SVG.parseColorLinear({object: this, color: prop.highlightFill});
            prop.backgroundColor     = RG.SVG.parseColorLinear({object: this, color: prop.backgroundColor});
        };








        //
        // Draws the labelsAbove
        //
        this.drawLabelsAbove = function ()
        {
            // Go through the above labels
            if (prop.labelsAbove) {
            
                var total = 0;

                for (var i=0; i<this.coords.length; ++i) {
                    
                    var num    = this.data[i],
                        total  = total + num;

                    if (typeof num === 'number' || RG.SVG.isNull(num)) {
                        
                        if (RG.SVG.isNull(num)) {
                            num = total;
                        }

                        var str = RG.SVG.numberFormat({
                            object:    this,
                            num:       num.toFixed(prop.labelsAboveDecimals),
                            prepend:   typeof prop.labelsAboveUnitsPre  === 'string'   ? prop.labelsAboveUnitsPre  : null,
                            append:    typeof prop.labelsAboveUnitsPost === 'string'   ? prop.labelsAboveUnitsPost : null,
                            point:     typeof prop.labelsAbovePoint     === 'string'   ? prop.labelsAbovePoint     : null,
                            thousand:  typeof prop.labelsAboveThousand  === 'string'   ? prop.labelsAboveThousand  : null,
                            formatter: typeof prop.labelsAboveFormatter === 'function' ? prop.labelsAboveFormatter : null
                        });

                        // Facilitate labelsAboveSpecific
                        if (prop.labelsAboveSpecific && prop.labelsAboveSpecific.length && (typeof prop.labelsAboveSpecific[i] === 'string' || typeof prop.labelsAboveSpecific[i] === 'number') ) {
                            str = prop.labelsAboveSpecific[i];
                        } else if ( prop.labelsAboveSpecific && prop.labelsAboveSpecific.length && typeof prop.labelsAboveSpecific[i] !== 'string' && typeof prop.labelsAboveSpecific[i] !== 'number') {
                            continue;
                        }
    
                        var x = parseFloat(this.coords[i].element.getAttribute('x')) + parseFloat(this.coords[i].element.getAttribute('width') / 2) + prop.labelsAboveOffsetx;
    
                        if (this.data[i] >= 0) {
                            var y = parseFloat(this.coords[i].element.getAttribute('y')) - 7 + prop.labelsAboveOffsety;
                            var valign = prop.labelsAboveValign;
                        } else {
                            var y = parseFloat(this.coords[i].element.getAttribute('y')) + parseFloat(this.coords[i].element.getAttribute('height')) + 7 - prop.labelsAboveOffsety;
                            var valign = prop.labelsAboveValign === 'top' ? 'bottom' : 'top';
                        }









                        // Formatting options for the labels
                        //
                        // NB The last label can have different formatting
                        if (i === (this.coords.length - 1) ) {

                            var font       = prop.labelsAboveLastFont              || prop.labelsAboveFont              || prop.textFont,
                                size       = prop.labelsAboveLastSize              || prop.labelsAboveSize              || prop.textSize,
                                color      = prop.labelsAboveLastColor             || prop.labelsAboveColor             || prop.textColor,
                                background = prop.labelsAboveLastBackground        || prop.labelsAboveBackground        || null,
                                padding    = (typeof prop.labelsAboveLastBackgroundPadding === 'number' ? prop.labelsAboveLastBackgroundPadding : prop.labelsAboveBackgroundPadding) || 0;
                            
                            // Bold
                            if (typeof prop.labelsAboveLastBold === 'boolean') {
                                var bold = prop.labelsAboveLastBold;
                            } else if (typeof prop.labelsAboveBold === 'boolean') {
                                var bold = prop.labelsAboveBold;
                            } else {
                                var bold = prop.textBold;
                            }

                            // Italic
                            if (typeof prop.labelsAboveLastItalic === 'boolean') {
                                var italic = prop.labelsAboveLastItalic;
                            } else if (typeof prop.labelsAboveItalic === 'boolean') {
                                var italic = prop.labelsAboveItalic;
                            } else {
                                var italic = prop.textItalic;
                            }

                        
                        
                        
                        
                        
                        
                        
                        
                        
                        } else {
                            var font       = prop.labelsAboveFont              || prop.textFont,
                                size       = prop.labelsAboveSize              || prop.textSize,
                                color      = prop.labelsAboveColor             || prop.textColor,
                                background = prop.labelsAboveBackground        || null,
                                padding    = prop.labelsAboveBackgroundPadding || 0;


                            // Bold
                            if (typeof prop.labelsAboveBold === 'boolean') {
                                var bold = prop.labelsAboveBold;
                            } else {
                                var bold = prop.textBold;
                            }

                            // Italic
                            if (typeof prop.labelsAboveItalic === 'boolean') {
                                var italic = prop.labelsAboveItalic;
                            } else {
                                var italic = prop.textItalic;
                            }
                        }





                        RG.SVG.text({
                            object:     this,
                            parent:     this.svg.all,
                            tag:        'labels.above',
                            text:       str,
                            x:          x,
                            y:          y,
                            halign:     prop.labelsAboveHalign,
                            valign:     valign,
                            font:       font,
                            size:       size,
                            bold:       bold,
                            italic:     italic,
                            color:      color,
                            background: background,
                            padding:    padding
                        });
                    }
                }
            }
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
        // The Bar chart grow effect
        //
        this.grow = function ()
        {
            var opt      = arguments[0] || {},
                frames   = opt.frames || 30,
                frame    = 0,
                obj      = this,
                data     = [],
                height   = null,
                seq      = 0;
/*
            //
            // Copy the data
            //
            data = RG.SVG.arrayClone(this.data);

            this.draw();

            var iterate = function ()
            {

                for (var i=0,seq=0,len=obj.coords.length; i<len; ++i, ++seq) {

                    var   multiplier = (frame / frames)
                        * RG.SVG.FX.getEasingMultiplier(frames, frame)
                        * RG.SVG.FX.getEasingMultiplier(frames, frame);
                
                
                
                
                    // TODO Go through the data and update the value according to
                    // the frame number
                    if (typeof data[i] === 'number') {

                        height      = ma.abs(obj.getYCoord(data[i]) - obj.getYCoord(0));
                        obj.data[i] = data[i] * multiplier;
                        height      = multiplier * height;
                        
                        // Set the new height on the rect
                        obj.coords[seq].element.setAttribute(
                            'height',
                            height
                        );

                        // Set the correct Y coord on the object
                        obj.coords[seq].element.setAttribute(
                            'y',
                            data[i] < 0 ? obj.getYCoord(0) : obj.getYCoord(0) - height
                        );

                    } else if (typeof data[i] === 'object') {

                        var accumulativeHeight = 0;

                        for (var j=0,len2=data[i].length; j<len2; ++j, ++seq) {

                            height         = ma.abs(obj.getYCoord(data[i][j]) - obj.getYCoord(0));
                            height         = multiplier * height;
                            obj.data[i][j] = data[i][j] * multiplier;

                            obj.coords[seq].element.setAttribute(
                                'height',
                                height
                            );

                            obj.coords[seq].element.setAttribute(
                                'y',
                                data[i][j] < 0 ? (obj.getYCoord(0) + accumulativeHeight) : (obj.getYCoord(0) - height - accumulativeHeight)
                            );
                            
                            accumulativeHeight += (prop.grouping === 'stacked' ? height : 0);
                        }

                        //
                        // Set the height and Y cooord of the backfaces if necessary
                        //
                        if (obj.stackedBackfaces[i]) {
                            obj.stackedBackfaces[i].setAttribute(
                                'height',
                                accumulativeHeight
                            );
    
                            obj.stackedBackfaces[i].setAttribute(
                                'y',
                                obj.height - prop.gutterBottom - accumulativeHeight
                            );
                        }

                        // Decrease seq by one so that it's not incremented twice
                        --seq;
                    }
                }

                if (frame++ < frames) {
                    //setTimeout(iterate, frame > 1 ? opt.delay : 200);
                    RG.SVG.FX.update(iterate);
                } else if (opt.callback) {
                    (opt.callback)(obj);
                }
            };

            iterate();
*/
            return this;
        };








        /**
        * HBar chart Wave effect.
        * 
        * @param object OPTIONAL An object map of options. You specify 'frames'
        *                        here to give the number of frames in the effect
        *                        and also callback to specify a callback function
        *                        thats called at the end of the effect
        */
        this.wave = function ()
        {
/*
            // First draw the chart
            this.draw();


            var obj = this,
                opt = arguments[0] || {};
            
            opt.frames      = opt.frames || 60;
            opt.startFrames = [];
            opt.counters    = [];

            var framesperbar    = opt.frames / 3,
                frame           = -1,
                callback        = opt.callback || function () {};

            for (var i=0,len=this.coords.length; i<len; i+=1) {
                opt.startFrames[i] = ((opt.frames / 2) / (obj.coords.length - 1)) * i;
                opt.counters[i]    = 0;
                
                // Now zero the width of the bar
                this.coords[i].element.setAttribute('height', 0);
            }


            function iterator ()
            {
                ++frame;

                for (var i=0,len=obj.coords.length; i<len; i+=1) {
                    if (frame > opt.startFrames[i]) {                            
                        
                        var originalHeight = obj.coords[i].element.getAttribute('data-original-height'),
                            height,
                            value = parseFloat(obj.coords[i].element.getAttribute('data-value'));

                        obj.coords[i].element.setAttribute(
                            'height',
                            height = ma.min(
                                ((frame - opt.startFrames[i]) / framesperbar) * originalHeight,
                                originalHeight
                            )
                        );

                        obj.coords[i].element.setAttribute(
                            'y',
                            value >=0 ? obj.getYCoord(0) - height : obj.getYCoord(0)
                        );
                        
                        if (prop.grouping === 'stacked') {
                            var seq = obj.coords[i].element.getAttribute('data-sequential-index');
                            
                            var indexes = RG.SVG.sequentialIndexToGrouped(seq, obj.data);
                            
                            if (indexes[1] > 0) {
                                obj.coords[i].element.setAttribute(
                                    'y',
                                    parseInt(obj.coords[i - 1].element.getAttribute('y')) - height
                                );
                            }
                        }
                    }
                }


                if (frame >= opt.frames) {
                    callback(obj);
                } else {
                    RG.SVG.FX.update(iterator);
                }
            }
            
            iterator();
*/
            return this;
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