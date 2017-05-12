function _htre_win(id) { return document.getElementById(id).contentWindow; }
function htre_document(id) { return _htre_win(id).document; }

function _htre_parse_id(d) {
	var arr = d.id.match(/^(.+)_(\w+)$/);
	return [ arr[1], arr[2] ];
}

var _htre_state_tags = { FONT: [ "fontsize", function(n) { return n.size; } ]
	, OL: [ "insertorderedlist", function(n) { return true; } ]
	, A: [ "link", function(a) { return a.href; } ]
	, UL: [ "insertunorderedlist", function(n) { return true; } ] };

var _htre_state_styles = { fontname: "fontFamily", forecolor: "color"
		, hilitecolor: "backgroundColor", bold: "fontWeight"
		, underline: "textDecoration", italic: "fontStyle"
		, textalign: "textAlign" };

function htre_get_selection_state(id) {
	var sel = _htre_win(id).getSelection();
	if (!sel)
		return;

	var res = { selection: sel };
	var an = sel.focusNode;
	if (an.tagName && an.tagName.toUpperCase() == "BODY" && an.childNodes.length == 1)
		an = an.childNodes[0];

	for (; an; an = an.parentNode) {
		if (!an.tagName)
			continue;

		var st = _htre_state_tags[an.tagName.toUpperCase()];
		if (st && !(st[0] in res))
			res[ st[0] ] = st[1](an);

		for (var i in _htre_state_styles)
			if (!res[i])
				res[i] = an.style[ _htre_state_styles[i] ];
	}
	res[ "justify" + res.textalign ] = true;
	return res;
}

function htre_get_selection(id) {
	return _htre_win(id).getSelection();
}

function htre_focus(id) {
	setTimeout(function() { _htre_win(id).focus(); }, 0);
}

function htre_exec_command(id, cmd, arg) {
	htre_document(id).execCommand(cmd, false, arg);
	htre_focus(id);
}

function htre_insert_image(id, src) {
	var bad_img = "file:///_htre_foo";
	htre_exec_command(id, "insertimage", bad_img);
	var ims = htre_document(id).getElementsByTagName("img");
	for (var i = 0; i < ims.length; i++)
		if (ims[i].src == bad_img) {
			ims[i].src = src;
			return ims[i];
		}
}

function _htre_exec_cmd_with_tag(d, arg) {
	var pres = _htre_parse_id(d);
	htre_exec_command(pres[0], pres[1], arg);
}

function _htre_but_command(e) { _htre_exec_cmd_with_tag(e.currentTarget); }

function _htre_sel_command(e) {
	var d = e.currentTarget;
	if (d.selectedIndex > 0)
		_htre_exec_cmd_with_tag(d, d.options[d.selectedIndex].value);
	else
		htre_focus(_htre_parse_id(d)[0]);
}

var _htre_modifiers = [ [ "bold", "click", _htre_but_command ]
	, [ "italic", "click", _htre_but_command ]
	, [ "underline", "click", _htre_but_command ]
	, [ "justifyleft", "click", _htre_but_command ]
	, [ "justifyright", "click", _htre_but_command ]
	, [ "justifycenter", "click", _htre_but_command ]
	, [ "insertorderedlist", "click", _htre_but_command ]
	, [ "insertunorderedlist", "click", _htre_but_command ]
	, [ "outdent", "click", _htre_but_command ]
	, [ "indent", "click", _htre_but_command ]
	, [ "undo", "click", _htre_but_command ]
	, [ "redo", "click", _htre_but_command ]
	, [ "fontname", "change", _htre_sel_command ]
	, [ "fontsize", "change", _htre_sel_command ] ];

function _htre_on_paste(id) {
	var ix = htre_get_value(id);
	htre_set_value(id, htre_escape(ix));
}

function htre_init(id) {
	/* Do it only once - no way to test it ... */
	if (htre_document(id).designMode == "on")
		return;

	htre_document(id).designMode = "on";
	for (var i = 0; i < _htre_modifiers.length; i++) {
		var mod = _htre_modifiers[i];
		var bo = document.getElementById(id + "_" + mod[0]);
		if (!bo)
			continue;

		/* For some reason, closure doesn't work here ... */
		bo.addEventListener(mod[1], mod[2], false);
	}
	htre_document(id).body.addEventListener("paste", function(e) {
		setTimeout(function() { _htre_on_paste(id); }, 0);
	}, false);
}

function htre_register_on_load(id) {
	window.addEventListener("load", function() { htre_init(id) }, false);
}

function htre_get_inner_xml(node) {
	var xml = (new XMLSerializer()).serializeToString(node);
	var b = new RegExp("^<" + node.nodeName + "[^>]*>", "i");
	var e = new RegExp("</" + node.nodeName + ">$", "i");
	return xml.replace(b, "").replace(e, "").replace(/ _moz_\w+="\w*"/g, "");
}

function htre_get_value(id) {
	/* innerHTML doesn't return valid XML, so do it hard way... */
	return htre_get_inner_xml(htre_document(id).body);
}

function htre_set_value(id, val) {
	htre_document(id).body.innerHTML = val;
}

function htre_add_onchange_listener(id, func) {
	htre_document(id).addEventListener("blur", func, false);
}

var htre_tag_whitelist = { SPAN: 1, BR: 1, P: 1, HTRE: 1
	, FONT: 1, DIV: 1, OL: 1, LI: 1, UL: 1, A: 1, IMG: 1 };
var htre_attr_whitelist = { style: 1, size: 1, href: 1, src: 1 };
function _htre_escape_filter(doc, no_recurse) {
	var tags = [];
	var again = false;
	while (doc.childNodes.length) {
		var d = doc.removeChild(doc.childNodes[0]);
		if (!d || !d.nodeName)
			continue;

		if (htre_tag_whitelist[d.nodeName.toUpperCase()]
				|| d.nodeName == "#text") {
			tags.push(d);
			continue;
		}

		for (var i = 0; i < d.childNodes.length; i++)
			tags.push(d.childNodes[i]);

		again = true;
	}

	for (var i = 0; i < tags.length; i++) {
		var d = tags[i];
		for (var j = 0; j < (d.attributes || []).length; j++) {
			var a = d.attributes[j];
			if (!a || !a.nodeName)
				continue;
			if (!htre_attr_whitelist[a.nodeName])
				d.removeAttribute(a.name);
		}

		if (!no_recurse)
			_htre_escape_filter(d);
		doc.appendChild(d);
	}
	if (again)
		_htre_escape_filter(doc, true);
}

function htre_escape(str) {
	str = "<HTRE>" + str + "</HTRE>"; 
	var doc = (new DOMParser()).parseFromString(str, "application/xml");
	if (doc.childNodes[0].nodeName != "HTRE")
		return str.replace(/<\/?[^>]+>/g, "");
	_htre_escape_filter(doc);
	return htre_get_inner_xml(doc.getElementsByTagName("HTRE")[0]);
}

function htre_do_tick(doc, name, cb, msecs) {
	if (doc._htre_tick_active)
		return;

	doc._htre_tick_active = true;
	setTimeout(function() {
		var state = htre_get_selection_state(name);
		if (state)
			cb(name, state);
		doc._htre_tick_active = false;
	}, msecs);
}

function htre_listen_for_state_changes(name, cb, msecs) {
	var doc = htre_document(name);
	var f = function(e) { htre_do_tick(e.currentTarget, name, cb, msecs); };
	doc.addEventListener("keypress", f, true);
	doc.addEventListener("mouseup", f, true);
	doc.addEventListener("mousedown", f, true);
}
