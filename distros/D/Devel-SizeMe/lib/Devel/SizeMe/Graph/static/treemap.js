// based on http://thejit.org/static/v20/Jit/Examples/Treemap/example2.html
var labelType, useGradients, nativeTextSupport, animate;

(function() {
  var ua = navigator.userAgent,
      iStuff = ua.match(/iPhone/i) || ua.match(/iPad/i),
      typeOfCanvas = typeof HTMLCanvasElement,
      nativeCanvasSupport = (typeOfCanvas == 'object' || typeOfCanvas == 'function'),
      textSupport = nativeCanvasSupport 
        && (typeof document.createElement('canvas').getContext('2d').fillText == 'function');
  //I'm setting this based on the fact that ExCanvas provides text support for IE
  //and that as of today iPhone/iPad current text support is lame
  labelType = (!nativeCanvasSupport || (textSupport && !iStuff))? 'Native' : 'HTML';
  nativeTextSupport = labelType == 'Native';
  useGradients = nativeCanvasSupport;
  animate = !(iStuff || !nativeCanvasSupport);
  console.log({ "labelType":labelType, "useGradients":useGradients, "nativeTextSupport":nativeTextSupport });
})();

var Log = {
  elem: false,
  write: function(text){
    if (!this.elem) 
      this.elem = document.getElementById('log');
    this.elem.innerHTML = text;
    this.elem.style.left = (500 - this.elem.offsetWidth / 2) + 'px';
  }
};

/**
 * Convert number of bytes into human readable format
 *
 * @param integer bytes     Number of bytes to convert
 * @param integer precision Number of digits after the decimal separator
 * @return string
 * via http://codeaid.net/javascript/convert-size-in-bytes-to-human-readable-format-(javascript)
 */
function bytesToSize(bytes, precision) {
    var sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    var posttxt = 0;
    while( bytes >= 1024 ) {
        posttxt++;
        bytes = bytes / 1024;
    }
    var num = (posttxt) ? Number(bytes).toFixed(precision) : bytes;
    return num + " " + sizes[posttxt];
}


// http://stackoverflow.com/questions/5199901/how-to-sort-an-associative-array-by-its-values-in-javascript
function bySortedValue(obj, comparitor, callback, context) {
    var tuples = [];
    for (var key in obj) {
        if (obj.hasOwnProperty(key)) {
            tuples.push([key, obj[key]]);
        }
    }

    tuples.sort(comparitor);

    if (callback) {
        var length = tuples.length;
        while (length--) callback.call(context, tuples[length][0], tuples[length][1]);
    }
    return tuples;
}


function init(){

    var levelsToShow = 1;

  //init TreeMap
  var tm = new $jit.TM.Squarified({
    //where to inject the visualization
    injectInto: 'infovis',
    //show only one tree level
    levelsToShow: levelsToShow,
    //parent box title heights
    titleHeight: 14,
    //enable animations
    animate: animate,
    //box offsets
    offset: 1,
    //use canvas text
    // XXX disabled to allow the onMouseEnter/onMouseLeave Events to fire to set the blue border
    XXX_Label: {
      type: labelType,
      size: 10,
      family: 'Tahoma, Verdana, Arial'
    },
    //enable specific canvas styles
    //when rendering nodes
    Node: {
      CanvasStyles: {
        shadowBlur: 0,
        shadowColor: '#000'
      }
    },
    //Attach left and right click events
    Events: {
      enable: true,
      onClick: function(node) {
        if(node) {
            // TODO use https://github.com/browserstate/history.js ?
            window.history.pushState({ "id":node.id }, "", "/"+node.id+"?"+jQuery('#sizeme_params_form').serialize());
            tm.enter(node);
        }
      },
      onRightClick: function() {
        tm.out();
      },
      //change node styles and canvas styles
      //when hovering a node
      onMouseEnter: function(node, eventInfo) {
        if(node) {
          //add node selected styles and replot node
          node.setCanvasStyle('shadowBlur', 7);
          node.setData('color', '#888');
          tm.fx.plotNode(node, tm.canvas);
          tm.labels.plotLabel(tm.canvas, node);
        }
      },
      onMouseLeave: function(node) {
        if(node) {
          node.removeData('color');
          node.removeCanvasStyle('shadowBlur');
          tm.plot();
        }
      }
    },
    //duration of the animations
    duration: 200,
    //Enable tips
    Tips: {
      enable: true,
      type: 'Native',
      //add positioning offsets
      offsetX: 20,
      offsetY: 20,
      //implement the onShow method to
      //add content to the tooltip when a node
      //is hovered
      onShow: function(tip, node, isLeaf, domElement) {

          // XXX all this needs html escaping
        var data = node.data;
        var html = "<div class=\"tip-title\">"
          + (data.title ? "\""+data.title+"\"" : "")
          + " " + data.name
          + "</div><div class=\"tip-text\">";

        html += "<br />";
        html += sprintf("Memory use: %s<br />", bytesToSize(data.self_size+data.kids_size,2));
        if (data.kids_size) {
            html += sprintf("Child use:  %s<br />", bytesToSize(data.kids_size,2));
        }
        if (data.self_size) {
            if (data.kids_size)
                html += sprintf("Own use:    %s<br />", bytesToSize(data.self_size,2));
        }

        $("#sizeme_data_div").JSONView({
            "attributes": data.attr,
            "parts": data.leaves,
            "depth": data.depth,
            "kids_node_count": data.kids_node_count,
            "kids_size_bytes": data.kids_size,
            "self_size_bytes": data.self_size,
            "name": data.name,
            "title": data.title,
            "parent_id": data.parent_id,
            "id": sprintf("%s%s", node.id, data._ids_merged ? data._ids_merged : "")
        });

        tip.innerHTML =  html; 
      }  
    },

    //Implement this method for retrieving a requested  
    //subtree that has as root a node with id = nodeId,  
    //and level as depth. This method could also make a server-side  
    //call for the requested subtree. When completed, the onComplete   
    //callback method should be called.  
    request: function(nodeId, level, onComplete){  
            request_jit_tree(nodeId, level, levelsToShow, function(data) {
                console.log({ "node": nodeId, "request_jit_tree": data});
                update_node_path(data);
                onComplete.onComplete(nodeId, data.nodes);
            });
            // XXX workaround jit bug where old tooltip is still shown till the
            // mouse moves
            jQuery("#_tooltip").fadeOut("fast");
    },

    //Add the name of the node in the corresponding label
    //This method is called once, on label creation and only for DOM labels.
    onCreateLabel: function(domElement, node){
        domElement.innerHTML = node.name;

        // this doesn't work with Label:{} above
        var style = domElement.style;  
        style.display = '';  
        style.border = '1px solid transparent';  
        domElement.onmouseover = function() {  
            style.border = '1px solid #9FD4FF';  
        };  
        domElement.onmouseout = function() {  
            style.border = '1px solid transparent';  
        };  

    },
    onPlaceLabel: function(domElement, node){ },
  });


function request_jit_tree(nodeId, level, levelsToShow, onComplete){
    var params = jQuery('#sizeme_params_form').serialize();
    jQuery.getJSON('jit_tree/'+nodeId+'/'+levelsToShow, params, onComplete);
}

function request_jit_tree_for_node_and_refresh(nodeId){
  if (!nodeId)
      nodeId = 1;
  console.log({ request_jit_tree_for_node_and_refresh: nodeId });
  request_jit_tree(nodeId, 0, levelsToShow, function(data) {
        console.log({ request_jit_tree: data });
        update_node_path(data);
        tm.loadJSON(data.nodes);
        tm.refresh();
    });
}

function update_node_path(data){
    jQuery("#sizeme_path_ul").html(data.name_path_html);
    // update #sizeme_path_ul
    //   <li><a href="#">Home</a> <span class="divider">/</span></li>
    //   <li><a href="#">Library</a> <span class="divider">/</span></li>
    //   <li class="active">Data</li>
}

  request_jit_tree_for_node_and_refresh(window.location.pathname.split('/')[1]); // XXX get from url

    //add event to buttons
    $jit.util.addEvent($jit.id('goto_parent'), 'click', function() {
        // record new node in history
        var parents = tm.graph.getNode(tm.clickedNode && tm.clickedNode.id || tm.root).getParents();
        var parent_id = parents[0].id;
        window.history.pushState({ "id":parent_id }, "", "/"+parent_id+"?"+jQuery('#sizeme_params_form').serialize());
        // move out one level with a nice animation
        tm.out();
    });

    jQuery('#sizeme_logarea_checkbox').change( function() {
        request_jit_tree_for_node_and_refresh(tm.clickedNode && tm.clickedNode.id || tm.root);
    });

    window.onpopstate = function(e) {
        if (e.state && e.state.id)
            request_jit_tree_for_node_and_refresh(e.state.id);
    };

}


