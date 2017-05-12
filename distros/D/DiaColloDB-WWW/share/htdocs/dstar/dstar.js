// -*- Mode: Javascript; coding: utf-8 -*-


//=============================================================================)
// index

function queryVar(key) {
  return $.url().param(key);
}

//-- any2bool(): (anything)-to-boolean conversion
function any2bool(val) {
  if      (typeof(val) == "boolean") { ; }
  else if (typeof(val) == "string")  { val = (val != "" && val != "false" && val != "no" && val != "off" && val != "0"); }
  else if (typeof(val) == "number")  { val = (val != 0); }
  else                               { val = (val != null); }
  return val;
}

//-- optObj = selectOption(selectObj,valStr)
function selectOption(selectObj,valStr) {
  for (opti in selectObj.options) {
    opt = selectObj.options[opti];
    if (opt.value == valStr) {
      return opt;
    }
  }
  return null;
}

//--------------------------------------------------------------
// val = valGet(nod_or_id)
function valGet(id) {
    var nod = id;
    if (typeof(nod) == 'string') {
	nod = document.getElementById(id);
    }
    if (nod==null) {
	throw("valGet(): no node for id="+id);
	return null;
    }
    var ttag = nod.tagName.toLowerCase();

    if (ttag=="input" || ttag=="select" || ttag=="textarea") {
	var ttype = nod.getAttribute('type');
	if (ttype==null) { ttype=ttag; }
	ttype = ttype.toLowerCase();
	if (ttype=="checkbox")    { return nod.checked; }
	else if (ttype=="select") { return nod.options[nod.selectedIndex].value; }
	else { return nod.value; }
    }
    return nod.innerHTML;
}

//--------------------------------------------------------------
// undef = valSet(nod_or_id,val)
function valSet(id,val) {
    var nod = id;
    if (typeof(nod) == 'string') {
        nod = document.getElementById(id);
    }
    if (nod==null) {
	throw("valSet(): no node for id="+id+", val="+val);
	return null;
    }
    if (val==null) {
	val = "";
    }
    var ttag = nod.tagName.toLowerCase();
    if (ttag=="input" || ttag=="select") {
	var ttype = nod.getAttribute('type');
	if (ttype==null) { ttype = ttag; }
	ttype = ttype.toLowerCase();
	if (ttype=="checkbox")    { nod.checked = Boolean(val); }
	else if (ttype=="select") {
	  for (opti in nod.options) {
	    if (nod.options[opti].value == val) {
	      nod.selectedIndex = opti;
	      break;
	    }
	  }
	}
	else { nod.value = String(val); }
    } else {
	nod.innerHTML = String(val);
    }
}

//-- set a generic input object default value (if non-null)
function initInput(qvar, qparam) {
    var qval = $.url().param(qparam==null ? qvar : qparam);
    if (qval != null) {
	valSet("in_"+qvar,qval);
    }
}

function userFormInit() {
  initInput("qq");
  initInput("q");
  initInput("fmt");
  initInput("start");
  initInput("limit");
  initInput("ctx");
  initInput("debug");
  if (document.getElementById('in_flags') != null) {
      initInput("flags", "corpus");
      initInput("flags");
  }

  autocompleteInit();

  //-- for chromium, since this isn't a root path (throws up a dialog)
  //if (window.external.AddSearchProvider != null) { window.external.AddSearchProvider("http://kaskade.dwds.de/dtaos/dta-ddc-osd.xml"); }
  document.getElementById('in_q').focus();
}

function userFormSubmit() {
  var uqq = document.getElementById('in_qq').value;
  var uq  = document.getElementById('in_q').value;
  var qfq = document.getElementById('qf_q');

  qfq.value = uq;
  if (any2bool(uqq)) { qfq.value += ' ' + uqq; }

  valSet('qf_fmt',valGet('in_fmt'));
  valSet('qf_start',valGet('in_start'));
  valSet('qf_limit',valGet('in_limit'));
  valSet('qf_ctx',valGet('in_ctx'));
  if (any2bool(valGet('in_debug'))) { valSet('qf_debug',1); }
  else { valSet('qf_debug',''); }
  if (document.getElementById('in_flags') != null) { valSet('qf_flags',valGet('in_flags')); }

  document.getElementById('queryForm').submit();
  return false;
}

function userFormReset() {
  document.getElementById('userForm').reset();
  userFormInit();
  document.getElementById('in_qq').value = "";
}


//=============================================================================)
// html, kwic

//----------------------------------------------------------------------
var autocomplete_options;
function dstarSearchInit() {
    //-- hit expander
    $(".dtaHitExpander").prop("href", function() {
	return "javascript:toggleHitMeta("+$(this).parents("[hit_i]").attr("hit_i")+")";
    });

    autocompleteInit();
}

//----------------------------------------------------------------------
function autocompleteInit() {
    if (autocomplete_options != null) {
	$(function() {
	    $("input.ddcQuery").autocomplete(autocomplete_options);
	});
    }
}

//----------------------------------------------------------------------
function toggleHitMeta(hit_i) {
  var meta = $("#hitMeta"+hit_i);
  var tgl  = $("#hitMeta"+hit_i+"Tgl");
  meta.toggle();
  if (meta.is(":visible")) {
    tgl.text("[<<less]");
  } else {
    tgl.text("[more>>]");
  }
}


//----------------------------------------------------------------------
if (typeof String.prototype.trim != 'function') { // detect native implementation
  String.prototype.trim = function () {
      return this.replace(/^\s+/, '').replace(/\s+$/, '').replace(/\s+/g,' ');
  };
}
//----------------------------------------------------------------------
String.prototype.xlit = function () {
    return (this
	    .replace(/ſ/g, 's')
	    .replace(/aͤ/g, 'ä')
	    .replace(/oͤ/g, 'ö')
	    .replace(/uͤ/g, 'ü')
	    .replace(/Aͤ/g, 'Ä')
	    .replace(/Oͤ/g, 'Ö')
	    .replace(/Uͤ/g, 'Ü')
	   );
};

//=============================================================================)
// caberr stuff

var caberr_url_base = "/caberr";
function cabErrBtnClick() {
    //-- now construct caberr insert-query
    var iq  = {
	"wold":"" //,"wbad":null, "wnew":null 
	//,"dtaid":null ,"dtadir":null ,"page":null ,"ctx":null
    };
    var wdom = null;

    //-- first try: use selected text
    if (window.getSelection().rangeCount > 0) {
	var rng = window.getSelection().getRangeAt(0);
        iq.wold = rng.toString().trim();
	iq.how  = "selection";
	wspan   = $(rng.startContainer).parents("[title*=', v=']").first();
    }

    //-- second try: use first matched token
    if (iq.wold == "") {
	wspan   = $(".matchedToken").first();
	iq.wold = wspan.text().trim();
	iq.how  = "match";
	wspan   = wspan.add(wspan.contents()).filter("[title*=', v=']").first();
    }

    //-- mapping properties
    iq.wbad = wspan.attr("title").replace(/^.*, v=/,'').replace(/, p=.*$/,'').trim();
    if (iq.wbad == "-") { iq.wbad = "???"; }
    iq.wnew = prompt("Correct contemporary form for mapping ( "+iq.wold+" -> "+iq.wbad+" )", iq.wold.xlit());
    if (iq.wnew == null) { return; }

    //-- context properties
    var hittr = wspan.parents("[dstarid]");
    iq.dtaid  = hittr.attr("dstarid");
    iq.dtadir = hittr.attr("base");
    iq.page   = hittr.attr("page");
    iq.ctx    = hittr.find(".hitText").text().replace(iq.wold, "  *"+iq.wold+"  ").trim();

    //alert(JSON.stringify(iq)); return; //-- DEBUG

    //-- setup insert-request
    delete iq.how;
    if (iq.wbad == iq.wnew || iq.wbad == "???") { delete iq.wbad; }
    var iq_url = caberr_url_base + "/insert.perl?" + jQuery.param(iq);
    window.open(iq_url,'_blank');
}


//=============================================================================)
// histogram stuff

//-- user query params
var user_query = {};
var user_pformat = "";

//-- timing
var ttk_elapsed = 0;

//----------------------------------------------------------------------
// histogram: init

function ubool(b) {
    return (String(b).search('^(0|n|no|false|f|off)?$') != 0);
}

function dhistReady() {
    //-- display user query
    $("#i_query").val(user_query["query"]);
    $("#i_norm").val(user_query["norm"]);
    $("#i_slice").val(user_query["slice"]);
    $("#i_window").val(user_query["window"]);
    $("#i_wbase").val(user_query["wbase"]);
    $("#i_totals").prop('checked', ubool(user_query["totals"]) );
    $("#i_single").prop('checked', ubool(user_query["single"]) );
    $("#i_grand").prop('checked', ubool(user_query["grand"]) );
    $("#i_grid").prop('checked', ubool(user_query["grid"]) );
    //$("#i_logproj").prop('checked', ubool(user_query["logproj"]) );
    $("#i_logavg").prop('checked', ubool(user_query["logavg"]) );

    $("#i_logscale").prop('checked', ubool(user_query["logscale"]) );
    $("#i_xrange").val(user_query["xrange"]);
    $("#i_yrange").val(user_query["yrange"]);
    $("#i_pformat").val(user_pformat);
    $("#i_psize").val(user_query["psize"]);
    $("#i_smooth").val(user_query["smooth"]);
    $("#i_points").prop('checked', ubool(user_query["points"]) );
    $("#i_gaps").prop('checked', ubool(user_query["gaps"]) );
    $("#i_prune").val(user_query["prune"]);

    //-- watch image loading
    var t0 = jQuery.now();
    if ($("#plotData").length == 0) {
	$("#statusMsg").text("(no query specified)").show();
    } else {
	//$("#statusMsg").text("loading...").show();
	$("#plotData").hide().load(function() {
	    var t1      = jQuery.now();
	    var elapsed = (ttk_elapsed + (t1-t0)/1000.0);
	    elapsed     = Math.floor(elapsed*10000)/10000.0;
	    $("#elapsed").hide().text(elapsed + " sec").fadeIn();
	    $("#statusMsg").hide();
	    $(this).fadeIn();
	});
    }
}

function plotError() {
    $("#statusMsg").addClass("errorMsg").text("ERROR: failed to plot histogram data").show();
    //$("#plotErrorFrame").attr('src', $("#plotData").attr('src')).show();
    $("#plotLink").show();
}

function escapeDDC(s) {
    if (s.search(/\W/) == -1) { return s; }
    return "'" + s.replace(/['\\]/g,"\\$&") + "'";
}

//=============================================================================)
// expand (lizard)

function expandOnLoad(){
  if (document.getElementsByClassName == undefined) {
	document.getElementsByClassName = function(className)
	{
		var hasClassName = new RegExp("(?:^|\\s)" + className + "(?:$|\\s)");
		var allElements = document.getElementsByTagName("*");
		var results = [];
		var element;
		for (var i = 0; (element = allElements[i]) != null; i++) {
			var elementClass = element.className;
			if (elementClass && elementClass.indexOf(className) != -1 && hasClassName.test(elementClass))
				results.push(element);
		}
		return results;
	}
  }
  setAllExpansions(true);
}

function setAllExpansions(val) {
  xelts = document.getElementsByClassName('xcheckbox');
  for (var xi=0; xi < xelts.length; xi++) {
    xelts[xi].checked = val;
  }
}


function ddcQuote(s) {
  if (s.search(/[^a-zA-Z0-9\xe4\xf6\xfc\xc4\xd6\xdc\xdf\u017f\u0364]/) < 0) { return s; }
  return "'"+s.replace("\\","\\\\").replace("'","\\'")+"'";
}

function queryUrl() {
  xelts = document.getElementsByClassName('xcheckbox');
  qargs = [];
  for (var xi=0; xi < xelts.length; xi++) {
    if (!xelts[xi].checked) { continue; }
    qargs.push(ddcQuote(xelts[xi].value));
  }
  //return "dta.perl?q="+encodeURIComponent("@{"+qargs.join(",")+"}");
  return "@{" + qargs.join(", ") + "}";
}

function querySubmit() {
  qurl = queryUrl();
  document.getElementById("xQueryValue").value = qurl;
  document.getElementById("xQueryForm").submit();
}

