//-*- Mode: Javascript; coding: utf-8; -*-
//
// File: diacollo.js
// Author: Bryan Jurish <moocow@cpan.org>
// Description: client-side diacollo callbacks & visualization routines
//
// WARNING
//  The following code is hacky, messy, sloppy, ugly, and otherwise generally sub-optimal.
//  Patches & improvements welcome.
//  Continue at your own risk.
//

//-- user query params
var user_query   = {};
var user_format  = null; //-- save format request, e.g. for motion-charts
var qinfo        = null; //-- query info, set e.g. by html mode
var responseData = null; //-- cached response data, for browser-friendly 'save as'

//-- timing
var ttk_elapsed = 0;
var dcp_t0 = 0;

//----------------------------------------------------------------------
// profile queries params
var dcp_url_base = ".";
var dcp_url_local = "./profile.perl";
var dcp_params_default = {
    "query" : null,
    "date"  : null,
    "slice" : null,
    "score" : null,
    "kbest" : null,
    "cutoff" : null,
    "diff" : null,
    "global" : null,
    "onepass" : null,
    "profile" : null,
    "format" : "text",
    "debug" : 0,
    "groupby": null,
    "eps" : 0
};
var dynformats = {
    "gmotion" : true,
    "hichart" : true,
    "bubble" : true,
    "cloud": true
};
var scoreNames = {
    'f': 'Frequency',
    'fm': 'Frequency per Million',
    'lf': 'log Frequency',
    'lfm': 'log Frequency per Million',
    'milf': 'Pointwise Mutual Information * log Frequency',
    'mi1': 'Pointwise Mutual Information',
    'mi3': 'Mutual Information^3',
    'ld': 'log Dice',
    'll': 'log Likelihood'
};

//----------------------------------------------------------------------
function dqReady() {
    //-- set preliminary timing info
    $(".elapsed").text("~" + String(ttk_elapsed) + "\u00a0sec");

    //-- setup submit-on-enter for IE
    $("#dqForm input[type='text']").keypress(function(e) {
	if (e.which==13) { $("#dqForm").submit() }
    });

    //-- set default query parameters
    profileSelectChange();
    var param = user_query;
    keys(dcp_params_default).forEach(function(k) {
	if (param[k] == null) { param[k] = dcp_params_default[k]; }
	if (param[k] == null) { delete param[k]; }
	if (param[k] == "")   { delete param[k]; }
    });
    if (!param.profile.match(/^diff-/)) {
	["query","date","slice"].forEach(function(k) {
	    delete param["a"+k];
	    delete param["b"+k];
	});
    }

    if (param.query == null) {
	dcpInfoMsg("No 'query' parameter specified - please enter a query.");
	return;
    }

    //-- save and tweak format request
    user_format = param.format;
    if (Boolean(dynformats[user_format])) {
	param.format = "json"; //-- dynamic chart: google motion chart or highcharts 2d plot: query json
    }

    //-- ui tweaks and timing
    dcpStatusMsg("loading","Querying...");
    dcp_t0 = $.now();

    //-- setup raw link url
    var uparam = $.param(param);
    var uhref  = dcp_url_base + "?" + uparam;
    $("#rawLink").prop("href",uhref).text(uhref).show();

    //-- setup initial debug table
    setupDebugTable({});

    //-- check for pre-fetched data (--> loading from local file exported by browser "Save As" function)
    if (dcpData != null) {
	$("#profileDataD3").hide();
	$("#dqForm td label").addClass("disabled");
	$("#dqForm").on('submit',function() {
	    alert("You cannot submit queries from an offline data set!");
	    return false;
	});
	document.title += " [exported]";
	$(".headers h1").append(" [exported]");
	//$("#dqForm, #dqForm input, #dqForm select").prop("disabled",true);

	dcpOnComplete(null,"success");
	dcpOnSuccess(dcpData,"success",{"responseText":dcpData});
    } else {
	//-- send request
	$.ajax({
	    type: "GET",
	    url: dcp_url_local+'?'+uparam,
	    dataType: "text",
	    success: dcpOnSuccess,
	    error: dcpOnError,
	    complete: dcpOnComplete
	})
    }
}

//----------------------------------------------------------------------
function setupDebugTable(qinfo = null) {
    //-- populate
    if (qinfo) {
	$("#debug_qcanon").text(qinfo.qcanon ? qinfo.qcanon : "(not available)")
	$("#debug_qtemplate").text(qinfo.qtemplate ? qinfo.qtemplate : "(not available)")
    }

    //-- show/hide
    if ($("#in_debug").prop('checked')) {
	$(".debugInfo").show();
    } else {
	$(".debugInfo").hide();
    }
}

//----------------------------------------------------------------------
// jqStatusSelection = dcpStatusMsg(cls,msg)
function dcpStatusMsg(cls,msg) {
    var st = $("#status");
    st.on("click", function() { st.fadeOut(); });
    st.attr("class","status "+cls).find(".msg").text(msg);
    return st;
}

// dcpErrorMsg(msg)
function dcpErrorMsg(msg,time) { return dcpStatusMsg("error",msg).fadeIn(Number(time)); }
function dcpWarnMsg(msg,time) { return dcpStatusMsg("warning",msg).fadeIn(Number(time)); }
function dcpInfoMsg(msg,time) { return dcpStatusMsg("info",msg).fadeIn(Number(time)); }
function dcpHintMsg(msg,time) { return dcpStatusMsg("info hint",msg).fadeIn(Number(time)); }
function dcpClearMsg(time) { return dcpStatusMsg("","").fadeOut(Number(time)); };

function dcpShowPrefetchHint() {
    if (dcpData) {
	dcpInfoMsg("Cached result data: you will be unable to submit new queries.").fadeOut(5000);
    }
}

function dcpCacheData(data) {
    if (dcpData == null) {
	$("#diacolloResponseData").text('dcpData = ' + JSON.stringify(data).replace(/</g,'\\u003c').replace(/>/g,'\\u003e') + ';');
    }
}

//----------------------------------------------------------------------
var isDiff;
var isAbsDiff;
function dcpOnSuccess(data,textStatus,jqXHR) {
    dcpClearMsg();
    isDiff    = Boolean(user_query.profile.match(/^diff-/));
    isAbsDiff = Boolean(isDiff && user_query.diff.match(/^adiff/)); //|min

    //-- cache response if appropriate
    if (dcpData==null) {
	dcpCacheData(jqXHR.responseText);
    }

    //-- format dispatch
    if (user_format == "html" || jqXHR.responseText.match(/<html\b/i)) {
	//-- response: html
	dcpFormatHtml(data, jqXHR);
    }
    else if (user_format == "gmotion") {
	//-- response: gmotion (google motion chart)
	dcpFormatGMotion(data, jqXHR);
    }
    else if (user_format == "hichart") {
	//-- response: hichart (highcharts 2d plot)
	dcpFormatHiChart(data, jqXHR);
    }
    else if (user_format == "bubble") {
	//-- response: bubble (d3 bubble chart)
	dcpFormatBubble(data, jqXHR);
    }
    else if (user_format == "cloud") {
	//-- response: cloud (d3 cloud)
	dcpFormatCloud(data, jqXHR);
    }
    else {
	//-- response: other (treat as text data)
	if (user_format == "json") {
	    var jdata = (data instanceof Object) ? data : $.parseJSON(data);
	    qinfo = jdata.qinfo;
	} else {
	    qinfo = {};
	}
	setupDebugTable(qinfo);
	$("#profileDataText").text(data).fadeIn();
    }
}

//----------------------------------------------------------------------
function dcpOnError(jqXHR, textStatus, errorMsg) {
    dcpErrorMsg(textStatus + ": " + errorMsg);
    if (textStatus == "error" && jqXHR.responseText.match(/<html\b/i)) {
	if (jqXHR.responseText.match(/<h1\b/i)) { dcpClearMsg(); }
	$("#errorDiv")
	    .addClass("error")
	    .append( $.parseHTML(jqXHR.responseText, document, false) )
	    .find("h1")
	    .prepend($("#status .icon").clone());
	$("#errorDiv").show();
    } 
}

//----------------------------------------------------------------------
function dcpOnComplete(jqXHR, textStatus) {
    var dcp_t1 = $.now();
    var elapsed = (ttk_elapsed + (dcp_t1-dcp_t0)/1000.0);
    elapsed     = Math.floor(elapsed*10000)/10000.0;
    $(".elapsed").hide().text(String(elapsed) + "\u00a0sec").fadeIn();
}

//----------------------------------------------------------------------
function dcpFormatHtml(data, jqXHR) {
    //-- parse response
    $("#profileDataHtml").empty().append( $.parseHTML(jqXHR.responseText, document, true) );
    $("#profileDataHtml").find("table").addClass("dbViewTable dcpTable " + (isDiff ? "diffTable" : "prfTable"));
    if ($("#profileDataHtml td").size()==0) {
	dcpErrorMsg("Error: no data to display!");
	return;
    }
    $("#profileDataHtml").fadeIn();

    //-- setup debug debug
    setupDebugTable(qinfo);
   
    //-- parse headers
    var cols = [];
    $("#profileDataHtml tr:first-child th").each(function(i,th) {
	cols.push($(th).text());
    });
    var ilabel = cols.indexOf("label");
    var iscore = cols.indexOf(isDiff ? "diff" : "score");

    //-- setup label-change classes
    var plabel = '';
    $("#profileDataHtml tr:not(:first-child)").each(function(i,tr) {
	var label = $(tr).find(":nth-child("+(ilabel+1)+")").text();
	if (label != plabel) {
	    $(tr).addClass("newlabel").attr("id",label);
	    plabel = label;
	}
    });

    //-- setup ddc kwic links
    if (ilabel != -1 && Boolean(ddc_url_root)) {
	var qtemplate = (qinfo.qtemplate!=null ? qinfo.qtemplate : qinfo.aqtemplate);
	$("#profileDataHtml tr:first-child").append("<th/>");
	$("#profileDataHtml tr:not(:first-child)").each(function(i,tr) {
	    var linkhtml;
	    if (isDiff) {
		linkhtml = (kwiclink({"tr":tr,"ilabel":ilabel,
				      "qtemplate":qinfo.aqtemplate,"text":"KWIC:A","dtrim":/[^0-9].*$/,"dslice":user_query.slice,
				      "title":"DDC KWIC search for row pairs (QUERY)"
				     })
			    + "&#xa0;"
			    + kwiclink({"tr":tr,"ilabel":ilabel,
					"qtemplate":qinfo.bqtemplate,"text":"KWIC:B","dtrim":/^.*[^0-9]/,"dslice":user_query.bslice,
					"title":"DDC KWIC search for row pairs (~QUERY)"
				       }));
	    } else {
		linkhtml = kwiclink({"tr":tr,"ilabel":ilabel,"qtemplate":qinfo.qtemplate,"text":"KWIC",
				     "title":"DDC KWIC search for row pairs"
				    });
	    }
	    $(tr).append('<td class="links">'+linkhtml+'</td>');
	});
    }

    //-- setup score colors
    if (true) {
	//-- get min, max score values
	var max;
	$("#profileDataHtml tr:not(:first-child)").find(":nth-child("+(iscore+1)+")").each(function(i,td) {
	    var val = Number($(td).text());
	    if (max==null || Math.abs(val) > max) {
		max = Math.abs(val);
	    }
	});

	//-- insert header
	$("#profileDataHtml tr:first-child").append("<th/>");

	//-- map to colors
	var min = (isAbsDiff || user_query.score == "mi" ? -max : 0);
	var ctitle = (isAbsDiff
		      ? "Color-coded association preference (red:a .. blue:b)"
		      : "Color-coded association preference (red:attract..blue:repel)");
	$("#profileDataHtml tr:not(:first-child)").each(function(i,tr) {
	    $(tr).append('<td title="'+ctitle+'" class="diffColor"><span>&#xa0;</span></td>');
	    var val = Number($(tr).find("td:nth-child("+(iscore+1)+")").text());
	    var  st = $(tr).find(".diffColor span");
	    var  sz = st.height()+"px";
	    st.css({"background-color":heatcolorv(val, min, max), width:sz, height:sz});
	});
    }

    //-- jump to fragment if specified
    var fragment = locFragment(window.location);
    if (fragment != "") {
	window.location.hash = '';
	window.location.hash = '#'+fragment;
    }
}

//----------------------------------------------------------------------
function dcpFormatGMotion(data, jqXHR) {
    //-- parse data
    data  = $.parseJSON(data);
    qinfo = data.qinfo;
    setupDebugTable(qinfo);
    if (data.profiles.length == 0) {
	dcpErrorMsg("Error: no data to display!");
	return;
    }

    //-- setup plot area
    $(".rawURL").hide();
    $("#profileDataChart").addClass("gmChart").fadeIn();

    //-- setup chart data
    var cstate = '{}'; //-- chart state
    var cdata  = new google.visualization.DataTable();
    cdata.addColumn('string', data.titles.join('/')); //-- 1st column must be item type
    cdata.addColumn('number', 'year');                //-- 2nd column must be date ('number' => year)

    if (isDiff) {
	//-- motion chart: diff
	cdata.addColumn('number', 'ascore');
	cdata.addColumn('number', 'bscore');
	cdata.addColumn('number', 'diff');
	data.profiles.forEach(function(p) {
	    var year   = Number(String(p.label).replace(/^0-/,'').replace(/-.*$/,''));
	    var scoref = p.score;
	    for (var key in p[scoref]) {
		var item = key.replace(/\t/g,'/');
		cdata.addRow([item, year, p.prf1[scoref][key], p.prf2[scoref][key], p[scoref][key]]);
	    }
	});
	cstate = '{"showTrails":false}';
    }
    else {
	//-- motion chart: profile
	cdata.addColumn('number', 'f2');
	cdata.addColumn('number', 'f12');
	cdata.addColumn('number', 'score');
	data.profiles.forEach(function(p) {
	    var year   = Number(p.label);
	    var scoref = p.score;
	    for (var key in p[scoref]) {
		var item = key.replace(/\t/g,'/');
		cdata.addRow([item, year, p.f2[key], p.f12[key], p[scoref][key]]);
	    }
	});
	cstate = '{"showTrails":false,"xLambda":0,"yLambda":0}';
    }
    //-- plot the chart
    var chart = new google.visualization.MotionChart(document.getElementById('profileDataChart'));
    chart.draw(cdata, {width:600, height:480, state:cstate});
}

//----------------------------------------------------------------------
var hitem2key = {};
function dcpFormatHiChart(data, jqXHR) {
    //-- parse data
    //data  = $.parseJSON(data);
    //qinfo = data.qinfo;

    if ( !(data = dcpParseFlat(data,{mode:"bubble"})) ) { return; }
    if (data.profiles.length == 0) {
	dcpErrorMsg("Error: no data to display!");
	return;
    }
    dcpStatusMsg("loading","Rendering...");

    //-- hichart: enable "download" icon
    $("#d3icons > a").hide();
    $("#profileDataD3, #d3icons, #exportBtn").fadeIn();

    //-- setup plot data
    var cdata = { //-- chart data
	chart: {
            type: (user_query.debug ? 'line' : 'spline'),
	    zoomType: 'x'
        },
	credits: {
	    enabled: false
	},
	title: {
	    text:"DiaCollo Profile"+(isDiff ? " Diff" : "")
	    
	},
	subtitle: {
            text: (isDiff ? (chartTitleString('',1)+' - '+chartTitleString('b',1)) : chartTitleString())
        },
	xAxis: {
	    title: { text: 'Date (slice)' },
	},
	yAxis: {
            title: { text: 'Score'+(isDiff ? (' Diff ('+user_query.diff+')') : '')+' ('+scoreNames[user_query.score]+')' }
        },
	legend: {
            layout: 'vertical',
            align: 'right',
            verticalAlign: 'middle',
            borderWidth: 0,
	    padding: 5
	    //,itemStyle: { "color": "#333333", "cursor": "pointer", "fontSize": "12px", "fontWeight": "normal" }
        },
	plotOptions: {
	    series: {
                cursor: 'pointer',
                point: {
                    events: {
			click: function (e) {
			    dcur  = dlabels.indexOf(String(this.label).replace(/\./g,"-"));
			    var idata = items[ itemid[this.series.name.replace(/\//g,"\t")] ];
			    var dopts = {};
			    if (!$("#profileDataPopup").is(":visible")) {
				dopts.position = {at:"center", of:e}
			    }
			    d3InfoPopup(idata, dopts);
			}
                    }
                },
                marker: {
                    lineWidth: 1
                }
            }
        },
	series: []
    };

    //-- create hicharts series
    var item, di, score;
    items.forEach(function(item) {
	item.hiseries = { name:item.label, data:[] };
	for (var di in dlabels) {
	    score = item.score[di];
	    item.hiseries.data.push({x:Number(String(dlabels[di]).replace(/-/g,".")), y:(score==null ? null : score), label:dlabels[di]});
	}
	cdata.series.push(item.hiseries);
    });

    //-- setup plot area 
    $(".rawURL").hide();
    $("#profileDataChart").addClass("hcParent").show();

    //-- plot the chart
    $("#profileDataChart").addClass("hcChart").highcharts(cdata).show();
    dcpClearMsg();
}

//----------------------------------------------------------------------
// str = chartTitleString(prefix,parens)
function chartTitleString(prefix,parens) {
    if (prefix==null) { prefix = ''; }
    var q = user_query[prefix+'query'];

    var title = q;
    /*
    var d = user_query[prefix+'date'];
    if (d != null && d != '') {
	title += ' ['+d.replace(/:/,'-')+']';
    }
    var s = user_query[prefix+'slice'];
    if (s != null && s != '') {
	title += ' /'+s;
    }
    */
    return Boolean(parens) ? ('('+title+')') : title;
}


//----------------------------------------------------------------------
// d3: common variables & utilities

var dforce, dcloud, dcur, dsnapto, dkeys, dlabels, itemid, items;
var dcpScoreRange; //-- [minScore,maxScore]
var dcpValueNull;  //-- null value
var dcpSizeRange;  //-- [minSize,maxSize]
var dcpItemSize;   //-- interpolating accessor for item size (cloud:font-size, bubble:radius)
var d3InfoCur;     //-- currently selected info-popup data

var brushInterp;  //-- function variable for brush interpolation
var brushSnap;    //-- function variable for brush snap

// data = dcpParseFlat(dataStr,opts)
//  + parses profile data into flat d3-friendly format
//  + returns true on success; sets $("#status .msg").text() and returns false on error
//  + sets globals:
//     qinfo   = data.qinfo
//     dkeys   = [$date0,...]  (slice key-strings, raw,     e.g. "1900-1900" or "0-1750")
//     dlabels = [$date0,...]  (slice key-strings, trimmed, e.g. "1900"      or   "1750")
//     items   = [$itemData0,...]
//     itemid  = {$itemKey0:$itemId0, ...}
//     dcur    = $currentSliceIndex  //-- may be fractional if inbetween slices
//     dcpScoreRange = [min,max]
//     dcpSizeRange  = [min,max]
//     dcpItemSize = function(d,dcur) { ... }
//     dcpDateInterp = function(dcur) { ... }
//  + where items[itemId] =
//     item    = {id:$itemId, item:$itemKey, label:$itemLabel, score:[...], value:[...], avalue:[...], sizes:[...], opacity:[...], maxSize:maxSize?}
//  + array-valued item data keys are indexed by dlabels[] index
//  + calls setupDebugTable() after parsing qinfo()
//  + options:
//     mode: MODE,   //-- parse mode (known values: "bubble", "cloud")
var d3data = null;
function dcpParseFlat(data,opts) {
    //-- status message
    dcpStatusMsg("loading","Parsing...");

    //-- parse JSON data
    if (!(data instanceof Object)) { data = $.parseJSON(data); }
    d3data = data;
    qinfo = data.qinfo;
    setupDebugTable(qinfo);
    if (data.profiles.length == 0) {
	dcpErrorMsg("Error: no data to display!");
	return null;
    }

    //-- options
    if (opts==null)      { opts={}; }
    if (opts.mode==null) { opts.mode="bubble"; }

    var isBubble   = opts.mode == "bubble";
    var isCloud    = opts.mode == "cloud";

    //-- initialize
    dkeys   = [];
    dlabels = [];
    itemid  = {};
    items   = [];
    dcur    = 0; //-- current subprofile index

    //-- get data range
    data.profiles.forEach(function (p) { p.range = d3.extent(d3.values(p[p.score])); });
    var smin = d3.min(data.profiles, function(p) { return p.range[0]; });
    var smax = d3.max(data.profiles, function(p) { return p.range[1]; });
    if (smin > 0)    { smin = 0; }
    if (smax < smin) { smax = smin; }
    if (smin==smax)  { smin -= 1e-5; smax += 1e-5; }
    var amax      = Math.max(Math.abs(smin),Math.abs(smax));
    dcpScoreRange = [smin,smax];
    dcpValueNull  = dcpScoreValue(0);

    //-- setup scales: size/radius ("sizes" key)
    dcpSizeRange = (isBubble
		    ? [8,56]    //-- bubble: radius range
		    : [12,78]   //-- cloud: font-size range (in pixels)
		   );
    dcpItemSize = (isAbsDiff
		   ? function(item,pos) { return dcpSizeRange[0] + linterp(item.avalue,pos)*(dcpSizeRange[1]-dcpSizeRange[0]); }
		   : function(item,pos) { return dcpSizeRange[0] + linterp(item.value,pos) *(dcpSizeRange[1]-dcpSizeRange[0]); }
		  );

    //-- setup formatters (for details popup)
    var ffmt = d3.format(",r");
    var sfmt = d3.format(user_query.score=="ld" ? ".4r"
			 : (user_query.score=="f" ? ",r"
			    : ".4s"));

    //-- parse data
    var pi, p, pscores, iid, idata, iscore, ivalue, avalue;
    for (pi=0; pi < data.profiles.length; ++pi) {
	p = data.profiles[pi];
	p.label = String(p.label);
	dkeys.push(p.label);

	//-- simplify label
	p.label = p.label.replace(/^([0-9]+)-\1/,'$1').replace(/^0-/,'').replace(/-0$/,'');
	dlabels.push(p.label);
	pscores = p[p.score];

	for (var item in pscores) {
	    if ((iid=itemid[item]) != null) {
		//-- existing item
		idata = items[iid];
	    } else {
		//-- new item
		itemid[item] = iid = items.length;
		items.push(idata={"id":iid,
				  "item":item,
				  "label":item.replace(/\t/g, '/'),
				  "text":item.replace(/\t.*$/,''),
				  score:[], value:[], avalue:[], sizes:[], opacity:[]
				 });
		if (isDiff) {
		    idata.N1 = []; //ffmt(p.prf1.N);
		    idata.N2 = []; //ffmt(p.prf2.N);
		    idata.af1 = [];
		    idata.bf1 = [];
		    idata.af2 = [];
		    idata.bf2 = [];
		    idata.af12 = [];
		    idata.bf12 = [];
		    idata.ascore=[];
		    idata.bscore=[];
		} else {
		    idata.N   = []; //ffmt(p.N);
		    idata.f1  = [];
		    idata.f2  = [];
		    idata.f12 = [];
		}
	    }

	    idata.score[pi] = iscore = pscores[item];
	    idata.value[pi] = ivalue = dcpScoreValue(iscore);
	    idata.avalue[pi] = avalue = Math.abs(iscore)/amax;
	    idata.sizes[pi] = dcpItemSize(idata,pi);
	    idata.opacity[pi] = 1;

	    if (isDiff) {
		idata.N1[pi] = ffmt(p.prf1.N);
		idata.N2[pi] = ffmt(p.prf2.N);
		idata.af1[pi] = ffmt(p.prf1.f1);
		idata.bf1[pi] = ffmt(p.prf2.f1);
		idata.af2[pi] = ffmt(p.prf1.f2[item]);
		idata.bf2[pi] = ffmt(p.prf2.f2[item]);
		idata.af12[pi] = ffmt(p.prf1.f12[item]);
		idata.bf12[pi] = ffmt(p.prf2.f12[item]);
		idata.ascore[pi] = sfmt(p.prf1[p.score][item]);
		idata.bscore[pi] = sfmt(p.prf2[p.score][item]);
	    } else {
		idata.N[pi]   = ffmt(p.N);
		idata.f1[pi]  = ffmt(p.f1);
		idata.f2[pi]  = ffmt(p.f2[item]);
		idata.f12[pi] = ffmt(p.f12[item]);
	    }

	}
    }

    //-- check again for empty data-set (b/c we might have empty profiles)
    if (items.length == 0) {
	dcpErrorMsg("Error: no items to display!");
	return null;
    }


    //-- setup date-interpolator
    var dltuples = dlabels.map(function(l) { return l.split("-"); });
    var dln      = d3.max(dltuples, function(tup) { return tup.length; });
    if (dln <= 1) {
	//-- scalar date-labels: easy interpolation
	dcpDateInterp = function(di) { return Math.round(linterp(dlabels,di)); };
    } else {
	//-- multi-component date-labels: build tuple-wise interpolator
	var dlscale = [];
	for (i=0; i < dln; ++i) {
	    dlscale[i] = d3.scale.linear()
		.domain(dltuples.map(function(e,ei) { return ei }))
		.range(dltuples.map(function(e) { return e[i] }))
		.clamp(true);
	}
	dcpDateInterp = function(di) {
	    return dlscale.map(function(s) { return Math.round(s(di)) }).join("-");
	};
    }

    //-- setup callbacks
    if (isBubble) {
	brushInterp = dcpForceInterp;
	brushSnap   = dcpForceSnap;
    }
    if (isCloud) {
	brushInterp = dcpCloudInterp;
	brushSnap   = dcpCloudSnap;
    }

    //-- initialize current subprofile index (dcur) from URL fragment
    var fragment = locFragment(window.location);
    if (fragment != "" && dlabels.indexOf(fragment) >= 0) {
	dcur = dlabels.indexOf(fragment);
    } else {
	dcur = 0;
    }

    return data;
}

//----------------------------------------------------------------------
// d3: common: interpolating accessors
function vinterp(frac, x0,x1, missing) {
    if (missing==null) missing=0;
    return ((1.0-frac)*(x0==null ? missing : x0)) + (frac*(x1==null ? missing : x1));
}
function linterp(l,pos,missing) {
    return vinterp(pos-Math.floor(pos), l[Math.floor(pos)], l[Math.ceil(pos)], missing);
}
function dcpItemScore(item,pos) { return linterp(item.score, pos); }
function dcpItemValue(item,pos) { return linterp(item.value, pos, dcpValueNull); }
function dcpItemAbsValue(item,pos) { return linterp(item.avalue, pos); }
//dcpItemSize : function variable
function dcpItemScale(item,pos) { return dcpItemSize(item,pos) / item.maxSize; }

function dcpScoreValue(score) {
    return (score-dcpScoreRange[0]) / (dcpScoreRange[1]-dcpScoreRange[0]);
}

//-- dcpItemSat, dcpItemVal: for "old" rainbow-style colors
//   + green takes up too much space in these for some reason (~ 4 score points on for diff [-8..8])
//   + better differentiation using colorbrewer colors and d3 scale, not as pretty for html though
var dcpItemSat = 1;
var dcpItemVal = 1;
function dcpItemColor(item,pos) { return heatcolorf(dcpItemValue(item,pos), dcpItemSat, dcpItemVal); }
function dcpMinColor() { return heatcolorf(0, dcpItemSat, dcpItemVal); }
function dcpMaxColor() { return heatcolorf(1, dcpItemSat, dcpItemVal); }

function dcpItemOpacity(item,pos,max) {
    return (max==null ? 1 : max)*linterp(item.opacity,pos);
}

// interpolator = dcpDateInterpolator(dlabel0,dlabel1)
//  + returned function is called as "interpolatedDateLabel = interpolator(t)" with 0 <= t <= 1
function dcpDateInterpolator(dlabel0,dlabel1) {
    var d0 = dlabel0.split("-");
    var d1 = dlabel1.split("-");
    if (d0.length==1) {
	return d3.interpolateRound(Number(d0[0]),Number(d1[0]));
    } else {
	var interp = d0.map(function(e,i){ return d3.interpolateRound(Number(d0[i]),Number(d1[i])); });
	return function(t) { return interp.map(function(i) { return i(t) }).join("-"); };
    }
}

//--------------------------------------------------------------
// d3: common: node titles (bubble,cloud)
function d3NodeTitleText(d) {
    return (d.label + " ~ " + dcpItemScore(d,dcur)
	    + (user_query.debug ? (": " + JSON.stringify({id:d.id, value:dcpItemValue(d,dcur), avalue:dcpItemAbsValue(d,dcur), size:dcpItemSize(d,dcur)})) : '')
	   );
}

//--------------------------------------------------------------
// d3: info popup
function d3InfoPopup(d,opts) {
    var dsnap  = Math.round(dcur);
    var dlabel = dlabels[dsnap];
    

    //-- save current info item
    d3InfoCur = {data:d};

    var dopts = {
	title: d.label,
	autoOpen: true,
	modal: false,
	minHeight: 64,
	minWidth: 300,
	height: "auto",
	width: "auto",
	show: {effect:"scale",percent:100, duration:150},
	hide: {effect:"scale",percent:0, duration:150},
	close: function(e,ui) {
	    d3InfoCur = null;
	    d3.selectAll(".node").classed("selected",false);
	    $(".content").focus();
	}
    };
    if (!$("#profileDataPopup").is(":visible")) {
	dopts.position = {at:"center",of:this};
    }
    for (var o in opts) {
	if (o == null) {
	    delete dopts[o];
	} else {
	    dopts[o] = opts[o];
	}
    }

    var content = (''
		   +'<span class="ui-helper-hidden-accessible"><input type="text"/></span>' //-- disable ugly jquery-ui autofocus
		   +'<table class="dcslide">'
		   +'<tr><th>slice:</th><td class="slice">' + dlabel +'</td></tr>'
		   + '<th>score:</th><td class="score">' + d.score[dsnap] + '</td></tr>'
		  );
    var tr      = [dkeys[dsnap]].concat(d.item.split("\t"));
    if (isDiff) {
	d3InfoCur.kwic = {"tr":tr,"ilabel":0,
			   "qtemplate":qinfo.aqtemplate,"text":"KWIC:A","dtrim":/[^0-9].*$/,"dslice":user_query.slice,
			   title:"DDC KWIC search for point pairs (QUERY)",
			   classes:"textButtonSmall kwic"
			  };
	d3InfoCur.bkwic = {"tr":tr,"ilabel":0,
			   "qtemplate":qinfo.bqtemplate,"text":"KWIC:B","dtrim":/^.*[^0-9]/,"dslice":user_query.bslice,
			   title:"DDC KWIC search for point pairs (~QUERY)",
			   classes:"textButtonSmall bkwic"
			  };
	content += (''
 		    +'<tr><th>search:</th><td>'
		    + kwiclink(d3InfoCur.kwic)
		    + '&#xa0;'
		    + kwiclink(d3InfoCur.bkwic)
		    + '</td></tr>'
		    +'<tr><th>details:</th><td class="diff details">'+(
			'<table>'
			    +'<tr><th>N(a/b):</th><td class="num N1">'+d.N1[dsnap]+'</td><td>/</td><td class="num N2">'+d.N2[dsnap]+'</tr>'
			    +'<tr><th>f1(a/b):</th><td class="num af1">'+d.af1[dsnap]+'</td><td>/</td><td class="num bf1">'+d.bf1[dsnap]+'</tr>'
			    +'<tr><th>f2(a/b):</th><td class="num af2">'+d.af2[dsnap]+'</td><td>/</td><td class="num bf2">'+d.bf2[dsnap]+'</tr>'
			    +'<tr><th>f12(a/b):</th><td class="num af12">'+d.af12[dsnap]+'</td><td>/</td><td class="num bf12">'+d.bf12[dsnap]+'</tr>'
			    +'<tr><th>score(a/b):</th><td class="num ascore">'+d.ascore[dsnap]+'</td><td>/</td><td class="num bscore">'+d.bscore[dsnap]+'</tr>'
		    	    +'</table>'
		    )
		   );
    } else {
	d3InfoCur.kwic = {"tr":tr,"ilabel":0,"qtemplate":qinfo.qtemplate,"text":"KWIC",
			  title:"DDC KWIC search for point pairs",
			  classes:"textButtonSmall kwic"
			 };
	content += (''
		    +'<tr><th>search:</th><td>'
		    + kwiclink(d3InfoCur.kwic)
		    + '</td></tr>'
		    +'<tr><th>details:</th><td class="details">'+(
			'<table>'
			    +'<tr><th>N:</th><td class="num N">'+d.N[dsnap]+'</td></tr>'
			    +'<tr><th>f1:</th><td class="num f1">'+d.f1[dsnap]+'</td></tr>'
			    +'<tr><th>f2:</th><td class="num f2">'+d.f2[dsnap]+'</td></tr>'
			    +'<tr><th>f12:</th><td class="num f12">'+d.f12[dsnap]+'</td></tr>'
		    	    +'</table>'
		    )
		   );
    }
    var dlg = $("#profileDataPopup").html(content).dialog(dopts);

    //-- add node-class
    d3.selectAll(".node").classed("selected",false);
    d3.select("#g"+d.id).classed("selected",true);

    return false;
}

//--------------------------------------------------------------
// d3: info popup: update
function d3InfoPopupUpdate(snapto) {
    //-- maybe update info box
    if (d3InfoCur != null && snapto != dsnapto) {
	var dlg   = $("#profileDataPopup");
	var d     = d3InfoCur.data;
	dlg.find(".slice").text(String(dlabels[snapto]));
	dlg.find(".score").text(String(d.score[snapto]));
	if (d3InfoCur.kwic != null)  { d3InfoCur.kwic.tr[0]  = dkeys[snapto]; dlg.find(".kwic").prop('href',kwicurl(d3InfoCur.kwic)); }
	if (d3InfoCur.bkwic != null) { d3InfoCur.bkwic.tr[0] = dkeys[snapto]; dlg.find(".bkwic").prop('href',kwicurl(d3InfoCur.bkwic)); }
	if (isDiff) {
	    dlg.find(".N1").text(String(d.N1[snapto]));
	    dlg.find(".N2").text(String(d.N2[snapto]));
	    dlg.find(".af1").text(String(d.af1[snapto]));
	    dlg.find(".bf1").text(String(d.bf1[snapto]));
	    dlg.find(".af2").text(String(d.af2[snapto]));
	    dlg.find(".bf2").text(String(d.bf2[snapto]));
	    dlg.find(".af12").text(String(d.af12[snapto]));
	    dlg.find(".bf12").text(String(d.bf12[snapto]));
	    dlg.find(".ascore").text(String(d.ascore[snapto]));
	    dlg.find(".bscore").text(String(d.bscore[snapto]));
	} else {
	    dlg.find(".N").text(String(d.N[snapto]));
	    dlg.find(".f1").text(String(d.f1[snapto]));
	    dlg.find(".f2").text(String(d.f2[snapto]));
	    dlg.find(".f12").text(String(d.f12[snapto]));
	}
	//dlg.parent().stop(true,true).effect("highlight");
	d3.select("#g"+d.id).classed("selected",true);
    }
}

//--------------------------------------------------------------
// d3: brush-slider (date-slice selector)
// + see http://bl.ocks.org/mbostock/6452972
//    dbrush = d3brush(dlabels, selector, opts)
// + sets global dbrush=brush, bhandle=handle, bsvg=brush-svg
var dbrush, bhandle, bsvg;
function dcpTransportSlider(dlabels, parent_selector, opts) {

    //-- setup defaults
    if (opts.id==null) opts.id = "d3slider";
    if (opts.width==null) opts.width = 800;
    if (opts.height==null) opts.height = 50;
    var margin = opts.margin==null ? {} : opts.margin;
    if (margin.left==null) margin.left = 0;
    if (margin.right==null) margin.right = 0;
    if (margin.top==null) margin.top = 0;
    if (margin.bottom==null) margin.bottom = 0;
    if (opts.translate==null) opts.translate = {x:0,y:0};

    //debug_log("dcpTransportSlider(dlabels="+JSON.stringify(dlabels)+", parent_selector="+JSON.stringify(parent_selector)+", opts="+JSON.stringify(opts)+")");

    //-- common variables
    var width  = opts.width - margin.left - margin.right;
    var height = opts.height - margin.top - margin.bottom; 
    var xscale = d3.scale.linear()  //d3.v4: d3.scaleLinear()
	.domain([0,dlabels.length-1])
	.range([0,width])
	.clamp(true);

    var brush = dbrush = d3.svg.brush()		//d3.v4: d3.brushX() 
	.x(xscale)				//d3.v4: ???
	.extent([dcur, dcur])
	.on("brushstart", dcpOnBrushStart)	//d3.v4: ???
	.on("brush", dcpOnBrush)		//d3.v4: ???
	.on("brushend", dcpOnBrushEnd)		//d3.v4: ???
    ;

    var parent = d3.select(parent_selector);
    var svg = bsvg = parent.append("g")
	.attr("id", opts.id)
	.attr("width", opts.width)
	.attr("height", opts.height)
	.append("g")
	.attr("class","brush")
    	.attr("transform", "translate(" + (margin.left+opts.translate.x) + "," + (margin.top+opts.translate.y) + ")");
    svg.append("title")
    	.text("Date-slice to display (drag, left/right arrow, Home, End)");

    var labelPad = 6;
    var dy = 15+labelPad; //height/2;
    svg.append("g")
	.attr("class", "x axis")
	.attr("transform", "translate(0," + dy + ")")
	.call(d3.svg.axis()
	      .scale(xscale)
	      .orient("bottom")
	      //--^ d3.v4: d3.axisBottom(xscale)
	      .tickSize(12)
	      .tickPadding(3)
	      .ticks(dlabels.length-1)
	     );

    $("#profileDataD3").fadeIn(); //-- must be displayed in order to compute sizes
    var ticks = svg.selectAll(".x.axis .tick");
    ticks
	.data(dlabels)
	.attr("id",function(d,i) { return "tick"+i; });
    ticks.each(function(d,i) { d3.select("#tick"+i+" text").text(d); });
    //svg.select(".tick:first-of-type text").style("text-anchor","start");
    //svg.select(".tick:last-of-type text").style("text-anchor","end");

    //-- check for tick overflow
    var nticks         = ticks.size();
    var tickLabelWidth = [];
    ticks.each(function(d,i) { tickLabelWidth.push(d3.select("#tick"+i+" text").node().getComputedTextLength()); });
    var tickPad      = 5;
    var tickWidthMax = d3.max(tickLabelWidth) + tickPad;
    var tickmod = 1;
    while ( (nticks/tickmod)*tickWidthMax >= opts.width ) {
	++tickmod;
    }
    ticks.each(function(d,i) {
	if ((i % tickmod) != 0) {
	    d3.select("#tick"+i).classed("minor",true);
	}
    });

    //-- setup slider
    var slider = svg.append("g")
	.attr("class", "slider")
	.call(brush);

    slider.selectAll(".extent,.resize")
	.remove();
    slider.select(".background")
	.attr("height", height);
	

    var handle = bhandle = slider.append("g")
	.attr("class", "handle")
	.attr("transform", "translate(0,0)");
    handle.append("circle")
	.attr("cx",0)
	.attr("cy",dy)
	.attr("r", 8);
    handle.append("text")
	.attr("x",0)
	.attr("y",10)
	.text("");

    var x0 = dcur; //xscale(dlabels[0]);
    slider
	.call(brush.event)		//-- d3.v4: ???
	.call(brush.extent([x0,x0]))
	.call(brush.event);		//-- d3.v4: ???

    //-- mouse events: hover
    svg
	.on("mouseenter", function(b) { svg.classed("hovering",true); })
	.on("mouseleave", function(b) { svg.classed("hovering",false); });

    //$("#profileDataD3").show(); //-- debug
    return brush;
}

//--------------------------------------------------------------
// d3: brush-slider: callbacks
function brushDebug(value,label) {
    if (label==null) label="debug";
    var msg = "[" + label + "] value=" + value;
    debug_log(msg);
    d3.select("#brushVal").text(msg);
}

function dcpOnBrushStart(force) {
    //var value = dbrush.extent()[0];
    if (force || d3.event.sourceEvent) { // not a programmatic event
	dcpPlay(false);
	bsvg.classed("brushing",true);	
    }
}

function dcpBrushMove(value,dur,easeby) {
    var nearest = Math.round(value);
    d3.selectAll(".tick text").classed("selected",false);
    d3.select(".tick:nth-of-type("+(nearest+1)+") text").classed("selected",true);
    if (dur==null || easeby==null) {
	bhandle.transition().duration(0);
	bhandle
	    .attr("transform","translate("+dbrush.x()(value)+",0)")
	    .select("text")
	    .text(dcpDateInterp(value))
	;
    } else {
	bhandle.transition()
	    .duration(dur)
	    .ease(easeby)
	    .attr("transform","translate("+dbrush.x()(value)+",0)")
	    .select("text")
	    .tween("handle-text", function() {
		var interp = dcpDateInterpolator(this.textContent, String(dcpDateInterp(value)));
		return function(t) { this.textContent = interp(t); };
	    })
	;
    }
    dcur = value;
    dbrush.extent([value,value]);
    brushInterp(value,dur,easeby);
}

function dcpOnBrush() {
    var value  = dbrush.extent()[0];
    //brushDebug(value,"brush");
    if (d3.event.sourceEvent) { // not a programmatic event
	value = dbrush.x().invert(d3.mouse(this)[0]);
	bsvg.classed("brushing",true);
    }
    dcpBrushMove(value);
}

function dcpOnBrushEnd(force,dur,easeby,dosnap) {
    if (!force && !d3.event.sourceEvent) return; // only transition after input
    if (dosnap==null) dosnap=true;
    var value  = dbrush.extent()[0];
    var snapto = Math.round(value);
    var moveto = dosnap ? snapto : value;

    if (force || (d3.event && d3.event.sourceEvent)) { // not a programmatic event
	bsvg.classed("brushing",false);
    }

    dcpBrushMove(moveto,
		 (!force ||    dur==null ? 500       : dur),
		 (!force || easeby==null ? "elastic" : easeby));

    //dcpBrushMove(value1);
    //brushDebug(value0 + "->" + value1,"end");
}

function dcpBrushSet(value,dur,easeby,dosnap) {
    if (dur==null) dur=100;
    if (easeby==null) easeby="elastic";
    //dcpOnBrushStart(true);
    //dbrush.extent([value,value]);
    //dcpBrushMove(value,dur,easeby);
    dcpPlay(false);
    dbrush.extent([value,value]);
    dcpOnBrushEnd(true,dur,easeby,dosnap);
}

//--------------------------------------------------------------
// d3: key bindings & focus
function dcpBrushKeys(sel2tabindex) {
    for (var sel in sel2tabindex) {
	var ix = sel2tabindex[sel];
	var jsel = $(sel);
	jsel.attr("tabindex",ix)
	    .keydown(function(e) {
		//debug_log("keydown: which="+e.which+"; key="+e.key);
		var dskip = 0;
		var dosnap = true;
		switch(e.which) {
		case 10: // newline
		case 13: // enter
		case 32: // space
		    dcpPlay(!dcpPlaying);
		    break;

		case 83: // s(Save)
		case 88: // x(eXport)
		    document.getElementById("exportBtn").click();
		    break;

		case 35: // end
		    dcpBrushSet(dlabels.length-1);
		    break;

		case 36: // home
		    dcpBrushSet(0);
		    break;

		case 49: // number-1: reset speed
		case 48: // number-0 or equal
		case 97: // keypad-1
		case 96: // keypad-0
		case 97: // keypad-1
		    d3SpeedSet(1,100,"elastic");
		    break;

		case 50: //-- number-2
		case 51: //-- number-3
		case 52: //-- number-4
		case 53: //-- number-5
		case 54: //-- number-6
		case 55: //-- number-7
		case 56: //-- number-8
		case 57: //-- number-9
		case 98: //-- keypad-2
		case 99: //-- keypad-3
		case 100: //-- keypad-4
		case 101: //-- keypad-5
		case 102: //-- keypad-6
		case 103: //-- keypad-7
		case 104: //-- keypad-8
		case 105: //-- keypad-9
		    var digit = e.which % 48;
		    d3SpeedSet((e.shiftKey ? 1.0/digit : digit),100,"elastic");
		    break;

		case 40:  // down: -speed
		case 189: // minus
		case 109: // keypad minus
		case 111: // keypad div
		    d3SpeedSet(Math.max(dcpSpeed/(e.shiftKey ? 1.125 : 2), speedBrush.y().domain()[1]),100,"elastic");
		    break;

		case 38:  // up: +speed
		case 187: // plus
		case 107: // keypad plus
		case 106: // keypad times
		    d3SpeedSet(Math.min(dcpSpeed*(e.shiftKey ? 1.125 : 2), speedBrush.y().domain()[0]),100,"elastic");
		    break;

		case 220: // less-than | greater-than : skip-(left|right)
		    dskip = e.shiftKey ? 1 : -1;
		    break;

		case 37: // left: skip-left
		case 33: // page-up
		    dosnap = !e.shiftKey;
		    dskip  = -1;
		    break;

		case 39: // right: skip-right
		case 34: // page-down
		    dosnap = !e.shiftKey;
		    dskip  = 1;
		    break;

		default: return; // exit this handler for other keys
		}

		//-- date-slice skip
		var dur    = dosnap ? 400       : 100;
		var easeby = dosnap ? "elastic" : "cubic-in-out";
		if (dskip < 0) {
		    //-- skip-left
		    dcpBrushSet((dosnap
				 ? (dsnapto < dcur ? dsnapto : Math.max(0,Math.round(dcur+dskip)))
				 : Math.max(0,dcur+dskip/4)),
				dur,easeby,dosnap);
		} else if (dskip > 0) {
		    //-- skip-right
		    dcpBrushSet((dosnap
				 ? (dsnapto > dcur ? dsnapto : Math.min(dlabels.length-1,Math.round(dcur+dskip)))
				 : Math.min(dlabels.length-1,dcur+dskip/4)),
				dur,easeby,dosnap);
		}
		e.preventDefault(); // prevent the default action (scroll / move caret)
	    });

	//-- set focus handlers
	jsel.focusin(function(e) { d3SetFocus(true); })
	    .focusout(function(e) { d3SetFocus(false); });

	//-- set focus
	if (ix==1) jsel.focus();
    }
}

//-- d3: keyboard bindings & focus: focus handlers
var d3HasFocus=false;
function d3SetFocus(val) {
    if (val==null) val=!d3HasFocus;
    d3HasFocus = val;
    //debug_log("setFocus("+val+")");
    //exportMenuHide(0);
    if (val) {
	//-- enable keyboard focus
	$("#kbicon").attr("title","Keyboard shortcuts enabled (arrow-keys, spacebar)");
	$("#kbiconx").hide();
    } else {
	//-- disable keyboard focus
	$("#kbicon").attr("title","Keyboard shortcuts disabled (click to enable)");
	$("#kbiconx").show();
    }
}

//---------------------------------------------------------------------.
// d3: play/pause transport
var dcpPlaying=false;
var dcpSpeed=1, speedNode, speedBrush, speedScale, speedHandle;
function dcpTransportButtons(parent_selector, opts) {
    if (opts==null) { opts = {}; }
    if (opts.id==null) { opts.id = "d3buttons"; }
    if (opts.width==null) { opts.width = 75; }
    if (opts.height==null) { opts.height = 50; }
    if (opts.pad==null)  { opts.pad = 10; }
    var margin = opts.margin==null ? {} : opts.margin;
    if (margin.top==null) { margin.top=4; }
    if (margin.bottom==null) { margin.bottom=1; }
    if (margin.left==null)  { margin.left=1; }
    if (margin.right==null) { margin.right=1; }
    if (opts.bpad==null) { opts.bpad = (opts.height-margin.top-margin.bottom)/8; }
    if (opts.bround==null) { opts.bround = (opts.height-margin.top-margin.bottom)/4; }

    //debug_log("dcpTransportButtons(parent_selector="+JSON.stringify(parent_selector)+", opts="+JSON.stringify(opts)+")");
    
    //var div = d3.select(selector);
    var parent = d3.select(parent_selector);

    var svg = parent.append("g")
	.attr("id", opts.id)
	.attr("width", opts.width)
	.attr("height", opts.height);
    var btn = svg.append("g")
	.attr("class","btn")
	.attr("transform", "translate(" + margin.left + "," + margin.top + ")")
	.on("mouseenter", function(b) { btn.classed("hovering",true); })
	.on("mouseleave", function(b) { btn.classed("hovering",false); })
	.on("click", function() { dcpPlay(!dcpPlaying); });
    btn.append("title")
	.text("Toggle play/pause animation (click or space to toggle)");

    var bsize = opts.height-margin.top-margin.bottom;
    var border = btn.append("rect")
	.attr("class","border")
	.attr("x",0)
	.attr("y",0)
	.attr("width",bsize)
	.attr("height",bsize)
        .attr("rx",opts.bround)
	.attr("ry",opts.bround);

    var bplay = btn.append("polygon")
	.attr("class","symbol play")
	.attr("points",
	      [[1.5*opts.bpad,opts.bpad],
	       [bsize-opts.bpad, bsize/2],
	       [1.5*opts.bpad,bsize-opts.bpad]
	      ].map(function(p) { return p.join(",") }).join(" "));

    var prheight = bsize - 3*opts.bpad;
    var prwidth = bsize/2 - 2*opts.bpad;
    var prect   = btn.append("rect")
	.attr("class","symbol pause")
	.attr("height",prheight)
	.attr("width",prwidth)
	.attr("x", 1.5*opts.bpad)
	.attr("y", 1.5*opts.bpad);
    d3.select( btn.node().appendChild(prect.node().cloneNode(1)) )
	.attr("x", bsize-prwidth-1.5*opts.bpad);
    /*
    var stoppad  = 2*opts.pad;
    var stopsize = bsize-2*stoppad;
    var pstop = btn.append("rect")
	.attr("class","symbol stop")
	.attr("height",stopsize)
	.attr("width",stopsize)
	.attr("x", stoppad)
	.attr("y", stoppad);
    */

    //-- setup playback speed axis
    var shsize = 8; //-- speeder handle size (height)
    var sscale = speedScale = d3.scale.log()
	.domain([8,0.125])
	.range([shsize/2, bsize-shsize/2])
	.clamp(true);

    var sbrush = speedBrush = d3.svg.brush()
	.y(sscale)
	.extent([1,1])
	.on("brushstart", d3OnSpeedBrushStart)
	.on("brush",      d3OnSpeedBrush)
	.on("brushend",   d3OnSpeedBrushEnd)
    ;

    //-- speeder: background-gradient
    svg.append("linearGradient")
	.attr("id", "speedGradient")
	.attr("gradientUnits", "userSpaceOnUse")
	.attr("x1", 0).attr("y1", 0)
	.attr("x2", 0).attr("y2", bsize)
	.selectAll("stop")
	.data([
            {offset: "0%",  color: "#999"},
            {offset: "85%", color: "#fff"}
	])
	.enter().append("stop")
	.attr("offset",     function(d) { return d.offset; })
	.attr("stop-color", function(d) { return d.color; });

    //-- speeder: wedge
    var ssize = opts.width - bsize - opts.pad - margin.left - margin.right;
    var spad  = ssize/8;
    var speeder = speedNode = svg.append("g")
	.attr("class","speeder")
	.attr("transform", "translate(" + (margin.left+bsize+opts.pad) + "," + margin.top + ")");

    speeder.append("title")
	.text("Set playback speed (drag, (shift+)up/down arrow, (shift+)number keys)");
    speeder.append("polygon")
	.attr("class","wedge")
	.attr("points",
	      [[spad,0],
	       [ssize/2,bsize],
	       [ssize-spad,0]
	      ].map(function(p) { return p.join(",") }).join(" "))
	.style("fill","url(#speedGradient)");

    //-- speeder: brush
    speeder
	.call(sbrush)
	.selectAll(".extent,.resize").remove();
    speeder.select(".background")
	.attr("height",bsize)
	.attr("width",ssize)
	.style("cursor","inherit");

    //-- speeder: double-click (reset)
    speeder.on("dblclick", function() { d3SpeedSet(1); });
    d3.select("#curspeed").on("dblclick", function() { d3SpeedSet(1); });


    //-- speeder: handle
    speedHandle = speeder.append("rect")
	.attr("class","handle")
	.attr("x",0)
	.attr("y",(bsize-shsize)/2)
	.attr("width",ssize)
	.attr("height",shsize)
	.attr("ry",shsize/2);

    //-- speeder: initialize
    var s0 = dcpSpeed;
    speeder
	.call(sbrush.event)
	.call(sbrush.extent([s0,s0]))
	.call(sbrush.event);

    //-- initialize play/pause visibility
    dcpPlay(false);

    return svg;
}

function d3SpeedBrushDebug(label) {
    //debug_log(label+": val=" + speedBrush.extent()[0] + " ~ " + speedScale(speedBrush.extent()[0]));
    return;
}

function d3SpeedBrushMove(value,dur,easeby) {
    dcpSpeed = value;
    speedBrush.extent([value,value]);
    var voff = speedHandle.attr("height")/2;
    var fmt  = d3.format(".3f");
    if (dur==null || easeby==null) {
	speedHandle.attr("y",speedBrush.y()(value)-voff);
    } else {
	speedHandle.transition()
	    .duration(dur)
	    .ease(easeby)
	    .attr("y",speedBrush.y()(value)-voff);
    }
    $("#curspeed").text(fmt(value)+"x"); //-- +"\u00d7"
    if (dcpPlaying) dcpPlay(true,true); //-- re-compute play animation
}

function d3SpeedSet(value,dur,easeby) {
    //debug_log("d3SpeedSet("+JSON.stringify({"value":value,"dur":dur,"easeby":easeby})+")");
    dcpSpeed = value;
    d3SpeedBrushMove(value,dur,easeby);
}

function d3OnSpeedBrushStart() {
    //d3SpeedBrushDebug("d3OnSpeedBrushStart()");
    if (d3.event.sourceEvent) { // not a programmatic event
	speedNode.classed("brushing",true);
    }
}

function d3OnSpeedBrush() {
    //d3SpeedBrushDebug("d3OnSpeedBrush()");
    var value  = speedBrush.extent()[0];
    if (d3.event.sourceEvent) { // not a programmatic event
	value = speedBrush.y().invert(d3.mouse(this)[1]);
    }
    d3SpeedBrushMove(value);
}

function d3OnSpeedBrushEnd() {
    //d3SpeedBrushDebug("d3OnSpeedBrushEnd()");
    speedNode.classed("brushing",false);
}

//----------------------------------------------------------------------
// d3: play/pause transport: callbacks
function dcpPlay(playing,force) {
    if (playing==null) playing = dcpPlaying;
    if (force==null) force=false;
    //exportMenuHide(0);

    //-- setup buttons
    var btn = d3.selectAll(".btn");
    btn.selectAll(".play").style("opacity",Number(!playing));
    btn.selectAll(".pause,.stop").style("opacity",Number(playing));

    if (!force && playing==dcpPlaying) return;
    dcpPlaying = playing;

    //-- maybe start playing
    if (playing) {
	//-- play
	if (dlabels.length < 2) {
	    alert("Play animation only available for multi-slice profiles!");
	    return dcpPlay(false);
	}
	var pos0 = dbrush.extent()[0];
	var pos1 = dlabels.length-1;
	if (pos0 == pos1) { pos0 = 0; }
	var totaldur = 15000 / dcpSpeed; //-- play-length for total sequence (in ms; google motion chart ~15s; [2s=.133x .. 40s=2.6x])
	var interp   = d3.interpolate(pos0,pos1);
	d3.select("#d3slider")
	    .transition()
	    .duration((totaldur/(dlabels.length-1))*(pos1-pos0))
	    .ease("linear")
	    .tween("brush", function() {
		//-- hack: check dcpPlaying to avoid transition interference (keybd interrupting play)
		return function(t) { if (dcpPlaying) dcpBrushMove(interp(t)); }
	    })
	    .each("end",function() { dcpPlay(false); });
    }
    else {
	//-- stop
	d3.select("#d3slider")
	    .transition()
	    .duration(0)
	    .tween("brush", function() { return function(t) { ; } })
	    //.call(dbrush.event)
	;
    }
}

//----------------------------------------------------------------------
// d3: legend (color-scale / "y axis")
function dcpLegend(parent_selector,opts) {
    //-- defaults
    if (opts==null) opts={};
    if (opts.id==null) { opts.id="d3legend"; }
    if (opts.width==null) { opts.width = 50; }
    if (opts.height==null) { opts.height = 450; }
    if (opts.opacity==null) { opts.opacity = 1; }
    var margin = opts.margin==null ? {} : opts.margin;
    if (margin.left==null) margin.left = 0;
    if (margin.right==null) margin.right = 0;
    if (margin.top==null) margin.top = 0;
    if (margin.bottom==null) margin.bottom = 0;
    if (opts.translate==null) opts.translate = {x:0,y:0};

    //debug_log("dcpLegend(parent_selector="+JSON.stringify(parent_selector)+", opts="+JSON.stringify(opts)+")");

    //-- common variables
    var width  = opts.width - margin.left - margin.right;
    var height = opts.height - margin.top - margin.bottom; 
    var yscale = d3.scale.linear()
	.domain(dcpScoreRange.reverse())
	.range([0,height])
	.clamp(true);

    var parent = d3.select(parent_selector);

    var svg = parent.append("g")
	.attr("id",opts.id)
	.classed("d3legend",true)
	.classed("scale",true)
	.attr("width", opts.width)
	.attr("height", opts.height)
    	.attr("transform","translate("+(margin.left+opts.translate.x)+","+(margin.top+opts.translate.y)+")");
    svg.append("title")
	.text("Legend: node colors by collocate score"+(isDiff ? " difference" : ""));

    svg.append("g")
	.attr("class", "y axis")
	.call(d3.svg.axis()
	      .scale(yscale)
	      .orient("right")
	      .tickSize(12)
	      .tickFormat(d3.format(".2s"))
	      .tickPadding(5));

    var cmin = dcpMinColor(); //-- ensure heatcolor_scale is defined (if applicable)
    var rw   = 14;
    if (heatcolor_scale==null) {
	//-- no d3 color-scale defined: add quantized visual scale via filled rectangles
	var boxes = svg.selectAll(".y.axis")
	    .append("g")
	    .attr("class","boxes");
	var rh    = 5;
	var nrect = ~~(height/rh);
	for (var i=0; i < nrect; ++i) {
	    boxes.append("rect")
	    //.attr("id","ybox"+i)
		.attr("height",rh)
		.attr("width", rw)
		.attr("x",0)
		.attr("y",i*rh)
		.style("fill", heatcolorf(1-i/nrect, dcpItemSat, dcpItemVal))
		.style("opacity",opts.opacity)
	    ;
	}
    }
    else {
	//-- d3 color-scale defined: add visual scale via linear-gradient fill
	var cscale = heatcolor_scale;
	var pfmt   = d3.format("%");
	var box    = svg.selectAll(".y.axis")
	    .append("g")
	    .attr("class","gradbox");
	box.append("linearGradient")
	    .attr("id", "colorGradient")
	    .attr("gradientUnits", "userSpaceOnUse")
	    .attr("x1", 0).attr("y1", 0)
	    .attr("x2", 0).attr("y2", height)
	    .selectAll("stop")
	    .data(cscale.domain().map(function(f,i) { return {offset:pfmt(1.0-f), color:cscale(f)}; }))
	    .enter().append("stop")
	    .attr("offset",     function(d) { return d.offset; })
	    .attr("stop-color", function(d) { return d.color; });
	box.append("rect")
	    .attr("height",height)
	    .attr("width", rw)
	    .attr("x",0)
	    .attr("y",0)
	    .style("fill", "url(#colorGradient)")
	    .style("opacity",opts.opacity);	  
    }


    //$("#profileDataD3").show(); //-- debug
    return svg;
}

//----------------------------------------------------------------------
// d3: export: export svg guts
//  + see http://stackoverflow.com/questions/23218174/how-do-i-save-export-an-svg-file-after-creating-an-svg-with-d3-js-ie-safari-an
function d3exportSvg(event) {
    //get svg element.
    var mode = $("#profileDataChart").is(":visible") ? 'hichart' : 'd3';
    var svg;
    if (mode == 'hichart') {
	svg = d3.select("#profileDataChart svg");
    } else {
	svg = d3.select("#d3content");
    }
    svg = svg.node().cloneNode(true);

    //-- insert inline css into svg (d3 only)
    if (mode == 'd3') {
	var style = document.createElementNS("http://www.w3.org/2000/svg","style");
	var css   = getcss(true,/diacollo\.css/,/d3/);
	$(style).text(css);
	svg.insertBefore(style, svg.firstChild);

	//-- boldface current slider slice label (hack for inkscape)
	$(svg).find("#d3slider .brush .tick text.selected").css("font-weight","bold");
    }

    //-- get svg source.
    var serializer = new XMLSerializer();
    var source = serializer.serializeToString(svg);

    //-- add namespaces
    if(!source.match(/^<svg[^>]*xmlns="http\:\/\/www\.w3\.org\/2000\/svg"/)){
	source = source.replace(/^<svg/, '<svg xmlns="http://www.w3.org/2000/svg"');
    }
    if(!source.match(/^<svg[^>]*"http\:\/\/www\.w3\.org\/1999\/xlink"/)){
	source = source.replace(/^<svg/, '<svg xmlns:xlink="http://www.w3.org/1999/xlink"');
    }

    //-- add xml declaration
    source = '<?xml version="1.0" encoding="UTF-8" standalone="no"?>\r\n' + source;

    //-- convert svg source to URI data scheme
    //var url = "data:image/svg+xml;charset=utf-8,"+encodeURIComponent(source);
    var url = "data:image/svg+xml;charset=utf-8,"+encodeURIComponent(source);

    //-- set url value to the export button's element's href attribute
    $("#exportBtn") 
	//.prop("target","_tab")
	.prop("download","diacollo.svg")
	.prop("href",url);

    //-- go get it (must use DOM click() method, not jQuery if using exportTarget != event.target)
    /*
      exportMenuHide();
      document.getElementById('exportTarget').click();
    */

    //-- direct-click button: just return true
    return true;
}

//--------------------------------------------------------------
// d3: export: utils: get css string from selected stylsheets
//  + see http://stackoverflow.com/questions/1679507/getting-all-css-used-in-html-file
function getcss(wantIntern, hrefRegex, selectorRegex) {
    var css = ""; //variable to hold all the css that we extract
    //-- add internal styles
    if (wantIntern) {
	$("style").each(function(i,s) {
	    css += s.innerHTML;
	});
    }

    //-- check for selected external stylesheets
    if (hrefRegex==null) hrefRegex = /./;
    if (selectorRegex==null) selectorRegex = /./;
    for (var si = 0; si < document.styleSheets.length; si++) {
        var sheet = document.styleSheets[si];
	if (String(sheet.href).search(hrefRegex) == -1) continue;

        //-- loop over all the styling rules in this external stylesheet
        for (var ri = 0; ri < sheet.cssRules.length; ri++) {
	    if (sheet.cssRules[ri].selectorText.search(selectorRegex) != -1) {
		css += sheet.cssRules[ri].cssText; //-- extract the styling rule
	    }
        }
    }

    return css;
}

//----------------------------------------------------------------------
// d3: common: controls & geometry
//  + opts:
//     legendOpacity:OPACITY  //-- legend color-scale opacity
//     width:WIDTH,           //-- total width (default=window.innerWidth-16)
//     height:HEIGHT,         //-- total height (default=500)
//     bodyWidth:WIDTH        //-- body,slider width
//     buttonsWidth:WIDTH     //-- buttons width
//     legendWidth:WIDTH      //-- legend width
//  + returns: opts + keys
//     bodyWidth:WIDTH        //-- body width
//     bodyHeight:HEIGHT      //-- body height
function d3SetupCommon(opts) {

    //-- options
    if (opts.legendOpacity==null) opts.legendOpacity=1;

    //-- common variables
    if (opts==null) opts={};
    if (opts.height==null) opts.height = 500;
    if (opts.buttonsWidth==null) opts.buttonsWidth = 90; //$("#d3buttons").width();      //-- not defined yet!
    if (opts.legendWidth==null) opts.legendWidth = 50; //$("#d3legend").width();         //-- not defined yet!
    if (opts.bodyHeight==null) opts.bodyHeight = opts.height - 50 - 5;                   //-- -5:ypad

    //debug_log("d3SetupCommon:pre: "+JSON.stringify(opts));

    //-- cleanup any stale content & create new svg with proper height (may add scrollbars!)
    $("#d3content").remove();
    var svg = d3.select("#profileDataD3")
	.append("svg")
	.attr("id","d3content")
	//.attr("width",opts.width) //-- delayed in case scrollbars were added
	.attr("height", opts.height);


    //-- get width (temporary show)
    $("#profileDataD3").show();
    if (opts.width==null) opts.width = $(".outer").width();
    if (opts.sliderWidth==null) opts.sliderWidth = opts.width - opts.buttonsWidth ;//- 20;  //-- 10px goofiness margin (firefox, mobile emulation)
    if (opts.bodyWidth==null) opts.bodyWidth = opts.width-opts.legendWidth ;//- 20;         //-- 10px goofiness margin (firefox, mobile emulation)
    $("#profileDataD3").hide();
    svg.attr("width",opts.width);

    //debug_log("d3SetupCommon+width: "+JSON.stringify(opts));

    //-- transport: buttons + brush-slider
    var transport = svg.append("g")
	.attr("id","d3transport")
	.attr("width",opts.width)
	.attr("height",50);

    var sliderPadX = 50;
    dcpTransportButtons("#d3transport", {id:"d3buttons", width:opts.buttonsWidth, height:50});
    dcpTransportSlider(dlabels, "#d3transport", { id:"d3slider", width:opts.sliderWidth, height:50,
						  margin:{top:0, bottom:0, left:sliderPadX, right:sliderPadX},
						  translate:{x:opts.buttonsWidth, y:0}
						});

    //-- legend + body
    dcpLegend("#d3content", { id:"d3legend", width:opts.legendWidth, height:opts.bodyHeight, opacity:opts.legendOpacity,
			      margin:{top:10,bottom:10,left:0,right:0},
			      translate:{x:0,y:50},
			    });
    var main = svg.append("g")
	.attr("id","d3main")
	.attr("transform", "translate("+(opts.legendWidth)+","+55+")")
    ;
    var bg = main.append("rect")
	.attr("id","d3background")
        .attr("width",opts.bodyWidth)
	.attr("height",opts.bodyHeight)
    ;
    var body = main.append("g")
	.attr("id","d3body")
	.attr("width",opts.bodyWidth)
	.attr("height",opts.bodyHeight)
    ;
    var frame = main.append("rect")
	.attr("id", "d3frame")
	.attr("rx",$("#d3buttons .btn .border").attr("rx"))
	.attr("ry",$("#d3buttons .btn .border").attr("ry"))
        .attr("width",opts.bodyWidth-1)
	.attr("height",opts.bodyHeight-1)
    ;

    //-- key bindings
    dcpBrushKeys({".content":1});
    $("#d3icons").fadeIn();

    //-- status
    $("#statusRel").addClass("d3");
    dcpStatusMsg("loading","Rendering...");

    return opts;
}

//----------------------------------------------------------------------
// d3: bubble: force-drirected graph chart;
// + see https://githu    //-- common variablesb.com/mbostock/d3/wiki/Force-Layout (force layout demo)
// + see https://gist.github.com/mbostock/3231298 (collision detection demo)
var bubbleOpacity = 0.9;
function dcpFormatBubble(data, jqXHR) {
    //-- parse data
    if ( !(data = dcpParseFlat(data,{mode:"bubble"})) ) { return; }

    var cfg = d3SetupCommon({legendOpacity:bubbleOpacity});
    var width = cfg.bodyWidth;
    var height = cfg.bodyHeight;

    //-- setup d3 force chart
    var psvg = d3.select("#d3body")
	.classed("d3chart",true)
    	.classed("d3force",true)
    ;
    d3.select("#d3main")
	.append("title")
	.text("Bubble-graph for selected date-slice. Click+drag to move bubbles, double-click to display details.");

    var force = dforce = d3.layout.force()
	.links([])
	.nodes([])
	.charge(0)
	.size([width, height])
	.on("tick", function(e) {
	    //-- circle collision detection
	    var nodes = force.nodes();
	    var q = d3.geom.quadtree(nodes);
	    var i = -1;
	    var n = nodes.length;
	    
	    while (++i < n) q.visit(collide(nodes[i], width, height));
	    
	    psvg.selectAll(".node")
		.attr("transform", function(d) {
		    return "translate(" + d.x + "," + d.y + ")";
		});
	})
    ;
    
    dcpForceSnap();
    //dcpBrushMove(dcur);

    //dcpErrorMsg("-- work in progress --");
    dcpClearMsg();
    $(".rawURL").hide();
    $("#profileDataD3").fadeIn();

    //dcpShowPrefetchHint(); //-- show "pre-fetched data" hint if appropriate
    return;
}

//--------------------------------------------------------------
// d3: bubble: force layout update (snap)
var dcpSnapEase = "elastic"; //-- pretty, but "elastic" causes bogus negative radius values
//var dcpSnapEase = "cubic-out";
function dcpForceSnap(value) {
    if (value==null) value=dcur;
    dcpPlay(false);
    dcpForceInterp(Math.round(value), 500, dcpSnapEase); //-- "elastic" causes bogus negative radius values
}

//--------------------------------------------------------------
// d3: bubble: force layout update (interp)
var d3BodySelector = '#d3body';
function dcpForceInterp(value,dur,easeby) {
    if (dforce==null) return; //-- not defined yet
    if (value==null) { value = dcur; }
    if (dur==null) { dur = 100; }
    if (easeby==null) { easeby = "linear"; }

    dcur = value;
    var snapto = Math.round(dcur);
    var dcur0 = Math.floor(dcur);
    var dcur1 = Math.ceil(dcur);
    var dfrac = dcur-dcur0;
    var ditems = items.filter(function(i) { return i.value[dcur0] != null || i.value[dcur1] != null; });
    ditems.forEach(function(i) { i.gravity = linterp(i.value,dcur); });
    dforce.nodes(ditems);

    var psvg = d3.select(d3BodySelector);
    var nodes = psvg.selectAll(".node")
	.data(ditems, function(d) { return d.id; });

    //-- UPDATE: update existing elements
    //var updated = nodes;

    //-- ENTER: append new elements
    var entered = nodes.enter()
	.append("g")
	.attr("class", "node")
	.attr("id", function(d) { return "g"+d.id; })
	.attr("opacity",0)
	.on("dblclick", d3InfoPopup)
	.call(dforce.drag);
    entered
	.append("title");
    entered
	.append("circle")
	.attr("opacity",bubbleOpacity)
	.attr("r",dcpSizeRange[0]);
    entered
	//.filter(function(d) { return d.avalue >= 0.25 }) //-- only annotate nodes with 75%+ absolute score-quantiles
	.append("text")
	.text(function(d) { return d.text; });

    //-- ENTER+UPDATE: update old or new nodes
    nodes.selectAll("title").text(d3NodeTitleText);
    var updated = nodes.transition()
	.duration(dur)
	.ease(easeby);
    updated
	.attr("opacity",function(d) { return dcpItemOpacity(d,dcur); })
	.selectAll("circle")
	.attr("r", function(d) { return d.r = dcpItemSize(d,dcur); })
	.style("fill", function(d) { return dcpItemColor(d,dcur); })
    ;

    //-- EXIT: remove old elements as needed
    var exited = nodes.exit()
	.transition()
	.duration(dur)
	.ease(easeby)
	.remove();
    exited
	.attr("opacity",0)
	.selectAll("circle")
	.attr("r",dcpSizeRange[0]);

    //-- (re-)start the force layout
    dforce.start();

    //-- update info popup and current snap-to value
    d3InfoPopupUpdate(snapto);
    dsnapto = snapto;
}


//--------------------------------------------------------------
// d3: bubble: collision detection: text "radius" (really horizontal only)
function itemTextRadius(item) {
    if (Number(item.textRadius) > 0) return item.textRadius;
    return item.textRadius = d3.select("#g"+item.id+" text").node().getBBox().width/2;
}

//--------------------------------------------------------------
// d3: bubble: collision detection
// + see https://gist.github.com/mbostock/3231298 (orig, circles only)
// + see http://stackoverflow.com/questions/29844823/force-layout-collision-detection-with-group-nodes (for group nodes)
// + using canvas-constraints from http://bl.ocks.org/mbostock/1129492
function collide(node, canvasWidth, canvasHeight) {
    var nodeElt = d3.select("#g"+node.id).node();
    var bbox = nodeElt.getBBox();
    var pad  = 2;

    //-- fit to canvas hack from http://bl.ocks.org/mbostock/1129492
    node.x = Math.max(node.r, Math.min(canvasWidth  - bbox.width/2, node.x));
    node.y = Math.max(node.r, Math.min(canvasHeight - bbox.height/2, node.y));

    var
      rx  = bbox.width/2 + pad,
      ry  = bbox.height/2 + pad,
      r   = Math.max(rx,ry),
      //r  = ry,
      nx1 = node.x - rx, //rx
      nx2 = node.x + rx, //rx
      ny1 = node.y - ry, //ry
      ny2 = node.y + ry; //ry
    return function(quad, x1, y1, x2, y2) {
        if (quad.point && (quad.point !== node)) {
	    //-- collision detection: circles
            var x  = node.x - quad.point.x,
                y  = node.y - quad.point.y,
                dl = Math.sqrt(x * x + y * y),
	        dr = r + Math.max(quad.point.r, itemTextRadius(quad.point));
	    	//dr = r + quad.point.r;
            if (dl < dr) {
                dl = (dl - dr) / dl * .5;
                node.x -= x *= dl;
                node.y -= y *= dl;
                quad.point.x += x;
                quad.point.y += y;
            }
        }
	//return x1 > nx2 || x2 < nx1 || y1 > ny2 || y2 < ny1;
    };
}


//----------------------------------------------------------------------
// d3: cloud: tag-cloud layout
// + see https://github.com/jasondavies/d3-cloud
var dcpCloudFont = {family:"Impact",weight:"normal",style:"normal"};
//var dcpCloudFont = {family:"Arial",weight:"bold",style:"normal"};
//var dcpCloudFont = {family:"Arial Black",weight:"bold",style:"normal"};
//var dcpCloudFont = {family:"sans-serif",weight:"bold",style:"normal"};
function dcpFormatCloud(data, jqXHR) {
    //-- parse data
    if ( !(data = dcpParseFlat(data,{mode:"cloud"})) ) { return; }

    var cfg = d3SetupCommon({legendOpacity:1});
    var width = cfg.bodyWidth;
    var height = cfg.bodyHeight;

    //-- for old heat-colors
    dcpItemSat  = 1;
    dcpItemVal  = 0.9;

    //-- setup cloud svg item
    var psvg = d3.select("#d3body")
	.classed("d3chart",true)
	.classed("d3cloud",true)
    ;
    d3.select("#d3main")
	.append("title")
	.text("Tag-cloud for selected date-slice. Click a word to display details.");

    //-- (re-)initialize cloud layout
    dcpCloudSetup(psvg);
}

//--------------------------------------------------------------
// d3: cloud: setup / rescale

//-- random seed (d3.cloud still isn't deterministic even with constant seed!)
var seed = Math.floor(Math.random() * 65535);
var xrandom = function() { var x = Math.sin(seed++) * 10000; return x - Math.floor(x); }
xrandom = Math.random;

var dcpCloudScale = 1;
var dcpCloudSizeMax = null;
function dcpCloudSetup(psvg) {
    if (psvg==null)  { psvg=d3.select(d3BodySelector); }

    //xrandom = Math.random;
    //seed = 42;
    //debug_log("random seed = " + seed);

    //-- size-scaling: re-populate item.size; item.maxSize
    if (dcpCloudSizeMax==null) {
	dcpCloudSizeMax = dcpSizeRange[1];
    }
    dcpSizeRange[1] = dcpCloudSizeMax * dcpCloudScale;
    items.forEach(function(item) {
	item.sizes   = item.sizes.map(function(x,i) { return ~~dcpItemSize(item,i); });
	item.maxSize = Math.round( d3.max(item.sizes) );
    });

    //-- rotations
    var rotations 
	= [0];
	//= [0,90];
        //= [0,90,45,-45];
	//= [0,45,-45];
       //= [45,-45];
    var main  = d3.select("#d3main");
    var cloud = dcloud = d3.layout.cloud()
	.size([Number(psvg.attr("width")),Number(psvg.attr("height"))+25]) //-- weird unused space at bottom: tweaking height+25
	.words(items)
	.padding(1)
	.random(xrandom)
	//.rotate(0)
	//.rotate(function(d) { return rotations[d.id % rotations.length]; })
	.rotate(function() { return rotations[~~(xrandom() * rotations.length)]; })
	.font(dcpCloudFont.family)
	.fontWeight(dcpCloudFont.weight)
	.fontStyle(dcpCloudFont.style)
	.fontSize(function(d) { return d.maxSize; })
	.timeInterval(50)
	.on("end",dcpCloudEnd);

    //dcpErrorMsg("-- work in progress --");
    $(".rawURL").hide();
    $("#profileDataD3").show();
    cloud.start();
    return;
}
/*-- test color-scale:
function cboxes(scale) {
    var boxes = d3.selectAll(".y.axis .boxes rect");
    var imax  = boxes.size();

    boxes.style("fill", function(d,i) {
	//console.log("color("+i+"/imax:"+(i/imax)+"~"+(i/imax*scale.range().length)+")="+x);
	debug_log("color("+i+"/imax:"+(i/imax)+"~"+(i/imax)+")="+scale(i/imax));
	return scale(i/imax);
    });
}
function cscale(colors,interp) {
    if (interp==null) interp = d3.interpolateRgb;
    var scale = d3.scale.linear()
	.domain(d3.range(0,colors.length).map(function(i) { return i/(colors.length-1); }))
	.range(colors)
	.interpolate(interp);
    return scale;
}
//-- color brewer colors; see http://colorbrewer2.org/
//-- diff (divergent)
redgb4 = ["rgb(215,25,28)", "rgb(253,174,97)", "rgb(171,221,164)", "rgb(43,131,186)"]
redgb8 = ["rgb(213,62,79)", "rgb(244,109,67)", "rgb(253,174,97)", "rgb(254,224,139)", "rgb(230,245,152)", "rgb(171,221,164)", "rgb(102,194,165)", "rgb(50,136,189)"]
//-- sequential
red4 = ['rgb(254,240,217)','rgb(253,204,138)','rgb(252,141,89)','rgb(215,48,31)']
*/

//--------------------------------------------------------------
// d3: cloud: callbacks
function dcpCloudEnd(placedWords,bounds) {
    var svg = d3.select(d3BodySelector);
    svg
	.append("g")
	.attr("transform", "translate(" + dcloud.size()[0]/2 + "," + dcloud.size()[1]/2 + ")");

    //-- warn about placement errors and maybe recompute
    var nbad = items.length - placedWords.length;
    if (nbad > 0) {
	var cls = "warning";
	var msg = "Warning: "+nbad+" of "+items.length+" data point(s) could not be displayed";
	var tryRescale = (dcpCloudScale > 0.125);
	if (tryRescale) {
	    dcpCloudScale *= 0.5;
	    var trimKeys = ["onScreen","x","x0","x1","xoff","y","y0","y1","yoff","width","height","size","rotate","font","hasText","padding","weight","style"];
	    items.forEach(function(d) {
		trimKeys.forEach(function(k) { delete d[k]; });
	    });
	    msg += " -- re-computing with scale="+dcpCloudScale;
	    cls += " loading";
	} else {
	    msg += " at minimum scale="+dcpCloudScale;
	}
	debug_log(msg);
	dcpStatusMsg(cls,msg).hide().fadeIn();
	if (tryRescale) {
	    return dcpCloudSetup(svg);
	}
	else  {
	    $("#status").fadeOut(5000);
	}
    } else if (dcpCloudScale == 1) {
	dcpClearMsg();
    }  else {
	dcpInfoMsg("Placed all "+items.length+" data point(s) at scale="+dcpCloudScale).fadeOut(2000);
    }

    //-- record final placement errors
    placedWords.forEach(function(d) { d.onScreen=true; });

    //dcpCloudDebug(); return; //-- DEBUG
    //dcpCloudDebug(0,'linear',0,true);  return; //-- we don't get collisions if we do dcpCloudDebug() before dcpCouldInterp(): why???

    //-- draw data
    dcpCloudInterp(dcur,1000,"cubic-in-out");
    //dcpBrushMove(dcur,1000,"cubic-in-out");

    //dcpShowPrefetchHint(); //-- show "pre-fetched data" hint if appropriate
}

//-- debug: bbox string for getBoundingClientRect()
function bbstr(bb) {
    return '[' + [bb.left,bb.top,bb.right,bb.bottom].join(',') + ']';
}


//--------------------------------------------------------------
// d3: cloud: update (snap)
function dcpCloudSnap(value) {
    if (value==null) value=dcur;
    dcpPlay(false);
    dcpCloudInterp(Math.round(value), 500, dcpSnapEase);
}

//--------------------------------------------------------------
// d3: cloud: update (interp)
function dcpCloudInterp(value,dur,easeby) {
    if (dcloud==null) return; //-- not defined (yet)
    if (value==null) { value = dcur; }
    if (dur==null) { dur = 100; }
    if (easeby==null) { easeby = "linear"; }

    dcur = value;
    var snapto = Math.round(dcur);
    var dcur0 = Math.floor(dcur);
    var dcur1 = Math.ceil(dcur);
    var dfrac = dcur-dcur0;
    var ditems = items.filter(function(d) { return d.onScreen && (d.value[dcur0] != null || d.value[dcur1] != null); });

    function tween_font_size(d) {
	var interp = d3.interpolateRound(d.curSize, ~~dcpItemSize(d,dcur));
	return function(t) {
	    $(this).css("font-size",(d.curSize=Math.max(dcpSizeRange[0],interp(t)))+"px");
	};
    };

    var nodes = d3.select(d3BodySelector+" > g")
	.selectAll(".node")
	.data(ditems, function(d) { return d.id; });

    //-- UPDATE: update existing elements
    //var updated = nodes;

    //-- ENTER: append new elements
    var entered = nodes.enter()
	.append("g")
	.attr("id", function(d) { return "g"+d.id; })
	.attr("class","node")
	.attr("transform", function(d) { return "translate(" + [d.x, d.y] + ")rotate(" + d.rotate + ")"; })
	.on("click", d3InfoPopup);
    
    //-- enter: title
    entered.append("title");

    //-- enter: text
    entered.append("text")
    //-- enter: text: constant attributes
	.text(function(d) { return d.text; })
        //-- these get set by css [but we might need them for svg export?]
        .attr("text-anchor","middle")
	.style("font-family",dcpCloudFont.family)
	.style("font-weight",dcpCloudFont.weight)
	.style("font-style",dcpCloudFont.style)
	.style("fill",dcpMinColor())
	.attr("opacity",0)
	.style("font-size",function(d) { (d.curSize=dcpSizeRange[0])+"px"; }) //-- use dcpSizeRange[0] rather than 0 minimum size; 0 --> collisions!
    ;

    //-- ENTER+UPDATE: update old or new nodes
    nodes.selectAll("title").text(d3NodeTitleText);
    nodes.transition()
	.duration(dur)
	.ease(easeby)
	.selectAll("text")
	.attr("opacity", function(d) { return dcpItemOpacity(d,dcur) })
	.style("fill", function(d) { return dcpItemColor(d,dcur) })
	//.style("font-size", function(d) { return ~~dcpItemSize(d,dcur)+"px"; })
	.tween("font-size",tween_font_size)
    ;


    //-- EXIT: remove old elements as needed
    var exited = nodes.exit()
	.transition()
	.duration(dur)
	.ease(easeby)
	.remove();
    exited.selectAll("text")
	.attr("opacity", 0)
	.style("fill", dcpMinColor())
	.tween("font-size", tween_font_size)
    ;

    //-- maybe update info popup
    d3InfoPopupUpdate(snapto);
    dsnapto = snapto;
}

//--------------------------------------------------------------
// d3: cloud: debug (show all at max size)
function dcpCloudDebug(dur,easeby,opacity,doInterp) {
    if (dcloud==null) return; //-- not defined yet
    if (dur==null) { dur = 1000; }
    if (easeby==null) { easeby = "linear"; }
    if (opacity==null) { opacity = 1; }
    if (doInterp==null) { doInterp = false; }
    debug_log("dcpCloudDebug("+dur+","+","+easeby+","+opacity+","+doInterp+")");

    var ditems = items;

    function tween_font_size(d) {
	var interp = d3.interpolateRound(d.curSize, d.maxSize);
	return function(t) {
	    $(this).css("font-size",(d.curSize=interp(t))+"px");
	};
    };

    var nodes = d3.select(d3BodySelector+" > g")
	.selectAll(".node")
	.data(ditems, function(d) { return d.id; });

    //-- UPDATE: update existing elements
    //var updated = nodes;

    //-- ENTER: append new elements
    var entered = nodes.enter()
	.append("g")
	.attr("id", function(d) { return "g"+d.id; })
	.attr("class","node")
	.attr("transform", function(d) { return "translate(" + [d.x, d.y] + ")rotate(" + d.rotate + ")"; })
	.on("click", d3InfoPopup);
    entered
	.append("title")
    ;
    
    //-- enter: text
    entered.append("text")
    //-- enter: text: constant attributes
	.text(function(d) { return d.text; })
        //-- these get set by css [but we might need them for svg export?]
        .attr("text-anchor","middle")
	.style("font-family",dcpCloudFont.family)
	.style("font-weight",dcpCloudFont.weight)
	.style("font-style",dcpCloudFont.style)
	.style("fill",dcpMinColor())
	.attr("opacity",0)
	.style("font-size",function(d) { (d.curSize=dcpSizeRange[0])+"px"; })
    ;

    //-- ENTER+UPDATE: update old or new nodes
    var ntrans=0;
    nodes.selectAll("text")
	.transition()
	.duration(dur)
	.ease(easeby)
	.attr("opacity", opacity)
	.style("fill", function(d) { return heatcolorf(d3.max(isDiff ? d.avalue : d.value)); })
	.tween("font-size",tween_font_size)
    //
    	.each("start", function() { ntrans++; })
	.each("end",function() {
	    if (--ntrans === 0 && doInterp) {
		dcpCloudInterp(0,1000,"cubic-in-out");
	    }
	})
    ;

    //-- EXIT: remove old elements as needed
    var exited = nodes.exit()
	.transition()
	.duration(dur)
	.ease(easeby)
	.remove()
    ;
    exited.selectAll("text")
	.attr("opacity", 0)
	.style("fill", dcpMinColor())
	.tween("font-size", tween_font_size)
    ;
}

//==============================================================================
// UI stuff

//----------------------------------------------------------------------
function profileSelectChange() {
    var ptyp = $("#in_profile").val();
    if (ptyp.match(/^diff-/)) {
	$("#td_cutoff").hide().find("#in_cutoff").prop('disabled',true);
	$("#td_diff").show().find("#in_diff").prop('disabled',false);
	$(".diffpar").show().find("input").prop('disabled',false);
    } else {
	$(".diffpar").hide().find("input").prop('disabled',true);
	$("#td_diff").hide().find("#in_diff").prop('disabled',true);
	$("#td_cutoff").show().find("#in_cutoff").prop('disabled',false);
    }

    if (ptyp.match(/2$/)) {
	//$("#td_onepass").show().find("input").prop('disabled',false);
	$("#td_onepass").removeClass("disabled").find("input").prop('disabled',false);
    } else {
	//$("#td_onepass").hide().find("input").prop('disabled',true);
	$("#td_onepass").addClass("disabled").find("input").prop('disabled',true);
    }
}

//==============================================================================
// ddc linkup stuff

// global for ddc (d*) kwic links
var ddc_url_root = null;

// html = ddclink({option:value, ...})
//  + options:
//     tr        : row for which to generate query or array of item-keys
//     ilabel    : index of 'label' column
//     qtemplate : query template (e.g. user_query.qinfo.qtemplate)
//     dslice    : slice parameter (default: user_query.slice)
//     dtrim     : label-trimming regex for #asc_date[] filter generation
//     classes   : (optional) html class(es); default: ''
//     title     : (optional) kwic-link title
function ddclink(opts) {
    if (opts.dtrim==null) { opts.dtrim = /[^0-9].*$/; }
    if (opts.dslice==null) { opts.dslice = user_query.slice; }
    var atitle = (opts.title!=null ? (' title="'+escapeHTML(opts.title)+'"') : '');
    var aclass = (opts.classes==null ? '' : opts.classes);
    var qstr   = rowq(opts.tr, opts.qtemplate, opts.ilabel, opts.dtrim, opts.dslice);
    var qtxt   = escapeHTML(qstr);
    if (!Boolean(ddc_url_root)) {
	//aclass += " disabled";
	return '<span class="'+aclass+'" onclick="javascript:alert(\'Variable ddc_url_root not set: KWIC links disabled!\');"'+atitle+'>'+qtxt+'</span>';
    }
    var href = ddc_url_root + "?" + $.param({"q":qstr});
    return '<a class="' + aclass +'" href="'+href+'"'+atitle+'>'+qtxt+'</a>';
}


// html = kwiclink({option:value, ...})
//  + options:
//     tr        : row for which to generate query or array of item-keys
//     ilabel    : index of 'label' column
//     qtemplate : query template (e.g. user_query.qinfo.qtemplate)
//     dslice    : slice parameter (default: user_query.slice)
//     title     : (optional) kwic-link title
//     text      : (optional) button-text
//     dtrim     : label-trimming regex for #asc_date[] filter generation
//     classes   : html class(es); default: 'textButtonSmall'
function kwiclink(opts) {
    var atitle = (opts.title!=null ? (' title="'+escapeHTML(opts.title)+'"') : '');
    var aclass = (opts.classes==null ? 'textButtonSmall' : opts.classes);
    var ltext  = (opts.text==null ? "kwic" : escapeHTML(opts.text));
    if (!Boolean(ddc_url_root)) {
	aclass += " disabled";
	return '<span class="'+aclass+'" onclick="javascript:alert(\'Variable ddc_url_root not set: KWIC links disabled!\');"'+atitle+'>'+ltext+'</span>';
    }
    return '<a class="'+aclass+'" href="'+kwicurl(opts)+'"'+atitle+">"+ltext+'</a>';
}

// href = kwicurl(opts)
//  + options:
//     tr        : row for which to generate query or array of item-keys
//     ilabel    : index of 'label' column
//     qtemplate : query template (e.g. user_query.qinfo.qtemplate)
//     dslice    : slice parameter (default: user_query.slice)
function kwicurl(opts) {
    if (opts.dtrim==null) { opts.dtrim = /[^0-9].*$/; }
    if (opts.dslice==null) { opts.dslice = user_query.slice; }
    return ddc_url_root + "?" + $.param({"q":rowq(opts.tr, opts.qtemplate, opts.ilabel, opts.dtrim, opts.dslice)});
}

// str = celltext(td_or_string)
function celltext(cell) {
    if      (typeof(cell) == 'string') { return cell; }
    else if (typeof(cell) == 'number') { return String(cell); }
    else if (typeof(cell) == 'undefined') { return ''; }
    return $(cell).text();
}

// qstr = rowq(tr_or_array, qtemplate, ilabel, dtrim, dslice)
function rowq(tr, qtemplate, ilabel, dtrim, dslice) {
    var qstr  = qtemplate;
    var ds    = Number(dslice!=null ? dslice : user_query.slice);
    var cells = (tr instanceof Array ? tr : tr.cells);
    if (ds != 0) {
	var d2 = Number(celltext(cells[ilabel]).replace(dtrim,''));
	qstr += " #asc_date["+String(d2)+"-00-00,"+String(d2+ds-1)+"-99-99]";
    }
    for (var tdi=ilabel+1; tdi < cells.length; ++tdi) {
	qstr = replaceAll(qstr, '__W2.'+String(tdi-ilabel)+'__', escapeDDC(celltext(cells[tdi]),false));
    }
    return qstr;
}

// result = replaceAll(str, searchStr,replaceStr)
function replaceAll(s, searchStr,replaceStr) {
    while (s.indexOf(searchStr) != -1) {
	s = s.replace(searchStr,replaceStr);
    }
    return s;
}

//==============================================================================
// Generic Utils

//--------------------------------------------------------------
function debug_log(msg) {
    if (user_query.debug) console.log("DEBUG: "+msg);
}

//--------------------------------------------------------------
var htmlEntities = {
    "&": "&amp;",
    "<": "&lt;",
    ">": "&gt;",
    '"': '&quot;',
    "'": '&#39;',
    "/": '&#x2F;'
  };
function escapeHTML(s) {
    return String(s).replace(/[&<>"'\/]/g, function (s) {
	return htmlEntities[s];
    });
}

//--------------------------------------------------------------
function urlFragment(url) {
    var a = document.createElement('a');
    a.href = url;
    var fragment = a.hash.replace(/^#/,'');
    $(a).remove();
    return fragment;
}

function locFragment(loc) {
    return loc.hash.replace(/^#/,'');
}

//--------------------------------------------------------------
function escapeDDC(s, enquote) {
    if (s.search(/\W/) == -1) { return s; }
    if (enquote==null) { enquote=true; }
    return (Boolean(enquote) ? "'" : "") + s.replace(/['\\]/g,"\\$&") + (Boolean(enquote) ? "'" : "");
}

//--------------------------------------------------------------
// generic: hash keys, values

function keys(obj) {
    if (!(obj instanceof Object)) { return []; }
    var keys = [];
    for (var k in obj) { keys.push(k);  }
    return keys;
}
function values(obj) {
    if (!(obj instanceof Object)) { return []; }
    var vals = [];
    for (var k in obj) { vals.push(obj[k]); }
    return vals;
}

//--------------------------------------------------------------
// generic: (deep|shallow) object copy

function cloneObject(oldObject,deepClone) {
    if (deepClone==null || Boolean(deepClone)) {
	return jQuery.extend(true, {}, oldObject);
    } else {
	return jQuery.extend({}, oldObject);
    }
}

//--------------------------------------------------------------
// generic: numeric comparisons
function cmpNumeric(a,b) {
    return Number(a)-Number(b);
}
function cmpNumericR(a,b) {
    return Number(b)-Number(a);
}

//--------------------------------------------------------------
// generic: data range

//  + [min,max] = minmax(values, func?)
//  + returns minimum and maximum of func(v) for each v in array values
function minmax(values, func) {
    var min = null;
    var max = null;
    values.forEach(function (val) {
	if (func!=null) { val = func(val); }
	if (min==null || val < min) { min = val; }
	if (max==null || val > max) { max = val; }
    });
    return [min,max];
}

//--------------------------------------------------------------
// heatcolorf(frac, sat=1, val=1)
//  + returns rgb string representing frac, which should be in range [0(blue):1(red)]
function heatcolorf_hsv(frac,sat,val) {
    if      (frac == null || frac < 0) { frac = 0; }
    else if (frac  > 1) { frac = 1; }
    return hsv2rgb(240*(1-frac), (sat==null ? 1 : sat), (val==null ? 1 : val));
}

var heatcolor_scale;
function heatcolorf(frac,sat,val) {
    if (heatcolor_scale==null) {
	//-- colors from http://colorbrewer2.org/
	var colors
	    //= ["rgb(215,25,28)", "rgb(253,174,97)", "rgb(171,221,164)", "rgb(43,131,186)"];
	    = ["rgb(213,62,79)", "rgb(244,109,67)", "rgb(253,174,97)", "rgb(254,224,139)", "rgb(230,245,152)", "rgb(171,221,164)", "rgb(102,194,165)", "rgb(50,136,189)"];
	if (user_format=="cloud") {
	    colors = colors.map(function(c) { return d3.rgb(c).darker(0.25); });
	}
	heatcolor_scale = d3.scale.linear()
	    .domain(d3.range(0,colors.length).map(function(i) { return i/(colors.length-1); }).reverse())
	    .range(colors)
	    .interpolate(d3.interpolateRgb);
    }
    return heatcolor_scale(frac);
}

//--------------------------------------------------------------
// heatcolorv(val, min, max, opts)
// heatcolorv(val, [min,max], opts)
//  + returns rgb string representing val, which should be in range [min(blue):max(red)]
//  + opts:
//      sat: saturation (default=1)
//      val: value      (default=1)
function heatcolorv(val, min, max, opts) {
    if (min instanceof Array) {
	if (opts==null) { opts=max; }
	max=min[1];
	min=min[0];
    }
    if (opts==null) { opts={}; }
    return heatcolorf((max==min ? 0.5 : (val-min)/(max-min)), opts.sat, opts.val);
}


//--------------------------------------------------------------
// hsv2rgb() : see http://schinckel.net/2012/01/10/hsv-to-rgb-in-javascript/
function hsv2rgb(h,s,v) {
  var rgb, i, data = [];
  if (s === 0) {
    rgb = [v,v,v];
  } else {
    h = h / 60;
    i = Math.floor(h);
    data = [v*(1-s), v*(1-s*(h-i)), v*(1-s*(1-(h-i)))];
    switch(i) {
      case 0:
        rgb = [v, data[2], data[0]];
        break;
      case 1:
        rgb = [data[1], v, data[0]];
        break;
      case 2:
        rgb = [data[0], v, data[2]];
        break;
      case 3:
        rgb = [data[0], data[1], v];
        break;
      case 4:
        rgb = [data[2], data[0], v];
        break;
      default:
        rgb = [v, data[0], data[1]];
        break;
    }
  }
  return '#' + rgb.map(function(x){ 
    return ("0" + Math.round(x*255).toString(16)).slice(-2);
  }).join('');
};
