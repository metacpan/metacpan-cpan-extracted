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



    RG.SVG.Line = function (conf)
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
        this.uid             = RG.SVG.createUID();
        this.container       = document.getElementById(this.id);
        this.layers          = {}; // MUST be before the SVG tag is created!
        this.svg             = RG.SVG.createSVG({object: this,container: this.container});
        this.isRGraph        = true;
        this.width           = Number(this.svg.getAttribute('width'));
        this.height          = Number(this.svg.getAttribute('height'));
        
        // Convert single datasets to a multi-dimensional format
        if (RG.SVG.isArray(conf.data) && RG.SVG.isArray(conf.data[0])) {
            this.data = RG.SVG.arrayClone(conf.data);
        } else if (RG.SVG.isArray(conf.data)) {
            this.data = [RG.SVG.arrayClone(conf.data)];
        } else {
            this.data = [[]];
        }

        this.type            = 'line';
        this.coords          = [];
        this.coords2         = [];
        this.coordsSpline    = [];
        this.hasMultipleDatasets = typeof this.data[0] === 'object' && typeof this.data[1] === 'object' ? true : false;
        this.colorsParsed    = false;
        this.originalColors  = {};
        this.gradientCounter = 1;
        this.originalData    = RG.SVG.arrayClone(this.data);
        this.filledGroups    = [];

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
            backgroundImageStretch:     true,
            backgroundImageAspect:      'none',
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
            
            colors:           ['red', '#0f0', 'blue', '#ff0', '#0ff', 'green'],
            
            filled:             false,
            filledColors:       [],
            filledClick:        null,
            filledOpacity:      1,
            filledAccumulative: false,
            
            hmargin:      0,

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
            xaxisLabelsOffsetx:   0,
            xaxisLabelsOffsety:   0,
            xaxisLabelsPosition:  'edge',
            xaxisLabelsPositionEdgeTickmarksCount: null,
            xaxisColor:           'black',
            
            textColor: 'black',
            textFont: 'sans-serif',
            textSize: 12,
            textBold: false,
            textItalic: false,

            linewidth: 1,

            tooltips: null,
            tooltipsOverride: null,
            tooltipsEffect: 'fade',
            tooltipsCssClass: 'RGraph_tooltip',
            tooltipsEvent: 'mousemove',
            
            highlightStroke: 'rgba(0,0,0,0)',
            highlightFill: 'rgba(255,255,255,0.7)',
            highlightLinewidth: 1,
            
            tickmarksStyle: 'none',
            tickmarksSize: 5,
            tickmarksFill: 'white',
            tickmarksLinewidth: 1,

            labelsAbove:                  false,
            labelsAboveFont:              null,
            labelsAboveSize:              null,
            labelsAboveBold:              null,
            labelsAboveItalic:            null,
            labelsAboveColor:             null,
            labelsAboveBackground:        'rgba(255,255,255,0.7)',
            labelsAboveBackgroundPadding: 2,
            labelsAboveUnitsPre:          null,
            labelsAboveUnitsPost:         null,
            labelsAbovePoint:             null,
            labelsAboveThousand:          null,
            labelsAboveFormatter:         null,
            labelsAboveDecimals:          null,
            labelsAboveOffsetx:           0,
            labelsAboveOffsety:           -10,
            labelsAboveHalign:            'center',
            labelsAboveValign:            'bottom',
            labelsAboveSpecific:          null,

            shadow: false,
            shadowOffsetx: 2,
            shadowOffsety: 2,
            shadowBlur: 2,
            shadowOpacity: 0.25,
            
            spline: false,
            stepped: false,
            
            title: '',
            titleSize: null,
            titleX: null,
            titleY: null,
            titleHalign: 'center',
            titleValign: null,
            titleColor:  null,
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
















            // Create the defs tag
            RG.SVG.createDefs(this);





            this.graphWidth  = this.width - prop.gutterLeft - prop.gutterRight;
            this.graphHeight = this.height - prop.gutterTop - prop.gutterBottom;



            // Parse the colors for gradients
            RG.SVG.resetColorsToOriginalValues({object:this});
            this.parseColors();
            
            // Clear the coords arrays
            this.coords       = [];
            this.coords2      = [];
            this.coordsSpline = [];
            
            // Reset the data back to the original
            this.data = RG.SVG.arrayClone(this.originalData);

            
            // Set this to zero
            this.tooltipsSequentialIndex = 0;














            // Go through all the data working out the max value
            // whilst taking errorbars into account
            for (var i=0,tmp=[]; i<this.data.length; ++i) {
                for (var j=0; j<this.data[i].length; ++j) {
                    
                    // Init the tmp array slot
                    if (typeof tmp[j] === 'undefined') {
                        tmp[j] = 0;
                    }

                    if (prop.filled && prop.filledAccumulative) {
                        tmp[j] += this.data[i][j];
                        
                        // Only add this once (from the last dataset)
                        if (i === (this.data.length - 1) ) {
                             tmp[j] += (prop.errorbars ? prop.errorbars[RG.SVG.groupedIndexToSequential({object: this, dataset: i, index: j})].max : 0)
                        }
                    } else {
                        tmp[j] = ma.max(tmp[j], this.data[i][j] + (prop.errorbars ? prop.errorbars[RG.SVG.groupedIndexToSequential({object: this, dataset: i, index: j})].max : 0) );
                    }
                }
            }


            // Go through the data and work out the maximum value
            var values = [];

            // Go thru each dataset
            for (var i=0,max=0; i<this.data.length; ++i) {
                
                if (RG.SVG.isArray(this.data[i]) && !prop.filledAccumulative) {
                    values.push(RG.SVG.arrayMax(tmp));

                } else if (RG.SVG.isArray(this.data[i]) && prop.filled && prop.filledAccumulative) {
                
                   for (var j=0; j<this.data[i].length; ++j) {
                        values[j] = values[j]  || 0;
                        values[j] = values[j] + this.data[i][j];
                        
                        // This adds values to prior values in order
                        // to create the stacking effect.
                        this.data[i][j] = values[j];
                    }
                }
            }

            
            
            if (prop.filled && prop.filledAccumulative) {
                var max = RG.SVG.arrayMax(tmp)
            } else {
                var max = RG.SVG.arrayMax(values);
            }
















            // A custom, user-specified maximum value
            if (typeof prop.yaxisMax === 'number') {
                max = prop.yaxisMax;
            }
            
            // Set the ymin to zero if it's set mirror
            if (prop.yaxisMin === 'mirror') {
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


            // Draw the axes over the bars
            RG.SVG.drawXAxis(this);
            RG.SVG.drawYAxis(this);


            for (var i=0; i<this.data.length; ++i) {
                this.drawLine(this.data[i], i);
            }

            // Always redraw the liines now so that tickmarks are drawn
            this.redrawLines();








            
            
            // Draw the key
            if (typeof prop.key !== null && RG.SVG.drawKey) {
                RG.SVG.drawKey(this);
            } else if (!RGraph.SVG.isNull(prop.key)) {
                alert('The drawKey() function does not exist - have you forgotten to include the key library?');
            }







            // Draw the labelsAbove labels
            this.drawLabelsAbove();



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
        // Draws the bars
        //
        this.drawLine = function (data, index)
        {
            var coords = [],
                path   = [];

            // Generate the coordinates
            for (var i=0,len=data.length; i<len; ++i) {
                
                var val = data[i],
                    x   = (( (this.graphWidth - prop.hmargin - prop.hmargin) / (len - 1) ) * i) + prop.gutterLeft + prop.hmargin,
                    y   = this.getYCoord(val);

                coords.push([x,y]);
            }


            // Go through the coordinates and create the path that draws the line
            for (var i=0; i<coords.length; ++i) {

                if (i === 0 || RG.SVG.isNull(data[i]) || RG.SVG.isNull(data[i - 1])) {
                    var action = 'M';
                } else {
                     // STEPPED Add extra lines
                    if (prop.stepped) {
                        path.push('L {1} {2}'.format(
                            coords[i][0],
                            coords[i - 1][1]
                        ));
                    }
                    var action = 'L';
                }

                path.push(action + '{1} {2}'.format(
                    coords[i][0],
                    coords[i][1]
                ));
            }
            






            //
            // Add the coordinates to the coords array, coords2 array and if
            // necessary, the coordsSpline array 
            //

            // The coords array

            for (var k=0; k<coords.length; ++k) {
                
                this.coords.push(RG.SVG.arrayClone(coords[k]));

                this.coords[this.coords.length - 1].x      = coords[k][0];
                this.coords[this.coords.length - 1].y      = coords[k][1];
                this.coords[this.coords.length - 1].object = this;
                this.coords[this.coords.length - 1].value  = data[k];
                this.coords[this.coords.length - 1].index  = k;
                this.coords[this.coords.length - 1].path = path;
            }

            // The coords2 array
            this.coords2[index] = RG.SVG.arrayClone(coords);

            for (var k=0; k<coords.length; ++k) {
                this.coords2[index][k].x      = coords[k][0];
                this.coords2[index][k].y      = coords[k][1];
                this.coords2[index][k].object = this;
                this.coords2[index][k].value  = data[k];
                this.coords2[index][k].index  = k;
                this.coords2[index][k].path = path;

                // Draw the errorbar if required
                if (prop.errorbars) {
                    this.drawErrorbar({
                        object:    this,
                        dataset:   index,
                        index:     k,
                        x:         x,
                        y:         y
                    });
                }
            }




            // The coordsSpline array
            if (prop.spline) {
                this.coordsSpline[index] = this.drawSpline(coords);
            }




            // If the line should be filled, draw the fill part
            if (prop.filled === true || (typeof prop.filled === 'object' && prop.filled[index]) ) {

                if (prop.spline) {
                    
                    var fillPath = ['M{1} {2}'.format(
                        this.coordsSpline[index][0][0],
                        this.coordsSpline[index][0][1]
                    )];

                    for (var i=1; i<this.coordsSpline[index].length; ++i) {
                        fillPath.push('L{1} {2}'.format(
                            this.coordsSpline[index][i][0] + ((i === (this.coordsSpline[index].length) - 1) ? 1 : 0),
                            this.coordsSpline[index][i][1]
                        ));
                    }

                } else {
                    var fillPath = RG.SVG.arrayClone(path);
                }


                // Draw a line down to the X axis
                fillPath.push('L{1} {2}'.format(
                    this.coords2[index][this.coords2[index].length - 1][0] + 1,
                    index > 0 && prop.filledAccumulative ? (prop.spline ? this.coordsSpline[index - 1][this.coordsSpline[index - 1].length - 1][1] : this.coords2[index - 1][this.coords2[index - 1].length - 1][1]) : this.getYCoord(prop.yaxisMin > 0 ? prop.yaxisMin : 0) + (prop.xaxis ? 0 : 1)
                ));

                if (index > 0 && prop.filledAccumulative) {
                    
                    var path2 = RG.SVG.arrayClone(path);
                    
                    if (index > 0 && prop.filledAccumulative) {
                        if (prop.spline) {
                            for (var i=this.coordsSpline[index - 1].length-1; i>=0; --i) {
                                fillPath.push('L{1} {2}'.format(
                                    this.coordsSpline[index - 1][i][0],
                                    this.coordsSpline[index - 1][i][1]
                                ));
                            }
                        } else {
                            for (var i=this.coords2[index - 1].length-1; i>=0; --i) {

                                fillPath.push('L{1} {2}'.format(
                                    this.coords2[index - 1][i][0],
                                    this.coords2[index - 1][i][1]
                                ));
                                
                                // For STEPPED charts
                                if (prop.stepped && i > 0) {
                                    fillPath.push('L{1} {2}'.format(
                                        this.coords2[index - 1][i][0],
                                        this.coords2[index - 1][i - 1][1]
                                    ));
                                }
                            }
                        }
                    }
                } else {

                    // This is the bottom left corner. The +1 is so that
                    // the fill doesn't go over the axis
                    fillPath.push('L{1} {2}'.format(
                        this.coords2[index][0][0] + (prop.yaxis ? 1 : 0),
                        this.getYCoord(prop.yaxisMin > 0 ? prop.yaxisMin : 0) + (prop.xaxis ? 0 : 1)
                    ));
                }

                // Find the first none-null value and use that
                // values X value
                fillPath.push('L{1} {2}'.format(
                    this.coords2[index][0][0] + (prop.yaxis ? 1 : 0),
                    this.coords2[index][0][1]
                ));

                for (var i=0; i<this.data[index].length; ++i) {
                    if (!RG.SVG.isNull(this.data[index][i])) {
                        fillPath.push('L{1} {2}'.format(
                            this.coords2[index][i][0],
                            this.getYCoord(0)
                        ));
                        break;
                    }
                }

                // Create a group that the fill is added to. Later the line
                // will also be added to it
                this.filledGroups[index] = RG.SVG.create({
                    svg: this.svg,
                    type: 'g',
                    parent: this.svg.all,
                    attr: {
                        'class': 'rgraph_filled_line_' + index
                    }
                });

                // Add the fill path to the scene
                var fillPathObject = RG.SVG.create({
                    svg: this.svg,
                    parent: this.filledGroups[index],
                    type: 'path',
                    attr: {
                        d: fillPath.join(' '),
                        stroke: 'rgba(0,0,0,0)',
                        'fill': prop.filledColors && prop.filledColors[index] ? prop.filledColors[index] : prop.colors[index],
                        'fill-opacity': prop.filledOpacity,
                        'stroke-width': 1,
                        'clip-path': this.isTrace ? 'url(#trace-effect-clip)' : ''
                    }
                });


                if (prop.filledClick) {
                    
                    var obj = this;
                    fillPathObject.addEventListener('click', function (e)
                    {
                        prop.filledClick(e, obj, index);
                    }, false);
                    
                    fillPathObject.addEventListener('mousemove', function (e)
                    {
                        e.target.style.cursor = 'pointer';
                    }, false);
                }
            }









            //
            // Create the drop shadow effect if its required
            //
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














            // Add the path to the scene
            if (prop.spline) {

                // Make the raw coords into a path
                var str = ['M{1} {2}'.format(
                    this.coordsSpline[index][0][0],
                    this.coordsSpline[index][0][1]
                )];

                for (var i=1; i<this.coordsSpline[index].length; ++i) {
                    str.push('L{1} {2}'.format(
                        this.coordsSpline[index][i][0],
                        this.coordsSpline[index][i][1]
                    ));
                }
                
                str = str.join(' ');

                var line = RG.SVG.create({
                    svg: this.svg,
                    parent: prop.filled ? this.filledGroups[index] : this.svg.all,
                    type: 'path',
                    attr: {
                        d: str,
                        stroke: prop['colors'][index],
                        'fill':'none',
                        'stroke-width':  this.hasMultipleDatasets && prop.filled && prop.filledAccumulative ? 0.1 : (RG.SVG.isArray(prop.linewidth) ? prop.linewidth[index] : prop.linewidth + 0.01),
                        'stroke-linecap': 'round',
                        'stroke-linejoin': 'round',
                        filter: prop.shadow ? 'url(#dropShadow)' : '',
                        'clip-path': this.isTrace ? 'url(#trace-effect-clip)' : ''
                    }
                });

            } else {

                var path2 = RG.SVG.arrayClone(path);

                if (prop.filled && prop.filledAccumulative && index > 0) {
                    for (var i=this.coords2[index - 1].length-1; i>=0; --i) {
                        path2.push('L{1} {2}'.format(
                            this.coords2[index - 1][i][0],
                            this.coords2[index - 1][i][1]
                        ));
                    }
                }

                path2 = path2.join(' ');

                var line = RG.SVG.create({
                    svg: this.svg,
                    parent: prop.filled ? this.filledGroups[index] : this.svg.all,
                    type: 'path',
                    attr: {
                        d: path2,
                        stroke: prop.colors[index],
                        'fill':'none',
                        'stroke-width': this.hasMultipleDatasets && prop.filled && prop.filledAccumulative ? 0.1 : (RG.SVG.isArray(prop.linewidth) ? prop.linewidth[index]: prop.linewidth + 0.01),
                        'stroke-linecap': 'round',
                        'stroke-linejoin': 'round',
                        filter: prop.shadow ? 'url(#dropShadow)' : '',
                        'clip-path': this.isTrace ? 'url(#trace-effect-clip)' : ''
                    }
                });
            }






            if (prop.tooltips && prop.tooltips.length) {

                var group = RG.SVG.create({
                    svg: this.svg,
                    parent: this.svg.all,
                    type: 'g',
                    attr: {
                        'fill': 'transparent',
                        className: "rgraph_hotspots"
                    },
                    style: {
                        cursor: 'pointer'
                    }
                });
                
            
                //for (var i=0; i<this.coords2[index].length; ++i,++this.tooltipsSequentialIndex) {
                for (var i=0; i<this.coords2[index].length && this.tooltipsSequentialIndex < prop.tooltips.length; ++i,++this.tooltipsSequentialIndex) {
                    if (prop.tooltips[this.tooltipsSequentialIndex] && this.coords2[index][i][0] && this.coords2[index][i][1]) {

                        var hotspot = RG.SVG.create({
                            svg: this.svg,
                            
                            // Intentionally omitted So that the hotspotis on top of 
                            // everything else
                            //parent: group,

                            type: 'circle',
                            attr: {
                                cx: this.coords2[index][i][0],
                                cy: this.coords2[index][i][1],
                                r: 10,
                                fill: 'transparent',
                                'data-dataset': index,
                                'data-index': i
                            },
                            style: {
                                cursor: 'pointer'
                            }
                        });

                        var obj = this;
                        (function (sequentialIndex)
                        {
                            hotspot.addEventListener(prop.tooltipsEvent, function (e)
                            {
                                var indexes = RG.SVG.sequentialIndexToGrouped(sequentialIndex, obj.data),
                                    index   = indexes[1],
                                    dataset = indexes[0];


                                if (RG.SVG.REG.get('tooltip') && RG.SVG.REG.get('tooltip').__index__ === index && RG.SVG.REG.get('tooltip').__dataset__ === dataset) {
                                    return;
                                }
                                
                                obj.removeHighlight();

                                RG.SVG.hideTooltip();

                                // Show the tooltip
                                if (prop.tooltips[sequentialIndex]) {
                                    var text = prop.tooltips[sequentialIndex];
                                }

                                RG.SVG.tooltip({
                                    object: obj,
                                    index: index,
                                    dataset: dataset,
                                    sequentialIndex: sequentialIndex,
                                    text: text,
                                    event: e
                                });


                                // Highlight the chart here
                                var outer_highlight1 = RG.SVG.create({
                                    svg: obj.svg,
                                    parent: obj.svg.all,
                                    type: 'circle',
                                    attr: {
                                        cx: obj.coords2[dataset][index][0],
                                        cy: obj.coords2[dataset][index][1],
                                        r: 13,
                                        fill: obj.properties.colors[dataset],
                                        'fill-opacity': 0.5
                                    },
                                    style: {
                                        cursor: 'pointer'
                                    }
                                });


                                var outer_highlight2 = RG.SVG.create({
                                    svg: obj.svg,
                                    parent: obj.svg.all,
                                    type: 'circle',
                                    attr: {
                                        cx: obj.coords2[dataset][index][0],
                                        cy: obj.coords2[dataset][index][1],
                                        r: 14,
                                        fill: 'white',
                                        'fill-opacity': 0.75
                                    },
                                    style: {
                                        cursor: 'pointer'
                                    }
                                });


                                var inner_highlight1 = RG.SVG.create({
                                    svg: obj.svg,
                                    parent: obj.svg.all,
                                    type: 'circle',
                                    attr: {
                                        cx: obj.coords2[dataset][index][0],
                                        cy: obj.coords2[dataset][index][1],
                                        r: 6,
                                        fill: 'white'
                                    },
                                    style: {
                                        cursor: 'pointer'
                                    }
                                });


                                var inner_highlight2 = RG.SVG.create({
                                    svg: obj.svg,
                                    parent: obj.svg.all,
                                    type: 'circle',
                                    attr: {
                                        cx: obj.coords2[dataset][index][0],
                                        cy: obj.coords2[dataset][index][1],
                                        r: 5,
                                        fill: obj.properties.colors[dataset]
                                    },
                                    style: {
                                        cursor: 'pointer'
                                    }
                                });
                                
                                // Set the highlight in the registry
                                RG.SVG.REG.set('highlight', [
                                    outer_highlight1,
                                    outer_highlight2,
                                    inner_highlight1,
                                    inner_highlight2
                                ]);
                                
                            }, false);
                        })(this.tooltipsSequentialIndex);
    
                    }
                }
            }
        };








        //
        // Draws tickmarks
        //
        // @param number index  The index of the line/dataset of coordinates
        // @param object data   The origvinal line data points
        // @param object coords The coordinates of the points
        //
        this.drawTickmarks = function (index, data, coords)
        {
            for (var i=0; i<data.length; ++i) {

                if (typeof data[i] === 'number') {
                    switch (prop.tickmarksStyle) {
                        case 'filledcircle':
                        case 'filledendcircle':
                            if (prop.tickmarksStyle === 'filledcircle' || (i === 0 || i === data.length - 1) ) {
                                var circle = RG.SVG.create({
                                    svg: this.svg,
                                    type: 'circle',
                                    attr: {
                                        cx: coords[index][i][0],
                                        cy: coords[index][i][1],
                                        r: prop.tickmarksSize,
                                        'fill': prop.colors[index],
                                        filter: prop.shadow? 'url(#dropShadow)' : '',
                                        'clip-path': this.isTrace ? 'url(#trace-effect-clip)' : ''
                                    }
                                });
                            }


                            break;

                        case 'circle':
                        case 'endcircle':

                            if (prop.tickmarksStyle === 'circle' || (prop.tickmarksStyle === 'endcircle' && (i === 0 || i === data.length - 1)) ) {

                                var outerCircle = RG.SVG.create({
                                    svg: this.svg,
                                    parent: this.svg.all,
                                    type: 'circle',
                                    attr: {
                                        cx: coords[index][i][0],
                                        cy: coords[index][i][1],
                                        r: prop.tickmarksSize + prop.tickmarksLinewidth,
                                        'fill': prop.colors[index],
                                        filter: prop.shadow? 'url(#dropShadow)' : '',
                                        'clip-path': this.isTrace ? 'url(#trace-effect-clip)' : ''
                                    }
                                });

                                var innerCircle = RG.SVG.create({
                                    svg: this.svg,
                                    parent: this.svg.all,
                                    type: 'circle',
                                    attr: {
                                        cx: coords[index][i][0],
                                        cy: coords[index][i][1],
                                        r: prop.tickmarksSize,
                                        'fill': prop.tickmarksFill,
                                        'clip-path': this.isTrace ? 'url(#trace-effect-clip)' : ''
                                    }
                                });

                                break;
                            }
                            break;

                        case 'endrect':
                        case 'rect':
                            if (prop.tickmarksStyle === 'rect' || (prop.tickmarksStyle === 'endrect' && (i === 0 || i === data.length - 1)) ) {
                            
                                var half = (prop.tickmarksSize + prop.tickmarksLinewidth) / 2;
                                var fill = typeof prop.tickmarksFill === 'object'&& typeof prop.tickmarksFill[index] === 'string' ? prop.tickmarksFill[index] : prop.tickmarksFill;
                            
                                var rect = RG.SVG.create({
                                    svg: this.svg,
                                    parent: this.svg.all,
                                    type: 'rect',
                                    attr: {
                                        x:      coords[index][i][0] - half,
                                        y:      coords[index][i][1] - half,
                                        width:  prop.tickmarksSize+ prop.tickmarksLinewidth,
                                        height: prop.tickmarksSize+ prop.tickmarksLinewidth,
    
                                        'stroke-width': prop.tickmarksLinewidth,
                                        'stroke': prop.colors[index],
                                        'fill': fill,
                                        'clip-path': this.isTrace ? 'url(#trace-effect-clip)' : ''
                                    }
                                });
                            }
                            
                            break;

                        case 'filledendrect':
                        case 'filledrect':
                            if (prop.tickmarksStyle === 'filledrect' || (prop.tickmarksStyle === 'filledendrect' && (i === 0 || i === data.length - 1)) ) {

                                var half = (prop.tickmarksSize + prop.tickmarksLinewidth) / 2;
                                var fill = prop.colors[index];
                            
                                var rect = RG.SVG.create({
                                    svg: this.svg,
                                    parent: this.svg.all,
                                    type: 'rect',
                                    attr: {
                                        x:      coords[index][i][0] - half,
                                        y:      coords[index][i][1] - half,
                                        width:  prop.tickmarksSize+ prop.tickmarksLinewidth,
                                        height: prop.tickmarksSize+ prop.tickmarksLinewidth,
                                        'fill': fill,
                                        'clip-path': this.isTrace ? 'url(#trace-effect-clip)' : ''
                                    }
                                });
                            }
                    }
                }
            }
        };








        //
        // Redraws the line in certain circumstances:
        //  o filled
        //  o filledAccumulative
        //  o Multiple lines
        //
        this.redrawLines = function ()
        {
            if (prop.spline) {
                for (var i=0; i<this.coordsSpline.length; ++i) {

                    var linewidth = RG.SVG.isArray(prop.linewidth) ? prop.linewidth[i] : prop.linewidth,
                        color     = prop['colors'][i],
                        path      = '';
                    
                    // Create the path from the spline coordinates
                    for (var j=0; j<this.coordsSpline[i].length; ++j) {
                        if (j === 0) {
                            path += 'M{1} {2} '.format(
                                this.coordsSpline[i][j][0],
                                this.coordsSpline[i][j][1]
                            );
                        } else {
                            path += 'L{1} {2} '.format(
                                this.coordsSpline[i][j][0],
                                this.coordsSpline[i][j][1]
                            );
                        }
                    }



                    RG.SVG.create({
                        svg: this.svg,
                        parent: prop.filled ? this.filledGroups[i] : this.svg.all,
                        type: 'path',
                        attr: {
                            d: path,
                            stroke: color,
                            'fill':'none',
                            'stroke-width':  linewidth + 0.01,
                            'stroke-linecap': 'round',
                            'stroke-linejoin': 'round',
                            filter: prop.shadow ? 'url(#dropShadow)' : '',
                            'clip-path': this.isTrace ? 'url(#trace-effect-clip)' : ''
                        }
                    });
                }
                

                // Now draw the tickmarks
                for (var dataset=0; dataset<this.coords2.length; ++dataset) {
                    this.drawTickmarks(
                        dataset,
                        this.data[dataset],
                        this.coords2
                    );
                }

            } else {


                for (var i=0; i<this.coords2.length; ++i) {

                    var linewidth = RG.SVG.isArray(prop.linewidth) ? prop.linewidth[i] : prop.linewidth,
                        color     = prop['colors'][i],
                        path      = '';

                    // Create the path from the coordinates
                    for (var j=0; j<this.coords2[i].length; ++j) {
                        if (j === 0 || RG.SVG.isNull(this.data[i][j]) || RG.SVG.isNull(this.data[i][j - 1])) {
                            path += 'M{1} {2} '.format(
                                this.coords2[i][j][0],
                                this.coords2[i][j][1]
                            );
                        } else {
                            if (prop.stepped) {
                                path += 'L{1} {2} '.format(
                                    this.coords2[i][j][0],
                                    this.coords2[i][j - 1][1]
                                );
                            }

                            path += 'L{1} {2} '.format(
                                this.coords2[i][j][0],
                                this.coords2[i][j][1]
                            );
                        }
                    }



                    RG.SVG.create({
                        svg: this.svg,
                        parent: prop.filled ? this.filledGroups[i] : this.svg.all,
                        type: 'path',
                        attr: {
                            d: path,
                            stroke: color,
                            'fill':'none',
                            'stroke-width':  linewidth + 0.01,
                            'stroke-linecap': 'round',
                            'stroke-linejoin': 'round',
                            filter: prop.shadow ? 'url(#dropshadow)' : '',
                            'clip-path': this.isTrace ? 'url(#trace-effect-clip)' : ''
                        }
                    });

                }

                // Now draw the tickmarks
                for (var dataset=0; dataset<this.coords2.length; ++dataset) {
                    this.drawTickmarks(
                        dataset,
                        this.data[dataset],
                        this.coords2
                    );
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
            var prop = this.properties, y;

            if (value > this.scale.max) {
                return null;
            }

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
        * TODO This function looks like its needs updating
        * 
        * @param object rect The rectangle to highlight
        */
        this.highlight = function (rect)
        {
            var x = rect.getAttribute('x'),
                y = rect.getAttribute('y');

/*
            var highlight = RG.SVG.create({
                svg: this.svg,
                type: 'rect',
                attr: {
                    stroke: prop.highlightStroke,
                    fill: prop.highlightFill,
                    x: x,
                    y: y,
                    width: width,
                    height: height,
                    'stroke-width': prop.highlightLinewidth
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


            // Store the highlight rect in the rebistry so
            // it can be cleared later
            RG.SVG.REG.set('highlight', highlight);
*/
        };








        //
        // Remove highlight from the chart (tooltips)
        //
        this.removeHighlight = function ()
        {
            var highlight = RG.SVG.REG.get('highlight');

            if (highlight && highlight.parentNode) {
                highlight.parentNode.removeChild(highlight);
            
            } else if (highlight) {
                // The highlight is an array
                for (var i=0; i<highlight.length; ++i) {
                    if (highlight[i] && highlight[i].parentNode) {
                        highlight[i].parentNode.removeChild(highlight[i]);
                    }
                }
            }
            
            RG.SVG.REG.set('highlight', null);
        };








        //
        // Draw a spline Line chart
        //
        // @param array coords The coords for the line
        //
        this.drawSpline = function (coords)
        {
            var xCoords      = [];
                gutterLeft   = prop.gutterLeft,
                gutterRight  = prop.gutterRight,
                hmargin      = prop.hmargin,
                interval     = (this.graphWidth - (2 * hmargin)) / (coords.length - 1),
                coordsSpline = [];

            /**
            * The drawSpline function takes an array of JUST Y coords - not X/Y coords. So the line coords need converting
            * if we've been given X/Y pairs
            */
            for (var i=0,len=coords.length; i<len;i+=1) {
                if (typeof coords[i] == 'object' && coords[i] && coords[i].length == 2) {
                    coords[i] = Number(coords[i][1]);
                }
            }

            /**
            * Get the Points array in the format we want - the first value should
            * be null along with the lst value
            */
            var P = [coords[0]];
            for (var i=0; i<coords.length; ++i) {
                P.push(coords[i]);
            }
            P.push(coords[coords.length - 1] + (coords[coords.length - 1] - coords[coords.length - 2]));

            for (var j=1; j<P.length-2; ++j) {
                for (var t=0; t<10; ++t) {
                    
                    var yCoord = spline( t/10, P[j-1], P[j], P[j+1], P[j+2] );
    
                    xCoords.push(((j-1) * interval) + (t * (interval / 10)) + gutterLeft + hmargin);

                    coordsSpline.push([
                        xCoords[xCoords.length - 1],
                        yCoord
                    ]);
                    
                    if (typeof index === 'number') {
                        coordsSpline[index].push([
                            xCoords[xCoords.length - 1],
                            yCoord
                        ]);
                    }
                }
            }


            // Draw the last section
            coordsSpline.push([
                ((j-1) * interval) + gutterLeft + hmargin,
                P[j]
            ]);

            if (typeof index === 'number') {
                coordsSpline.push([
                    ((j-1) * interval) + gutterLeft + hmargin,
                    P[j]
                ]);
            }

            function spline (t, P0, P1, P2, P3)
            {
                return 0.5 * ((2 * P1) +
                             ((0-P0) + P2) * t +
                             ((2*P0 - (5*P1) + (4*P2) - P3) * (t*t) +
                             ((0-P0) + (3*P1)- (3*P2) + P3) * (t*t*t)));
            }
            
            // Add some properties to the coordinates
            for (var i=0; i<coordsSpline.length; ++i) {
                coordsSpline[i].object = this;
                coordsSpline[i].x      = this;
                coordsSpline[i].y      = this;
            }

            return coordsSpline;
        };








        /**
        * This allows for easy specification of gradients
        */
        this.parseColors = function () 
        {
            if (!Object.keys(this.originalColors).length) {
                this.originalColors = {
                    colors:              RG.SVG.arrayClone(prop.colors),
                    filledColors:        RG.SVG.arrayClone(prop.filledColors),
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
            
            
            // Fill colors
            var filledColors = prop.filledColors;

            if (filledColors) {
                for (var i=0; i<filledColors.length; ++i) {
                    filledColors[i] = RG.SVG.parseColorLinear({
                        object: this,
                        color: filledColors[i]
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
            
                var data_seq = RG.SVG.arrayLinearize(this.data),
                    seq      = 0;

                for (var dataset=0; dataset<this.coords2.length; ++dataset,seq++) {
                    for (var i=0; i<this.coords2[dataset].length; ++i,seq++) {
    
                        var str = RG.SVG.numberFormat({
                            object:    this,
                            num:       this.data[dataset][i].toFixed(prop.labelsAboveDecimals ),
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

                        RG.SVG.text({
                            object:     this,
                            parent:     this.svg.all,
                            tag:        'labels.above',
                            text:       str,
                            x:          parseFloat(this.coords2[dataset][i][0]) + prop.labelsAboveOffsetx,
                            y:          parseFloat(this.coords2[dataset][i][1]) + prop.labelsAboveOffsety,
                            halign:     prop.labelsAboveHalign,
                            valign:     prop.labelsAboveValign,
                            font:       prop.labelsAboveFont              || prop.textFont,
                            size:       prop.labelsAboveSize              || prop.textSize,
                            bold:       prop.labelsAboveBold              || prop.textBold,
                            italic:     prop.labelsAboveItalic            || prop.textItalic,
                            color:      prop.labelsAboveColor             || prop.textColor,
                            background: prop.labelsAboveBackground        || null,
                            padding:    prop.labelsAboveBackgroundPadding || 0
                        });
                    }
                    
                    // Necessary so that the seq doesn't get incremented twice
                    seq--;
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








// This function is used to draw the errorbar. Its in the common
// file because it's used by multiple chart libraries
this.drawErrorbar = function (opt)
{
    var linewidth = RG.SVG.getErrorbarsLinewidth({object: this, index: opt.index}),
        color     = RG.SVG.getErrorbarsColor({object: this, index: opt.index}),
        capwidth  = RG.SVG.getErrorbarsCapWidth({object: this, index: opt.index}),
        index     = opt.index,
        dataset   = opt.dataset,
        x         = opt.x,
        y         = opt.y,
        value     = this.data[dataset][index],
        seq       = RG.SVG.groupedIndexToSequential({
            dataset: dataset,
            index: index,
            object: this
        });
    
    
    // Get the Y coord of the point
    var y = this.getYCoord(y);



    // Get the error bar value
    var max = RG.SVG.getErrorbarsMaxValue({
        object: this,
        index: seq
    });

    

    // Get the error bar value
    var min = RG.SVG.getErrorbarsMinValue({
        object: this,
        index: seq
    });




    if (!max && !min) {
        return;
    }
















    var x = this.coords2[dataset][index].x,
        y = this.coords2[dataset][index].y,
        halfCapWidth = capwidth / 2,
        y1 = this.getYCoord(value + max),
        y3 = this.getYCoord(value - min) === null ? y : this.getYCoord(value - min);


    if (max > 0) {

        // Draw the UPPER vertical line
        var errorbarLine = RG.SVG.create({
            svg: this.svg,
            type: 'line',
            parent: this.svg.all,
            attr: {
                x1: x,
                y1: y,
                x2: x,
                y2: y1,
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
                x1: x - halfCapWidth,
                y1: y1,
                x2: x + halfCapWidth,
                y2: y1,
                stroke: color,
                'stroke-width': linewidth
            }
        });
    }












    // Draw the minimum errorbar if necessary
    if (typeof min === 'number') {

        var errorbarLine = RG.SVG.create({
            svg: this.svg,
            type: 'line',
            parent: this.svg.all,
            attr: {
                x1: x,
                y1: y,
                x2: x,
                y2: y3,
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
                x1: x - halfCapWidth,
                y1: y3,
                x2: x + halfCapWidth,
                y2: y3,
                stroke: color,
                'stroke-width': linewidth
            }
        });
    }
};








        //
        // A trace effect
        //
        //  @param object    Options to give to the effect
        // @param  function  A function to call when the effect has completed
        //
        this.trace = function ()
        {
            var opt      = arguments[0] || {},
                frame    = 1,
                frames   = opt.frames || 60,
                obj      = this;
            
            this.isTrace = true;

            this.draw();

            // Create the clip area
            var clipPath = RG.SVG.create({
                svg: this.svg,
                parent: this.svg.defs,
                type: 'clipPath',
                attr: {
                    id: 'trace-effect-clip'
                }
            });

            var clipPathRect = RG.SVG.create({
                svg: this.svg,
                parent: clipPath,
                type: 'rect',
                attr: {
                    x: 0,
                    y: 0,
                    width: 0,
                    height: this.height
                }
            });


            var iterator = function ()
            {
                var width = (frame++) / frames * obj.width;

                clipPathRect.setAttribute("width", width);
                
                if (frame <= frames) {
                    RG.SVG.FX.update(iterator);
                } else if (opt.callback) {
                    (opt.callback)(obj);
                }
            };
            
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
    }
    
    
    
    return this;




// End module pattern
})(window, document);