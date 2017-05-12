package HTTP::Proxy::GreaseMonkey;

use warnings;
use strict;
use Carp;
use HTTP::Proxy::GreaseMonkey::Script;
use Data::UUID;

use base qw( HTTP::Proxy::BodyFilter );

=head1 NAME

HTTP::Proxy::GreaseMonkey - Run GreaseMonkey scripts in any browser

=head1 VERSION

This document describes HTTP::Proxy::GreaseMonkey version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use HTTP::Proxy;
    use HTTP::Proxy::GreaseMonkey;

    my $proxy = HTTP::Proxy->new( port => 8030 );
    my $gm = HTTP::Proxy::GreaseMonkey->new;
    $gm->add_script( 'gm/myscript.js' );
    $proxy->push_filter(
        mime     => 'text/html',
        response => $gm
    );
    $proxy->start;
  
=head1 DESCRIPTION

GreaseMonkey allows arbitrary user defined Javascript to be run against
specific pages. Unfortunately GreaseMonkey only works with FireFox.

C<HTTP::Proxy::GreaseMonkey> creates a local HTTP proxy that allows
GreaseMonkey user scripts to be used with any browser.

When you install C<HTTP::Proxy::GreaseMonkey> a program called
F<gmproxy> is installed in your default bin directory. To launch the
GreaseMonkey proxy issue a command something like this:

    $ gmproxy ~/.userscripts

By default the proxy will listen on port 8030. The supplied directory is
scanned before each request; any scripts that have been updated or added
will be reloaded and any that have been deleted will be discarded.

=head2 Mac OS

On MacOS F<net.hexten.gmproxy.plist> is created in the project home
directory. Create a directory called F<~/.userscripts> and then add gmproxy
as a launch item:

    $ cp net.hexten.gmproxy.plist ~/Library/LaunchAgents
    $ launchctl load ~/Library/LaunchAgents/net.hexten.gmproxy.plist
    $ launchctl start net.hexten.gmproxy

Then change your network settings to route HTTP through proxy
localhost:8030. Once this is done F<gmproxy> will load automatically
when you log in.

Important: As of 2007-12-17 PubSubAgent crashes periodically (actually
during .mac synchronisation) when HTTP is proxied. The solution appears
to be to add *.mac.com to the list of domains that bypass the proxy. As
far as I'm aware this is a Mac OS problem that has nothing specifically
to do with HTTP::Proxy::GreaseMonkey.

=head2 Other Platforms

Patches welcome from anyone who has equivalent instructions for other
platforms.

=head2 Compatibility

For maximum GreaseMonkey compatibility this module must be used in
conjunction with L<HTTP::Proxy::GreaseMonkey::Redirector> which provides
compatibility services within the proxy. The easiest way to achieve this
is to use the C<gmproxy> command line program. If you're rolling your
own proxy use something like this to install the necessary filters:

    my $proxy = HTTP::Proxy->new(
        port          => $self->port,
        start_servers => $self->servers
    );
    my $gm = HTTP::Proxy::GreaseMonkey::ScriptHome->new;
    $gm->verbose( $self->verbose );
    my @dirs = map glob, @args;
    $gm->add_dir( @dirs );
    $proxy->push_filter(
        mime     => 'text/html',
        response => $gm
    );
    # Make the redirector
    my $redir = HTTP::Proxy::GreaseMonkey::Redirector->new;
    $redir->passthru( $gm->get_passthru_key );
    $redir->state_file(
        File::Spec->catfile( $dirs[0], 'state.yml' ) )
      if @dirs;
    $proxy->push_filter( request => $redir, );
    $proxy->start;

=head3 Supported Functions

The C<GM_registerMenuCommand> function is not supported; it makes no
sense in a proxied environment.

C<GM_setValue> and C<GM_getValue> operate on a YAML encoded state file
which, by default, is stored in the first named user scripts directory.

C<GM_log> outputs log messages to any TTY that the proxy is attached to.
Log output does not appear in the browser.

C<GM_xmlhttpRequest> forwards requests via the proxy to bypass the
browser's cross site scripting policy.

=head3 Performance

C<GM_setValue>, C<GM_getValue> and C<GM_log> talk to the proxy using
synchronous JSONRPC - so they're a little slow. It remains to be seen
whether this is a problem for typical GreaseMonkey scripts.

=head2 Security

I believe it would be possible for a specially crafted page that was
aware of this implementation to access the C<GM_xmlhttpRequest> backdoor
and make cross-site HTTP requests.

I'll attempt to plug that security hole in a future release.

=head1 INTERFACE 

=head2 C<< add_script( $script ) >>

Add a GM script to the proxy. The argument may be the filename of a
script or an existing L<HTTP::Proxy::GreaseMonkey::Script>.

=cut

sub add_script {
    my ( $self, $script ) = @_;

    $script = HTTP::Proxy::GreaseMonkey::Script->new( $script )
      unless eval { $script->can( 'script' ) };

    push @{ $self->{script} }, $script;
}

=head2 C<< verbose >>

Set / get verbosity.

=cut

sub verbose {
    my $self = shift;
    $self->{verbose} = shift if @_;
    return $self->{verbose};
}

=head2 C<< get_passthru_key >>

Get the passthru key that is used to signal to the proxy that it should
rewrite request URLs.

=cut

sub get_passthru_key {
    my $self = shift;
    return $self->{_key} ||= Data::UUID->new->create_str;
}

=head2 C<< get_gm_globals >>

Return a block of Javascript that initialises various globals that are
required by the GreaseMonkey environment.

=cut

sub get_gm_globals {
    my $self = shift;
    my $h = $self->{_html} ||= HTML::Tiny->new;
    return 'var GM__global = '
      . $h->json_encode(
        {
            host     => $self->{uri}->host,
            passthru => $self->get_passthru_key
        }
      ) . ";\n";
}

=head2 C<< get_support_script >>

Returns a block of Javascript that is injected before any user scripts.
Typically this code provides the GM_* support functions.

=cut

sub get_support_script {
    my $self = shift;

    return $self->{_support_js} ||= do { local $/; <DATA> };
}

=head2 C<< init >>

Called to initialise the filter.

=cut

sub init {
    my $self = shift;
    # Bodge: Do this now because it seems to fail after forking.
    $self->get_support_script;
    $self->get_passthru_key;
}

=head2 C<< will_modify >>

Will this filter modify content? Called by L<HTTP::Proxy>.

=cut

sub will_modify { scalar @{ shift->{to_run} } }

=head2 C<< begin >>

Called at the start of processing.

=cut

sub begin {
    my ( $self, $message ) = @_;

    my $uri = $self->{uri} = $message->request->uri;

    print "Proxying $uri\n" if $self->verbose;

    $self->{to_run} = [];
    for my $script ( @{ $self->{script} } ) {
        if ( $script->match_uri( $uri ) ) {
            # Wrap each script in an anon function to give it a
            # private scope.
            push @{ $self->{to_run} },
              $self->_js_scope( $script->support, $script->script );
            print "  Filtering with ", $script->name, "\n"
              if $self->verbose;
        }
    }
}

sub _js_scope {
    my $self = shift;
    return join "\n", '( function() {', @_, '} )()';
}

=head2 C<< filter >>

The filter entry point. Called for each chunk of input.

=cut

sub filter {
    my ( $self, $dataref, $message, $protocol, $buffer ) = @_;

    if ( $self->will_modify ) {
        if ( defined $buffer ) {
            $$buffer  = $$dataref;
            $$dataref = "";
        }
        else {
            my $insert = "<script>\n//<![CDATA[\n"
              . $self->_js_scope( $self->get_gm_globals,
                $self->get_support_script, @{ $self->{to_run} } )
              . "\n//]]>\n</script>\n";

            # TODO: Fragile - needs a fairly normal looking </body>
            $$dataref =~ s{</body>}{$insert</body>}ig;
        }
    }
}

=head2 C<< end >>

Finished processing.

=cut

sub end {
    my $self = shift;
    $self->{to_run} = [];
}

1;

=head1 CONFIGURATION AND ENVIRONMENT
  
HTTP::Proxy::GreaseMonkey requires no configuration files or environment
variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-http-proxy-greasemonkey@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut

__DATA__
// GM Support script

function GM__cook_url(url) {
    return url.replace( /^(\w+:\/\/)/, 
        '$1' + GM__global.host + '/' + GM__global.passthru + '/' );
}

function GM__get_request_obj() {
	var req = null;
    if ( window.XMLHttpRequest && !window.ActiveXObject ) {
    	try {
			req = new XMLHttpRequest();
        } catch(e) {
            req = null;
        }
    } else if(window.ActiveXObject) {
       	try {
        	req = new ActiveXObject("Msxml2.XMLHTTP");
      	} catch(e) {
        	try {
          		req = new ActiveXObject("Microsoft.XMLHTTP");
        	} catch(e) {
          		req = null;
        	}
		}
    }
    
    return req;
}

function GM_xmlhttpRequest(details) {
    var req = GM__get_request_obj();

    if ( ! req ) { throw "Can't get XMLHttpRequest object" }

    // URL - cooked to pass through proxy
    var url = details.url;
    if ( url == undefined ) { throw "Missing arg: url" }
    url = GM__cook_url(url);

    // Setup the headers
    var headers = details.headers;
    if ( headers ) {
        for ( var h in headers ) {
            req.setRequestHeader( h, headers[h] );
        }
    }

    // Method
    var method = details.method;
    if ( method == undefined ) { method = 'GET' }

    var data = details.data;
    if ( data == undefined ) { data = '' }
    
    var async = details.async;
    if ( async == undefined ) { async = true }

    var onload              = details.onload;
    var onerror             = details.onerror;
    var onreadystatechange  = details.onreadystatechange;

    req.onreadystatechange = function() {
        var spec = (req.readyState == 4) ? {
            'status':           req.status,
            'statusText':       req.statusText,
            'responseHeaders':  req.getAllResponseHeaders(),
            'responseText':     req.responseText,
            'responseXML':      req.responseXML,
            'readyState':       req.readyState
        } : {
            'status':           0,
            'statusText':       '',
            'responseHeaders':  null,
            'responseText':     '',
            'responseXML':      null,
            'readyState':       req.readyState
        };

        if (onreadystatechange) {
            onreadystatechange(spec);
        }

        if (spec.readyState == 4) {
            var handler = (spec.status == 200) ? onload : onerror;
            if (handler) { handler(spec) }
        }
    }
    
    req.open(method, url, async);
    req.send(data);
}

// From http://www.JSON.org/json2.js
function GM__jsonEncode(value) {
    var m = {    // table of character substitutions
        '\b': '\\b', '\t': '\\t', '\n': '\\n', '\f': '\\f',
        '\r': '\\r', '"' : '\\"', '\\': '\\\\' 
    };

    var a, i, k, l, v;
    var r = /["\\\x00-\x1f\x7f-\x9f]/g;

    switch (typeof value) {
    case 'string':
        return r.test(value) ?
            '"' + value.replace(r, function(a) {
                var c = m[a];
                if (c) { return c }
                c = a.charCodeAt();
                return '\\u00' + Math.floor(c / 16).toString(16) +
                                           (c % 16).toString(16);
            }) + '"' :
            '"' + value + '"';

    case 'number':
        return isFinite(value) ? String(value) : 'null';

    case 'boolean':
    case 'null':
        return String(value);

    case 'object':
        if (!value) {
            return 'null';
        }

        if (typeof value.toJSON === 'function') {
            return GM__jsonEncode(value.toJSON());
        }

        a = [];
        if (typeof value.length === 'number' &&
                !(value.propertyIsEnumerable('length'))) {
            l = value.length;
            for (i = 0; i < l; i += 1) {
                a.push(GM__jsonEncode(value[i]) || 'null');
            }

            return '[' + a.join(',') + ']';
        }

        for (k in value) {
            if (typeof k === 'string') {
                v = GM__jsonEncode(value[k]);
                if (v) {
                    a.push(GM__jsonEncode(k) + ':' + v);
                }
            }
        }

        return '{' + a.join(',') + '}';
    }
}

function GM__proxyFunction(method, namespace, name, args) {
    var url = 'http://$internal$?' + GM__jsonEncode({
        m: method,
        ns: namespace,
        n: name,
        a: args
    });

    var result = null;

    GM_xmlhttpRequest({
        url: url,
        async: false,
        onload: function(spec) {
            result = eval(spec.responseText)[0];
        },
        onerror: function(spec) {
            throw spec.statusText;
        },
    });
    
    return result;
}
