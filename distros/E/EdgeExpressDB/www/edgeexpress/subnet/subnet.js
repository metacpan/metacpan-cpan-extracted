var networkXMLHttp;
var networkURL = "/eedb_fantom4/cgi/getnetwork.cgi";
//var networkURL = "../cgi/getnetwork.cgi";
var cookieURL = "../cgi/eedb_ck_genes.cgi";

showAllSearch=1;

function searchClick(id, geneName) {
  document.getElementById("names_text").value += " " + geneName ;
}

function searchClickAll(geneNames) {
  document.getElementById("names_text").value += " " + geneNames ;
}

function singleValue() {
}

///////////////////

function resetForm() {
  document.getElementById("tfbsCheck").checked = 1;
  document.getElementById("mirnaTCheck").checked = 1;
  document.getElementById("pubCheck").checked = 1;
  document.getElementById("ppiCheck").checked = 1;
  document.getElementById("chipCheck").checked = 1;
  document.getElementById("perturbCheck").checked = 1;

  document.getElementById("tfbsCheck2").checked = 0;
  document.getElementById("mirnaTCheck2").checked = 0;
  document.getElementById("pubCheck2").checked = 0;
  document.getElementById("ppiCheck2").checked = 0;
  document.getElementById("chipCheck2").checked = 0;
  document.getElementById("perturbCheck2").checked = 0;

  document.getElementById("expandNodesCheck").checked = 0;
  document.getElementById("singletonCheck").checked = 1;
  document.getElementById("leafCheck").checked = 0;

  document.getElementById("names_text").value = "" ;
  clearGenelistCookie();
}

function clearGenelistCookie() {
  var url = cookieURL + "?clear=1";
  var object_html = "<object type=\"text/xml\" data=\"" + url + "\" />";
  document.getElementById("cookieDiv").innerHTML= object_html;
}

function loadGenelistCookie() {
  var names = readCookie("EEDB_subnet_gene_list");
  document.getElementById("names_text").value = names ;
}

function readCookie(name) {
	var nameEQ = name + "=";
	var ca = document.cookie.split(';');
	for(var i=0;i < ca.length;i++) {
		var c = ca[i];
		while (c.charAt(0)==' ') c = c.substring(1,c.length);
		if (c.indexOf(nameEQ) == 0) return unescape(c.substring(nameEQ.length,c.length));
	}
	return null;
}


function subnetURL(str, e)
{
  var x=document.getElementById("names_text");
  
  var splitNames = x.value.split(/[ \t\n\r]/);
  var commaNames = splitNames.join(",");
  var url = networkURL + "?names=" + commaNames;

  if(document.getElementById("singletonCheck").checked)
     url += "&singles=n";
  if(document.getElementById("leafCheck").checked)
     url += "&leaves=n";
  if(document.getElementById("expandNodesCheck").checked) url += "&expand=y";

  var edgeSet1 = "";
  if((document.getElementById("tfbsCheck").checked)) edgeSet1 += "tfbs,";
  if((document.getElementById("mirnaTCheck").checked)) edgeSet1 += "mirnaT,";
  if((document.getElementById("pubCheck").checked)) edgeSet1 += "pub,";
  if((document.getElementById("perturbCheck").checked)) edgeSet1 += "perturb,";
  if((document.getElementById("ppiCheck").checked)) edgeSet1 += "ppi,";
  if((document.getElementById("chipCheck").checked)) edgeSet1 += "chip,";
  if(edgeSet1.length >0) url += "&edgeSet1=" + edgeSet1;

  var edgeSet2 = "";
  if((document.getElementById("tfbsCheck2").checked)) edgeSet2 += "tfbs,";
  if((document.getElementById("mirnaTCheck2").checked)) edgeSet2 += "mirnaT,";
  if((document.getElementById("pubCheck2").checked)) edgeSet2 += "pub,";
  if((document.getElementById("perturbCheck2").checked)) edgeSet2 += "perturb,";
  if((document.getElementById("ppiCheck2").checked)) edgeSet2 += "ppi,";
  if((document.getElementById("chipCheck2").checked)) edgeSet2 += "chip,";
  if(edgeSet2.length >0) url += "&edgeSet2=" + edgeSet2;

  var timepoint = document.getElementById("timepoint").value;
  url += "&timepoint=" + timepoint;

  return url;
}


function generateSubnet(str, e)
{
  var url = subnetURL();

  var format = document.getElementById("format").value;
  url += "&format=" + format;

  if(format == "netgenes") {
    var iframe_html = "<iframe width=690px height=520px SCROLLING=yes src=\"" + url + "\" />";
    document.getElementById("SVGdiv").innerHTML= iframe_html;
  } else {
    var newWindow = window.open(url, 'eeDB_subnet_full');
    newWindow.focus();
  }
}



function previewSubnetSVG(str, e)
{
//  if(ie4) {
//    document.getElementById("SVGdiv").innerHTML= "Sorry Internet Explorer does not support SVG.<br>Please try another browser<br>"+
//     "or download plugin available here <br>"+
//     "<a href=\"http://www.adobe.com/svg/viewer/install/mainframed.html\">http://www.adobe.com/svg/viewer/install/mainframed.html</a>";
//  } else {
    var svg_url = subnetURL();
    svg_url += "&preview=1&format=svg";

    var object_html = "<object width=690px height=520px type=\"image/svg+xml\" data=\"" + svg_url + "\" />";
    var iframe_html = "<iframe width=690px height=520px SCROLLING=auto src=\"" + svg_url + "\" />";
    document.getElementById("SVGdiv").innerHTML= iframe_html;
//  }
}


function demoSubnet(id) {
  var  genes = "myc myb notch1";

  resetForm();
  document.getElementById("SVGdiv").innerHTML= "clicked to demo subnet " + id;
  if(id == 1) {
    genes = "FOXJ3 FOXM1 FOXO1 FOXP1 FOXP2  MYB MYC NOTCH1 POU2F1 RBM9 VDR WT1 hsa-mir-9-1"; 
  }
  if(id == 2) {
    genes = "FOXD1 FOXJ3 FOXM1 FOXO1 FOXP1 FOXP2  MYB MYC NOTCH1 POU2F1 RBM9 VDR WT1 FLT4 NRP1 VEGFA VEGFB EGR1 EGR2 KLF10 NAB1 NAB2 TOE1"; 
  }
  if(id == 3) {
    genes = "EBI2 ETS1 ITGAL LIMS1 NFE2L1 NT5E RUNX1 SP1 SPI1 hsa-mir-221 hsa-mir-222"; 
    document.getElementById("pubCheck").checked = 0;
    document.getElementById("perturbCheck").checked = 0;

    document.getElementById("ppiCheck2").checked = 1;
    document.getElementById("pubCheck2").checked = 1;
    document.getElementById("perturbCheck2").checked = 1;
  }
  if(id == 4) {
    genes = "BCL6 EGR1 ETS1 ETS2 FOXD1 FOXP1 FOXP2 GAS6 GRB2 IRF7 KLF10 KLF2 LMO2 MXI1 NAB2 NFAT5 NFE2L1 NFKB1 NRAS RUNX1 SNAI1 SREBF1 SRF TGFBI TGFBRAP1 TNFAIP3 TNFRSF12A TNFSF14 TP53INP1 TP53INP2 YY1";

    document.getElementById("pubCheck").checked = 0;
    document.getElementById("ppiCheck").checked = 0;
    document.getElementById("perturbCheck").checked = 0;
    document.getElementById("chipCheck").checked = 0;

    document.getElementById("pubCheck2").checked = 1;
    document.getElementById("perturbCheck2").checked = 1;
    document.getElementById("chipCheck2").checked = 1;
  }
  if(id == 5) {
    genes = "BCL6 BMI1 CTCF ETS1 FOXM1 FOXP1 FOXP2 IRF7 IRX3 MYB MYC NFE2L1 NFKB1 NFYA NOTCH1 NRAS PTTG1 RUNX1 SNAI1 VDR WT1 " +
            "hsa-mir-155 E2F1 EGR1 ETS2 FOXD1 FOXP1 GADD45A GAS6 GRB2 IRF7 KLF10 KLF2 LMO2 MXI1 MYC NAB2 NFAT5 NFE2L1 NFKB1 NFYA "+
            "NRAS PTTG1 RUNX1 SREBF1 SRF TGFBI TGFBRAP1 TNFAIP3 TNFRSF12A TNFSF14 TP53INP1 TP53INP2 TPD52 USMG5 YY1 EGR1 ELF1 ELK1 "+
            "ETS1 ETS2 IRF1 IRF7 KLF4 LMO2 MXI1  NFE2L1 NFKB1 REL RELA RUNX1 SNAI1 SNAI3 SP1 SREBF1 SRF  STAT4 STAT5A STAT6 "+
            "YY1 hsa-mir-221 hsa-mir-222";
    document.getElementById("pubCheck").checked = 0;
    document.getElementById("ppiCheck").checked = 0;
    document.getElementById("perturbCheck").checked = 0;
    document.getElementById("chipCheck").checked = 0;

    document.getElementById("pubCheck2").checked = 1;
    document.getElementById("perturbCheck2").checked = 1;
  }

  document.getElementById("names_text").value = genes ;
  previewSubnetSVG();
}


