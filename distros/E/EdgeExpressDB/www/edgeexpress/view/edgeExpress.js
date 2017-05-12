var expressXMLHttp;
var dataURL = "../cgi/edgeexpress.fcgi";
var imageURL = "../tmpimages/";
var expressURL = "../cgi/edgeXpression.cgi";

var L3_promoters = new Spry.Data.XMLDataSet(null, "EEDB/promoters/feature");

var promoter_to = new Spry.Data.XMLDataSet(null, "EEDB/promoter_to_edges");
var promoter_from = new Spry.Data.XMLDataSet(null, "EEDB/promoters/promoter_from_edges");
var gene_p_from = new Spry.Data.NestedXMLDataSet(promoter_from, "link_from");
var ppi = new Spry.Data.XMLDataSet(null, "EEDB/ppi_edges/link");
var exp_from = new Spry.Data.XMLDataSet(null, "EEDB/experiment_edges/link_from");
var exp_to   = new Spry.Data.XMLDataSet(null, "EEDB/experiment_edges/link_to");
var ptb_from = new Spry.Data.XMLDataSet(null, "EEDB/perturbation_edges/link_from");
var ptb_to   = new Spry.Data.XMLDataSet(null, "EEDB/perturbation_edges/link_to");
var chip_from = new Spry.Data.XMLDataSet(null, "EEDB/chipchip_edges/link_from");
var chip_to   = new Spry.Data.XMLDataSet(null, "EEDB/chipchip_edges/link_to");
var mirna_from = new Spry.Data.XMLDataSet(null, "EEDB/miRNA_edges/link_from");
var mirna_to   = new Spry.Data.XMLDataSet(null, "EEDB/miRNA_edges/link_to");
var g2g_from = new Spry.Data.XMLDataSet(null, "EEDB/gene2gene_edges/link_from");
var g2g_to   = new Spry.Data.XMLDataSet(null, "EEDB/gene2gene_edges/link_to");
var other_from = new Spry.Data.XMLDataSet(null, "EEDB/other_edges/link_from");
var other_to   = new Spry.Data.XMLDataSet(null, "EEDB/other_edges/link_to");
var tfbs_to   = new Spry.Data.XMLDataSet(null, "EEDB/tfbs_predictions/link_to");
var database  = new Spry.Data.XMLDataSet(null, "EEDB/database");
var feature  = new Spry.Data.XMLDataSet(null, "EEDB/feature");
var featureSymbols = new Spry.Data.XMLDataSet(null, "EEDB/feature/symbol");
var featureMData = new Spry.Data.XMLDataSet(null, "EEDB/feature/mdata");


var featureObserver = new Object;
featureObserver.onPostUpdate = processAlias;
Spry.Data.Region.addObserver('featureResults', featureObserver);
var g2gToObserver = new Object;
g2gToObserver.onPostUpdate = selfRegulates;
Spry.Data.Region.addObserver('toResults', g2gToObserver);
var g2gFromObserver = new Object;
g2gFromObserver.onPostUpdate = updateL3;
Spry.Data.Region.addObserver('fromResults', g2gFromObserver);

function initialize() 
{
  dhtmlHistory.initialize();
  dhtmlHistory.addListener(handleHistoryChange);
  var initialLocation = dhtmlHistory.getCurrentLocation();
  updateUI(initialLocation, null);
}

function handleHistoryChange(newLocation, historyData) 
{
   updateUI(newLocation, historyData);                           
}

function updateUI(newLocation, historyData) 
{  
	if(newLocation!=null && newLocation.length>0)
	{
		getFeatureData(newLocation);
	}
}


function searchClick(id, gene) {
//  clearSearchResults();
  getFeatureData(id);
}

function searchClickAll(names) {
  //do nothing}
}

function saveSource(id) {
	window.open(dataURL+"?save=true&id="+id);
}

function saveExpressionXML(id) {
  window.open(dataURL+"?mode=express_xml&save=true&id="+id);
}

function clearResults()
{
	document.getElementById("searchResults").innerHTML="";
}

function gf(id)
{
	//This method has a very short name for speed - short for getFeatureData(id)
	document.getElementById('searchText').value='';
	document.getElementById("searchResults").innerHTML="";
	getFeatureData(id);
}

function getFeatureData(id)
{
	if(id==null)
		return;

	if(cancelClickAfterDrag)
	{
		cancelClickAfterDrag = false;
		return;
	}
	
	toolTip();
	
	var url=dataURL+"?id="+id;

	dhtmlHistory.add(id+'', {message: url});
	
	fetchData(id);
	
	return false;
}

function fetchData(id)
{
	document.getElementById("expressionGraphs").innerHTML="";
	document.getElementById("graphValues").innerHTML="";
	document.getElementById("fantomLink2").innerHTML="";
	document.getElementById("L2Promoters").innerHTML="";
	document.getElementById("L3Promoters").innerHTML="";
	document.getElementById("promoterOptions").style.display="none";
	targetGene="";
	selectedIds="";	
	var url;
	
	id = id.toString().replace(/[\+]/g,'%2B');
	equals = (id+"").indexOf("=");
	if(equals>-1)
		url = dataURL+"?source="+id.substring(0,equals)+"&name="+id.substring(equals+1);
	else
		url = dataURL+"?id="+id;

	g2g_from.setURL(url);
    	g2g_to.setURL(url);
    	other_to.setURL(url);
    	other_from.setURL(url);
    	tfbs_to.setURL(url);
	feature.setURL(url);
	database.setURL(url);
	featureSymbols.setURL(url);
	featureMData.setURL(url);
	ppi.setURL(url);
	exp_from.setURL(url);
	exp_to.setURL(url);
	ptb_from.setURL(url);
	ptb_to.setURL(url);
	chip_from.setURL(url);
	chip_to.setURL(url);
	mirna_from.setURL(url);
	mirna_to.setURL(url);
	
	promoter_to.setURL(url);
	promoter_from.setURL(url);
	L3_promoters.setURL(url);

	promoter_to.loadData();
	promoter_from.loadData();
	L3_promoters.loadData();

	other_to.loadData();
	other_from.loadData();
	g2g_to.loadData();
	tfbs_to.loadData();
	g2g_from.loadData();
        database.loadData();
	feature.loadData();
	featureSymbols.loadData();
	featureMData.loadData();
	ppi.loadData();
	exp_from.loadData();
	exp_to.loadData();
	gene_p_from.loadData();
	ptb_from.loadData();
	ptb_to.loadData();
	chip_from.loadData();
	chip_to.loadData();
	mirna_from.loadData();
	mirna_to.loadData();
}



function GetXmlHttpObject()
{
	var xmlHttp=null;
	try
	  {  	  xmlHttp=new XMLHttpRequest();		}// Firefox, Opera 8.0+, Safari
	catch (e)
	  { 
	  try
		{   	xmlHttp=new ActiveXObject("Msxml2.XMLHTTP");    } // Internet Explorer
	  catch (e)
	  {    	xmlHttp=new ActiveXObject("Microsoft.XMLHTTP");    }
	 }
	return xmlHttp;
} 

function singleValue()
{
	if(searchXMLHttp!=null
			&& searchXMLHttp.responseXML!=null
			&& searchXMLHttp.responseXML.documentElement!=null
			&& searchXMLHttp.responseXML.documentElement.childNodes!=null )
	{	
		var xmlDoc=searchXMLHttp.responseXML.documentElement;
		nodes = xmlDoc.getElementsByTagName("match");
		str = document.getElementById("searchText").value.toUpperCase();
		if(nodes.length==1)
			getFeatureData(nodes[0].getAttribute("feature_id"));
		else
			for(i=0; i<nodes.length; i++)
				if(nodes[i].getAttribute("desc").toUpperCase()==str)
					getFeatureData(nodes[i].getAttribute("feature_id"));
	}
}

function sortInput(value)
{
	var colArray = value.split(/\s/);
	gene_p_from.sort(colArray, "toggle");
	g2g_from.sort(colArray, "toggle");
	exp_from.sort(colArray, "toggle");
	ptb_from.sort(colArray, "toggle");
	chip_from.sort(colArray, "toggle");
	mirna_from.sort(colArray, "toggle");
}

function sortOutput(value)
{
	var colArray = value.split(/\s/);
	exp_to.sort(colArray, "toggle");
	g2g_to.sort(colArray, "toggle");
	tfbs_to.sort(colArray, "toggle");
	ptb_to.sort(colArray, "toggle");
	chip_to.sort(colArray, "toggle");
	mirna_to.sort(colArray, "toggle");
}


var sourcerx;

function filterResults()
{
	var srx = "";
			  
	if(document.getElementById("exp").checked)
	{
		srx='Experimental';
	}
	if(document.getElementById("pred").checked)
	{
		if(srx.length>0)
			srx+='|';
		srx+= 'Predicted';
	}
	if(document.getElementById("pub").checked)
	{
		if(srx.length>0)
			srx+='|';
		srx+= 'Published';
	}
	if(document.getElementById("mirna").checked)
	{
		if(srx.length>0)
			srx+='|';
		srx+= 'miRNA';
	}
	if(document.getElementById("sirna").checked)
	{
		if(srx.length>0)
			srx+='|';
		srx+= 'siRNA';
	}
	if(document.getElementById("chip").checked)
	{
		if(srx.length>0)
			srx+='|';
		srx+= 'ChIP';
	}

	
	if(srx.length==0)
		srx = null;
		
	sourcerx = new RegExp(srx); 
	
	g2g_to.filter(filterSource);
	g2g_from.filter(filterSource);
	
	//promoter_to.filter(filterSource);
	//promoter_from.filter(filterSource);
	ppi.filter(filterSource);
}

var filterSource = function(dataSet, row, rowNumber)
{
	if (row["@source"].search(sourcerx) != -1)
		return row; 

	return null; 
}

function updateL3()
{
	var L3 = document.getElementsByTagName("td");
	lastL3Text = null;
	lastL3 = null;
	pcount=0;
	for(i=0; i<L3.length; i++)
	{
		if(L3[i]==null)
			continue;
		if(L3[i].className=="L3")
		{	
			if(lastL3!=null && lastL3Text==L3[i].innerHTML)
			{
				
				rs = 1;
				if(lastL3.getAttribute("rowSpan")!=null)
					rs = parseInt(lastL3.getAttribute("rowSpan"));
				rs++;
				L3[i].parentNode.removeChild(L3[i]);
				lastL3.setAttribute("rowSpan",rs );
			}
			else
			{	
				pcount++;
				lastL3Text = L3[i].innerHTML;
				lastL3 = L3[i];
			}
			
			
			elem = lastL3;

			if(elem.firstChild.firstChild!=null)
				elem = elem.firstChild.firstChild;
			else
				elem = lastL3.childNodes[1].childNodes[1];
			
			
			if(lastL3Text.indexOf("Antisense")==-1)
				elem.innerHTML = "P"+pcount+"<sup style='text-decoration:none'>&nbsp;L3</sup>";
			else
				elem.innerHTML = "AS"+pcount+"<sup style='text-decoration:none'>&nbsp;L3</sup>";
		}
	}
	
	if(pcount==0)
		document.getElementById("promoterOptions").style.display="none";	
}

function processAlias()
{ 			
	if(document.getElementById("entrezAlias")==null)
		return ;
		

	var alias = "";
	var entrezId = "";
	var desc = "";
        var authors="";
        var journal = "";
        var abstract = "";
	var rows = featureSymbols.getData();
	var otherSymbol=0;
	if(rows!=null)
	{
		for(i=0; i<rows.length; i++)
		{
			if(rows[i]["@type"]=="Entrez_synonym")
			{
				if(alias.length>0)
					alias+=", ";
				alias += rows[i]["@value"];
			}
			else if(rows[i]["@type"]=="EntrezID")
			{
				entrezId = rows[i]["@value"];
			}	
			else if(rows[i]["@type"].search(/(Ensembl_ID)|(Interpro)|(miRBase)/i)==-1)
			{
				otherSymbol++;
			}
		}
	}


	rows = featureMData.getData();
	if(rows!=null)
	{
		for(i=0; i<rows.length; i++)
		{
			if(rows[i]["@type"]=="description") { desc = rows[i]["mdata"]+"<br><br>"; }
			if(rows[i]["@type"]=="title") { desc = rows[i]["mdata"]; }
			if(rows[i]["@type"]=="authors") { authors = rows[i]["mdata"]; }
			if(rows[i]["@type"]=="journal") { journal = rows[i]["mdata"]; }
			if(rows[i]["@type"]=="abstract") { abstract = rows[i]["mdata"]; }
		}
	}
	

	rows = feature.getData();
	targetGene = rows[0]["@id"];
	rows = promoter_from.getData();
	poptions = "";
	if(rows!=null && rows.length>0)
	{
		var ptype="";
		for(i=0; i<rows.length; i++)
		{
			if(rows[i]["@source"].indexOf("antisense")>-1)
				ptype="AS";
			else
				ptype="P";
			poptions+=ptype+(i+1)+"<input type=\"checkbox\" onClick=\"updateGraphs();\" checked=\"checked\" value=\""+ptype
				+(i+1)+":"+	rows[i]["@feature_id"]+"\">&nbsp;";
				
		}
		document.getElementById("promoterOptions").style.display="inline";
		document.getElementById("L2Promoters").innerHTML = "&nbsp;"+poptions;
	}
	
	poptions = "";
	if(rows!=null)
	{	
		var ptype="";
		for(i=0; i<rows.length; i++)
		{
			if(rows[i]["@source"].indexOf("antisense")>-1)
				ptype="AS";
			else
				ptype="P";
			poptions+=ptype+(i+1)+"<input type=\"checkbox\" onClick=\"updateGraphs();\" checked=\"checked\" value=\""+ptype
				+(i+1)+":"+	rows[i]["@feature_id"]+"\">&nbsp;";
				
		}
	}
	document.getElementById("L3Promoters").innerHTML = "&nbsp;"+poptions;
	
	poptions = "";
	if(rows!=null)
	{
		var ptype="";
		var lastL3 = "";
		pcount = 0;
		for(i=0; i<rows.length; i++)
		{
			if(lastL3!=rows[i]["@L3promoter"])
			{	
				pcount++;
				lastL3 = rows[i]["@L3promoter"];
				if(rows[i]["@source"].indexOf("antisense")>-1)
					ptype="AS";
				else
					ptype="P";
				poptions+=ptype+(pcount)+"<input type=\"checkbox\" onClick=\"updateGraphs();\" checked=\"checked\" value=\""+ptype
					+(pcount)+":"+	rows[i]["@L3promoter"]+"\">&nbsp;";
	}
				
		}
	}
	poptions+="&nbsp;";
	document.getElementById("L3Promoters").innerHTML = poptions;
	
	selectedIds = targetGene;
	updateGraphs();

	
	if(alias.length>0)
	{
		alias = "Alias: "+alias+"<br>";
	}

        if(authors) {
  	  document.getElementById("entrezAlias").innerHTML = 
               "<div onMouseOver=\"setToolTipWidth(450)\" onMouseOut=\"setToolTipWidth()\" >" +
               "<span style='font-weight:bold;font-size:10pt' onMouseOver=\"pubmedToolTip('" + abstract + "', 450)\" onMouseOut=\"toolTip()\" >" +
                desc+"</span><br>" +
               "<span style='font-style:italic;font-size:8pt'>" +
                authors +"<br>" + journal + "</span><br>"+
               "</div>";
        } else {
  	  document.getElementById("entrezAlias").innerHTML = desc+alias;
        }
	
	if(entrezId.length>0)
	{
		document.getElementById("entrezLink").innerHTML = 
		"<a href='http://www.ncbi.nlm.nih.gov/sites/entrez?db=gene&cmd=Retrieve&dopt=full_report&list_uids="+entrezId+"' target='entrez'>("+entrezId+")</a>";
	}
	
	findRange();
} 


locationrx = /(\d+)/g;
function findRange()
{
	var chr, min, max, strand;
	var rows = feature.getData();
	if(rows!=null)
	{
		min = parseInt(rows[0]["@start"]);
		max = parseInt(rows[0]["@end"]);
		chr = rows[0]["@chr"];
		strand = rows[0]["@strand"];
	}
	if(chr=='unknown' || (!chr)) return;

	document.getElementById("genomeLoc").innerHTML= "<br>" + chr+ ":" +min+ ".." +max+ " ("+ strand +")<br>";

	rows = promoter_from.getData();
	if(rows!=null)
	{
		for(var i=0; i<rows.length; i++)
		{
			minmax = rows[i]["@loc"].match(locationrx);
			if(minmax[2]==null)
				continue;
			if(min==null || min>minmax[1])
				min = parseInt(minmax[1]);
			if(max==null || max<minmax[2])
				max = parseInt(minmax[2]);			
		}
	}

	range = max-min;
	min -= Math.round(range*.25);
	max += Math.round(range*.25);
	
	document.getElementById("fantomLink").innerHTML="View in <a href=\"/nw2006/fantom44/gev/gbrowse/hg18/?ref="+chr+";start="+min+";stop="+max+"\" target=\"fantomdb\">FantomDB</a> <a href=\"http://genome.ucsc.edu/cgi-bin/hgTracks?org=Human&db=hg18&position="+chr+":"+min+"-"+max+"\" target=\"ucsc\">UCSC</a>";
	
	document.getElementById("fantomLink2").innerHTML="<a href=\"/nw2006/fantom44/gev/gbrowse/hg18/?ref="+chr+";start="+min+";stop="+max+"\" target=\"fantomdb\"><img border=\"0\" src=\"/nw2006/fantom44/gev/gbrowse_img/hg18/?name="
+chr+":"+min+".."+max+	";type=Transcript+paper1_cage_cluster_level2+paper1_cage_cluster_level3+TU+Illumina_BR_PMA+TF_PMA_Full+PU1_1st_PMA0h+PU1_1st_PMA96h+PU1_2nd_PMA0h+PU1_2nd_PMA96h+SP1_1st_PMA0h+SP1_1st_PMA96h+SP1_2nd_PMA0h+SP1_2nd_PMA96h+TFBS_MotEvo_refseq+TFBS_MotEvo_cage;width=800;options=paper1_cage_cluster_level2+paper1_cage_cluster_level3+3+Illumina_BR_PMA+3+TF_PMA_Full_2nd+3+TFBS_MotEvo_refseq+3+TFBS_MotEvo_cage+3;width=800\"></a>";	
}

function showPromoterRegion(location)
{
   if(location.indexOf("location")>-1)
   {
	window.open('/nw2006/fantom44/gev/gbrowse/hg18/?name='+location.replace(/[\+]/g,'%2B'), 'fantomdb');   
   }
   else
   {
  	loc = location.match(locationrx);
   	window.open('/nw2006/fantom44/gev/gbrowse/hg18/?ref=chr'+loc[0]+';start='+loc[1]+';stop='+loc[2], 'fantomdb');
   }
}

function selfRegulates()
{
	if(document.getElementById("selfRegulates")==null)
		return ;
		
	rows = feature.getData();
	id=rows[0]["@id"];

	if(test_self(id, ppi.getData())) {
	   document.getElementById("dimer").innerHTML= "<img src=\"../images/dimer.png\" align=\"top\"> Forms dimer";
        }
	
	if(test_self(id, g2g_to.getData()) ||test_self(id, promoter_to.getData()) ||test_self(id, promoter_from.getData()) 
		||test_self(id, gene_p_from.getData())   ||test_self(id, exp_from.getData()) 
		||test_self(id, exp_to.getData())||test_self(id, ptb_from.getData()) 	||test_self(id, ptb_to.getData()) 
		||test_self(id, chip_from.getData()) ||test_self(id, chip_to.getData())||test_self(id, mirna_from.getData()) 
		||test_self(id, mirna_to.getData())	||test_self(id, g2g_from.getData()) )																			
		document.getElementById("selfRegulates").innerHTML=
					"<br><br><img src=\"../images/self.png\" align=\"top\"> Self Regulates<br>";
		
}

function test_self(id, rows) {
  if(rows!=null) {
    for(var i=0; i<rows.length; i++) {
      if(rows[i]["@feature_id"]==id && rows[i]["@source"].indexOf("siRNA")==-1) return true;
    }
  }
}


<!-- Begin Graph Drawing Functions  -->
var ie=document.all;
var nn6=document.getElementById&&!document.all;
var selectedIds="";
var isdrag=false;
var cancelClickAfterDrag = false;
var x,y;
var dobj;
function findPos(obj) {
	var curleft = curtop = 0;
	if(obj!=null && obj.offsetParent) 
	{
		curleft = obj.offsetLeft
		curtop = obj.offsetTop
		while (obj = obj.offsetParent)
		{
			curleft += obj.offsetLeft
			curtop += obj.offsetTop
		}
	}
	return [curleft,curtop];
}

function movemouse(e)
{
  if (isdrag)
  {
	cancelClickAfterDrag = true;
	if(dobj.style.position!='relative')
		dobj.style.position='relative';
	
	my = nn6 ?  e.clientY :  event.clientY ;
    	dobj.style.left = nn6 ?  e.clientX - x :  event.clientX - x;
    	dobj.style.top  = my - y;
	
	var datatable = document.getElementById("dataTable");

	var dragLimits = findPos( datatable );
	
	var h = window.pageYOffset ||
	           document.body.scrollTop ||
	           document.documentElement.scrollTop;
	
	
	var pheight = datatable.height;
		
	if(pheight==null || pheight<1)
		pheight = datatable.offsetHeight;	
	
		
	if(my>dragLimits[1]+pheight-h)
	{	
		endDrag();
		if(selectedIds.length>0)
			selectedIds+=",";
		selectedIds+=dobj.id;
		updateGraphs();		
		
	}
	return false;	
  }
}

function checkPromoters()
{
	document.getElementById('L2Promoters').style.display=
		(document.getElementById('L2').checked?"inline":"none");
	document.getElementById('L3Promoters').style.display=
		(document.getElementById('L3').checked?"inline":"none");
	updateGraphs();
}

var targetGene="";
function updateGraphs(size, type)
{
	var url=expressURL+"?ids="+selectedIds;
	if(document.getElementById("L2").checked)
	{
		poptions = document.getElementById("L2Promoters");
		for(i=0; i<poptions.childNodes.length; i++)
		{
			node = poptions.childNodes[i];
			if(node.type == 'checkbox' && node.checked)
				url+=","+node.value;	
		}
	}
	else if(document.getElementById("L3").checked)
	{
		poptions = document.getElementById("L3Promoters");
		url+='&names=';
		comma = "";
		for(i=0; i<poptions.childNodes.length; i++)
		{
			node = poptions.childNodes[i];
			if(node.type == 'checkbox' && node.checked)
			{	url+=comma+node.value;	 comma=","; }
		}	
	}
	
	url+= "&type="+ (type==null?"cage,illumina,qrt-pcr":type);
	rows = feature.getData();
	if(rows[0]["featuresource/@category"]!=null && rows[0]["featuresource/@category"]=="miRBase")
	{ 
		url += (rows[0]["featuresource/@name"]=="miRBase_mature"?",miRNA&mature=true":",miRNA&mature=false");	
	}
	
	dataset = "";
	if(document.getElementById("riken1").checked)
		dataset += "1";
	if(document.getElementById("riken3").checked)
	{
		if(dataset.length>0)
			dataset+=",";
		dataset+="3";
	}
	if(document.getElementById("riken6").checked)
	{
		if(dataset.length>0)
			dataset+=",";
		dataset+="6";
	}
	if(dataset.length>0)
		url += "&dataset="+dataset;

	if(size!=null)
		url += "&size="+size;
	else
	{
		document.getElementById("expressionGraphs").innerHTML="<br><br><br><br><br><br><br>Fetching Expression Data.....<br><br><br><br><br><br><br>";
		document.getElementById("graphValues").innerHTML="";
	}
			
	url += "&rnd="+Math.random();
	url = url.replace(/[\+]/g,'%2B'); 

	expressXMLHttp=GetXmlHttpObject()
	if (expressXMLHttp==null)
	{
	  alert ("Your browser does not support AJAX!");
	  return;
	}	
 
	if(size!=null)
		expressXMLHttp.onreadystatechange=popupGraph;
	else
		expressXMLHttp.onreadystatechange=displayGraph;
	expressXMLHttp.open("GET",url,true);
	expressXMLHttp.send(null);
}

function popupGraph()
{
	if(expressXMLHttp.readyState==4)
	{
		var xmlDoc=expressXMLHttp.responseXML.documentElement;
		nodes = xmlDoc.getElementsByTagName("graph");
		window.open(imageURL+nodes[0].getAttribute("url"),'largeGraph');
	}
}

function displayGraph()
{
	valuesrx = /([\d\.-]+)/g;

	if (expressXMLHttp!=null && expressXMLHttp.readyState==4)
	{
		if(expressXMLHttp==null || expressXMLHttp.responseXML==null || expressXMLHttp.responseXML.documentElement==null)
		{
			//alert('Problem fetching Expression Data!');
			document.getElementById("expressionGraphs").innerHTML="<br><br>Error retrieving expression data.";
			return;
		}
		
		var xmlDoc=expressXMLHttp.responseXML.documentElement;
		var imageTable = "<table width=\"100%\" border=\"0\"><tr>";
		var dataTable = "<table width=\"100%\" border=\"0\" cellspacing=\"0\" cellpadding=\"0\"><tr>";
		var dataHeader="";
		var nodes;
		var dataFound = false;


		for(i=0; i<xmlDoc.childNodes.length; i++)
		{				
			nodes = xmlDoc.getElementsByTagName("graph");
			if(nodes==null || nodes[i]==null)
			{
				continue;
			}
			dataFound = true;

			width = 100/nodes.length;

			if(nodes[i].getAttribute("url")!=null)
				imageTable+="<td align=\"center\" width=\""+width+"%\">"
					+"<a href=\"#\" onClick=\"window.open('graphLoading.html','largeGraph');updateGraphs('large','"+nodes[i].getAttribute("type") +"');return false;\">"
					+"<img border=\"0\" src=\""+imageURL+nodes[i].getAttribute("url")+"\"></a></td>";

			genes = nodes[i].getElementsByTagName("gene");
			dataTable+="<td valign=\"top\" align=\"center\" width=\""+width+"%\"><table border=\"1\" class=\"small\" cellpadding=\"0\" cellspacing=\"0\">";
			for(n=0; n<genes.length; n++)
			{

				values = genes[n].getAttribute("data").match(valuesrx);

				if(n==0)
				{
					dataTable+="<tr><th>&nbsp;</th>";
					for(v=0; v<values.length; v+=2)
						dataTable+="<th>"+values[v]+"</th>";
					dataTable+="</tr>";

				}

				dataTable+="<tr align=\"center\"><td>"
					+genes[n].getAttribute("name")+"(R"+genes[n].getAttribute("dataset")+")";
				
				if(genes[n].getAttribute("probeId")!=null)
					dataTable+="("+genes[n].getAttribute("probeId")+")";
				dataTable+="</td>";

				for(v=1; v<values.length; v+=2)
					dataTable+="<td>"+values[v]+"</td>";

				dataTable+="</tr>"	
			}
			dataTable+="</table></td>";

		}

		if(dataFound)
		{
			document.getElementById("expressionGraphs").innerHTML = imageTable+"</tr></table>";
			document.getElementById("graphValues").innerHTML = dataTable+"</tr></table>";
		}
		else
			document.getElementById("expressionGraphs").innerHTML="<br><br>No expression found.";
			
		expressXMLHttp=null;
				
	}
}

function resetGraphs()
{
	 selectedIds=targetGene;
	 updateGraphs();
}


function selectmouse(e) 
{
  var fobj       = nn6 ? e.target : event.srcElement;
  var topelement = nn6 ? "HTML" : "BODY";

  while (fobj.tagName != topelement && fobj.className.search("dragme")==-1)
  {
    fobj = nn6 ? fobj.parentNode : fobj.parentElement;
    if(fobj==null)
	return;
  }

  if (fobj.className.search("dragme")>-1)
  {
    isdrag = true;
    dobj = fobj;
    x = nn6 ? e.clientX : event.clientX; 
    y = nn6 ? e.clientY : event.clientY;
    document.onmousemove=movemouse;
    return false;
  }
}

function endDrag()
{
	isdrag = false;
	if(dobj!=null)
	{
		if(nn6)
			dobj.style.position = null;
		else
		{
			dobj.style.left=0;
			dobj.style.top=0;
		}
	}
	document.onmousemove = moveToMouseLoc;		
}

document.onmousedown=selectmouse;
document.onmouseup=endDrag;


function pmd(id)
{
	//again, shorthand function to avoid writing this out 10000 times
	window.open('http://www.ncbi.nlm.nih.gov/sites/entrez?Db=pubmed&Cmd=ShowDetailView&ordinalpos=1&itool=EntrezSystem2.PEntrez.Pubmed.Pubmed_ResultsPanel.Pubmed_RVBrief&TermToSearch='+id,'pubmed');	
}


