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



    RG.SVG.Scatter = function (conf)
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
        this.width            = Number(this.svg.getAttribute('width'));
        this.height           = Number(this.svg.getAttribute('height'));
        this.data             = conf.data;
        this.type             = 'scatter';
        this.coords           = [];
        this.coords2          = [];
        this.colorsParsed     = false;
        this.originalColors   = {};
        this.gradientCounter  = 1;
        this.sequential       = 0;

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
            
            xmax:                 0,
            tickmarksStyle:       'cross',
            tickmarksSize:        7,
            colors:               ['black'],
            
            line:                 false,
            lineColors:           1,
            lineLinewidth:        1,
            
            errorbarsColor:       'black',
            errorbarsLinewidth:   1,
            errorbarsCapwidth:    10,

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
            xaxisLabelsPositionEdgeTickmarksCount: 10,
            xaxisColor:           'black',
            xaxisLabelsOffsetx:   0,
            xaxisLabelsOffsety:   0,
            xaxisMin:             0,
            xaxisMax:             null,
            
            xaxisLabelsCount:     10,
            xaxisUnitsPre:        '',
            xaxisUnitsPost:       '',
            xaxisMax:             null,
            xaxisMin:            0,
            xaxisPoint:           '.',
            xaxisRound:           false,
            xaxisThousand:        ',',
            xaxisDecimals:        0,
            xaxisFormatter:       null,

            textColor:            'black',
            textFont:             'sans-serif',
            textSize:             12,
            textBold:             false,
            textItalic:           false,


            labelsAboveFont:              null,
            labelsAboveSize:              null,
            labelsAboveBold:              null,
            labelsAboveItalic:            null,
            labelsAboveColor:             null,
            labelsAboveBackground:        'rgba(255,255,255,0.7)',
            labelsAboveBackgroundPadding: 2,
            
            labelsAboveXUnitsPre:          null,
            labelsAboveXUnitsPost:         null,
            labelsAboveXPoint:             null,
            labelsAboveXThousand:          null,
            labelsAboveXFormatter:         null,
            labelsAboveXDecimals:          null,
            labelsAboveXDecimalsTrim:      null,

            labelsAboveYUnitsPre:          null,
            labelsAboveYUnitsPost:         null,
            labelsAboveYPoint:             null,
            labelsAboveYThousand:          null,
            labelsAboveYFormatter:         null,
            labelsAboveYDecimals:          null,

            labelsAboveOffsetx:           0,
            labelsAboveOffsety:           -10,
            labelsAboveHalign:            'center',
            labelsAboveValign:            'bottom',
            labelsAboveSeperator:         ',',

            tooltipsOverride:     null,
            tooltipsEffect:       'fade',
            tooltipsCssClass:     'RGraph_tooltip',
            tooltipsEvent:        'mousemove',

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

            key:            null,
            keyColors:      null,
            keyOffsetx:     0,
            keyOffsety:     0,
            keyTextOffsetx: 0,
            keyTextOffsety: -1,
            keyTextSize:    null,
            keyTextBold:    null,
            keyTextItalic:  null,
            
            bubble:            false,
            bubbleMaxValue:    null,
            bubbleMaxRadius:   null,
            bubbleColorsSolid: false,
            
            errorbars:            null,
            errorbarsColor:       'black',
            errorbarsLinewidth:   1,
            errorbarsCapwidth:    10,
        };




        //
        // Copy the global object properties to this instance
        //
        RG.SVG.getGlobals(this);





        //
        // Set the options that the user has provided
        //
        for (i in conf.options) {
            if (typeof i === 'string') {
                this.set(i, conf.options[i]);
            }
        }





        // Handles the data that was supplied to the object. If only one dataset
        // was given, convert it into into a multiple dataset style array
        if (this.data[0] && !RG.SVG.isArray(this.data[0])) {
            this.data = [];
            this.data[0] = conf.data;
        }





        /**
        * "Decorate" the object with the generic effects if the effects library has been included
        */
        if (RG.SVG.FX && typeof RG.SVG.FX.decorate === 'function') {
            RG.SVG.FX.decorate(this);
        }




        var prop = this.properties;
        
        
        //
        // Convert string X values to timestamps
        //
        if (typeof prop.xaxisMin === 'string') {
            prop.xaxisMin = RG.SVG.parseDate(prop.xaxisMin);
        }

        if (typeof prop.xaxisMax === 'string') {
            prop.xaxisMax = RG.SVG.parseDate(prop.xaxisMax);
        }

        for (var i=0; i<this.data.length; ++i) {
            for (var j=0; j<this.data[i].length; ++j) {
                if (typeof this.data[i][j].x === 'string') {
                    this.data[i][j].x = RG.SVG.parseDate(this.data[i][j].x);
                }
            }
        }







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





            this.graphWidth  = this.width - prop.gutterLeft - prop.gutterRight;
            this.graphHeight = this.height - prop.gutterTop - prop.gutterBottom;
            
            
            // Prevents these from growing
            this.coords  = [];
            this.coords2 = [];




            // Parse the colors for gradients
            RG.SVG.resetColorsToOriginalValues({object:this});
            this.parseColors();




            // Work out the maximum value
            for (var ds=0,max=0; ds<this.data.length; ++ds) { // Datasets
                for (var dp=0; dp<this.data[ds].length; ++dp) { // Datapoints
                    max = ma.max(
                        max,
                        this.data[ds][dp].y + (this.data[ds][dp].errorbar ? (typeof this.data[ds][dp].errorbar === 'number' ? this.data[ds][dp].errorbar : this.data[ds][dp].errorbar.max) : 0)
                    );
                }
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







            // Draw the axes under the points

            RG.SVG.drawXAxis(this);
            RG.SVG.drawYAxis(this);






            // Create a group for all of the datasets
            var dataset_group = RGraph.SVG.create({
                svg: this.svg,
                type: 'g',
                parent: this.svg.all,
                attr: {
                    className: 'scatter_datasets_' + this.uid
                }
            });

            // Draw the points for all of the datasets
            for (var i=0; i<this.data.length; ++i) {

                this.drawPoints({
                    index: i,
                    data: this.data[i],
                    group: dataset_group
                });

                // Draw a line for this dataset
                if (prop.line === true || (typeof prop.line === 'object' && prop.line[i] === true)) {
                    this.drawLine({
                         index: i,
                        coords: this.coords2[i]
                    });
                }
            }



            // Draw the key
            if (typeof prop.key !== null && RG.SVG.drawKey) {
                RG.SVG.drawKey(this);
            } else if (!RGraph.SVG.isNull(prop.key)) {
                alert('The drawKey() function does not exist - have you forgotten to include the key library?');
            }




            // Add the event listener that clears the highlight rect if
            // there is any. Must be MOUSEDOWN (ie before the click event)
            //var obj = this;
            //doc.body.addEventListener('mousedown', function (e)
            //{
                //RG.SVG.removeHighlight(obj);

            //}, false);



            // Fire the draw event
            RG.SVG.fireCustomEvent(this, 'ondraw');




            return this;
        };








        //
        // Draws the Points
        //
        // @param opt object Options to the function which can consist of:
        //                     o index:   The numerical index of the DATASET
        //                     o dataset: The dataset.
        //
        this.drawPoints = function (opt)
        {
            var index = opt.index,
                data  = opt.data,
                group = opt.group;

            // Initialise the array for coordinates
            if (!this.coords2[index]) {
                this.coords2[index] = [];
            }

            //
            // Create the <g> tag that the datapoints are added to
            //
            var group = RG.SVG.create({
                svg: this.svg,
                type: 'g',
                parent: group,
                attr: {
                    className: 'scatter_dataset_' + index + '_' + this.uid
                }
            });

            // Loop through the data
            for (var i=0; i<data.length; ++i) {

                var point = data[i];
            
                if (typeof point.x === 'number'&& typeof point.y === 'number') {
                    var ret = this.drawSinglePoint({
                        dataset:    data,
                        datasetIdx: index,
                        point:      point,
                        index:      i,
                        group:      group, // The SVG <g> tag the the points are added to
                        sequential: this.sequential
                    });
                    
                    // Add the coordinates to the coords arrays
                    this.coords.push({
                        x:       ret.x,
                        y:       ret.y,
                        z:       ret.size,
                        type:    ret.type,
                        element: ret.mark,
                        object:  this
                    });

                    this.coords2[index][i] = {
                        x:       ret.x,
                        y:       ret.y,
                        z:       ret.size,
                        type:    ret.type,
                        element: ret.mark,
                        object:  this
                    };
                    
                    this.sequential++
                }













                //
                // Add tooltip highlight to the point
                //
                if ( (typeof data[i].tooltip === 'string' && data[i].tooltip) || (typeof data[i].tooltip === 'number') ) {

                    // Convert the tooltip to a string
                    data[i].tooltip = String(data[i].tooltip);

                    // Make the tooltipsEvent default to click
                    if (prop.tooltipsEvent !== 'mousemove') {
                        prop.tooltipsEvent = 'click';
                    }

                    if (!group_tooltip_hotspots) {
                        var group_tooltip_hotspots = RG.SVG.create({
                            svg: this.svg,
                            parent: this.svg.all,
                            type: 'g',
                            attr: {
                                className: 'rgraph-scatter-tooltip-hotspots'
                            }
                        });
                    }

                    var rect = RG.SVG.create({
                        svg:  this.svg,
                        parent: this.svg.all,
                        type: 'rect',
                        parent: group_tooltip_hotspots,
                        attr: {
                            x: ret.x - (ret.size / 2),
                            y: ret.y - (ret.size / 2),
                            width: ret.size,
                            height: ret.size,
                            fill: 'transparent',
                            stroke: 'transparent',
                            'stroke-width': 0
                        },
                        style: {
                            cursor: 'pointer'
                        }
                    });
                    
                    // Add the hotspot to the original tickmark
                    ret.mark.hotspot = rect;

                    (function (dataset, index, seq, obj)
                    {
                        rect.addEventListener(prop.tooltipsEvent, function (e)
                        {
                            var tooltip = RG.SVG.REG.get('tooltip');

                            if (tooltip && tooltip.__dataset__ === dataset && tooltip.__index__ === index) {
                                return;
                            }
                
                            obj.removeHighlight();

                            // Show the tooltip
                            RG.SVG.tooltip({
                                object: obj,
                                dataset: dataset,
                                index: index,
                                sequentialIndex: seq,
                                text: obj.data[dataset][index].tooltip,
                                event: e
                            });


                            // Highlight the shape that has been clicked on
                            if (RG.SVG.REG.get('tooltip')) {
                                obj.highlight(this);
                            }
                            
                        }, false);
                
                        // Install the event listener that changes the
                        // cursor if necessary
                        if (prop.tooltipsEvent === 'click') {
                            rect.addEventListener('mousemove', function (e)
                            {
                                e.target.style.cursor = 'pointer';
                            }, false);
                        }
                        
                    }(index, i, this.sequential - 1, this));
                }
            }
        };








        //
        // Draws a single point on the chart
        //
        this.drawSinglePoint = function (opt)
        {
            var dataset    = opt.dataset,
                datasetIdx = opt.datasetIdx,
                seq        = opt.sequential,
                point      = opt.point,
                index      = opt.index,
                valueX     = opt.point.x,
                valueY     = opt.point.y,
                conf       = opt.point || {},
                group      = opt.group,
                coordX     = opt.coordx = this.getXCoord(valueX),
                coordY     = opt.coordy = this.getYCoord(valueY);

            
            

            // Get the above label
            if (conf.labelsAbove) {
                var above = true;
            } else if (conf.labelAbove) {
                var above = true;
            } else if (conf.above) {
                var above = true;
            }






            // Allow shape to be synonym for type
            if (typeof conf.type === 'undefined' && typeof conf.shape !== 'undefined') {
                conf.type = conf.shape;
            }






            // set the type to the default if its not set
            if (typeof conf.type === 'string') {
                // nada
            } else if (typeof prop.tickmarksStyle === 'string') {
                conf.type = prop.tickmarksStyle;
            } else if (typeof prop.tickmarksStyle === 'object' && typeof prop.tickmarksStyle[datasetIdx] === 'string') {
                conf.type = prop.tickmarksStyle[datasetIdx];
            }












            // set the size to the default if its not set
            if (typeof conf.size !== 'number' && typeof prop.tickmarksSize === 'number') {
                conf.size = prop.tickmarksSize;
            } else if (typeof conf.size !== 'number' && typeof prop.tickmarksSize === 'object' && typeof prop.tickmarksSize[datasetIdx] === 'number') {
                conf.size = prop.tickmarksSize[datasetIdx];
            }







            // Set the color to the default if its not set and then blacck if thats not set either
            if (typeof conf.color === 'string') {
                // nada
            } else if (typeof prop.colors[datasetIdx] === 'string') {
                conf.color = prop.colors[datasetIdx];
            } else {
                conf.color = 'black';
            }







            // Set the opacity of this point
            if (typeof conf.opacity === 'undefined') {
                conf.opacity = 1;
            } else if (typeof conf.opacity === 'number') {
                // nada
            }






            //  Draw the errorbar here
            //
            // First convert the errorbar information in the data into an array in the properties
            //
            prop.errorbars = [];
            for (var ds=0,max=0; ds<this.data.length; ++ds) {
                for (var idx=0; idx<this.data[ds].length; ++idx) {
                    prop.errorbars.push(this.data[ds][idx].errorbar);
                }
            }

            this.drawErrorbar({
                object:     this,
                dataset:    datasetIdx,
                index:      index,
                group:      group,
                sequential: seq,
                x:          coordX,
                y:          coordY,
                valueX:     valueX,
                valueY:     valueY,
                parent:     group
            });











            // Bubble charts are drawn by their own function
            if (prop.bubble) {
                return this.drawBubble(opt, conf);
            }





















            // Handle the various shapes for tickmarks here
            switch (conf.type) {
                case 'image:' + conf.type.substr(6):
                
                    var src = conf.type.substr(6);

                    var img = new Image();
                    img.src = src;
                    
                    var mark = RG.SVG.create({
                        svg: this.svg,
                        type: 'image',
                        parent: group,
                        attr: {
                            preserveAspectRatio: 'xMidYMid meet',
                            'xlink:href': src
                        }
                    });

                    // Once the image has loaded the x/y/width/height can be set
                    // (both the image and it's hotspot)
                    img.onload = function ()
                    {
                        var x = coordX - (img.width / 2),
                            y = coordY - (img.height / 2),
                            w = img.width,
                            h = img.height;

                        mark.setAttribute('x', x);
                        mark.setAttribute('y', y);
                        mark.setAttribute('width', w);
                        mark.setAttribute('height', h);

                        if (mark && mark.hotspot) {
                            mark.hotspot.setAttribute('x', x);
                            mark.hotspot.setAttribute('y', y);
                            mark.hotspot.setAttribute('width', w);
                            mark.hotspot.setAttribute('height', h);
                        }
                    };

                    break;

                case 'triangle':
                    var mark = RG.SVG.create({
                        svg: this.svg,
                        type: 'path',
                        parent: group,
                        attr: {
                            d: 'M {1} {2} L {3} {4} L {5} {6}'.format(
                                coordX - (conf.size / 2),
                                coordY + (conf.size / 2),
                                coordX,
                                coordY - (conf.size / 2),
                                coordX + (conf.size / 2),
                                coordY + (conf.size / 2)
                            ),
                            fill: conf.color,
                            'fill-opacity': conf.opacity
                        }
                    });
                break;

                case 'plus':
                    var mark = RG.SVG.create({
                        svg: this.svg,
                        type: 'path',
                        parent: group,
                        attr: {
                            d: 'M {1} {2} L {3} {4} M {5} {6} L {7} {8}'.format(
                                coordX - (conf.size / 2),
                                coordY,
                                coordX +  (conf.size / 2),
                                coordY,
                                coordX,
                                coordY - (conf.size / 2),
                                coordX,
                                coordY + (conf.size / 2)
                            ),
                            stroke: conf.color,
                            'stroke-opacity': conf.opacity
                        }
                    });
                break;

                case 'square':
                case 'rect':
                    var mark = RG.SVG.create({
                        svg: this.svg,
                        type: 'rect',
                        parent: group,
                        attr: {
                            x: coordX - (conf.size / 2),
                            y: coordY - (conf.size / 2),
                            width: conf.size,
                            height: conf.size,
                            fill: conf.color,
                            'fill-opacity': conf.opacity
                        }
                    });
                break;



                case 'dot':
                case 'circle':
                    var mark = RG.SVG.create({
                        svg: this.svg,
                        type: 'circle',
                        parent: group,
                        attr: {
                            cx: coordX,
                            cy: coordY,
                            r: conf.size / 2,
                            fill: conf.color,
                            'fill-opacity': conf.opacity
                        }
                    });
                break;



                case 'cross':
                default:
                    var mark = RG.SVG.create({
                        svg: this.svg,
                        type: 'path',
                        parent: group,  
                        attr: {
                            d: 'M {1} {2} L {3} {4} M {5} {6} L {7} {8}'.format(
                                coordX - (conf.size / 2), coordY - (conf.size / 2),
                                coordX + (conf.size / 2), coordY + (conf.size / 2),
                                coordX - (conf.size / 2), coordY + (conf.size / 2),
                                coordX + (conf.size / 2), coordY - (conf.size / 2)
                            ),
                            stroke: conf.color,
                            'stroke-opacity': conf.opacity
                        }
                    });
                    break;
            }
            
            //
            // Draw the above label if it's present
            //
            if (typeof conf.above === 'string' || (typeof conf.above !== 'string' && conf.above) ) {
                this.drawLabelsAbove({
                     point: conf,
                    coordX: coordX,
                    coordY: coordY
                });
            }




            // Add some data attributes that save various values
            mark.setAttribute('data-index', index);
            mark.setAttribute('data-dataset', datasetIdx);
            mark.setAttribute('data-original-opacity', conf.opacity);
            mark.setAttribute('data-original-color', conf.color);
            mark.setAttribute('data-original-coordx', coordX);
            mark.setAttribute('data-original-coordy', coordY);
            mark.setAttribute('data-size', conf.size);
            mark.setAttribute('data-sequential', seq);
            mark.setAttribute('data-type', conf.type);

            return {
                x: coordX,
                y: coordY,
                size: conf.type.substr(0,6) === 'image:' ? img.width : conf.size,
                mark: mark,
                type: conf.type
            };
        };







        // Draw a bubble on a bubble chart
        this.drawBubble = function (opt, conf)
        {
            var size = (conf.z / prop.bubbleMaxValue) * prop.bubbleMaxRadius;

            var color = RG.SVG.parseColorRadial({
                object: this,
                color: prop.bubbleColorsSolid ? conf.color : 'Gradient(white:' + conf.color + ')',
                cx: opt.coordx + (size / 4),
                cy: opt.coordy - (size / 4),
                fx: opt.coordx + (size / 4),
                fy: opt.coordy - (size / 4),
                r: size * 1.5
            });

            var circle = RG.SVG.create({
                svg: this.svg,
                type: 'circle',
                attr: {
                    cx: opt.coordx,
                    cy: opt.coordy,
                    r: size,
                    fill: color,
                    'fill-opacity': conf.opacity
                }
            });

            // Add some data attributes that save various values
            circle.setAttribute('data-index', opt.index);
            circle.setAttribute('data-dataset', opt.datasetIdx);
            circle.setAttribute('data-original-opacity', conf.opacity);
            circle.setAttribute('data-original-color', conf.color);
            circle.setAttribute('data-original-coordx', opt.coordx);
            circle.setAttribute('data-original-coordy', opt.coordy);
            circle.setAttribute('data-size', size);
            circle.setAttribute('data-sequential', opt.sequential);
            circle.setAttribute('data-type', 'bubble');

            return {
                x: opt.coordx,
                y: opt.coordy,
                z: opt.coordz
            };
        };








        //
        // This functions draws a line if required
        //
        this.drawLine = function (opt)
        {
            var linewidth = 1,
                color     = 'black';



            // Calculate the linewidth
            if (typeof prop.lineLinewidth === 'object' && typeof prop.lineLinewidth[opt.index] === 'number') {
                linewidth = prop.lineLinewidth[opt.index];
            } else if (typeof prop.lineLinewidth === 'number') {
                linewidth = prop.lineLinewidth;
            } else {
                linewidth = 1;
            }






            // Determine the color
             if (typeof prop.lineColors === 'object' && prop.lineColors[opt.index]) {
                color = prop.lineColors[opt.index];
             } else if (prop.colors[opt.index] === 'string') {
                color = prop.colors[opt.index];
            } else {
                color = 'black';
            }





            for (var i=0,path=''; i<this.coords2[opt.index].length; ++i) {
                path += '{1} {2} {3} '.format(
                    i === 0 ? 'M' : 'L',
                    this.coords2[opt.index][i].x,
                    this.coords2[opt.index][i].y
                );
            }

            RG.SVG.create({
                svg: this.svg,
                type: 'path',
                parent: this.svg.all,
                attr: {
                    d: path,
                    fill: 'transparent',
                    stroke: color,
                    'stroke-width': linewidth,
                    'stroke-linecap': 'round',
                    'stroke-linejoin': 'round'
                }
            });
        };








        /**
        * This function can be used to retrieve the relevant X coordinate for a
        * particular value.
        * 
        * @param int value The value to get the X coordinate for
        */
        this.getXCoord = function (value)
        {
            var x;

            if (value > prop.xaxisMax) {
                return null;
            }

            if (value < prop.xaxisMin) {
                return null;
            }

            x  = ((value - prop.xaxisMin) / (prop.xaxisMax - prop.xaxisMin));
            x *= (this.width - prop.gutterLeft - prop.gutterRight);

            x = prop.gutterLeft + x;

            return x;
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
            rect.setAttribute('fill', prop.highlightFill);

            // Store the highlight rect in the registry so
            // it can be reset later
            RG.SVG.REG.set('highlight', rect);
        };








        //
        // Draws the labelsAbove
        //
        // @param opt An object that consists of various arguments to the function
        //
        this.drawLabelsAbove = function (opt)
        {
            var conf   = opt.point,
                coordX = opt.coordX,
                coordY = opt.coordY;

            
            // Facilitate labelsAboveSpecific
            if (typeof conf.above === 'string') {
                var str = conf.above;
            } else {

                conf.x = RG.SVG.numberFormat({
                    object:        this,
                    num:           conf.x.toFixed(prop.labelsAboveXDecimals ),
                    prepend:       typeof prop.labelsAboveXUnitsPre  === 'string'   ? prop.labelsAboveXUnitsPre  : null,
                    append:        typeof prop.labelsAboveXUnitsPost === 'string'   ? prop.labelsAboveXUnitsPost : null,
                    point:         typeof prop.labelsAboveXPoint     === 'string'   ? prop.labelsAboveXPoint     : null,
                    thousand:      typeof prop.labelsAboveXThousand  === 'string'   ? prop.labelsAboveXThousand  : null,
                    formatter:     typeof prop.labelsAboveXFormatter === 'function' ? prop.labelsAboveXFormatter : null,
                    decimals_trim: prop.labelsAboveXDecimalsTrim
                });
    
                conf.y = RG.SVG.numberFormat({
                    object:        this,
                    num:           conf.y.toFixed(prop.labelsAboveYDecimals ),
                    prepend:       typeof prop.labelsAboveYUnitsPre  === 'string'   ? prop.labelsAboveYUnitsPre  : null,
                    append:        typeof prop.labelsAboveYUnitsPost === 'string'   ? prop.labelsAboveYUnitsPost : null,
                    point:         typeof prop.labelsAboveYPoint     === 'string'   ? prop.labelsAboveYPoint     : null,
                    thousand:      typeof prop.labelsAboveYThousand  === 'string'   ? prop.labelsAboveYThousand  : null,
                    formatter:     typeof prop.labelsAboveYFormatter === 'function' ? prop.labelsAboveYFormatter : null,
                    decimals_trim: prop.labelsAboveYDecimalsTrim
                });

                var str = '{1}{2}{3}'.format(
                    conf.x,
                    prop.labelsAboveSeperator,
                    conf.y
                );
            }

            // Add the text to the scene
            RG.SVG.text({
                object:     this,
                parent:     this.svg.all,
                tag:        'labels.above',
                text:       str,
                x:          parseFloat(coordX) + prop.labelsAboveOffsetx,
                y:          parseFloat(coordY) + prop.labelsAboveOffsety,
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
        };








        /**
        * This allows for easy specification of gradients
        */
        this.parseColors = function () 
        {

// TODO Loop thru the data parsing the color for gradients too

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

            // IMPORTANT: Bubble chart gradients are parse in the drawBubble()
            //            function below
            if (colors && !prop.bubble) {
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
            
            if (highlight) {
                highlight.setAttribute('fill', 'transparent');
                RG.SVG.REG.set('highlight', null);
            }
        };







        //
        // Draws a single errorbar
        //
        this.drawErrorbar = function (opt)
        {
            // Get the error bar value
            var max = RG.SVG.getErrorbarsMaxValue({
                object: this,
                index: opt.sequential
            });
        
        
            // Get the error bar value
            var min = RG.SVG.getErrorbarsMinValue({
                object: this,
                index: opt.sequential
            });
    
            if (!max && !min) {
                return;
            }
    
            var linewidth    = RG.SVG.getErrorbarsLinewidth({object: this,  index: opt.sequential}),
                color        = RG.SVG.getErrorbarsColor({object: this,      index: opt.sequential}),
                capwidth     = RG.SVG.getErrorbarsCapWidth({object: this,   index: opt.sequential}),
                halfCapWidth = capwidth / 2;
    
    
    
    
    
    
            if (max > 0) {
            
                var y1 = this.getYCoord(opt.valueY + max)
                    y2 = this.getYCoord(opt.valueY - min);
    
                // Draw the UPPER vertical line
                var errorbarLine = RG.SVG.create({
                    svg: this.svg,
                    type: 'line',
                    parent: opt.parent,
                    attr: {
                        x1: opt.x,
                        y1: opt.y,
                        x2: opt.x,
                        y2: y1,
                        stroke: color,
                        'stroke-width': linewidth
                    }
                });
        
        
                // Draw the cap to the UPPER line
                var errorbarCap = RG.SVG.create({
                    svg: this.svg,
                    type: 'line',
                    parent: opt.parent,
                    attr: {
                        x1: opt.x - halfCapWidth,
                        y1: y1,
                        x2: opt.x + halfCapWidth,
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
                    parent: opt.parent,
                    attr: {
                        x1: opt.x,
                        y1: opt.y,
                        x2: opt.x,
                        y2: y2,
                        stroke: color,
                        'stroke-width': linewidth
                    }
                });
        
                // Draw the cap to the UPPER line
                var errorbarCap = RG.SVG.create({
                    svg: this.svg,
                    type: 'line',
                    parent: opt.parent,
                    attr: {
                        x1: opt.x - halfCapWidth,
                        y1: y2,
                        x2: opt.x + halfCapWidth,
                        y2: y2,
                        stroke: color,
                        'stroke-width': linewidth
                    }
                });
            }
        };

    };
            
    return this;

// End module pattern
})(window, document);