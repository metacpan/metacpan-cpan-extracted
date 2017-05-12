var eeServerURL = "../cgi/edgeexpress.fcgi";
var edgesourceXMLHttp;
var featuresourceXMLHttp;
var experimentXMLHttp;

function initContents() {

  $('edges_div').setStyle({color:'black', opacity:0.8}).update('loading data...');
  $('experiments_div').setStyle({color:'black', opacity:0.8}).update('loading data...');
  $('features_div').setStyle({color:'black', opacity:0.8}).update('loading data...');

  edgesourceXMLHttp=GetXmlHttpObject();
  featuresourceXMLHttp=GetXmlHttpObject();
  experimentXMLHttp=GetXmlHttpObject();

  if((edgesourceXMLHttp==null) || (featuresourceXMLHttp==null) || (experimentXMLHttp==null)) {
    alert ("Your browser does not support AJAX!");
    return;
  }

  edgesourceXMLHttp.onreadystatechange=showEdgeSources;
  edgesourceXMLHttp.open("GET", eeServerURL+"?mode=edge_sources", true);
  edgesourceXMLHttp.send(null);

  featuresourceXMLHttp.onreadystatechange=showFeatureSources;
  featuresourceXMLHttp.open("GET", eeServerURL+"?mode=feature_sources", true);
  featuresourceXMLHttp.send(null);

  experimentXMLHttp.onreadystatechange=showExperiments;
  experimentXMLHttp.open("GET", eeServerURL+"?mode=experiments", true);
  experimentXMLHttp.send(null);

  //new Ajax.Request(eeServerURL, 
  //  { method:'get', parameters: {'mode': 'edge_sources'},
  //    onSuccess: showEdgeSources,
  //    onFailure: function(transport){
  //       $('edges_div').setStyle({color:'black', opacity:1.0}).update('ajax callback to showEdgeSources');
  //    }
  //  });

  //new Ajax.Request(eeServerURL, 
  //  { method:'post', parameters: {'mode': 'experiments'},
  //    onSuccess: showExperiments,
  //    onFailure: function(){ alert('Something went wrong with the AJAX call...') }
  //  });

  //new Ajax.Request(eeServerURL, 
  //  { method:'post', parameters: {'mode': 'feature_sources'},
  //    onSuccess: showFeatureSources,
  //    onFailure: function(){ alert('Something went wrong with the AJAX call...') }
  //  });

}


function showEdgeSources(transport) {
  if(edgesourceXMLHttp == null) { return; }
  if(edgesourceXMLHttp.responseXML == null) return;
  if(edgesourceXMLHttp.readyState!=4) return;
  if(edgesourceXMLHttp.status!=200) { return; }

  var xmlDoc=edgesourceXMLHttp.responseXML.documentElement;

  //var xmlDoc=transport.responseXML.documentElement;
  if(xmlDoc==null) {
    $('edges_div').setStyle({color:'black', opacity:1.0}).update('Problem with eeDB server!');
    return;
  } 

  var div1 = new Element('div');
  var my_table = new Element('table');
  div1.appendChild(my_table);
  var trhead = my_table.appendChild(new Element('thead')).appendChild(new Element('tr'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('id'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('classification'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('source name'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('count'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('last update'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('comments'));

  var sources = xmlDoc.getElementsByTagName("edgesource");
  var tbody = my_table.appendChild(new Element('tbody'));
  for(i=0; i<sources.length; i++) {
    var tr = tbody.appendChild(new Element('tr'));
    if(i%2 == 0) { tr.addClassName('odd') } 
    else { tr.addClassName('even') } 

    tr.appendChild(new Element('td').update(sources[i].getAttribute("id")));
    tr.appendChild(new Element('td').update(sources[i].getAttribute("classification")));
    tr.appendChild(new Element('td').update(sources[i].getAttribute("name")));
    tr.appendChild(new Element('td').update(sources[i].getAttribute("count")));
    tr.appendChild(new Element('td').update(sources[i].getAttribute("create_date")));
    tr.appendChild(new Element('td').update(sources[i].getAttribute("comments")));
  }

  $('edges_div').update(div1);
}



function showExperiments(transport) {
  //var xmlDoc=transport.responseXML.documentElement;

  if(experimentXMLHttp == null) { return; }
  if(experimentXMLHttp.responseXML == null) return;
  if(experimentXMLHttp.readyState!=4) return;
  if(experimentXMLHttp.status!=200) { return; }
  var xmlDoc=experimentXMLHttp.responseXML.documentElement;

  if(xmlDoc==null) {
    $('experiments_div').setStyle({color:'black', opacity:1.0}).update('Problem with eeDB server!');
    return;
  } 

  var div1 = new Element('div');
  var my_table = new Element('table');
  div1.appendChild(my_table);
  var trhead = my_table.appendChild(new Element('thead')).appendChild(new Element('tr'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('id'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('detection platform'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('name'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('cellline/tissue'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('RNA library'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('time point'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('treatment'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('comments'));

  var experiments = xmlDoc.getElementsByTagName("experiment");
  var tbody = my_table.appendChild(new Element('tbody'));
  for(i=0; i<experiments.length; i++) {

    var treatment ='';
    var comments ='';
    var cell_line ="";
    var tissue ="";
    var lib_name ="";
    var syms = experiments[i].getElementsByTagName("symbol");
    var mdata = experiments[i].getElementsByTagName("mdata");
    for(j=0; j<syms.length; ++j) {
      if(syms[j].getAttribute("type")=="cell_line") { cell_line = syms[j].getAttribute("value"); }
      if(syms[j].getAttribute("type")=="library_name") { lib_name = syms[j].getAttribute("value"); }
    }
    for(j=0; j<mdata.length; ++j) {
      if(mdata[j].getAttribute("type")=="tissue") { tissue = mdata[j]; }
      if(mdata[j].getAttribute("type")=="tissue_type") { tissue = mdata[j]; }
      if(mdata[j].getAttribute("type")=="experimental_condition") { treatment = mdata[j]; }
      if(mdata[j].getAttribute("type")=="comments") { comments = mdata[j]; }
    }
    if(!cell_line) { cell_line = tissue; }

    var tr = tbody.appendChild(new Element('tr'));
    if(i%2 == 0) { tr.addClassName('odd') } 
    else { tr.addClassName('even') } 

    tr.appendChild(new Element('td').update(experiments[i].getAttribute("id")));
    tr.appendChild(new Element('td').update(experiments[i].getAttribute("platform")));
    tr.appendChild(new Element('td').update(experiments[i].getAttribute("name")));
    tr.appendChild(new Element('td').update(cell_line));
    tr.appendChild(new Element('td').update(lib_name));
    tr.appendChild(new Element('td').update(experiments[i].getAttribute("series_point")));
    tr.appendChild(new Element('td').update(treatment));
    tr.appendChild(new Element('td').update(comments));
  }

  $('experiments_div').update(div1);
}



function showFeatureSources(transport) {
  //var xmlDoc=transport.responseXML.documentElement;

  if(featuresourceXMLHttp == null) { return; }
  if(featuresourceXMLHttp.responseXML == null) return;
  if(featuresourceXMLHttp.readyState!=4) return;
  if(featuresourceXMLHttp.status!=200) { return; }
  var xmlDoc=featuresourceXMLHttp.responseXML.documentElement;

  if(xmlDoc==null) {
    $('features_div').setStyle({color:'black', opacity:1.0}).update('Problem with eeDB server!');
    return;
  } 

  var div1 = new Element('div');
  var my_table = new Element('table');
  div1.appendChild(my_table);
  var trhead = my_table.appendChild(new Element('thead')).appendChild(new Element('tr'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('id'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('feature classification'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('track name'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('count'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('last update'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('import source'));
  trhead.appendChild(new Element('th', { 'class': 'listView' }).update('comments'));

  var sources = xmlDoc.getElementsByTagName("featuresource");
  var tbody = my_table.appendChild(new Element('tbody'));
  for(i=0; i<sources.length; i++) {
    var tr = tbody.appendChild(new Element('tr'));
    if(i%2 == 0) { tr.addClassName('odd') } 
    else { tr.addClassName('even') } 

    tr.appendChild(new Element('td').update(sources[i].getAttribute("id")));
    tr.appendChild(new Element('td').update(sources[i].getAttribute("category")));
    tr.appendChild(new Element('td').update(sources[i].getAttribute("name")));
    tr.appendChild(new Element('td').update(sources[i].getAttribute("count")));
    tr.appendChild(new Element('td').update(sources[i].getAttribute("import_date")));
    tr.appendChild(new Element('td').update(sources[i].getAttribute("source")));
    tr.appendChild(new Element('td').update(sources[i].getAttribute("comments")));
  }

  $('features_div').update(div1);
}



