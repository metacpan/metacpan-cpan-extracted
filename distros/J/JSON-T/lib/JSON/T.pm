use 5.010;
use strict;
use warnings;
use utf8;

package JSON::T;

use overload '""' => \&_to_string;

BEGIN
{
	$JSON::T::AUTHORITY = 'cpan:TOBYINK';
	$JSON::T::VERSION   = '0.104';
}

our ($JSLIB, @Implementations);

sub _load_lib
{
	unless ($JSLIB)
	{
		local $/ = undef;
		$JSLIB = <DATA>;
	}
}

BEGIN
{
	push @Implementations, qw/
		JSON::T::SpiderMonkey
		JSON::T::JE
	/;
}

{
	no warnings 'redefine';
	sub DOES
	{
		my ($class, $role) = @_;
		return $role if $role eq 'XML::Saxon::XSLT2';
		return $class->SUPER::DOES($role);
	}
}

sub new
{
	my $class = shift;
	my ($transformation_code, $transformation_name) = @_;
	$transformation_name ||= '_main';
	
	if ($class eq __PACKAGE__)
	{
		require Module::Runtime;
		IMPL: for my $subclass (@Implementations)
		{
			next IMPL unless eval { Module::Runtime::use_module($subclass) };
			$class = $subclass;
			last IMPL;
		}
	}
	
	if ($class eq __PACKAGE__)
	{
		require Carp;
		Carp::croak("cannot load any known Javascript engine");
	}
	
	my $self = bless {
		code      => $transformation_code ,
		name      => $transformation_name ,
		messages  => [],
	}, $class;
	
	$self->init;
	$self->engine_eval($transformation_code);
	
	$self;
}

sub init
{
	my $self = shift;
	
	_load_lib;
	$self->engine_eval($JSLIB);
	
	$self;
}

sub engine_eval { require Carp; Carp::croak("must be implemented by subclass") }
sub parameters  { require Carp; Carp::carp("not implemented by subclass") }

sub _accept_return_value
{
	my $self = shift;
	my ($value) = @_;
	
	$self->{return_value} = $value;
}

sub _last_return_value
{
	my $self = shift;
	
	$self->{return_value};
}

sub _to_string
{
	my $self = shift;
	
	return 'JsonT:#'.$self->{'name'};
}

sub _json_backend
{
	my $self = shift;
	
	$self->{'json_backend'} ||= eval {
		require Cpanel::JSON::MaybeXS;
		'Cpanel::JSON::MaybeXS';
	};
	$self->{'json_backend'} ||= do {
		require JSON::PP;
		'JSON::PP';
	};
	
	$self->{'json_backend'};
}

sub transform
{
	my $self = shift;
	my ($input) = @_;
	
	if (ref $input)
	{
		require Scalar::Util;
		if (Scalar::Util::blessed($input) and $input->isa('JSON::JOM::Node'))
		{
			$input = $self->_json_backend->new->convert_blessed(1)->encode($input);
		}
		else
		{
			$input = $self->_json_backend->new->encode($input);
		}
	}
	
	my $name = $self->{'name'};
	my $rv1  = $self->engine_eval("return_to_perl(JSON.transform($input, $name));");

	($self->_last_return_value // '') . ''; # stringify
}

sub transform_structure
{
	my $self = shift;
	my ($input, $debug) = @_;
	
	my $output = $self->transform($input);
	eval 'use Test::More; Test::More::diag("\n${output}\n");'
		if $debug;
	
	$self->_json_backend->new->decode($output);
}

*transform_document = \&transform_structure;

# none of this is useful, but provided for XML::Saxon::XSLT2 compat.
sub messages
{
	return;
}

sub media_type
{
	my $self = shift;
	my ($default) = @_;
	
	$default;
}

*version        = \&media_type;
*doctype_system = \&media_type;
*doctype_public = \&media_type;
*encoding       = \&media_type;

1;

#
# Don't include __END__ here because we
# have a __DATA__ section below the pod!
#

=pod

=encoding utf-8

=head1 NAME

JSON::T - transform JSON using JsonT

=head1 SYNOPSIS

 my $jsont = slurp('foo/bar.js');
 my $input = slurp('foo/quux.json');
 my $JSONT = JSON::T->new($jsont);
 print $JSONT->transform($input);

=head1 DESCRIPTION

This module implements JsonT, a language for transforming JSON-like
structures, analogous to XSLT in the XML world.

JsonT is described at L<http://goessner.net/articles/jsont/>. JsonT is
a profile of Javascript; so JsonT needs a Javascript engine to actually
work. This module provides the engine-neutral stuff, while L<JSON::T::JE>
and L<JSON::T::SpiderMonkey> provide the necessary glue to hook it up to 
a couple of Javascript engines. 

JSON::T::JE uses the pure Perl Javascript implementation L<JE>.

JSON::T::SpiderMonkey uses L<JavaScript::SpiderMonkey> which in turn is
backed by Mozilla's libjs C library.

This module tries to provide a similar API to L<XML::Saxon::XSLT2>.

=head2 Constructor

=over 4

=item C<< new($code, $name) >>

Constructs a new JSON::T transformation. $code is the JsonT Javascript
code. As a JsonT file can contain multiple (potentially unrelated)
transformations, the name of the particular transformation you want to
use should also be provided. If $name is omitted, then the name "_main"
is assumed.

If you wish to use a particular Javascript implementation, you can
use, for example:

  JSON::T::SpiderMonkey->new($code, $name)

Otherwise 

  JSON::T->new($code, $name)

will try to pick a working implementation for you.

=back

=head2 Methods

=over 4

=item C<< parameters(param1=>$arg1, param2=>$arg2, ...) >>

Sets global variables available to the Javascript code. All arguments
are treated as strings.

=item C<< transform($input) >>

Run the transformation. The input may be a JSON string, a JSON::JOM::Node
or a native Perl nested arrayref/hashref structure, in which case it will be
stringified using the JSON module's to_json function. The output (return value)
will be a string.

=item C<< transform_structure($input) >>

Like C<transform>, but attempts to parse the output as a JSON string and
return a native Perl arrayref/hashref structure. This method will fail
if the output is not a JSON string.

=item C<< DOES($role) >>

Like L<UNIVERSAL>'s DOES method, but returns true for:

  JSON::T->DOES('XML::Saxon::XSLT2')

as an aid for polymorphism.

=back

The following methods also exist for compatibility with XML::Saxon::XSLT2,
but are mostly useless:

=over

=item C<< transform_document >>

=item C<< messages >>

=item C<< media_type >>

=item C<< version >>

=item C<< doctype_system >>

=item C<< doctype_public >>

=item C<< encoding >>

=back

=head2 Javascript Execution Environment

JSON::T is a profile of Javascript, so is evaluated in an execution
environment. As this is not a browser environment, many global objects
familiar to browser Javascript developers are not available. (For example,
C<window>, C<document>, C<navigator>, etc.)

A single global object called "JSON" is provided with methods
C<stringify> and C<parse> compatible with the well-known json2.js
library (L<http://www.JSON.org/json2.js>), and a method
C<transform(obj,jsont)> that provides a Javascript JsonT
implementation.

A function C<print_to_perl> is provided which prints to Perl's
STDOUT stream.

=head1 SUBCLASSING

Two subclasses are provided: L<JSON::T::JE> and L<JSON::T::SpiderMonkey>,
but if you need to hook L<JSON::T> up to another Javascript engine, it is
relatively simple. Just create a Perl class which is a subclass of L<JSON::T>.
This subclass must implement two required methods and should implement
one optional method.

=over

=item C<< init >>

Will be passed a newly created object (let's call it C<< $self >>). It is
expected to initialise a Javascript execution context for C<< $self >>, and
define two Javascript functions: C<return_to_perl> (which acts as a shim
to C<< $self->_accept_return_value() >>) and C<print_to_perl> (which acts
as a shim to C<print>). It must then call C<< SUPER::init >>.

=item C<< engine_eval >>

Will be passed an object (C<< $self >>) and a Javascript string. Must evaluate
the string in the object's Javascript execution context.

=item C<< parameters >>

This one is optional to implement it. If you don't implement it, then users
will get a warning message if they try to call C<< parameters >> on your
subclass.

Will be passed an object (C<< $self >>) and a hash of parameters, using the
following format:

  (
    name1  => 'value1',
    name2  => [ type2 => 'value2' ],
    name3  => [ type3 => 'value3', hint => 'hint value' ],
  )

This should have the effect of setting:

  var name1 = 'value1';
  var name2 = 'value2';
  var name3 = 'value3';

in the object's Javascript execution context. Parameter types and additional
hints may be used to set the correct types in Javascript.

=back

You are unlikely to need to do anything else when subclassing.

If you wish C<< JSON::T->new >> to know about your subclass, then push
its name onto C<< @JSON::T::Implementations >>.

=head1 BUGS

Please report any bugs to L<http://rt.cpan.org/>.

=head1 SEE ALSO

Specification: L<http://goessner.net/articles/jsont/>.

Related modules: L<JSON>, L<JSON::Path>, L<JSON::GRDDL>,
L<JSON::Hyper>, L<JSON::Schema>.

JOM version: L<JSON::JOM>, L<JSON::JOM::Plugins::JsonT>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

This module is embeds Stefan Goessner's Javascript implementation of
JsonT (version 0.9) to do the heavy lifting.

=head1 COPYRIGHT AND LICENCE

Copyright 2006 Stefan Goessner.

Copyright 2008-2011, 2013-2014 Toby Inkster.

Licensed under the Lesser GPL:
L<http://creativecommons.org/licenses/LGPL/2.1/>.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

# Here's the Javascript...

__DATA__

/*
    http://www.JSON.org/json2.js
    2008-11-19

    Public Domain.

    NO WARRANTY EXPRESSED OR IMPLIED. USE AT YOUR OWN RISK.

    See http://www.JSON.org/js.html

    This file creates a global JSON object containing two methods: stringify
    and parse.

        JSON.stringify(value, replacer, space)
            value       any JavaScript value, usually an object or array.

            replacer    an optional parameter that determines how object
                        values are stringified for objects. It can be a
                        function or an array of strings.

            space       an optional parameter that specifies the indentation
                        of nested structures. If it is omitted, the text will
                        be packed without extra whitespace. If it is a number,
                        it will specify the number of spaces to indent at each
                        level. If it is a string (such as '\t' or '&nbsp;'),
                        it contains the characters used to indent at each level.

            This method produces a JSON text from a JavaScript value.

            When an object value is found, if the object contains a toJSON
            method, its toJSON method will be called and the result will be
            stringified. A toJSON method does not serialize: it returns the
            value represented by the name/value pair that should be serialized,
            or undefined if nothing should be serialized. The toJSON method
            will be passed the key associated with the value, and this will be
            bound to the object holding the key.

            For example, this would serialize Dates as ISO strings.

                Date.prototype.toJSON = function (key) {
                    function f(n) {
                        // Format integers to have at least two digits.
                        return n < 10 ? '0' + n : n;
                    }

                    return this.getUTCFullYear()   + '-' +
                         f(this.getUTCMonth() + 1) + '-' +
                         f(this.getUTCDate())      + 'T' +
                         f(this.getUTCHours())     + ':' +
                         f(this.getUTCMinutes())   + ':' +
                         f(this.getUTCSeconds())   + 'Z';
                };

            You can provide an optional replacer method. It will be passed the
            key and value of each member, with this bound to the containing
            object. The value that is returned from your method will be
            serialized. If your method returns undefined, then the member will
            be excluded from the serialization.

            If the replacer parameter is an array of strings, then it will be
            used to select the members to be serialized. It filters the results
            such that only members with keys listed in the replacer array are
            stringified.

            Values that do not have JSON representations, such as undefined or
            functions, will not be serialized. Such values in objects will be
            dropped; in arrays they will be replaced with null. You can use
            a replacer function to replace those with JSON values.
            JSON.stringify(undefined) returns undefined.

            The optional space parameter produces a stringification of the
            value that is filled with line breaks and indentation to make it
            easier to read.

            If the space parameter is a non-empty string, then that string will
            be used for indentation. If the space parameter is a number, then
            the indentation will be that many spaces.

            Example:

            text = JSON.stringify(['e', {pluribus: 'unum'}]);
            // text is '["e",{"pluribus":"unum"}]'


            text = JSON.stringify(['e', {pluribus: 'unum'}], null, '\t');
            // text is '[\n\t"e",\n\t{\n\t\t"pluribus": "unum"\n\t}\n]'

            text = JSON.stringify([new Date()], function (key, value) {
                return this[key] instanceof Date ?
                    'Date(' + this[key] + ')' : value;
            });
            // text is '["Date(---current time---)"]'


        JSON.parse(text, reviver)
            This method parses a JSON text to produce an object or array.
            It can throw a SyntaxError exception.

            The optional reviver parameter is a function that can filter and
            transform the results. It receives each of the keys and values,
            and its return value is used instead of the original value.
            If it returns what it received, then the structure is not modified.
            If it returns undefined then the member is deleted.

            Example:

            // Parse the text. Values that look like ISO date strings will
            // be converted to Date objects.

            myData = JSON.parse(text, function (key, value) {
                var a;
                if (typeof value === 'string') {
                    a =
/^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2}(?:\.\d*)?)Z$/.exec(value);
                    if (a) {
                        return new Date(Date.UTC(+a[1], +a[2] - 1, +a[3], +a[4],
                            +a[5], +a[6]));
                    }
                }
                return value;
            });

            myData = JSON.parse('["Date(09/09/2001)"]', function (key, value) {
                var d;
                if (typeof value === 'string' &&
                        value.slice(0, 5) === 'Date(' &&
                        value.slice(-1) === ')') {
                    d = new Date(value.slice(5, -1));
                    if (d) {
                        return d;
                    }
                }
                return value;
            });


    This is a reference implementation. You are free to copy, modify, or
    redistribute.

    This code should be minified before deployment.
    See http://javascript.crockford.com/jsmin.html

    USE YOUR OWN COPY. IT IS EXTREMELY UNWISE TO LOAD CODE FROM SERVERS YOU DO
    NOT CONTROL.
*/

/*jslint evil: true */

/*global JSON */

/*members "", "\b", "\t", "\n", "\f", "\r", "\"", JSON, "\\", apply,
    call, charCodeAt, getUTCDate, getUTCFullYear, getUTCHours,
    getUTCMinutes, getUTCMonth, getUTCSeconds, hasOwnProperty, join,
    lastIndex, length, parse, prototype, push, replace, slice, stringify,
    test, toJSON, toString, valueOf
*/

// Create a JSON object only if one does not already exist. We create the
// methods in a closure to avoid creating global variables.

if (!this.JSON) {
    JSON = {};
}
(function () {

    function f(n) {
        // Format integers to have at least two digits.
        return n < 10 ? '0' + n : n;
    }

    if (typeof Date.prototype.toJSON !== 'function') {

        Date.prototype.toJSON = function (key) {

            return this.getUTCFullYear()   + '-' +
                 f(this.getUTCMonth() + 1) + '-' +
                 f(this.getUTCDate())      + 'T' +
                 f(this.getUTCHours())     + ':' +
                 f(this.getUTCMinutes())   + ':' +
                 f(this.getUTCSeconds())   + 'Z';
        };

        String.prototype.toJSON =
        Number.prototype.toJSON =
        Boolean.prototype.toJSON = function (key) {
            return this.valueOf();
        };
    }

    var cx = /[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,
        escapable = /[\\\"\x00-\x1f\x7f-\x9f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,
        gap,
        indent,
        meta = {    // table of character substitutions
            '\b': '\\b',
            '\t': '\\t',
            '\n': '\\n',
            '\f': '\\f',
            '\r': '\\r',
            '"' : '\\"',
            '\\': '\\\\'
        },
        rep;


    function quote(string) {

// If the string contains no control characters, no quote characters, and no
// backslash characters, then we can safely slap some quotes around it.
// Otherwise we must also replace the offending characters with safe escape
// sequences.

        escapable.lastIndex = 0;
        return escapable.test(string) ?
            '"' + string.replace(escapable, function (a) {
                var c = meta[a];
                return typeof c === 'string' ? c :
                    '\\u' + ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
            }) + '"' :
            '"' + string + '"';
    }


    function str(key, holder) {

// Produce a string from holder[key].

        var i,          // The loop counter.
            k,          // The member key.
            v,          // The member value.
            length,
            mind = gap,
            partial,
            value = holder[key];

// If the value has a toJSON method, call it to obtain a replacement value.

        if (value && typeof value === 'object' &&
                typeof value.toJSON === 'function') {
            value = value.toJSON(key);
        }

// If we were called with a replacer function, then call the replacer to
// obtain a replacement value.

        if (typeof rep === 'function') {
            value = rep.call(holder, key, value);
        }

// What happens next depends on the value's type.

        switch (typeof value) {
        case 'string':
            return quote(value);

        case 'number':

// JSON numbers must be finite. Encode non-finite numbers as null.

            return isFinite(value) ? String(value) : 'null';

        case 'boolean':
        case 'null':

// If the value is a boolean or null, convert it to a string. Note:
// typeof null does not produce 'null'. The case is included here in
// the remote chance that this gets fixed someday.

            return String(value);

// If the type is 'object', we might be dealing with an object or an array or
// null.

        case 'object':

// Due to a specification blunder in ECMAScript, typeof null is 'object',
// so watch out for that case.

            if (!value) {
                return 'null';
            }

// Make an array to hold the partial results of stringifying this object value.

            gap += indent;
            partial = [];

// Is the value an array?

            if (Object.prototype.toString.apply(value) === '[object Array]') {

// The value is an array. Stringify every element. Use null as a placeholder
// for non-JSON values.

                length = value.length;
                for (i = 0; i < length; i += 1) {
                    partial[i] = str(i, value) || 'null';
                }

// Join all of the elements together, separated with commas, and wrap them in
// brackets.

                v = partial.length === 0 ? '[]' :
                    gap ? '[\n' + gap +
                            partial.join(',\n' + gap) + '\n' +
                                mind + ']' :
                          '[' + partial.join(',') + ']';
                gap = mind;
                return v;
            }

// If the replacer is an array, use it to select the members to be stringified.

            if (rep && typeof rep === 'object') {
                length = rep.length;
                for (i = 0; i < length; i += 1) {
                    k = rep[i];
                    if (typeof k === 'string') {
                        v = str(k, value);
                        if (v) {
                            partial.push(quote(k) + (gap ? ': ' : ':') + v);
                        }
                    }
                }
            } else {

// Otherwise, iterate through all of the keys in the object.

                for (k in value) {
                    if (Object.hasOwnProperty.call(value, k)) {
                        v = str(k, value);
                        if (v) {
                            partial.push(quote(k) + (gap ? ': ' : ':') + v);
                        }
                    }
                }
            }

// Join all of the member texts together, separated with commas,
// and wrap them in braces.

            v = partial.length === 0 ? '{}' :
                gap ? '{\n' + gap + partial.join(',\n' + gap) + '\n' +
                        mind + '}' : '{' + partial.join(',') + '}';
            gap = mind;
            return v;
        }
    }

// If the JSON object does not yet have a stringify method, give it one.

    if (typeof JSON.stringify !== 'function') {
        JSON.stringify = function (value, replacer, space) {

// The stringify method takes a value and an optional replacer, and an optional
// space parameter, and returns a JSON text. The replacer can be a function
// that can replace values, or an array of strings that will select the keys.
// A default replacer method can be provided. Use of the space parameter can
// produce text that is more easily readable.

            var i;
            gap = '';
            indent = '';

// If the space parameter is a number, make an indent string containing that
// many spaces.

            if (typeof space === 'number') {
                for (i = 0; i < space; i += 1) {
                    indent += ' ';
                }

// If the space parameter is a string, it will be used as the indent string.

            } else if (typeof space === 'string') {
                indent = space;
            }

// If there is a replacer, it must be a function or an array.
// Otherwise, throw an error.

            rep = replacer;
            if (replacer && typeof replacer !== 'function' &&
                    (typeof replacer !== 'object' ||
                     typeof replacer.length !== 'number')) {
                throw new Error('JSON.stringify');
            }

// Make a fake root object containing our value under the key of ''.
// Return the result of stringifying the value.

            return str('', {'': value});
        };
    }


// If the JSON object does not yet have a parse method, give it one.

    if (typeof JSON.parse !== 'function') {
        JSON.parse = function (text, reviver) {

// The parse method takes a text and an optional reviver function, and returns
// a JavaScript value if the text is a valid JSON text.

            var j;

            function walk(holder, key) {

// The walk method is used to recursively walk the resulting structure so
// that modifications can be made.

                var k, v, value = holder[key];
                if (value && typeof value === 'object') {
                    for (k in value) {
                        if (Object.hasOwnProperty.call(value, k)) {
                            v = walk(value, k);
                            if (v !== undefined) {
                                value[k] = v;
                            } else {
                                delete value[k];
                            }
                        }
                    }
                }
                return reviver.call(holder, key, value);
            }


// Parsing happens in four stages. In the first stage, we replace certain
// Unicode characters with escape sequences. JavaScript handles many characters
// incorrectly, either silently deleting them, or treating them as line endings.

            cx.lastIndex = 0;
            if (cx.test(text)) {
                text = text.replace(cx, function (a) {
                    return '\\u' +
                        ('0000' + a.charCodeAt(0).toString(16)).slice(-4);
                });
            }

// In the second stage, we run the text against regular expressions that look
// for non-JSON patterns. We are especially concerned with '()' and 'new'
// because they can cause invocation, and '=' because it can cause mutation.
// But just to be safe, we want to reject all unexpected forms.

// We split the second stage into 4 regexp operations in order to work around
// crippling inefficiencies in IE's and Safari's regexp engines. First we
// replace the JSON backslash pairs with '@' (a non-JSON character). Second, we
// replace all simple value tokens with ']' characters. Third, we delete all
// open brackets that follow a colon or comma or that begin the text. Finally,
// we look to see that the remaining characters are only whitespace or ']' or
// ',' or ':' or '{' or '}'. If that is so, then the text is safe for eval.

            if (/^[\],:{}\s]*$/.
test(text.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g, '@').
replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g, ']').
replace(/(?:^|:|,)(?:\s*\[)+/g, ''))) {

// In the third stage we use the eval function to compile the text into a
// JavaScript structure. The '{' operator is subject to a syntactic ambiguity
// in JavaScript: it can begin a block or an object literal. We wrap the text
// in parens to eliminate the ambiguity.

                j = eval('(' + text + ')');

// In the optional fourth stage, we recursively walk the new structure, passing
// each name/value pair to a reviver function for possible transformation.

                return typeof reviver === 'function' ?
                    walk({'': j}, '') : j;
            }

// If the text is not JSON parseable, then a SyntaxError is thrown.

            throw new SyntaxError('JSON.parse');
        };
    }
})();




/*	This work is licensed under Creative Commons GNU LGPL License.

	License: http://creativecommons.org/licenses/LGPL/2.1/
	Version: 0.9
	Author:  Stefan Goessner/2006
	Web:	   http://goessner.net/ 
	
	Small changes by Toby Inkster.
*/

if (typeof JSON.transform !== 'function')
{
	JSON.transform = function (self, rules) {
		var T = {
			output: false,
			init: function() {
				for (var rule in rules)
					if (rule.substr(0,4) != "self")
						rules["self."+rule] = rules[rule];
				return this;
			},
			apply: function(expr) {
				var trf = function(s){ return s.replace(/{([A-Za-z0-9_\$\.\[\]\'@\(\)]+)}/g, 
												 function($0,$1){return T.processArg($1, expr);})},
					 x = expr.replace(/\[[0-9]+\]/g, "[*]"), res;
				if (x in rules) {
					if (typeof(rules[x]) == "string")
						res = trf(rules[x]);
					else if (typeof(rules[x]) == "function")
						res = trf(rules[x](eval(expr)).toString());
				}
				else 
					res = T.eval(expr);
				return res;
			},
			processArg: function(arg, parentExpr) {
				var expand = function(a,e){return (e=a.replace(/^\$/,e)).substr(0,4)!="self" ? ("self."+e) : e; },
					 res = "";
				T.output = true;
				if (arg.charAt(0) == "@")
					res = eval(arg.replace(/@([A-za-z0-9_]+)\(([A-Za-z0-9_\$\.\[\]\']+)\)/, 
												  function($0,$1,$2){return "rules['self."+$1+"']("+expand($2,parentExpr)+")";}));
				else if (arg != "$")
					res = T.apply(expand(arg, parentExpr));
				else
					res = T.eval(parentExpr);
				T.output = false;
				return res;
			},
			eval: function(expr) {
				var v = eval(expr), res = "";
				if (typeof(v) != "undefined") {
					if (v instanceof Array) {
						for (var i=0; i<v.length; i++)
							if (typeof(v[i]) != "undefined")
								res += T.apply(expr+"["+i+"]");
					}
					else if (typeof(v) == "object") {
						for (var m in v)
							if (typeof(v[m]) != "undefined")
								res += T.apply(expr+"."+m);
					}
					else if (T.output)
						res += v;
				}
				return res;
			}
		};
		return T.init().apply("self");
	}
}
