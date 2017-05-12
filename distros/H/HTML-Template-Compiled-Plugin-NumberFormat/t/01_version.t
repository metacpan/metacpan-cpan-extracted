# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-Template-Compiled.t'
# $Id: 02_version.t 54 2005-09-19 20:59:43Z tinita $

use Test::More tests => 2;
BEGIN { use_ok('HTML::Template::Compiled::Plugin::NumberFormat') };

ok(HTML::Template::Compiled::Plugin::NumberFormat->__test_version, "version ok");
