function _ht_flatten(pairs, data, prefix) {
	for(var n in data) {
		var v = data[n];
		if (!v && v != 0)
			v = "";
		if (v instanceof Array) {
			if (v.length == 0) {
				pairs.push([ prefix + n, "" ]);
				continue;
			}

			if (!(v[0] instanceof Object)) {
				pairs.push([ prefix + n, v.join(",") ]);
				continue;
			}

			for (var i = 0; i < v.length; i++)
				_ht_flatten(pairs, v[i],
					prefix + n + "__" + (i + 1) + "__");
		}
		else 
			pairs.push([ prefix + n, v ]);
	}
}

function ht_serializer_flatten(data) {
	var pairs = [];
	_ht_flatten(pairs, data, "");
	return pairs;
}

/* Synch requests are bad: block FF 3.0. Don't do them at all */
function _ht_ser_open_request(method, url, cb) {
	var req = new XMLHttpRequest();
	req.onreadystatechange = function() {
		if (req.readyState == 4)
			cb(req);
	};
	req.open(method, url, true);
	return req;
}

function ht_serializer_encode(val) {
	return ht_serializer_flatten(val).map(function(a) {
		return a[0] + '=' + encodeURIComponent(a[1])
					.replace(/%20/g, "+");
	}).join('&');
}

function ht_serializer_submit(val, url, cb) {
	var req = _ht_ser_open_request("POST", url, cb);
	req.setRequestHeader("Content-Type"
			, "application/x-www-form-urlencoded");
	req.send(ht_serializer_encode(val));
}

function ht_serializer_prepare_form(form_id, ser) {
	var form = document.getElementById(form_id);
	ht_serializer_flatten(ser).forEach(function(a) {
		h = document.createElement("input");
		h.type = "hidden";
		h.name = a[0];
		h.id = a[0];
		h.value = a[1];
		h._ht_ser_generated = true;
		form.appendChild(h);
	});
}

function ht_serializer_reset_form(form_id) {
	var form = document.getElementById(form_id);
	var form_els = form.elements;
	var arr = [];
	for (var i = 0; i < form_els.length; i++)
		arr.push(form_els[i]);

	for (var i = 0; i < arr.length; i++) {
		if (!arr[i]._ht_ser_generated)
			continue;
		arr[i].parentNode.removeChild(arr[i]);
		delete form[ arr[i].name ];
	}
}

function ht_serializer_get(url, cb) {
	_ht_ser_open_request("GET", url, cb).send(null);
}

function ht_serializer_extract(n, str) {
	return str.replace(new RegExp("^[\\s\\S]*<script>//<!\\[CDATA\\[\\nvar "
		+ n + " = ", "m"), "")
			.replace(/;\/\/\]\]>\n<\/script>[\s\S]*$/m, "");
}

function _ht_ser_eq(a, b) {
	if (a instanceof Array)
		a = a.join("");
	if (b instanceof Array)
		b = b.join("");
	return a == b;
}

function ht_serializer_diff_hash(old_o, new_o, res) {
	var cnt = 0;
	for (var k in new_o) {
		if (k in old_o && _ht_ser_eq(old_o[k], new_o[k]))
			continue;
		res[k] = new_o[k];
		cnt++;
	}
	for (var k in old_o) {
		if (k in new_o)
			continue;
		res[k] = undefined;
		cnt++;
	}
	return cnt;
}

function _ht_ser_key(keys, o) {
	return keys.map(function(k) { return o[k]; }).join("");
}

function _ht_ser_set_key(keys, from, to) {
	for (var i = 0; i < keys.length; i++)
		to[ keys[i] ] = from[ keys[i] ];
}

function ht_serializer_diff_array(keys, before, after, res, del, unordered) {
	var bhash = {};
	var indexes = {};
	for (var i = 0; i < before.length; i++) {
		var k = _ht_ser_key(keys, before[i]);
		bhash[k] = before[i];
		indexes[k] = i;
	}

	var cnt = 0;
	for (var i = 0; i < after.length; i++) {
		var k = _ht_ser_key(keys, after[i]);
		var be = bhash[k];
		var af = {};
		if (be) {
			if (ht_serializer_diff_hash(be, after[i], af)
					|| (!unordered && indexes[k] != i))
				cnt++;
			_ht_ser_set_key(keys, after[i], af);
			delete bhash[k];
		} else {
			af = after[i];
			cnt++;
		}
		res.push(af);
	}
	for (var i in bhash) {
		var n = {};
		_ht_ser_set_key(keys, bhash[i], n);
		del.push(n);
	}
	return cnt + del.length;
}
