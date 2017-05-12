/*
 * WebSocket client to test McBain APIs running with McBain::WithWebSocket
 * =======================================================================
 * Requires: NodeJS and the ws module (`npm install ws`)
 * To use this client, run `node client.js 8080` (change to the port where
 * your server is running). You can then issue requests to the API by
 * printing lines into the console, in the format "key1=value1 key2=value2",
 * which will be automatically converted into an object and then into JSON.
 * So, for example, echoing "path=GET:/math/sum one=1 two=2" will send the
 * JSON string '{ "path": "GET:/math/sum", "one": 1, "two": 2 }' to the API.
 * The result will be printed to the console.
 * Use Ctrl+D to close the console.
 */

var WebSocket = require('ws');

process.stdin.setEncoding('utf8');

var port = process.argv[2] || 8080;

var ws = new WebSocket('ws://localhost:'+port);
ws.on('message', function(data, flags) {
	console.log(data);
});

process.stdin.on('readable', function() {
	var chunk = process.stdin.read();
	if (chunk !== null) {
		var object = {};
		chunk.trim().split(' ').forEach(function(val) {
			var s = val.split('=');
			object[s[0]] = s[1];
		});
		console.log(object);
		ws.send(JSON.stringify(object));
	}
});

process.stdin.on('end', function() {
	process.exit(0);
});