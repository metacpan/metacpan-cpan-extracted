#!/usr/bin/env jss

use("Froody.DocFormatter");

var format = PodFormatter;

if (script.args.length > 1 && script.args[0] == '--wiky') {
  format = WikyFormatter;
  script.args.shift();
}

if (script.args.length != 1)
  throw "Usage: " + script.name + " [--wiky] My::Froody::API";

var api = script.args[0]
var formatter = new format(api);

// get the XML docs using perl, because it uses substitution
// placeholders all over the place.
var data = perl(sprintf("use lib 'lib';use %s; %s->xml()", api, api));

print(formatter.processFroodyXML(data));
