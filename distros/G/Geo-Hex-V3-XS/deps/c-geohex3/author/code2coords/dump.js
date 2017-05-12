"use strict";

var fs   = require('mz/fs');
var http = require('http');
var co   = require('co');

var get = function (url) {
  return new Promise(function (resolve, error) {
    http.get(url, function (res) {
      res.setEncoding('utf8');

      var buf = "";
      res.on('data', function (chunk) {
        buf += chunk;
      });
      res.on('end', function (chunk) {
        resolve(buf);
      });
    }).on('error', error);
  });
};

var getGeoHex = co(function *() {
  var window = {};

  var vm = require('vm');
  vm.createContext(window);

  var body = yield get("http://geohex.net/src/script/hex_v3.2_core.js");
  vm.runInContext(body, window);

  return window.GEOHEX;
});

var getCodes = co(function *() {
  var body = yield get('http://geohex.net/testcase/hex_v3.2_test_code2HEX.json');
  return JSON.parse(body).map(function (row) { return row[0]; });
});

co(function *() {
  var GeoHex = yield getGeoHex;
  var codes  = yield getCodes;

  var expects = [];
  codes.forEach(function (code) {
    var zone  = GeoHex.getZoneByCode(code);
    var coods = zone.getHexCoords().map(function (row) { return [row["lat"], row["lon"]]; });
    coods.unshift(code);
    expects.push(coods);
  });

  yield fs.writeFile("code2coords.json", JSON.stringify(expects, null, "  "));
  return;
});
