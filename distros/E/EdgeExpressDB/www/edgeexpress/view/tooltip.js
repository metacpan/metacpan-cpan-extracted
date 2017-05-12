
var ns4 = document.layers;
var ns6 = document.getElementById && !document.all;
var ie4 = document.all;
offsetX = 0;
offsetY = 20;
var toolTipSTYLE="";
var toolTipWidth = 210;
var winW = 800, winH = 460;

function initToolTips()
{
  if(ns4||ns6||ie4)
  {
    if(ns4) toolTipSTYLE = document.toolTipLayer;
    else if(ns6) toolTipSTYLE = document.getElementById("toolTipLayer").style;
    else if(ie4) toolTipSTYLE = document.all.toolTipLayer.style;
    if(ns4) document.captureEvents(Event.MOUSEMOVE);
    else
    {
      toolTipSTYLE.visibility = "visible";
      toolTipSTYLE.display = "none";
    }
    document.onmousemove = moveToMouseLoc;
  }
  window.onresize = getNewWindowSize;
  getNewWindowSize();
}

function ttip(source,index,index2)
{
        toolTipWidth = 210;

	//This is one step before the real tooltip, which parses out single quotes from XML attributes
	var row;
	if(source=='exp_from')
		row = exp_from.getRowByRowNumber([index]);
	else if(source=='chip_from')
		row = chip_from.getRowByRowNumber([index]);
	else if(source=='ptb_from')
		row = ptb_from.getRowByRowNumber([index]);
	else if(source=='mirna_from')
		row = mirna_from.getRowByRowNumber([index]);
	else if(source=='g2g_from')
		row = g2g_from.getRowByRowNumber([index]);
	else if(source=='exp_to')
		row = exp_to.getRowByRowNumber([index]);
	else if(source=='chip_to')
		row = chip_to.getRowByRowNumber([index]);
	else if(source=='ptb_to')
		row = ptb_to.getRowByRowNumber([index]);
	else if(source=='mirna_to')
		row = mirna_to.getRowByRowNumber([index]);
	else if(source=='g2g_to')
		row = g2g_to.getRowByRowNumber([index]);
	else if(source=='tfbs_to')
		row = tfbs_to.getRowByRowNumber([index]);
	
	if(row!=null)
	{
		toolTip(row['@name'],row['@feature_id'],row['@source'],row['@weight'],row['evidence_code']);
	}
	else if(source=='ppi')
	{
		row = ppi.getRowByRowNumber([index]);
		toolTip(row['@name'],row['@feature_id'],row['@source'],row['@weight'],'');
	}
	else if(source=='promoter_to')
	{
		row = promoter_to.getRowByRowNumber([index]);
		toolTip(row['@name'],row['@feature_id'],row['@source'],row['@weight'],row['@promoter'],row['@tfmatrix']);
	}
	else if(source=='TFBS' || source=='promoter_from')
	{
		row = promoter_from.getRowByRowNumber([index]);
		toolTip(row['@name'],row['@feature_id'],row['@source'],row['@weight'],'');
	}
	else if(source=='gene_p_from')
	{
		row = promoter_from.getRowByRowNumber([index]);		
		row = gene_p_from.getNestedDataSetForParentRow(row);
		row = row.getRowByRowNumber(index2);
		if(row!=null)
			toolTip(row['@name'],row['@feature_id'],row['@source'],row['@weight'],row['@evidence_code'],row['@promoter'],row['@tfmatrix']);
	}
}

function setToolTipWidth(width)  {
  if(!width) { toolTipWidth = 210; }
  else { toolTipWidth = width; }
}

function pubmedToolTip(abstract, width) 
{
 
  if(isdrag || pubmedToolTip.arguments.length < 1) // hide
  {
    if(ns4) toolTipSTYLE.visibility = "hidden";
    else toolTipSTYLE.display = "none";
  }
  else // show
  {
	msg = abstract;
	  
    var content =
    '<table border="0" cellspacing="0" cellpadding="1" bgcolor="#000000"><td><table width="' + width + '" border="0" cellspacing="0" cellpadding="1" bgcolor="#eeeeff"><td align="center"><font face="sans-serif" color="#000000" size="-2">' + msg + '</font></td></table></td></table>';

   if(ns4)
    {
      toolTipSTYLE.document.write(content);
      toolTipSTYLE.document.close();
      toolTipSTYLE.visibility = "visible";
    }
    if(ns6) 
    {
      document.getElementById("toolTipLayer").innerHTML = content;
      toolTipSTYLE.display='block'
    }
    if(ie4)
    {
      document.all("toolTipLayer").innerHTML=content;
      toolTipSTYLE.display='block'
    }
  }
}


function toolTip(name,id,source,weight,evidence,promoter,matrix)
{
 
  if(isdrag || toolTip.arguments.length < 1) // hide
  {
    if(ns4) toolTipSTYLE.visibility = "hidden";
    else toolTipSTYLE.display = "none";
  }
  else // show
  {
	msg = "<nobr>Name: "+name+"</nobr>"
	+(id!=null && id.length>0?"<br>Id: "+id:"")
	+(source!=null && source.length>0?"<br>Source: "+source:"") 
	+(weight!=null && weight.length>0?"<br>Weight: "+weight:"") 
	+(evidence!=null && evidence.length>0?"<br>Evidence: "+evidence:"") 
	+(promoter!=null && promoter.length>0?"<br>Promoter: "+promoter:"")
	+(matrix!=null && matrix.length>0?"<br>Matrix: "+matrix:"");
	
	
	  
    var content =
    '<table border="0" cellspacing="0" cellpadding="1" bgcolor="#000000"><td><table width="' + toolTipWidth + '" border="0" cellspacing="0" cellpadding="1" bgcolor="#eeeeff"><td align="center"><font face="sans-serif" color="#000000" size="-2">' + msg + '</font></td></table></td></table>';

   if(ns4)
    {
      toolTipSTYLE.document.write(content);
      toolTipSTYLE.document.close();
      toolTipSTYLE.visibility = "visible";
    }
    if(ns6) 
    {
      document.getElementById("toolTipLayer").innerHTML = content;
      toolTipSTYLE.display='block'
    }
    if(ie4)
    {
      document.all("toolTipLayer").innerHTML=content;
      toolTipSTYLE.display='block'
    }
  }
}


function moveToMouseLoc(e)
{  var posx = 0;
	var posy = 0;
	if (!e) var e = window.event;
	if (e.pageX || e.pageY) 	{
		posx = e.pageX;
		posy = e.pageY;
	}
	else if (e.clientX || e.clientY) 	{
		posx = e.clientX + document.body.scrollLeft
			+ document.documentElement.scrollLeft;
		posy = e.clientY + document.body.scrollTop
			+ document.documentElement.scrollTop;
	}

  var hscale = posx / winW;
  if(hscale > 1.0) hscale=1.0;
  toolTipSTYLE.left = (posx - Math.floor((toolTipWidth+10)*hscale)) +'px';
  toolTipSTYLE.top = (posy + offsetY) +'px';
  return true;
}

function getNewWindowSize() {

  if (parseInt(navigator.appVersion)>3) {
    if (navigator.appName.indexOf("Microsoft")!=-1) {
      winW = document.body.offsetWidth;
      winH = document.body.offsetHeight;
    }
    else {
      winW = window.innerWidth;
      winH = window.innerHeight;
    }
  }

  // not sure how to get this dynamically
  winW -= 20; /* whatever you set your body bottom margin/padding to be */
  winH -= 20; /* whatever you set your body bottom margin/padding to be */
};

