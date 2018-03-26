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



    RG.SVG.Bar = function (conf)
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
        this.layers           = {}; // MUST be before the SVG tag is created!
        this.svg              = RG.SVG.createSVG({object: this,container: this.container});
        this.isRGraph         = true;
        this.data             = conf.data;
        this.type             = 'bar';
        this.coords           = [];
        this.coords2          = [];
        this.stackedBackfaces = [];
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
            
            variant:          null,
            variant3dOffsetx: 10,
            variant3dOffsety: 5,

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
            colors: [
                'red', '#0f0', '#00f', '#ff0', '#0ff', '#0f0','pink','orange','gray','black',
                'red', '#0f0', '#00f', '#ff0', '#0ff', '#0f0','pink','orange','gray','black'
            ],
            colorsSequential:     false,
            strokestyle:          'rgba(0,0,0,0)',
            
            errorbars:            null,
            
            hmargin:              3,
            hmarginGrouped:       2,

            yaxis:                true,
            yaxisTickmarks:       true,
            yaxisTickmarksLength: 3,
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

            xaxis:                true,
            xaxisTickmarks:       true,
            xaxisTickmarksLength: 5,
            xaxisLabels:          null,
            xaxisLabelsPosition:  'section',
            xaxisLabelsPositionSectionTickmarksCount: null,
            xaxisColor:           'black',
            xaxisLabelsOffsetx:   0,
            xaxisLabelsOffsety:   0,
            
            labelsAbove:                  false,
            labelsAboveFont:              null,
            labelsAboveSize:              null,
            labelsAboveBold:              null,
            labelsAboveItalic:            null,
            labelsAboveColor:             null,
            labelsAboveBackground:        null,
            labelsAboveBackgroundPadding: 0,
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
            
            textColor:            'black',
            textFont:             'sans-serif',
            textSize:             12,
            textBold:             false,
            textItalic:           false,

            linewidth:            1,
            grouping:             'grouped',
            
            tooltips:             null,
            tooltipsOverride:     null,
            tooltipsEffect:       'fade',
            tooltipsCssClass:     'RGraph_tooltip',
            tooltipsEvent:        'click',

            highlightStroke:      'rgba(0,0,0,0)',
            highlightFill:        'rgba(255,255,255,0.7)',
            highlightLinewidth:   1,
            
            title:                '',
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
            
            shadow:               false,
            shadowOffsetx:        2,
            shadowOffsety:        2,
            shadowBlur:           2,
            shadowOpacity:        0.25,
            
            errorbars:            null,
            errorbarsColor:       'black',
            errorbarsLinewidth:   1,
            errorbarsCapwidth:    10,

            key:            null,
            keyColors:      null,
            keyOffsetx:     0,
            keyOffsety:     0,
            keyTextOffsetx: 0,
            keyTextOffsety: -1,
            keyTextSize:    null,
            keyTextBold:    null,
            keyTextItalic:  null,
            keyTextFont:    null
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


            // Zero these if the 3D effect is not wanted
            if (prop.variant !== '3d') {
                prop.variant3dOffsetx = 0;
                prop.variant3dOffsety = 0;

            } else {

                // Set the skew transform on the all group if necessary
                this.svg.all.setAttribute('transform', 'skewY(5)');
            }



            // Create the defs tag if necessary
            RG.SVG.createDefs(this);

            





            // Reset the coords array
            this.coords  = [];
            this.coords2 = [];


            this.graphWidth  = this.width - prop.gutterLeft - prop.gutterRight;
            this.graphHeight = this.height - prop.gutterTop - prop.gutterBottom;



            /**
            * Parse the colors. This allows for simple gradient syntax
            */

            // Parse the colors for gradients
            RG.SVG.resetColorsToOriginalValues({object:this});
            this.parseColors();



            // Go through the data and work out the maximum value
            // This now also accounts for errorbars
            var values = [];

            for (var i=0,max=0; i<this.data.length; ++i) {
                
                // Errorbars affect the max value
                if (prop.errorbars && typeof prop.errorbars[i] === 'number') {
                    var errorbar = prop.errorbars[i];
                } else if (prop.errorbars && typeof prop.errorbars[i] === 'object' && typeof  prop.errorbars[i].max === 'number') {
                    var errorbar = prop.errorbars[i].max;
                } else {
                    var errorbar = 0;
                }


                if (typeof this.data[i] === 'number') {
                    values.push(this.data[i] + errorbar);
                
                } else if (RG.SVG.isArray(this.data[i]) && prop.grouping === 'grouped') {
                    values.push(RG.SVG.arrayMax(this.data[i]) + errorbar);

                } else if (RG.SVG.isArray(this.data[i]) && prop.grouping === 'stacked') {
                    values.push(RG.SVG.arraySum(this.data[i]) + errorbar);
                }
            }
            var max = RG.SVG.arrayMax(values);

            // A custom, user-specified maximum value
            if (typeof prop.yaxisMax === 'number') {
                max = prop.yaxisMax;
            }
            
            // Set the ymin to zero if it's szet mirror
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
            // Set the ymin to zero if it's szet mirror
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



            // Draw the threeD axes here so everything else is drawn on top of
            // it, but after the scale generation
            if (prop.variant === '3d') {




                // Draw the 3D Y axis
                RG.SVG.create({
                    svg: this.svg,
                    parent: this.svg.all,
                    type: 'path',
                    attr: {
                        d: 'M {1} {2} L {3} {4} L {5} {6} L {7} {8}'.format(
                            prop.gutterLeft,
                            prop.gutterTop,
                            
                            prop.gutterLeft + prop.variant3dOffsetx,
                            prop.gutterTop - prop.variant3dOffsety,
                            
                            prop.gutterLeft + prop.variant3dOffsetx,
                            this.height - prop.gutterBottom - prop.variant3dOffsety,
                            
                            prop.gutterLeft,
                            this.height - prop.gutterBottom,
                            
                            prop.gutterLeft,
                            prop.gutterTop
                        ),
                        fill: '#ddd',
                        stroke: '#ccc'
                    }
                });




                // Add the group that the negative bars are added to. This makes them
                // appear below the axes
                this.threed_xaxis_group = RG.SVG.create({
                    svg: this.svg,
                    type: 'g',
                    parent: this.svg.all,
                    attr: {
                        className: 'rgraph_3d_bar_xaxis_negative'
                    }
                });



                // Draw the 3D X axis
                RG.SVG.create({
                    svg: this.svg,
                    parent: this.svg.all,
                    type: 'path',
                    attr: {
                        d: 'M {1} {2} L {3} {4} L {5} {6} L {7} {8}'.format(
                            prop.gutterLeft,
                            this.getYCoord(0),
                            
                            prop.gutterLeft + prop.variant3dOffsetx,
                            this.getYCoord(0) - prop.variant3dOffsety,
                            
                            this.width - prop.gutterRight + prop.variant3dOffsetx,
                            this.getYCoord(0) - prop.variant3dOffsety,
                            
                            this.width - prop.gutterRight,
                            this.getYCoord(0),
                            
                            prop.gutterLeft,
                            this.getYCoord(0)
                        ),
                        fill: '#ddd',
                        stroke: '#ccc'
                    }
                });
            }






            // Draw the bars
            this.drawBars();


            // Draw the axes over the bars
            RG.SVG.drawXAxis(this);
            RG.SVG.drawYAxis(this);
            
            
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
            var y = this.getYCoord(0);

            if (prop.shadow) {
                RG.SVG.setShadow({
                    object:  this,
                    offsetx: prop.shadowOffsetx,
                    offsety: prop.shadowOffsety,
                    blur:    prop.shadowBlur,
                    opacity: prop.shadowOpacity,
                    id:      'dropShadow'
                });
            }

            // Go through the bars
            for (var i=0,sequentialIndex=0; i<this.data.length; ++i,++sequentialIndex) {

                //
                // REGULAR BARS
                //
                if (typeof this.data[i] === 'number') {

                    var outerSegment = this.graphWidth / this.data.length,
                        height       = (ma.abs(this.data[i]) - ma.abs(this.scale.min)) / (ma.abs(this.scale.max) - ma.abs(this.scale.min)) * this.graphHeight,
                        width        = (this.graphWidth / this.data.length) - prop.hmargin - prop.hmargin,
                        x            = prop.gutterLeft + prop.hmargin + (outerSegment * i);

                    // Work out the height and the Y coord of the Bar
                    if (this.scale.min >= 0 && this.scale.max > 0) {
                        y = this.getYCoord(this.scale.min) - height;

                    } else if (this.scale.min < 0 && this.scale.max > 0) {
                        height = (ma.abs(this.data[i]) / (this.scale.max - this.scale.min)) * this.graphHeight;
                        y      = this.getYCoord(0) - height;
                        
                        if (this.data[i] < 0) {
                            y = this.getYCoord(0);
                        }
                    } else if (this.scale.min < 0 && this.scale.max < 0) {
                        height = (ma.abs(this.data[i]) - ma.abs(this.scale.max)) / (ma.abs(this.scale.min) - ma.abs(this.scale.max)) * this.graphHeight;
                        y = prop.gutterTop;
                    }









                    var rect = RG.SVG.create({
                        svg: this.svg,
                        type: 'rect',
                        parent: prop.variant === '3d' && this.data[i] < 0 ? this.threed_xaxis_group : this.svg.all, 
                        attr: {
                            stroke: prop.strokestyle,
                            fill: prop.colorsSequential ? (prop.colors[sequentialIndex] ? prop.colors[sequentialIndex] : prop.colors[prop.colors.length - 1]) : prop.colors[0],
                            x: x,
                            y: y,
                            width: width < 0 ? 0 : width,
                            height: height,
                            'stroke-width': prop.linewidth,
                            'data-original-x': x,
                            'data-original-y': y,
                            'data-original-width': width,
                            'data-original-height': height,
                            'data-tooltip': (!RG.SVG.isNull(prop.tooltips) && prop.tooltips.length) ? prop.tooltips[i] : '',
                            'data-index': i,
                            'data-sequential-index': sequentialIndex,
                            'data-value': this.data[i],
                            filter: prop.shadow ? 'url(#dropShadow)' : ''
                        }
                    });









                    // Draw the errorbar if required
                    this.drawErrorbar({
                        object:    this,
                        element:   rect,
                        index:     i,
                        value:     this.data[i],
                        type:      'normal'
                    });





                    this.coords.push({
                        object:  this,
                        element: rect,
                        x:      parseFloat(rect.getAttribute('x')),
                        y:      parseFloat(rect.getAttribute('y')),
                        width:  parseFloat(rect.getAttribute('width')),
                        height: parseFloat(rect.getAttribute('height'))
                    });

                    if (!this.coords2[0]) {
                        this.coords2[0] = [];
                    }
                
                    this.coords2[0].push({
                        object:  this,
                        element: rect,
                        x:      parseFloat(rect.getAttribute('x')),
                        y:      parseFloat(rect.getAttribute('y')),
                        width:  parseFloat(rect.getAttribute('width')),
                        height: parseFloat(rect.getAttribute('height'))
                    });



                    //
                    // Add the 3D faces if required
                    //
                    if (prop.variant === '3d') {
                        this.drawTop3dFace({rect: rect, value: this.data[i]});
                        this.drawSide3dFace({rect: rect, value: this.data[i]});
                    }






                    // Add the tooltip data- attribute
                    if (!RG.SVG.isNull(prop.tooltips) && prop.tooltips[sequentialIndex]) {

                        var obj = this;

                        //
                        // Add tooltip event listeners
                        //
                        (function (idx, seq)
                        {
                            rect.addEventListener(prop.tooltipsEvent.replace(/^on/, ''), function (e)
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

                            rect.addEventListener('mousemove', function (e)
                            {
                                e.target.style.cursor = 'pointer'
                            }, false);
                        })(i, sequentialIndex);
                    }





                //
                // GROUPED BARS
                //
                } else if (RG.SVG.isArray(this.data[i]) && prop.grouping === 'grouped') {

                    var outerSegment = (this.graphWidth / this.data.length),
                        innerSegment = outerSegment - (2 * prop.hmargin);

                    // Loop through the group
                    for (var j=0; j<this.data[i].length; ++j,++sequentialIndex) {

                        var width  = ( (innerSegment - ((this.data[i].length - 1) * prop.hmarginGrouped)) / this.data[i].length),
                            x      = (outerSegment * i) + prop.hmargin + prop.gutterLeft + (j * width) + ((j - 1) * prop.hmarginGrouped);
                        
                        x = prop.gutterLeft + (outerSegment * i) + (width * j) + prop.hmargin + (j * prop.hmarginGrouped);















// Calculate the height
// eg 0 -> 10
if (this.scale.min === 0 && this.scale.max > this.scale.min) {
    var height = ((this.data[i][j] - this.scale.min) / (this.scale.max - this.scale.min)) * this.graphHeight,
             y = this.getYCoord(0) - height;

// eg -5 -> -15
} else if (this.scale.max <= 0 && this.scale.min < this.scale.max) {
    var height = ((this.data[i][j] - this.scale.max) / (this.scale.max - this.scale.min)) * this.graphHeight,
             y = this.getYCoord(this.scale.max);
    
    height = ma.abs(height);

// eg 10 -> -10
} else if (this.scale.max > 0 && this.scale.min < 0) {

    var height = (ma.abs(this.data[i][j]) / (this.scale.max - this.scale.min)) * this.graphHeight,
             y = this.data[i][j] < 0 ? this.getYCoord(0) : this.getYCoord(this.data[i][j]);

// eg 5 -> 10
} else if (this.scale.min > 0 && this.scale.max > this.scale.min) {
    var height = (ma.abs(this.data[i][j] - this.scale.min) / (this.scale.max - this.scale.min)) * this.graphHeight,
             y = this.getYCoord(this.scale.min) - height;
}







                        // Add the rect tag
                        var rect = RG.SVG.create({
                            svg: this.svg,
                            parent: prop.variant === '3d' && this.data[i][j] < 0 ? this.threed_xaxis_group : this.svg.all,
                            type: 'rect',
                            attr: {
                                stroke: prop['strokestyle'],
                                fill: (prop.colorsSequential && prop.colors[sequentialIndex]) ? prop.colors[sequentialIndex] : prop.colors[j],
                                x: x,
                                y: y,
                                width: width,
                                height: height,
                                'stroke-width': prop.linewidth,
                                'data-original-x': x,
                                'data-original-y': y,
                                'data-original-width': width,
                                'data-original-height': height,
                                'data-index': i,
                                'data-subindex': j,
                                'data-sequential-index': sequentialIndex,
                                'data-tooltip': (!RG.SVG.isNull(prop.tooltips) && prop.tooltips.length) ? prop.tooltips[sequentialIndex] : '',
                                'data-value': this.data[i][j],
                                filter: prop.shadow ? 'url(#dropShadow)' : ''
                            }
                        });










                        // Draw the errorbar if required
                        this.drawErrorbar({
                            object:    this,
                            element:   rect,
                            index:     sequentialIndex,
                            value:     this.data[i][j],
                            type:      'grouped'
                        });










                        this.coords.push({
                            object:  this,
                            element: rect,
                            x:      parseFloat(rect.getAttribute('x')),
                            y:      parseFloat(rect.getAttribute('y')),
                            width:  parseFloat(rect.getAttribute('width')),
                            height: parseFloat(rect.getAttribute('height'))
                        });
                    
                        if (!this.coords2[i]) {
                            this.coords2[i] = [];
                        }
                    
                        this.coords2[i].push({
                            object:  this,
                            element: rect,
                            x:      parseFloat(rect.getAttribute('x')),
                            y:      parseFloat(rect.getAttribute('y')),
                            width:  parseFloat(rect.getAttribute('width')),
                            height: parseFloat(rect.getAttribute('height'))
                        });




                        //
                        // Add the 3D faces if required
                        //
                        if (prop.variant === '3d') {
                            this.drawTop3dFace({rect: rect, value: this.data[i][j]});
                            this.drawSide3dFace({rect: rect, value: this.data[i][j]});
                        }







                        // Add the tooltip data- attribute
                        if (!RG.SVG.isNull(prop.tooltips) && prop.tooltips[sequentialIndex]) {
                        
                            var obj = this;
    
                        
                            //
                            // Add tooltip event listeners
                            //
                            (function (idx, seq)
                            {
                                obj.removeHighlight();

                                var indexes = RG.SVG.sequentialIndexToGrouped(seq, obj.data);

                                rect.addEventListener(prop.tooltipsEvent.replace(/^on/, ''), function (e)
                                {
                                    // Show the tooltip
                                    RG.SVG.tooltip({
                                        object: obj,
                                        group: idx,
                                        index: indexes[1],
                                        sequentialIndex: seq,
                                        text: prop.tooltips[seq],
                                        event: e
                                    });
                                    
                                    // Highlight the rect that has been clicked on
                                    obj.highlight(e.target);
    
                                }, false);
                                
                                rect.addEventListener('mousemove', function (e)
                                {
                                    e.target.style.cursor = 'pointer'
                                }, false);
                            })(i, sequentialIndex);
                        }
                    }

                    --sequentialIndex;










                //
                // STACKED CHARTS
                //
                } else if (RG.SVG.isArray(this.data[i]) && prop.grouping === 'stacked') {

                    var section = (this.graphWidth / this.data.length);

                    
                    // Intialise the Y coordinate to the bottom gutter
                    var y = this.getYCoord(0);

                    

                    // Loop through the stack
                    for (var j=0; j<this.data[i].length; ++j,++sequentialIndex) {

                        var height  = (this.data[i][j] / (this.max - this.min)) * this.graphHeight,
                            width   = section - (2 * prop.hmargin),
                            x       = prop.gutterLeft + (i * section) + prop.hmargin,
                            y       = y - height;

                        // If this is the first iteration of the loop and a shadow
                        // is requested draw a rect here to create it.
                        if (j === 0 && prop.shadow) {
                            
                            var fullHeight = (RG.SVG.arraySum(this.data[i]) / (this.max - this.min)) * this.graphHeight;

                            var rect = RG.SVG.create({
                                svg: this.svg,
                                parent: this.svg.all,
                                type: 'rect',
                                attr: {
                                    fill: 'white',
                                    x: x,
                                    y: this.height - prop.gutterBottom - fullHeight,
                                    width: width,
                                    height: fullHeight,
                                    'stroke-width': 0,
                                    'data-index': i,
                                    filter: 'url(#dropShadow)'
                                }
                            });
                            
                            this.stackedBackfaces[i] = rect;
                        }



                        // Create the visible bar
                        var rect = RG.SVG.create({
                            svg: this.svg,
                            parent: this.svg.all,
                            type: 'rect',
                            attr: {
                                stroke: prop['strokestyle'],
                                fill: prop.colorsSequential ? (prop.colors[sequentialIndex] ? prop.colors[sequentialIndex] : prop.colors[prop.colors.length - 1]) : prop.colors[j],
                                x: x,
                                y: y,
                                width: width,
                                height: height,
                                'stroke-width': prop.linewidth,
                                'data-original-x': x,
                                'data-original-y': y,
                                'data-original-width': width,
                                'data-original-height': height,
                                'data-index': i,
                                'data-subindex': j,
                                'data-sequential-index': sequentialIndex,
                                'data-tooltip': (!RG.SVG.isNull(prop.tooltips) && prop.tooltips.length) ? prop.tooltips[sequentialIndex] : '',
                                'data-value': this.data[i][j]
                            }
                        });







                        // Draw the errorbar if required
                        if (j === (this.data[i].length - 1)) {

                            this.drawErrorbar({
                                object:    this,
                                element:   rect,
                                index:     i,
                                value:     this.data[i][j],
                                type:      'stacked'
                            });
                        }









                        this.coords.push({
                            object:  this,
                            element: rect,
                            x:      parseFloat(rect.getAttribute('x')),
                            y:      parseFloat(rect.getAttribute('y')),
                            width:  parseFloat(rect.getAttribute('width')),
                            height: parseFloat(rect.getAttribute('height'))
                        });

                        if (!this.coords2[i]) {
                            this.coords2[i] = [];
                        }
                    
                        this.coords2[i].push({
                            object:  this,
                            element: rect,
                            x:      parseFloat(rect.getAttribute('x')),
                            y:      parseFloat(rect.getAttribute('y')),
                            width:  parseFloat(rect.getAttribute('width')),
                            height: parseFloat(rect.getAttribute('height'))
                        });






                        //
                        // Add the 3D faces if required
                        //
                        if (prop.variant === '3d') {
                            this.drawTop3dFace({rect: rect, value: this.data[i][j]});
                            this.drawSide3dFace({rect: rect, value: this.data[i][j]});
                        }








                        // Add the tooltip data- attribute
                        if (!RG.SVG.isNull(prop.tooltips) && prop.tooltips[sequentialIndex]) {
                        
                            var obj = this;
    
                        
                            //
                            // Add tooltip event listeners
                            //
                            (function (idx, seq)
                            {
                                rect.addEventListener(prop.tooltipsEvent.replace(/^on/, ''), function (e)
                                {
                                    obj.removeHighlight();

                                    var indexes = RG.SVG.sequentialIndexToGrouped(seq, obj.data);

                                    // Show the tooltip
                                    RG.SVG.tooltip({
                                        object: obj,
                                        index: indexes[1],
                                        group: idx,
                                        sequentialIndex: seq,
                                        text: prop.tooltips[seq],
                                        event: e
                                    });
                                    
                                    // Highlight the rect that has been clicked on
                                    obj.highlight(e.target);
                                }, false);
                                
                                rect.addEventListener('mousemove', function (e)
                                {
                                    e.target.style.cursor = 'pointer';
                                }, false);
                            })(i, sequentialIndex);
                        }
                    }

                    --sequentialIndex;
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
                parent: this.svg.all,
                type: 'rect',
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


            if (prop.tooltipsEvent === 'mousemove') {
                
                //var obj = this;
                
                //highlight.addEventListener('mouseout', function (e)
                //{
                //    obj.removeHighlight();
                //    RG.SVG.hideTooltip();
                //    RG.SVG.REG.set('highlight', null);
                //}, false);
            }


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

                var data_seq      = RG.SVG.arrayLinearize(this.data),
                    seq           = 0,
                    stacked_total = 0;;

                for (var i=0; i<this.coords.length; ++i,seq++) {
                    
                    var num = typeof this.data[i] === 'number' ? this.data[i] : data_seq[seq] ;

            
            
            
            
                    // If this is a stacked chart then only dothe label
                    // if it's the top segment
                    if (prop.grouping === 'stacked') {
                        
                        var indexes   = RG.SVG.sequentialIndexToGrouped(i, this.data);
                        var group     = indexes[0];
                        var datapiece = indexes[1];

                        if (datapiece !== (this.data[group].length - 1) ) {
                            continue;
                        } else {
                            num = RG.SVG.arraySum(this.data[group]);
                        }
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
                    if (prop.labelsAboveSpecific && prop.labelsAboveSpecific.length && (typeof prop.labelsAboveSpecific[seq] === 'string' || typeof prop.labelsAboveSpecific[seq] === 'number') ) {
                        str = prop.labelsAboveSpecific[seq];
                    } else if ( prop.labelsAboveSpecific && prop.labelsAboveSpecific.length && typeof prop.labelsAboveSpecific[seq] !== 'string' && typeof prop.labelsAboveSpecific[seq] !== 'number') {
                        continue;
                    }

                    var x = parseFloat(this.coords[i].element.getAttribute('x')) + parseFloat(this.coords[i].element.getAttribute('width') / 2) + prop.labelsAboveOffsetx;

                    if (data_seq[i] >= 0) {
                        var y = parseFloat(this.coords[i].element.getAttribute('y')) - 7 + prop.labelsAboveOffsety;
                        var valign = prop.labelsAboveValign;
                    } else {
                        var y = parseFloat(this.coords[i].element.getAttribute('y')) + parseFloat(this.coords[i].element.getAttribute('height')) + 7 - prop.labelsAboveOffsety;
                        var valign = prop.labelsAboveValign === 'top' ? 'bottom' : 'top';
                    }

                    RG.SVG.text({
                        object:     this,
                        parent:     this.svg.all,
                        text:       str,
                        x:          x,
                        y:          y,
                        halign:     prop.labelsAboveHalign,
                        valign:     valign,
                        tag:        'labels.above',
                        font:       prop.labelsAboveFont              || prop.textFont,
                        size:       prop.labelsAboveSize              || prop.textSize,
                        bold:       prop.labelsAboveBold              || prop.textBold,
                        italic:     prop.labelsAboveItalic            || prop.textItalic,
                        color:      prop.labelsAboveColor             || prop.textColor,
                        background: prop.labelsAboveBackground        || null,
                        padding:    prop.labelsAboveBackgroundPadding || 0
                    });
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
        // Draws the top of 3D bars
        //
        this.drawTop3dFace = function (opt)
        {
            var rect  = opt.rect,
                arr   = [parseInt(rect.getAttribute('fill')), 'rgba(255,255,255,0.7)'],
                x     = parseInt(rect.getAttribute('x')),
                y     = parseInt(rect.getAttribute('y')),
                w     = parseInt(rect.getAttribute('width')),
                h     = parseInt(rect.getAttribute('height')),
                value = parseFloat(rect.getAttribute('data-value'));


            rect.rgraph_3d_top_face = [];


            for (var i=0; i<2; ++i) {
            
                var color = (i === 0 ? rect.getAttribute('fill') : 'rgba(255,255,255,0.7)');

                var face = RG.SVG.create({
                    svg: this.svg,
                    type: 'path',
                    parent: prop.variant === '3d' && opt.value < 0  ? this.threed_xaxis_group : this.svg.all,
                    attr: {
                        stroke: prop.strokestyle,
                        fill: color,
                        'stroke-width': prop.linewidth,
                        d: 'M {1} {2} L {3} {4} L {5} {6} L {7} {8}'.format(
                            x,
                            y,

                            x + prop.variant3dOffsetx,
                            y - prop.variant3dOffsety,

                            x + w + prop.variant3dOffsetx,
                            y - prop.variant3dOffsety,

                            x + w,
                            y
                        )
                    }
                });



                // Store a reference to the rect on the front face of the bar
                rect.rgraph_3d_top_face[i] = face
            }
        };








        //
        // Draws the top of 3D bars
        //
        this.drawSide3dFace = function (opt)
        {
            var rect  = opt.rect,
                arr   = [parseInt(rect.getAttribute('fill')), 'rgba(0,0,0,0.3)'],
                x     = parseInt(rect.getAttribute('x')),
                y     = parseInt(rect.getAttribute('y')),
                w     = parseInt(rect.getAttribute('width')),
                h     = parseInt(rect.getAttribute('height'));
            
            rect.rgraph_3d_side_face = [];

            for (var i=0; i<2; ++i) {
            
                var color = (i === 0 ? rect.getAttribute('fill') : 'rgba(0,0,0,0.3)');

                var face = RG.SVG.create({
                    svg: this.svg,
                    type: 'path',
                    parent: prop.variant === '3d' && opt.value < 0  ? this.threed_xaxis_group : this.svg.all,
                    attr: {
                        stroke: prop.strokestyle,
                        fill: color,
                        'stroke-width': prop.linewidth,
                        d: 'M {1} {2} L {3} {4} L {5} {6} L {7} {8}'.format(
                            x + w,
                            y,

                            x + w + prop.variant3dOffsetx,
                            y - prop.variant3dOffsety,

                            x + w + prop.variant3dOffsetx,
                            y + h - prop.variant3dOffsety,

                            x + w,
                            y + h
                        )
                    }
                });


                // Store a reference to the rect on the front face of the bar
                rect.rgraph_3d_side_face[i] = face
            }
        };








        // This function is used to draw the errorbar. Its in the common
        // file because it's used by multiple chart libraries
        this.drawErrorbar = function (opt)
        {
            var prop      = this.properties,
                index     = opt.index,
                datapoint = opt.value,
                linewidth = RG.SVG.getErrorbarsLinewidth({object: this, index: index}),
                color     = RG.SVG.getErrorbarsColor({object: this, index: index}),
                capwidth  = RG.SVG.getErrorbarsCapWidth({object: this, index: index}),
                element   = opt.element,
                type      = opt.type;
            
            

            // Get the error bar value
            var max = RG.SVG.getErrorbarsMaxValue({
                object: this,
                index: index
            });

            

            // Get the error bar value
            var min = RG.SVG.getErrorbarsMinValue({
                object: this,
                index: index
            });




            if (!max && !min) {
                return;
            }


            // Accounts for stacked bars
            if (type === 'stacked') {
                datapoint = RG.SVG.arraySum(this.data[index]);
            }


            if (datapoint >= 0) {
            
                var x1 = parseFloat(element.getAttribute('x')) + (parseFloat(element.getAttribute('width')) / 2);

                // Draw the UPPER vertical line
                var errorbarLine = RG.SVG.create({
                    svg: this.svg,
                    type: 'line',
                    parent: this.svg.all,
                    attr: {
                        x1: x1,
                        y1: parseFloat(element.getAttribute('y')),
                        x2: x1,
                        y2: this.getYCoord(parseFloat(datapoint + max)),
                        stroke: color,
                        'stroke-width': linewidth
                    }
                });
    
                // Draw the cap to the UPPER line
                var errorbarCap = RG.SVG.create({
                    svg: this.svg,
                    type: 'line',
                    parent: this.svg.all,
                    attr: {
                        x1: parseFloat(errorbarLine.getAttribute('x1')) - (capwidth / 2),
                        y1: errorbarLine.getAttribute('y2'),
                        x2: parseFloat(errorbarLine.getAttribute('x1')) + (capwidth / 2),
                        y2: errorbarLine.getAttribute('y2'),
                        stroke: color,
                        'stroke-width': linewidth
                    }
                });
















                // Draw the minimum errorbar if necessary
                if (typeof min === 'number') {

                    var errorbarLine = RG.SVG.create({
                        svg: this.svg,
                        type: 'line',
                        parent: this.svg.all,
                        attr: {
                            x1: x1,
                            y1: parseFloat(element.getAttribute('y')),
                            x2: x1,
                            y2: this.getYCoord(parseFloat(datapoint - min)),
                            stroke: color,
                            'stroke-width': linewidth
                        }
                    });
        
                    // Draw the cap to the UPPER line
                    var errorbarCap = RG.SVG.create({
                        svg: this.svg,
                        type: 'line',
                        parent: this.svg.all,
                        attr: {
                            x1: parseFloat(errorbarLine.getAttribute('x1')) - (capwidth / 2),
                            y1: errorbarLine.getAttribute('y2'),
                            x2: parseFloat(errorbarLine.getAttribute('x1')) + (capwidth / 2),
                            y2: errorbarLine.getAttribute('y2'),
                            stroke: color,
                            'stroke-width': linewidth
                        }
                    });
                }














            } else if (datapoint < 0) {

                var x1 = parseFloat(element.getAttribute('x')) + (parseFloat(element.getAttribute('width')) / 2),
                    y1 = parseFloat(element.getAttribute('y')) + parseFloat(element.getAttribute('height')),
                    y2 = this.getYCoord(parseFloat(datapoint - ma.abs(max) ))

                // Draw the vertical line
                var errorbarLine = RG.SVG.create({
                    svg: this.svg,
                    type: 'line',
                    parent: this.svg.all,
                    attr: {
                        x1: x1,
                        y1: y1,
                        x2: x1,
                        y2: y2,
                        stroke: color,
                        'stroke-width': linewidth
                    }
                });

                // Draw the cap to the vertical line
                var errorbarCap = RG.SVG.create({
                    svg: this.svg,
                    type: 'line',
                    parent: this.svg.all,
                    attr: {
                        x1: parseFloat(errorbarLine.getAttribute('x1')) - (capwidth / 2),
                        y1: errorbarLine.getAttribute('y2'),
                        x2: parseFloat(errorbarLine.getAttribute('x1')) + (capwidth / 2),
                        y2: errorbarLine.getAttribute('y2'),
                        stroke: color,
                        'stroke-width': linewidth
                    }
                });












                // Draw the minimum errorbar if necessary
                if (typeof min === 'number') {

                    var x1 = parseFloat(element.getAttribute('x')) + (parseFloat(element.getAttribute('width')) / 2);

                    var errorbarLine = RG.SVG.create({
                        svg: this.svg,
                        type: 'line',
                        parent: this.svg.all,
                        attr: {
                            x1: x1,
                            y1: this.getYCoord(parseFloat(datapoint + min)),
                            x2: x1,
                            y2: this.getYCoord(parseFloat(datapoint)),
                            stroke: color,
                            'stroke-width': linewidth
                        }
                    });
        
                    // Draw the cap to the UPPER line
                    var errorbarCap = RG.SVG.create({
                        svg: this.svg,
                        type: 'line',
                        parent: this.svg.all,
                        attr: {
                            x1: parseFloat(errorbarLine.getAttribute('x1')) - (capwidth / 2),
                            y1: errorbarLine.getAttribute('y1'),
                            x2: parseFloat(errorbarLine.getAttribute('x1')) + (capwidth / 2),
                            y2: errorbarLine.getAttribute('y1'),
                            stroke: color,
                            'stroke-width': linewidth
                        }
                    });
                }
            }
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



                        // This upadtes the size of the 3D sides to the bar
                        if (prop.variant === '3d') {
                        
                            // Remove the 3D sides to the bar
                            if (obj.coords[i].element.rgraph_3d_side_face[0].parentNode) obj.coords[i].element.rgraph_3d_side_face[0].parentNode.removeChild(obj.coords[i].element.rgraph_3d_side_face[0]);
                            if (obj.coords[i].element.rgraph_3d_side_face[1].parentNode) obj.coords[i].element.rgraph_3d_side_face[1].parentNode.removeChild(obj.coords[i].element.rgraph_3d_side_face[1]);
                            
                            if (obj.coords[i].element.rgraph_3d_top_face[0].parentNode) obj.coords[i].element.rgraph_3d_top_face[0].parentNode.removeChild(obj.coords[i].element.rgraph_3d_top_face[0]);
                            if (obj.coords[i].element.rgraph_3d_top_face[1].parentNode) obj.coords[i].element.rgraph_3d_top_face[1].parentNode.removeChild(obj.coords[i].element.rgraph_3d_top_face[1]);
                            
                            // Add the 3D sides to the bar (again)
                            obj.drawSide3dFace({rect: obj.coords[i].element});
                            
                            // Draw the top side of the 3D bar
                            if (prop.grouping === 'grouped') {
                                obj.drawTop3dFace({rect: obj.coords[i].element   });
                            }

                            // Now remove and immediately re-add the front face of
                            // the bar - this is so that the front face appears
                            // above the other sides
                            if (obj.coords[i].element.parentNode) {
                                var parent = obj.coords[i].element.parentNode;
                                var node   = parent.removeChild(obj.coords[i].element);
                                parent.appendChild(node);
                            }
                        }


                    } else if (typeof data[i] === 'object') {

                        var accumulativeHeight = 0;

                        for (var j=0,len2=data[i].length; j<len2; ++j, ++seq) {

                            height         = ma.abs(obj.getYCoord(data[i][j]) - obj.getYCoord(0));
                            height         = multiplier * height;
                            obj.data[i][j] = data[i][j] * multiplier;
                            height = ma.round(height);

                            obj.coords[seq].element.setAttribute(
                                'height',
                                height
                            );

                            obj.coords[seq].element.setAttribute(
                                'y',
                                data[i][j] < 0 ? (obj.getYCoord(0) + accumulativeHeight) : (obj.getYCoord(0) - height - accumulativeHeight)
                            );




    
                            // This updates the size of the 3D sides to the bar
                            if (prop.variant === '3d') {

                                // Remove the 3D sides to the bar
                                if (obj.coords[seq].element.rgraph_3d_side_face[0].parentNode) obj.coords[seq].element.rgraph_3d_side_face[0].parentNode.removeChild(obj.coords[seq].element.rgraph_3d_side_face[0]);
                                if (obj.coords[seq].element.rgraph_3d_side_face[1].parentNode) obj.coords[seq].element.rgraph_3d_side_face[1].parentNode.removeChild(obj.coords[seq].element.rgraph_3d_side_face[1]);
                                
                                if (obj.coords[seq].element.rgraph_3d_top_face[0].parentNode) obj.coords[seq].element.rgraph_3d_top_face[0].parentNode.removeChild(obj.coords[seq].element.rgraph_3d_top_face[0]);
                                if (obj.coords[seq].element.rgraph_3d_top_face[1].parentNode) obj.coords[seq].element.rgraph_3d_top_face[1].parentNode.removeChild(obj.coords[seq].element.rgraph_3d_top_face[1]);
                                
                                // Add the 3D sides to the bar (again)
                                obj.drawSide3dFace({rect: obj.coords[seq].element});

// Draw the top side of the 3D bar
// TODO Need to only draw the top face when the bar is either
//      not stacked or is the last segment in the stack
obj.drawTop3dFace({rect: obj.coords[seq].element});
    
                                // Now remove and immediately re-add the front face of
                                // the bar - this is so that the front face appears
                                // above the other sides
                                if (obj.coords[seq].element.parentNode) {
                                    var parent = obj.coords[seq].element.parentNode;
                                    var node   = parent.removeChild(obj.coords[seq].element);
                                    parent.appendChild(node);
                                }
                            }
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
                
                // Now zero the width of the bar (and remove the 3D faces)
                this.coords[i].element.setAttribute('height', 0);
                
                if (this.coords[i].element.rgraph_3d_side_face) {
                
                    var parent = this.coords[i].element.rgraph_3d_side_face[0].parentNode;
                    
                    parent.removeChild(this.coords[i].element.rgraph_3d_side_face[0]);
                    parent.removeChild(this.coords[i].element.rgraph_3d_side_face[1]);
                    
                    parent.removeChild(this.coords[i].element.rgraph_3d_top_face[0]);
                    parent.removeChild(this.coords[i].element.rgraph_3d_top_face[1]);
                }
            }

            function iterator ()
            {
                ++frame;

                for (var i=0,len=obj.coords.length; i<len; i+=1) {
                    if (frame > opt.startFrames[i]) {
                        
                        var originalHeight = obj.coords[i].element.getAttribute('data-original-height'),
                            height,
                            value = parseFloat(obj.coords[i].element.getAttribute('data-value'));

                            var height = ma.min(
                                ((frame - opt.startFrames[i]) / framesperbar) * originalHeight,
                                originalHeight
                            );
                        obj.coords[i].element.setAttribute(
                            'height',
                            height < 0 ? 0 : height
                        );

                        obj.coords[i].element.setAttribute(
                            'y',
                            value >=0 ? obj.getYCoord(0) - height : obj.getYCoord(0)
                        );



                        // This updates the size of the 3D sides to the bar
                        if (prop.variant === '3d') {
                        
                            // Remove the 3D sides to the bar
                            var parent = obj.coords[i].element.rgraph_3d_side_face[0].parentNode;
        
                            if (parent) parent.removeChild(obj.coords[i].element.rgraph_3d_side_face[0]);
                            if (parent) parent.removeChild(obj.coords[i].element.rgraph_3d_side_face[1]);
                            
                            var parent = obj.coords[i].element.rgraph_3d_top_face[0].parentNode;
                            if (parent) parent.removeChild(obj.coords[i].element.rgraph_3d_top_face[0]);
                            if (parent) parent.removeChild(obj.coords[i].element.rgraph_3d_top_face[1]);
                            


                            // Now remove and immediately re-add the front face of
                            // the bar - this is so that the front face appears
                            // above the other sides
                            if (obj.coords[i].element.parentNode) {
                                var parent = obj.coords[i].element.parentNode;
                                var node   = parent.removeChild(obj.coords[i].element);
                                parent.appendChild(node);
                            }
                        }


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

                        if (prop.variant === '3d') {
                            // Add the 3D sides to the bar (again)
                            obj.drawSide3dFace({
                                rect:  obj.coords[i].element,
                                value: obj.coords[i].element.getAttribute('data-value')
                            });
    
                            // Draw the top side of the 3D bar
                            if (prop.grouping === 'grouped' || (prop.grouping === 'stacked' && (indexes[1] + 1) === obj.data[indexes[0]].length) ) {
                                obj.drawTop3dFace({
                                    rect:  obj.coords[i].element,
                                    value: obj.coords[i].element.getAttribute('data-value')
                                });
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