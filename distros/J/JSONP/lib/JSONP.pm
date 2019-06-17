package JSONP;
# some older 5.8.x perl versions on exotic platforms don't get the v5.10 syntax
use 5.010;
use v5.10;
use strict;
use warnings;
use utf8;
use Time::HiRes qw(gettimeofday);
use File::Temp qw();
use File::Path;
use Cwd qw();
use Scalar::Util qw(reftype);
use CGI qw();
use Digest::SHA;
use JSON;
use Want;

our $VERSION = '1.93';

=encoding utf8

=head1 NAME

JSONP - a module to quickly build JSON/JSONP web services

=head1 SYNOPSIS

=over 2

=item * under CGI environment:

You can pass the name of instance variable, skipping the I<-E<gt>new> call.
If you prefer, you can use I<-E<gt>new> just passing nothing in I<use>.

	use JSONP 'jsonp';
	$jsonp->run;

	...

	sub yoursubname
	{
		$j->table->fields = $sh->{NAME};
		$j->table->data = $sh->fetchall_arrayref;
	}

OR

	use JSONP;

	my $j = JSONP->new;
	$j->run;

	...

	sub yoursubname
	{
		$j->table->fields = $sh->{NAME};
		$j->table->data = $sh->fetchall_arrayref;
	}

=item * under mod_perl:

You must declare the instance variable, remember to use I<local our>.

	use JSONP;
	local our $j = JSONP->new;
	$j->run;

	...

	sub yoursubname
	{
		my $namedparam = $j->params->namedparam;
		$j->table->fields = $sh->{NAME};
		$j->table->data = $sh->fetchall_arrayref;
	}

option setting methods allow for chained calls:

	use JSONP;
	local our $j = JSONP->new;
	$j->aaa('your_session_sub')->login('your_login_sub')->debug->insecure->run;

	...

	sub yoursubname
	{
		my $namedparam = $j->params->namedparam;
		$j->table->fields = $sh->{NAME};
		$j->table->data = $sh->fetchall_arrayref;
	}

just make sure I<run> it is the last element in chain.

=back

the module will call automatically the sub which name is specified in the req parameter of GET/POST request. JSONP will check if the sub exists in current script namespace by looking in typeglob and only in that case the sub will be called. The built-in policy about function names requires also a name starting by a lowercase letter, followed by up to 63 characters chosen between ASCII letters, numbers, and underscores. Since this module is intended to be used by AJAX calls, this will spare you to define routes and mappings between requests and back end code. In your subroutines you will therefore add all the data you want to the JSON/JSONP object instance in form of hashmap of any deep and complexity, JSONP will return that data automatically as JSON object with/without padding (by using the function name passed as 'callback' in GET/POST request, or using simply 'callback' as default) to the calling javascript. The supplied callback name wanted from calling javascript must follow same naming conventions as function names above. Please note that I<params> and I<session> keys on top of JSONP object hierarchy are reserved. See also "I<notation convenience features>" paragraph at the end of the POD.
The jQuery call:

	// note that jQuery will automatically chose a non-clashing callback name when you insert callback=? in request
	$.getJSON(yourwebserverhost + '?req=yoursubname&firstparam=firstvalue&...&callback=?', function(data){
		//your callback code
	});

processed by JSONP, will execute I<yoursubname> in your script if it exists, otherwise will return a JSONP codified error. The default error object returned by this module in its root level has a boolean "error" flag and an "errors" array where you can put a list of your customized errors. The structure of the elements of the array is of course free so you can adapt it to your needs and frameworks.

you can autovivify the response hash omiting braces

	$jsonp->firstlevelhashvalue = 'I am a first level hash value';
	$jsonp->first->second = 'I am a second level hash value';

you can then access hash values either with or without braces notation

	$jsonp->firstlevelhashvalue = 5;
	print $jsonp->firstlevelhashvalue; # will print 5

it is equivalent to:

	$jsonp->{firstlevelhashvalue} = 5;
	print $jsonp->{firstlevelhashvalue};

you can even build a tree:

	$jsonp->first->second = 'hello!';
	print $jsonp->first->second; # will print "hello!"

it is the same as:

	$jsonp->{first}->{second} = 'hello!';
	print $jsonp->{first}->{second};

or (the perl "array rule"):

	$jsonp->{first}{second} = 'hello!';
	print $jsonp->{first}{second};

or even (deference ref):

	$$jsonp{first}{second} = 'hello!';
	print $$jsonp{first}{second};

you can insert hashes at any level of structure and they will become callable with the built-in convenience shortcut:

	my $obj = {a => 1, b => 2};
	$jsonp->first->second = $obj;
	print $jsonp->first->second->b; # will print 2
	$jsonp->first->second->b = 3;
	print $jsonp->first->second->b; # will print 3

you can insert also array at any level of structure and the nodes (hashrefs) within resulting structure will become callable with the built-in convenience shortcut. You will need to call C<-E<gt>[index]> in order to access them, though:

	my $ary = [{a => 1}, 2];
	$jsonp->first->second = $ary;
	print $jsonp->first->second->[1]; # will print 2
	print $jsonp->first->second->[0]->a; # will print 1
	$jsonp->first->second->[0]->a = 9;
	print $jsonp->first->second->[0]->a; # will print 9 now

you can almost freely interleave above listed styles in order to access to elements of JSONP object. As usual, respect I<_private> variables if you don't know what you are doing. One value-leaf/object-node element set by the convenience notation shortcut will be read by normal hash access syntax. You can delete elements from the hash tree, though it is not supported via the convenience notation. You can use it, but the last node has to be referenced via braces notation:

	my $j = JSONP->new;
	$j->firstnode->a = 5;
	$j->firstnode->b = 9;
	$j->secondnode->thirdnode->a = 7;
	delete $j->secondnode->{thirdnode}; # will delete thirdnode as expected in hash structures.

TODO: will investigate if possible to implement deletion using exclusively the convenience notation feature.

IMPORTANT NOTE: while using the convenience notation without braces, if you autovivify a hierarchy without assigning anything to the last item, or assigning it an B<I<undef>>ined value, JSONP will assign to the last element a zero string ( '' ). Since it evaluates to false in a boolean context and can be safely catenated to other strings without causing runtime errors you can avoid several I<exists> checks without the risk to incur in runtime errors. The only dangerous tree traversal can occur if you try to treat an object node as an array node, or vice versa.

IMPORTANT NOTE 2: remember that all the method names of the module cannot be used as key names via convenience notation feature, at any level of the response tree. You can set such key names anyway by using the braces notation. To retrieve their value, you will need to use the brace notation for the node that has the key equal to a native method name of this very module. It is advisable to assign the branch that contains them to an higher level node:

	my $j = JSONP->new;
	$j->firstnode = 5;
	my $branch = {};
	$branch->{debug} = 0; # debug is a native method name
	$branch->{serialize} = 1; # serialize is a native method name
	$j->secondnode = $branch; # $branch structure will be grafted and relative nodes blessed accordingly
	say $j->secondnode->{serialize}; # will print 1

IMPORTANT NOTE 3: deserialized booleans from JSON are turned into referenes to scalars by JSON module, to say JSON I<true> will turn into a Perl I<\1> and JSON I<false> will turn into a Perl I<\0>. JSONP module detects boolen context so when you try to evaluate one of these values in a boolean context it correctly returns the actual boolean value hold by the leaf instead of the reference (that would always evaluate to I<true> even for I<\0>), to say will dereference I<\0> and I<\1> in order to return I<0> and I<1> respectively.

	$j->graft('testbool', q|{"true": true, "false":false}|);
	say $j->testbool->true;
	say $j->testbool->false;
	say !! $j->testbool->true;
	say !! $j->testbool->false;

NOTE: in order to get a "pretty print" via serialize method you will need to either call I<debug> or I<pretty> methods before serialize, use I<pretty> if you want to serialize a deeper branch than the root one:

	my $j = JSONP->new->debug;
	$j->firstnode->a = 5;
	$j->firstnode->b = 9;
	$j->secondnode->thirdnode->a = 7;
	my $pretty = $j->serialize; # will get a pretty print
	my $deepser = $j->firstnode->serialize; # won't get a pretty print, because deeper than root
	my $prettydeeper = $j->firstnode->pretty->serialize; # will get a pretty print, because we called I<pretty> first

NOTE: you can even replace a leaf with a new node:

	$j->first = 9;

	... do some things

	$j->first->second = 9;
	$j->first->second->third = 'Hi!';

this will enable you to discard I<second> leaf value and append to it whatever data structure you like.

=head1 DESCRIPTION

The purpose of JSONP is to give an easy and fast way to build JSON-only web services that can be used even from a different domain from which one they are hosted on. It is supplied only the object interface: this module does not export any symbol, apart the optional pointer to its own instance in the CGI environment (not possible in mod_perl environment).
Once you have the instance of JSONP, you can build a response hash tree, containing whatever data structure, that will be automatically sent back as JSON object to the calling page. The built-in automatic cookie session keeping uses a secure SHA256 to build the session key. The related cookie is HttpOnly, Secure (only SSL) and with path set way down the one of current script (keep the authentication script in the root of your scripts path to share session among all scripts). For high trusted intranet environments a method to disable the Secure flag has been supplied. The automatically built cookie key will be long exactly 64 chars (hex format).
You can retrieve parameters supplied from browser either via GET, POST, PUT, or DELETE by accessing the reserved I<params> key of JSONP object. For example the value of a parameter named I<test> will be accessed via $j->params->test. In case of POSTs or PUTs of application/json requests (JSONP application/javascript requests are always loaded as GETs) the JSONP module will transparently detect them and populate the I<params> key with the deserialization of posted JSON, note that in this case the JSON being P(OS|U)Ted must be an object and not an array, having a I<req> param key on the first level of the structure in order to point out the corresponding function to be invoked.
You have to provide the string name or sub ref (the module accepts either way) of your own I<aaa> and I<login> functions. The AAA (aaa) function will get called upon every request with the session key (retrieved from session cookie or newly created for brand new sessions) as argument. That way you will be free to implement routines for authentication, authorization, access, and session tracking that most suit your needs, together with rules for user/groups to access the methods you expose. Your AAA function must return the session string (if you previously saved it, read on) if a valid session exists under the given key. A return value evaluated as false by perl will result in a 'forbidden' response (you can add as much errors as you want in the I<errors> array of response object). B<Be sure you return a false value if the user is not authenticated!> otherwise you will give access to all users. If you want you can check the invoked method under the req parameter (see query method) in order to implement your own access policies. B<If> the request has been B<a POST or PUT> (B<but not a GET>)The AAA function will be called a second time just before the response to client will be sent out, the module checks for changes in session by concurrent requests that would have executed in meanwhile, and merges their changes with current one by a smart recursive data structure merge routine. Then it will call the AAA function again with the session key as first argument, and a serialized string of the B<session> branch as second (as you would have modified it inside your called function). This way if your AAA function gets called with only one paramenter it is the begin of the request cycle, and you have to retrieve and check the session saved in your storage of chose (memcached, database, whatever), if it gets called with two arguments you can save the updated session object (already serialized as UTF-8 JSON) to the storage under the given key. The B<session> key of JSONP object will be reserved for session tracking, everything you will save in that branch will be passed serialized to your AAA function right before the response to client. It will be also populated after the serialized string you will return from your AAA function at the beginning of the request cycle. The login function will get called with the current session key (from cookie or newly created) as parameter, you can retrieve the username and password passed by the query method, as all other parameters. This way you will be free to give whatever name you like to those two parameters. Return the outcome of login attempt in order to pass back to login javascript call the state of authentication. Whatever value that evaluates to true will be seen as "authentication ok", whatever value that Perl evaluates to false will be seen as "authentication failed". Subsequent calls (after authentication) will track the authentication status by mean of the session string you return from AAA function.
If you need to add a method/call/feature to your application you have only to add a sub with same name you will pass under I<req> parameter from frontend.

=head2 METHODS

=cut

sub import
{
	my ($self, $name) = @_;
	return if $ENV{MOD_PERL};
	return unless $name;
	die 'not valid variable name' unless $name =~ /^[a-z][0-9a-zA-Z_]{0,63}$/;
	my $symbol = caller() . '::' . $name;
	{
		no strict 'refs'; ## no critic
		*$symbol = \JSONP->new;
	}
}

=head3 new

class constructor, it does not accept any parameter by user. The options have to be set by calling correspondant methods (see below)

=cut

sub new
{
	my ($class) = @_;
	bless {}, $class;
}

=head3 run

executes the subroutine specified by req paramenter, if it exists, and returns the JSON output object to the calling browser. This have to be the last method called from JSONP object, because it will call the requested function and return the set object as JSON one.

=cut

sub _auth
{
	my ($self, $sid, $session) = @_;
	my $authenticated = eval {
			$self->{_aaa_sub}->($sid, $session);
	};

	if($@){
		$self->{eval} = $@ if $self->{_debug};
		$self->raiseError('unclassified error');
		$authenticated = 0;
	}

	$authenticated;
}

sub run
{
	my $self = shift;
	$self->{_authenticated} = 0;
	$self->{_is_root_element} = 1;
	$self->{error} = \0;
	$self->errors = [];
	$self->{_passthrough} = 0;
	$self->{_mimetype} = 'text/html';
	$self->{_html} = 0;
	$self->{_mod_perl} = defined $ENV{MOD_PERL};
	$self->{_jsonp_version} = $VERSION;
	# File::Temp will remove the tempdir and its content on after request end
	$self->{_tempdir} = File::Temp->newdir;
	my $curdir = Cwd::cwd;
	# Taint mode
	$curdir = $curdir =~ m{(/.*)} ? $1 : '';
	$self->{_curdir} = $curdir;
	#$ENV{PATH} = '' if $self->{_taint_mode} = ${^TAINT};
	die "you have to provide an AAA function" unless $self->{_aaa_sub};
	my $r = CGI->new;
	# this will enable us to give back the unblessed reference
	my %params = $r->Vars;
	my $contype = $r->content_type // '';
	my $method = $r->request_method;
	$self->{_request_method} = $method;
	if($contype =~ m{application/json} && scalar keys %params == 1){
		my $payload;
		if($method eq 'POST'){
			$payload = $params{POSTDATA};
		} elsif ($method eq 'PUT'){
			$payload = $params{PUTDATA};
		} else {
			$payload = '{}'; # dummy one, fallback for invalid requests
		}

		my $success = $self->graft('params', $payload);

		unless($success){
			$self->raiseError('invalid input JSON');
		}

	} else {
		$self->params = \%params;
	}

	unless((reftype $self->params // '') eq 'HASH'){
		$self->params = {};
		$self->raiseError('invalid input JSON type (array)');
	}

	if($self->{_rest}){
		my $name = $0;
		$name =~ m{([^/]+)$};
		$name = $1 // '';
		$self->{params}->{req} = $name;
	}

	my $req = $self->{params}->{req} // '';
	$req =~ /^([a-z][0-9a-zA-Z_]{1,63})$/; $req = $1 // '';
	my $sid = $r->cookie('sid');

	my $map = caller() . '::' . $req;
	my $session = $self->_auth($sid);
	$self->{_authenticated} = ! ! $session;
	if($self->{_authenticated}){
		$self->session = {} unless $self->graft('session', $session);
	} else {
		$self->session = {};
	}

	$$self{_cgi} = $r;

	my $isloginsub = \&$map == $self->{_login_sub};

	my $header = {-type => 'application/javascript', -charset => 'UTF-8'};
	unless ( $sid && !$isloginsub) {
		my $h = Digest::SHA->new(256);
		my @us = gettimeofday;
		$h->add(@us, map($r->http($_) , $r->http() )) if	$self->{_insecure_session};
		$h->add(@us, map($r->https($_), $r->https())) unless	$self->{_insecure_session};
		$sid = $h->hexdigest;
		my $current_path = $r->url(-absolute=>1);
		$current_path =~ s|/[^/]*$||;
		my $cookie = {
			-name		=> 'sid',
			-value		=> $sid,
			-path		=> $current_path,
			-secure		=> !$self->{_insecure_session},
			-httponly	=> 1
		};
		$cookie->{-expires} = "+$$self{_session_expiration}s" if $self->{_session_expiration};
		$header->{-cookie} = $r->cookie($cookie);
	}

	if (! ! $session && defined &$map || $isloginsub) {
		eval {
			no strict 'refs'; ## no critic
			my $outcome = &$map($sid);
			$self->{_authenticated} = $outcome if $isloginsub;
		};

		if($@){
			$self->{eval} = $@ if $self->{_debug};
			$self->raiseError('unclassified error');
		}

		# save back the session only during responses to PUT and POST HTTP methods
		if($self->{_authenticated} && ($method eq 'POST' || $method eq 'PUT')){
			# get session last changes made by concurrent requests
			# and merge them with current session right before to
			# pass it back to aaa sub that will save it to storage
			# note that current session keys/values will override
			# concurrent ones, see _merge function for details
			my $concurrentSession = $self->_auth($sid);
			my $thisSession = $self->session->serialize;
			$self->graft('thisSession', $thisSession);
			delete $self->{session};
			$self->graft('session', $concurrentSession);
			$self->_merge($self->session, $self->thisSession);
			delete $self->{thisSession};
			$self->_auth($sid, $self->session->serialize);
		}

	} elsif (! $req) {
		$self->raiseError('invalid request');
	} else {
		$self->raiseError('forbidden');
	}

	# give a nice JSON "true"/"false" output for authentication
	$self->authenticated = $self->{_authenticated} ? \1 : \0;
	$header->{'-status'} = $self->{_status_code} || 200;
	my $callback;
	unless($self->{_passthrough}){
		$callback = $self->params->callback if $self->{_request_method} eq 'GET';
		if($callback){
			$callback = $callback =~ /^([a-z][0-9a-zA-Z_]{1,63})$/ ? $1 : '';
			$self->raiseError('invalid callback') unless $callback;
		}

		$self->{_mimetype} = $callback ? 'application/javascript' : 'application/json';
		$header->{'-type'} = $self->{_mimetype};
		print $r->header($header);
		print "$callback(" if $callback;
		print $self->serialize;
		print ')' if $callback;
	} else {
		$header->{'-type'} = $self->{_mimetype};
		if($self->{_html}){
			print $r->header($header);
			print $self->{_html};
		} else {
			if ($self->{_inline}) {
				$header->{'-disposition'} = 'inline';
			} else {
				$header->{'-attachment'} = $self->{_sendfile} =~ /([^\/]+)$/ ? $1 : '';
			}
			print $r->header($header);
			print $self->_slurp($self->{_sendfile});
			unlink $self->{_sendfile} if $self->{_delete_after_download}
		}
	}

	# exit any eventual temp directory before it is removed by File::Temp
	chdir $self->{_curdir};

	if($self->{_mod_perl}){
		my $rh = $r->r;
		# suppress default Apache response
		$rh->custom_response($self->{_status_code} || 200, '');
		$rh->rflush;
	}

	$self;
}

sub _slurp
{
	my ($self, $filename) = @_;
	open my $fh, '<', $filename;
	local $/;
	<$fh>;
}

sub _merge
{
	# merge $_[2] into $_[1]
	# you must use params directly to make changes
	# directly on referenced objects, otherwise
	# perl will work on local copies of them

	unless((reftype $_[1] // '') eq 'HASH'){
		$_[1] = $_[2];
		return;
	} # if $_[0] points to a scalar or array, $_[1] will prevail

	unless(scalar keys %{$_[1]}){
		$_[1] = $_[2];
		return;
	} # if $_[0] is an empty hash, $_[1] will prevail

	my @keys = keys %{$_[1]};
	push @keys, keys %{$_[2]};
	my $resultOK = 1;
	for(@keys){
		if((reftype $_[1]->{$_} // '') ne 'HASH' || (reftype $_[2]->{$_} // '') ne 'HASH'){
			$_[1]->{$_} = defined $_[2]->{$_} ? $_[2]->{$_} : $_[1]->{$_};
			next;
		}
		$_[0]->_merge($_[1]->{$_}, $_[2]->{$_});
	}
}

=head3 html

use this method if you need to return HTML instead of JSON, pass the HTML string as argument

	yoursubname
	{
		...
		$j->html($html);
	}

=cut

sub html
{
	my ($self, $html) = @_;
	$self->{_passthrough} = 1;
	$self->{_html} = $html;
	$self;
}

=head3 sendfile

use this method if you need to return a file instead of JSON, pass the full file path as as argument. MIME type will be set always to I<application/octet-stream>. The last parameter is evaluated as boolean and if true will make JSONP to delete the passed file after it has been downloaded.

	yoursubname
	{
		...
		$j->sendfile($fullfilepath, $isTmpFileToDelete);
	}

=cut

sub sendfile
{
	my ($self, $filepath, $isTmpFileToDelete) = @_;
	$self->{_passthrough} = 1;
	$self->{_mimetype} = 'application/octet-stream';
	$self->{_sendfile} = $filepath;
	$self->{_delete_after_download} = ! ! $isTmpFileToDelete;
	$self;
}

=head3 file

call this method to send a file with custom MIME type and/or if you want to set it as inline. The last parameter is evaluated as boolean and if true will make JSONP to delete the passed file after it has been downloaded.

	$j->file('path to file', $mimetype, $isInline, $isTmpFileToDelete);

=cut

sub file
{
	my ($self, $filepath, $mime, $inline, $isTmpFileToDelete) = @_;
	$self->{_passthrough} = 1;
	$self->{_mimetype} = $mime;
	$self->{_sendfile} = $filepath;
	$self->{_inline} = ! ! $inline;
	$self->{_delete_after_download} = ! ! $isTmpFileToDelete;
	$self;
}

=head3 debug

call this method before to call C<run> to enable debug mode in a test environment, basically this one will output pretty printed JSON instead of "compressed" one. Furthermore with debug mode turned on the content of session will be returned to the calling page in its own json branch. You can pass a switch to this method (that will be parsed as bool) to set it I<on> or I<off>. It could be useful if you want to pass a variable. If no switch (or undefined one) is passed, the switch will be set as true. Example:

	$j->debug->run;

is the same as:

	$j->debug(1)->run;

=cut

sub debug
{
	my ($self, $switch) = @_;
	$switch = 1 unless defined $switch;
	$switch = ! ! $switch;
	$self->{_debug} = $switch;
	$self->{_pretty} = $switch;
	$self;
}

=head3 pretty

call this method before to call C<run> to enable pretty output on I<serialize> method, basically this one will output pretty printed JSON instead of "compressed" one. You can pass a switch to this method (that will be parsed as bool) to set it I<on> or I<off>. It could be useful if you want to pass a variable. If no switch (or undefined one) is passed, the switch will be set as true. Example:

	$j->pretty->run;

is the same as:

	$j->pretty(1)->run;

=cut

sub pretty
{
	my ($self, $switch) = @_;
	$switch = 1 unless defined $switch;
	$switch = ! ! $switch;
	$self->{_pretty} = $switch;
	$self;
}

=head3 insecure

call this method if you are going to deploy the script under plain http protocol instead of https. This method can be useful during testing of your application. You can pass a switch to this method (that will parsed as bool) to set it on or off. It could be useful if you want to pass a variable. If no switch (or undefined one) is passed, the switch will be set as true.

=cut

sub insecure
{
	my ($self, $switch) = @_;
	$switch = 1 unless defined $switch;
	$switch = ! ! $switch;
	$self->{_insecure_session} = $switch;
	$self;
}

=head3 rest

call this method if you want to omit the I<req> parameter and want that a sub with same name of the script will be called instead, so if your script will be I</var/www/cgi-bin/myscript> the sub I<myscript> will be called instead of the one passed with I<req> (that can be omitted at this point). You can pass a switch to this method (that will parsed as bool) to set it on or off. It could be useful if you want to pass a variable. If no switch (or undefined one) is passed, the switch will be set as true.

=cut

sub rest
{
	my ($self, $switch) = @_;
	$switch = 1 unless defined $switch;
	$switch = ! ! $switch;
	$self->{_rest} = $switch;
	$self;
}

=head3 set_session_expiration

call this method with desired expiration time for cookie in B<seconds>, the default behavior is to keep the cookie until the end of session (until the browser is closed).

=cut

sub set_session_expiration
{
	my ($self, $expiration) = @_;
	$self->{_session_expiration} = $expiration;
	$self;
}

=head3 query

call this method to retrieve a named parameter, $jsonp->query(paramenter_name) will return the value of paramenter_name from query string. The method called without arguments returns all parameters in hash form

=cut

# TODO remove query method, now it is useless
sub query
{
	my ($self, $param) = @_;
	$param ? $self->params->{$param} : $self->params;
}

=head3 plain_json

B<this function is deprecated and has no effect anymore, now a plain JSON request will be returned if no I<callback> parameter will be provided.>
call this function to enable output in simple JSON format (not enclosed within jquery_callback_name()... ). Do this only when your script is on the same domain of static content. This method can be useful also during testing of your application. You can pass a switch to this method (that will parsed as bool) to set it on or off. It could be useful if you want to pass a variable. If no switch (or undefined one) is passed, the switch will be set as true.

=cut

sub plain_json
{
	my ($self, $switch) = @_;
	$switch = 1 unless defined $switch;
	$switch = ! ! $switch;
	$self->{_plain_json} = $switch;
	$self;
}

=head3 aaa

pass to this method the reference (or the name, either way will work) of the function under which you will manage AAA stuff, like session check, tracking and expiration, and ACL to exposed methods

=cut

sub aaa
{
	my ($self, $sub) = @_;
	if (ref $sub eq 'CODE') {
		$self->{_aaa_sub} = $sub;
	}
	else {
		my $map = caller() . '::' . $sub;
		{
			no strict 'refs'; ## no critic
			die "given AAA function does not exist" unless defined &$map;
			$self->{_aaa_sub} = \&$map;
		}
	}
	$self;
}

=head3 login

pass to this method the reference (or the name, either way will work) of the function under which you will manage the login process. The function will be called with the current session key (from cookie or automatically created). It will be your own business to save the key-value pair to the storage you choose (database, memcached, NoSQL, and so on). It is advised to keep the initial value associated with the key void, as the serialized I<session> branch of JSONP object will be automatically passed to your aaa function at the end or request cycle, so you should save it from that place. If you want to access/modify the session value do it through the I<session> branch via I<$jsonp-E<gt>session-E<gt>whatever(value)> or I<$jsonp-E<gt>{session}{whatever} = value> or I<$jsonp-E<gt>{session}-E<gt>{whatever} = value> calls.

=cut

sub login
{
	my ($self, $sub) = @_;
	if (ref $sub eq 'CODE') {
		$self->{_login_sub} = $sub;
	}
	else {
		my $map = caller() . '::' . $sub;
		{
			no strict 'refs'; ## no critic
			die "given login function does not exist" unless defined &$map;
			$self->{_login_sub} = \&$map;
		}
	}
	$self;
}

=head3 logout

pass to this method the reference (or the name, either way will work) of the function under which you will manage the logout process. The function will be called with the current session key (from cookie or automatically created). It will be your own business to delete the key-value pair from the storage you choose (database, memcached, NoSQL, and so on).

=cut

sub logout
{
	my ($self, $sub) = @_;
	if (ref $sub eq 'CODE') {
		$self->{_logout_sub} = $sub;
	}
	else {
		my $map = caller() . '::' . $sub;
		{
			no strict 'refs'; ## no critic
			die "given logout function does not exist" unless defined &$map;
			$self->{_logout_sub} = \&$map;
		}
	}
	$self;
}

=head3 raiseError

call this method in order to return an error message to the calling page. You can add as much messages you want, calling the method several times, it will be returned an array of messages to the calling page. The first argument could be either a string or a <B strings array reference>. The second argument is an optional HTTP status code, the default will be 200.

=cut

sub raiseError
{
	my ($self, $message, $code) = @_;
	$self->error = \1;
	push @{$self->{errors}}, (reftype $message // '') eq 'ARRAY' ? @$message : $message;
	$self->{_status_code} = $code if defined $code;
	$self;
}

=head3 graft

call this method to append a JSON object as a perl subtree on a node. This is a native method, only function notation is supported, lvalue assignment notation is reserved to autovivification shortcut feature. Examples:
	$j->subtree->graft('newbranchname', '{"name" : "JSON object", "count" : 2}');
	print $j->subtree->newbranchname->name; # will print "JSON object"
	$j->sublist->graft->('newbranchname', '[{"name" : "first one"}, {"name" : "second one"}]');
	print $j->sublist->newbranchname->[1]->name; will print "second one"

This method will return the reference to the newly added element if added successfully, a false value otherwise.

=cut

sub graft
{
	my ($self, $name, $json) = @_;

	eval{
		$self->{$name} = JSON->new->allow_nonref->decode($json // '');
	};

	return 0 if $@;

	#_bless_tree returns the node passed to it blessed as JSONP
	$self->_bless_tree($self->{$name});
}

=head3 stack

call this method to add a JSON object to a node-array. This is a native method, only function notation is supported, lvalue assignment notation is reserved to autovivification shortcut feature. Examples:

	$j->first->second = [{a => 1}, {b = 2}];
	$j->first->second->stack('{"c":"3"}');
	say $j->first->second->[2]->c; # will print 3;

this method of course works only with nodes that are arrays. Be warned that the decoded JSON string will be added as B<element> to the array, so depending of the JSON string you pass, you can have an element that is an hashref (another "node"), a scalar (a "value") or an arrayref (array of arrays, if you want). This method will return the reference to the newly added element if added successfully, a false value otherwise. Combining this to graft method you can do crazy things like this:

	my $j = JSONP->new;
	$j->firstnode->graft('secondnode', '{"a" : 1}')->thirdnode = [];
	$j->firstnode->secondnode->thirdnode->stack('{"b" : 9}')->fourthnode = 10;
	say $j->firstnode->secondnode->a; # will print 1
	say $j->firstnode->secondnode->thirdnode->[0]->b; # will print 9
	say $j->firstnode->secondnode->thirdnode->[0]->fourthnode; # will print 10

=cut

sub stack
{
	my ($self, $json) = @_;

	return 0 unless (reftype $self // '') eq 'ARRAY';

	eval{
		push @$self, JSON->new->allow_nonref->decode($json // '');
	};
	return 0 if $@;

	#_bless_tree returns the node passed to it blessed as JSONP
	$self->_bless_tree($self->[$#{$self}]);
}

=head3 append

call this method to add a Perl object to a node-array. This is a native method, only function notation is supported, lvalue assignment notation is reserved to autovivification shortcut feature. Examples:

	$j->first->second = [{a => 1}, {b = 2}];
	$j->first->second->append({c => 3});
	say $j->first->second->[2]->c; # will print 3;

this method of course works only with nodes that are arrays. Be warned that the element will be added as B<element> to the array, so depending of the element you pass, you can have an element that is an hashref (another "node"), a scalar (a "value") or an arrayref (array of arrays, if you want). This method will return the reference to the newly added element if added successfully, a false value otherwise. You can do crazy things like this:

	my $j = JSONP->new;
	$j->firstnode->secondnode->a = 1;
	$j->firstnode->secondnode->thirdnode = [];
	$j->firstnode->secondnode->thirdnode->append({b => 9})->fourthnode = 10;
	say $j->firstnode->secondnode->a; # will print 1
	say $j->firstnode->secondnode->thirdnode->[0]->b; # will print 9
	say $j->firstnode->secondnode->thirdnode->[0]->fourthnode; # will print 10

=cut

sub append
{
	my ($self, $el) = @_;

	return 0 unless (reftype $self // '') eq 'ARRAY';

	eval{
		push @$self, $el;
	};
	return 0 if $@;

	#_bless_tree returns the node passed to it blessed as JSONP
	$self->_bless_tree($self->[$#{$self}]);
}

=head3 serialize

call this method to serialize and output a subtree:

	$j->subtree->graft('newbranchname', '{"name" : "JSON object", "count" : 2}');
	print $j->subtree->newbranchname->name; # will print "JSON object"
	$j->sublist->graft->('newbranchname', '[{"name" : "first one"}, {"name" : "second one"}]');
	print $j->sublist->newbranchname->[1]->name; will print "second one"
	$j->subtree->newbranchname->graft('subtree', '{"name" : "some string", "count" : 4}');
	print $j->subtree->newbranchname->subtree->serialize; # will print '{"name" : "some string", "count" : 4}'

IMPORTANT NOTE: do not assign any reference to a sub to any node, example:

	$j->donotthis = sub { ... };

for now the module does assume that nodes/leafs will be scalars/hashes/arrays, so same thing is valid for filehandles.

=cut

sub serialize
{
	my ($self) = @_;
	my $out;
	my $pretty = (reftype $self // '') eq 'HASH' && $self->{_pretty} ? 1 : 0;
	eval{
		$out = JSON->new->pretty($pretty)->allow_nonref->allow_unknown->allow_blessed->convert_blessed->encode($self);
	} || $@;
}

=head3 tempdir

returns a temporary directory whose content will be removed at the request end.
if you pass a relative path, it will be created under the random tmp directory.
if creation fails, a boolean false will be retured (void string).

	my $path = $j->tempdir; # will return something like /tmp/systemd-private-af123/tmp/nRmseALe8H
	my $path = $j->tempdir('DIRNAME'); # will return something like /tmp/systemd-private-af123/tmp/nRmseALe8H/DIRNAME

=cut

sub tempdir
{
	my ($self, $path) = @_;
	return $self->{_tempdir}->dirname unless $path;
	return $self->_makePath($path);
}

=head3 ctwd

changes current working directory to a random temporary directory whose content will be removed at the request end.
if you pass a path, it will be appended to the temporary directory before cwd'ing on it, bool outcome will be returned.
if creation fails, a boolean false will be returned (void string).

	my $cwdOK = $j->ctwd;

=cut

sub ctwd
{
	my ($self, $path) = @_;
	return chdir $self->{_tempdir} unless $path;
	$path = $self->_makePath($path);
	return $path ? chdir $path : '';
}

sub _makePath
{
	my ($self, $path) = @_;
	my $mkdirerr;
	$path = "$$self{_tempdir}/$path";
	File::Path::make_path($path, {error => \$mkdirerr});
	if(@$mkdirerr){
		for my $direrr (@$mkdirerr){
			my ($curdir, $curmessage) = %$direrr;
			say STDERR "error while attempting to create $curdir: $curmessage";
		}

		# if creation fails set $path to a "false" string
		$path = '';
	}

	$path;
}

sub _bless_tree
{
	my ($self, $node) = @_;
	my $refnode = ref $node;
	return unless $refnode eq 'HASH' || $refnode eq 'ARRAY';
	bless $node, ref $self;
	if ($refnode eq 'HASH'){
		$self->_bless_tree($node->{$_}) for keys %$node;
	}
	if ($refnode eq 'ARRAY'){
		$self->_bless_tree($_) for @$node;
	}
	$node;
}

sub TO_JSON
{
	my $self = shift;
	my $output;

	return [@$self] if (reftype $self // '') eq 'ARRAY';

	$output = {};
	for(keys %$self){
		my $skip;
		my $nodebug = ! $self->{_debug};
		if($self->{_is_root_element}){
			$skip++ if $_ =~ /_sub$/;
			$skip++ if $_ eq 'session' && $nodebug;
			$skip++ if $_ eq 'params' && $nodebug;
		}
		$skip++ if $_ =~ /^_/ && $nodebug;
		next if $skip;
		$output->{$_} = $self->{$_};
	}
	return $output;
}

# avoid calling AUTOLOAD on destroy
sub DESTROY{}

sub AUTOLOAD : lvalue
{
	my $classname = ref $_[0];
	my $validname = q{(?:[^[:cntrl:][:space:][:punct:][:digit:]][^':[:cntrl:]]{0,1023}|\d{1,1024})};
	our $AUTOLOAD =~ /^${classname}::($validname)$/;
	my $key = $1;
	die "illegal key name, must be of $validname form\n$AUTOLOAD" unless $key;
	my $miss = Want::want('REF OBJECT') ? {} : '';
	my $retval = $_[0]->{$key};
	my $isBool = Want::want('SCALAR BOOL') && ((reftype($retval) // '') eq 'SCALAR');
	return $$retval if $isBool;
	$_[0]->{$key} = $_[1] // $retval // $miss;
	$_[0]->_bless_tree($_[0]->{$key}) if ref $_[0]->{$key} eq 'HASH' || ref $_[0]->{$key} eq 'ARRAY';
	$_[0]->{$key};
}

=head1 NOTES

=head2 NOTATION CONVENIENCE FEATURES

In order to achieve autovivification notation shortcut, this module does not make use of perlfilter but does rather some gimmick with AUTOLOAD. Because of this, when you are using the convenience shortcut notation you cannot use all the names of public methods of this module (such I<new>, I<import>, I<run>, and others previously listed on this document) as hash keys, and you must always usei hash keys beginning with any Unicode char different from a posix defined space, punctuation, control, or digit char classes, followed from any combination of Unicode codepoints different from posix control chars, ' (apostrophe) and : (colon) chars. If you use a key hold from a variable, you can either use keys composed of only digits. The total lenght of the key must be not bigger than 1024 Unicode chars, this is an artificial limit set for security purposes. You can still set/access hash branches of whatever name using the brace notation. It is nonetheless highly discouraged the usage of underscore beginning keys through brace notation, at least at the top level of response hash hierarchy, in order to avoid possible clashes with private variable members of this very module.

=head2 MINIMAL REQUIREMENTS

this module requires at least perl 5.10 for its usage of "defined or" // operator

=head2 DEPENDENCIES

JSON and Want are the only non-core module used by this one, use of JSON::XS is strongly advised for the sake of performance. JSON::XS is been loaded transparently by JSON module when installed. CGI module is a core one at the moment of writing, but deprecated and likely to be removed from core modules in next versions of Perl.

=head1 SECURITY

Remember to always:

=over 4

=item 1. use taint mode

=item 2. use parametrized queries to access databases via DBI

=item 3. avoid as much as possible I<qx>, I<system>, I<exec>, and so on

=item 4. use SSL when you are keeping track of sessions

=back

=head1 HELP and development

the author would be happy to receive suggestions and bug notification. If somebody would like to send code and automated tests for this module, I will be happy to integrate it.
The code for this module is tracked on this L<GitHub page|https://github.com/ANSI-C/JSONP>.
Many thanks to L<Robert Acock|https://metacpan.org/author/LNATION> for providing improvement suggestions and bug reports.

=head1 LICENSE

This library is free software and is distributed under same terms as Perl itself.

=head1 COPYRIGHT

Copyright 2014-2019 by Anselmo Canfora.

=cut

1;
