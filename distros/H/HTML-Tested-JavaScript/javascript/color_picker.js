/* r, g, b are between 0-255. h is in [0-360]. v,s in [0-100] */
function htcp_rgb_to_hsv(r, g, b) {
	var h, s, v;
	var min, max, delta;

	r /= 255;
	g /= 255;
	b /= 255;

	min = Math.min(r, g, b);
	max = Math.max(r, g, b);
	v = max;

	delta = max - min;
	if (max != 0)
		s = delta / max;
	else 
		return [ 0, 0, 0 ];

	if( r == max )
		h = (g - b) / delta;
	else if(g == max)
		h = 2 + (b - r) / delta;
	else
		h = 4 + (r - g) / delta;

	h *= 60;
	if(h < 0)
		h += 360;
	else if (isNaN(h))
		h = 360;

	return [ Math.round(h), Math.round(s * 100), Math.round(v * 100) ];
}

function htcp_client_x(e) { return e.clientX + window.pageXOffset; }
function htcp_client_y(e) { return e.clientY + window.pageYOffset; }

function htcp_save_x_dimensions(el, e, ctx) {
	ctx.down_x = htcp_client_x(e);
	ctx.el_x = parseFloat(el.style.left);
}

function htcp_save_y_dimensions(el, e, ctx) {
	ctx.down_y = htcp_client_y(e);
	ctx.el_y = parseFloat(el.style.top);
}

function _htcp_half_height(el) { return (parseFloat(el.offsetHeight) / 2); }
function _htcp_half_width(el) { return (parseFloat(el.offsetWidth) / 2); }

function htcp_move_by_x(el, e, ctx) {
	var pos = htcp_client_x(e) - ctx.down_x + ctx.el_x;
	var hw = _htcp_half_width(el);
	var max = el.parentNode.offsetWidth - hw;
	if (pos > max)
		pos = max;
	else if (pos < -hw)
		pos = -hw;
	el.style.left = pos + "px";
}

function htcp_move_by_y(el, e, ctx) {
	var pos = htcp_client_y(e) - ctx.down_y + ctx.el_y;
	var hh = _htcp_half_height(el);
	var max = el.parentNode.offsetHeight - hh;
	if (pos > max)
		pos = max;
	else if (pos < -hh)
		pos = -hh;
	el.style.top = pos + "px";
}

function htcp_listen_for_mouse_events(el, mdown, mmove, mup) {
	var myup = function(e) {
		e.stopPropagation();
		e.preventDefault();
		document.removeEventListener("mousemove", mmove, true);
		document.removeEventListener("mouseup", myup, true);
		mup(e);
	}
	var mydown = function(e) {
		e.stopPropagation();
		e.preventDefault();
		document.addEventListener("mousemove", mmove, true);
		document.addEventListener("mouseup", myup, true);
		mdown(e);
	}
	el.addEventListener("mousedown", mydown, false);
	return mydown;
}

function htcp_init(name, hook) {
	window.addEventListener("load", function(e) {
		_htcp_init(name, hook); }, false);
}

function _htcp_cond_set(id, v) {
	var eb = document.getElementById(id);
	if (eb)
		eb.value = v;
}

function _htcp_set_rgb_indicators(name, r, g, b) {
	_htcp_cond_set(name + "_rgb_r", r);
	_htcp_cond_set(name + "_rgb_g", g);
	_htcp_cond_set(name + "_rgb_b", b);
	_htcp_cond_set(name + '_rgb_hex'
		, htcp_hex(r) + htcp_hex(g) + htcp_hex(b));
	var cc = document.getElementById(name + "_current_color");
	if (cc)
		cc.style.backgroundColor = "rgb(" + r + "," + g + "," + b + ")";
	window["__htcp_" + name + "_rgb"] = [ r, g, b ];
}

function _htcp_calculate_hue_rgb(name) {
	var hup = document.getElementById(name + "_hue_pointer");
	var c = _htcp_calc_color(hup);
	var n = 256/6, j = ((256/n) * (c % n));

	var hue_r = parseInt(c<n?255:c<n*2?255-j:c<n*4?0:c<n*5?j:255);
	var hue_g = parseInt(c<n*2?0:c<n*3?j:c<n*5?255:255-j);
	var hue_b = parseInt(c<n?j:c<n*3?255:c<n*4?255-j:0);
	document.getElementById(name + "_color").style.backgroundColor
			= "rgb(" + hue_r + "," + hue_g + "," + hue_b + ")";
	return [ hue_r, hue_g, hue_b ];
}

function _htcp_calc_ratio(ptr) {
	var ry = 1 / ptr.parentNode.offsetHeight;
	return (parseFloat(ptr.style.top) + _htcp_half_height(ptr)) * ry;
}

function _htcp_calc_color(ptr) { return parseInt(_htcp_calc_ratio(ptr) * 255); }

function _htcp_set_color_from_indicators(name) {
	var ptr = document.getElementById(name + "_color_pointer");
	var rx = 100 / ptr.parentNode.offsetWidth;
	var ptr_x = (parseFloat(ptr.style.left) + _htcp_half_width(ptr)) * rx;
	var ptr_x_col = parseInt(ptr_x * 255/100);
	var ptr_y_col = _htcp_calc_color(ptr);

	var h = _htcp_calculate_hue_rgb(name);

	var r = Math.round((1-(1-(h[0]/255))*(ptr_x_col/255))*(255-ptr_y_col));
	var g = Math.round((1-(1-(h[1]/255))*(ptr_x_col/255))*(255-ptr_y_col));
	var b = Math.round((1-(1-(h[2]/255))*(ptr_x_col/255))*(255-ptr_y_col));
	_htcp_set_rgb_indicators(name, r, g, b);
}

function htcp_set_indicators_from_rgb(name, r, g, b) {
	var hsv = htcp_rgb_to_hsv(r, g, b);
	var hup = document.getElementById(name + "_hue_pointer");
	var hph = hup.parentNode.offsetHeight;
	var huo = hup.offsetHeight;
	hup.style.top = (hph - (hsv[0] / 360) * hph - huo / 2) + "px";

	var ptr = document.getElementById(name + "_color_pointer");
	ptr.style.left = ((hsv[1] / 100) * ptr.parentNode.offsetWidth
		- ptr.offsetWidth / 2) + "px";
	ptr.style.top = (((100 - hsv[2]) / 100) * ptr.parentNode.offsetHeight
		- ptr.offsetHeight / 2) + "px";
	_htcp_calculate_hue_rgb(name);
	_htcp_set_rgb_indicators(name, r, g, b);
	_htcp_set_prev_color(name);
}

function htcp_hex(c) {
	c = c.toString(16);
	return c.length < 2 ? "0" + c : c;
}

function htcp_int_to_rgb(i) {
	var r = (i & (255 << 16)) >> 16;
	var g = (i & (255 << 8)) >> 8;
	var b = (i & 255);
	return [ r, g, b ];
}

function htcp_current_color(name) { return window["__htcp_" + name + "_rgb"]; }

function _htcp_set_prev_color(name) {
	var prev = document.getElementById(name + "_prev_color");
	var cur = document.getElementById(name + "_current_color");
	if (prev && cur)
		prev.style.backgroundColor = cur.style.backgroundColor;

	var hook = window["__htcp_" + name + "_hook"];
	if (!hook)
		return;
	var arr = htcp_current_color(name);
	hook(name, arr[0], arr[1], arr[2]);
}

function _htcp_on_rgb_enter(e) {
	var id = e.currentTarget.id;
	var r = parseInt(document.getElementById(id.replace(/\w$/, "r")).value);
	var g = parseInt(document.getElementById(id.replace(/\w$/, "g")).value);
	var b = parseInt(document.getElementById(id.replace(/\w$/, "b")).value);
	htcp_set_indicators_from_rgb(id.replace(/_rgb_\w$/, ""), r, g, b);
}

function _htcp_on_hex_enter(e) {
	var inp = e.currentTarget;
	var c = htcp_int_to_rgb(parseInt("0x" + inp.value));
	_htcp_set_rgb_indicators(name, c[0], c[1], c[2]);
	htcp_set_indicators_from_rgb(inp.id.replace(/_rgb_hex$/, "")
		, c[0], c[1], c[2]);
}

function _htcp_add_rgb_hook(name, sfx, hook) {
	var eb = document.getElementById(name + "_rgb_" + sfx);
	if (!eb)
		return;
	eb.addEventListener("keydown", function(e) {
		if (e.keyCode == 13)
			hook(e);
	}, true);
	eb.addEventListener("change", hook, true);
}

function htcp_get_absolute_offsets(el, stop) {
	var x = 0;
	var y = 0;
	/* offsetParent != parentNode. E.g. in list-items offsetParent == 0 */
	while (el) {
		if (stop && stop.isSameNode(el))
			break;
		x += el.offsetLeft;
		y += el.offsetTop;
		el = el.offsetParent;
	}
	return [ x, y ];
}

function _htcp_register_pointer(ptr, name, down, move) {
	var up = function(e) { _htcp_set_prev_color(name); };
	htcp_listen_for_mouse_events(ptr, down, move, up);
	ptr.parentNode.addEventListener("mousedown", function(e) {
		var poffs = htcp_get_absolute_offsets(ptr);
		down({ clientX: poffs[0] + _htcp_half_width(ptr)
			, clientY: poffs[1] + _htcp_half_height(ptr) });
		move(e);
		up();
	}, false);
}

function _htcp_init(name, hook) {
	var ptr = document.getElementById(name + "_color_pointer");
	var pctx = {};
	_htcp_register_pointer(ptr, name, function(e) {
		htcp_save_x_dimensions(ptr, e, pctx);
		htcp_save_y_dimensions(ptr, e, pctx);
	}, function(e) {
		htcp_move_by_x(ptr, e, pctx);
		htcp_move_by_y(ptr, e, pctx);
		_htcp_set_color_from_indicators(name);
	});

	var hup = document.getElementById(name + "_hue_pointer");
	var hctx = {};
	_htcp_register_pointer(hup, name, function(e) {
		htcp_save_y_dimensions(hup, e, hctx);
	}, function(e) {
		htcp_move_by_y(hup, e, hctx);
		_htcp_set_color_from_indicators(name);
	});

	_htcp_add_rgb_hook(name, "r", _htcp_on_rgb_enter);
	_htcp_add_rgb_hook(name, "g", _htcp_on_rgb_enter);
	_htcp_add_rgb_hook(name, "b", _htcp_on_rgb_enter);

	_htcp_add_rgb_hook(name, "hex", _htcp_on_hex_enter);
	window["__htcp_" + name + "_hook"] = hook;
}

function _htzp_view_size(par, pos, sz, k) {
	var nsz = par.baseVal.value * k;
	return pos - (nsz - sz) / 2;
}

function _htzp_set_zoom(ptr, z_factor, c) {
	var k = 1/Math.pow(z_factor, _htcp_calc_ratio(ptr) - 0.5);
	c.g.setAttribute("transform", c.tr + " scale(" + k + ", " + k + ")");
}

function htzp_init(ptr_name, range) {
	var ptr = document.getElementById(ptr_name);
	var he = (ptr.parentNode.offsetHeight - ptr.offsetHeight) / 2;
	ptr.style.top = he + "px";

	var svg = document.getElementsByTagName("svg")[0];
	var hctx = { g: document.getElementsByTagName("g")[0] };
	hctx.tr = hctx.g.getAttribute("transform");
	htcp_listen_for_mouse_events(ptr, function(e) {
		htcp_save_y_dimensions(ptr, e, hctx);
	}, function(e) {
		htcp_move_by_y(ptr, e, hctx);
		_htzp_set_zoom(ptr, range * range, hctx);
	}, function(e) {});

	var pan_c = {};
	htcp_listen_for_mouse_events(svg, function(e) {
		pan_c.down_x = htcp_client_x(e);
		pan_c.down_y = htcp_client_y(e);
		pan_c.view_box = svg.getAttribute("viewBox").split(" ");
	}, function(e) {
		var pos_x = -(htcp_client_x(e) - pan_c.down_x)
				+ Number(pan_c.view_box[0]);
		var pos_y = -(htcp_client_y(e) - pan_c.down_y)
				+ Number(pan_c.view_box[1]);
		svg.setAttribute("viewBox", pos_x + " " + pos_y
			+ " " + pan_c.view_box[2] + " " + pan_c.view_box[3]);
	}, function(e) {});
}
