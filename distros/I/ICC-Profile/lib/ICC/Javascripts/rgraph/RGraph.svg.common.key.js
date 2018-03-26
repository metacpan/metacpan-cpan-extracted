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

    RGraph          = window.RGraph || {isRGraph: true};
    RGraph.SVG      = RGraph.SVG || {};
    RGraph.SVG.HTML = RGraph.SVG.HTML || {};
    
// Module pattern
(function (win, doc, undefined)
{
    var RG = RGraph,
        ua = navigator.userAgent,
        ma = Math;




    /**
    * Draws the graph key (used by various graphs)
    * 
    * @param object obj The graph object
    * @param array  key An array of the texts to be listed in the key
    * @param colors An array of the colors to be used
    */
    RG.SVG.drawKey = function (obj)
    {
        var prop          = obj.properties,
            key           = prop.key,
            colors        = prop.keyColors || prop.colors,
            defaultFont   = 'Arial',
            blobSize      = 0,
            width         = 0,
            keyColorShape = prop.keyColorShape;
        
        // Work out the center point of the SVG tag
        var centerx = obj.svg.getAttribute('width') / 2;
        
        // If we're drawing a key on a funnel then work out the center of
        // the chart differently. This may be useful to other chart types
        // too
        if (obj.type === 'funnel') {
            centerx = (obj.graphWidth / 2) + prop.gutterLeft;
        }




        // Loop thru the key and draw them
        if (key && key.length) {

            // First measure the length so that the key can be centered
            for (var i=0,length = 0; i<key.length; i++) {

                // First measure the text
                var textDimensions = RG.SVG.measureText({
                    text: key[i],
                    bold: prop.keyTextBold || false,
                    font: prop.keyTextFont || prop.textFont || defaultFont,
                    size: prop.keyTextSize || prop.textSize
                });
        
                blobSize = ma.max(blobSize, textDimensions[1]);
        
                width = width + 10 + blobSize + 5 + textDimensions[0];
            }
        
            // Center the key
            x = centerx - width / 2;







            for (var i=0,y=prop.gutterTop - 5; i<key.length; ++i) {
            
                // Do this on the first iteration only
                if (i === 0) {
                    if (obj.type === 'pie' && prop.highlightStyle == 'outline') {
                        y -= prop.highlightStyleOutlineWidth;
                    }
                }
            
            
                // First measure the text
                var textDimensions = RG.SVG.measureText({
                    text: key[i],
                    bold: prop.keyTextBold || false,
                    font: prop.keyTextFont || prop.textFont || defaultFont,
                    size: prop.keyTextSize || prop.textSize
                });












                //
                // Draw the blob of color (accounting for it being an array first)
                //

                var shape = prop.keyColorShape;

                if (typeof shape === 'object') {
                    shape = prop.keyColorShape[i];
                }







                // A circle
                if (shape === 'circle') {
                    RG.SVG.create({
                        svg: obj.svg,
                        type: 'circle',
                        parent: obj.svg.all,
                        attr: {
                            cx: x + (blobSize / 2)  + prop.keyOffsety,
                            cy: y - (blobSize / 2) + prop.keyOffsety,
                            r: blobSize / 2,
                            fill: colors[i]
                        }
                    });





                // A triangle
                } else if (shape === 'triangle') {
                    RG.SVG.create({
                        svg: obj.svg,
                        type: 'path',
                        parent: obj.svg.all,
                        attr: {
                            d: 'M {1} {2} L {3} {4} L {5} {6} z'.format(
                                x + prop.keyOffsetx + (blobSize / 2),
                                y - blobSize + prop.keyOffsety,
                                
                                x + prop.keyOffsetx + blobSize,
                                y + prop.keyOffsety,
                                
                                x + prop.keyOffsetx,
                                y + prop.keyOffsety                                
                            ),
                            fill: colors[i]
                        }
                    });





                // A line
                } else if (shape === 'line') {
                    RG.SVG.create({
                        svg: obj.svg,
                        type: 'path',
                        parent: obj.svg.all,
                        attr: {
                            d: 'M {1} {2} L {3} {4}'.format(
                                x + prop.keyOffsetx,
                                y - (blobSize / 2) + prop.keyOffsety,
                                
                                x + prop.keyOffsetx + blobSize,
                                y - (blobSize / 2) + prop.keyOffsety
                            ),
                            stroke: colors[i],
                            'stroke-width': 2,
                            'stroke-linecap': 'round'
                        }
                    });





                // A dot
                } else if (shape === 'dot') {

                    RG.SVG.create({
                        svg: obj.svg,
                        type: 'path',
                        parent: obj.svg.all,
                        attr: {
                            d: 'M {1} {2} L {3} {4}'.format(
                                x + prop.keyOffsetx,
                                y - (blobSize / 2) + prop.keyOffsety,
                                
                                x + prop.keyOffsetx + blobSize,
                                y - (blobSize / 2) + prop.keyOffsety
                            ),
                            stroke: colors[i],
                            'stroke-width': 2,
                            'stroke-linecap': 'round'
                        }
                    });

                    RG.SVG.create({
                        svg: obj.svg,
                        type: 'circle',
                        parent: obj.svg.all,
                        attr: {
                            cx: x + (blobSize / 2)  + prop.keyOffsety,
                            cy: y - (blobSize / 2) + prop.keyOffsety,
                            r: blobSize / 4,
                            fill: colors[i]
                        }
                    });




                // Ccustom
                } else if (typeof shape === 'function') {
                    RG.SVG.create({
                        svg: obj.svg,
                        type: 'path',
                        parent: obj.svg.all,
                        attr: {
                            d: 'M {1} {2} L {3} {4}'.format(
                                x + prop.keyOffsetx,
                                y - (blobSize / 2) + prop.keyOffsety,
                                
                                x + prop.keyOffsetx + blobSize,
                                y - (blobSize / 2) + prop.keyOffsety
                            ),
                            stroke: colors[i],
                            'stroke-width': 2,
                            'stroke-linecap': 'round'
                        }
                    });



                // A rectangle default
                } else {
                    RG.SVG.create({
                        svg: obj.svg,
                        type: 'rect',
                        parent: obj.svg.all,
                        attr: {
                            x: x + prop.keyOffsetx,
                            y: y - blobSize + prop.keyOffsety,
                            width: blobSize,
                            height: blobSize,
                            fill: colors[i]
                        }
                    });
                }









                //
                // Add the text
                //
                RGraph.SVG.text({
                    object:     obj,
                    parent:     obj.svg.all,
                    tag:        'key',
                    size:       prop.keyTextSize || prop.textSize,
                    bold:       typeof prop.keyTextBold === 'boolean' ? prop.keyTextBold : prop.textBold,
                    italic:     typeof prop.keyTextItalic === 'boolean' ? prop.keyTextItalic : prop.textItalic,
                    font:       prop.keyTextFont || prop.textFont,
                    halign:     'left',
                    valign:     'bottom',
                    text:       key[i],
                    x:          x + blobSize + 5 + prop.keyTextOffsetx + prop.keyOffsetx,
                    y:          y + prop.keyTextOffsety + prop.keyOffsety,
                    color:      'black',
                    background: 'white',
                    padding:    0
                })
    
                x += 10 + blobSize + 5 + textDimensions[0];
            }
        }
    };








    /**
    * Create a TABLE based HTML key. There's lots of options so it's
    * suggested that you consult the documentation page
    * 
    * @param mixed id   This should be a string consisting of the ID of the container
    * @param object prop An object map of the various properties that you can use to
    *                    configure the key. See the documentation page for a list.
    */
    RG.SVG.HTML.key = function (id, prop)
    {
        var div = doc.getElementById(id);

        
        /**
        * Create the table that becomes the key
        */
        var str = '<table border="0" cellspacing="0" cellpadding="0" id="rgraph_key" style="display: inline;' + (function ()
            {
                var style = ''
                for (i in prop.tableCss) {
                    if (typeof i === 'string') {
                        style = style + i + ': ' + prop.tableCss[i] + ';';
                    }
                }
                return style;
            })() + '" ' + (prop.tableClass ? 'class="' + prop.tableClass + '"' : '') + '>';



        /**
        * Add the individual key elements
        */
        for (var i=0; i<prop.labels.length; i+=1) {
            str += '<tr><td><div style="' + (function ()
            {
                var style = '';

                for (var j in prop.blobCss) {
                    if (typeof j === 'string') {
                        style = style + j + ': ' + prop.blobCss[j] + ';';
                    }
                }

                return style;
            })() + 'display: inline-block; margin-right: 5px; margin-top: 4px; width: 15px; height: 15px; background-color: ' + prop.colors[i] + '"' + (prop.blobClass ? 'class="' + prop.blobClass + '"' : '') + '>&nbsp;</div><td>' + (prop.links && prop.links[i] ? '<a href="' + prop.links[i] + '">' : '') + '<span ' + (prop.labelClass ? 'class="' + prop.labelClass + '"' : '') + '" style="' + (function ()
            {
                var style = '';

                for (var j in prop.labelCss) {
                    if (typeof j === 'string') {
                        style = style + j + ': ' + prop.labelCss[j] + ';';
                    }
                }

                return style;
            })() + '" ' + (function ()
            {
                var style = '';

                if (prop['labelCss_' + i]) {
                    for (var j in prop['labelCss_' + i]) {
                        style = style + j + ': ' + prop['labelCss_' + i][j] + ';';
                    }
                }

                return style ? 'style="' + style + '"' : '';
            })() + '>' + prop.labels[i] + '</span>' + (prop.links && prop.links[i] ? '</a>' : '') + '</td></tr>';
        }
        
        div.innerHTML += (str + '</table>');

        // Return the TABLE object that is the HTML key
        return doc.getElementById('rgraph_key');
    };




// End module pattern
})(window, document);