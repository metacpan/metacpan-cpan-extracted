package Lithium::WebDriver;

use strict;
use warnings;

use JSON::XS;
use Time::HiRes qw/sleep gettimeofday alarm/;
use LWP::UserAgent;
use MIME::Base64;
use Lithium::WebDriver::Utils;
use HTTP::Request::Common ();

our $VERSION = '1.0.0';

# Add a delete function to LWP, for continuity!
no strict 'refs';
if (! defined *{"LWP::UserAgent::delete"}{CODE}) {
	*{"LWP::UserAgent::delete"} =
		sub {
			my ($self, $uri) = @_;
			$self->request(HTTP::Request::Common::DELETE($uri));
		};
}

my $user_agents = {
	linux => {
		firefox => 'Mozilla/5.0 (X11; Linux x86_64; rv:29.0) Gecko/20100101 Firefox/29.0',
		chrome  => 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36'
			      .' (KHTML, like Gecko) Chrome/31.0.1650.26 Safari/537.36',
	},
	apple => {
		ipad    => 'Mozilla/5.0 (iPad; CPU OS 6_0 like Mac OS X)'
			      .' AppleWebKit/536.26 (KHTML, like Gecko)'
			      .' Version/6.0 Mobile/10A5355d Safari/8536.25',
		iphone  => 'Mozilla/5.0 (iPhone; U; CPU iPhone OS 4_2_1'
			      .' like Mac OS X; da-dk) AppleWebKit/533.17.9'
			      .' (KHTML, like Gecko) Version/5.0.2 Mobile/8C148 Safari/6533.18.5',
	},
	android => {
		firefox => 'Mozilla/5.0 (Android; Mobile; rv:29.0) Gecko/29.0 Firefox/29.0',
		default => 'Mozilla/5.0 (Linux; U; Android 4.0.3; de-de;'
			      .' Galaxy S II Build/GRJ22) AppleWebKit/534.30'
			      .' (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30',
	}
};


sub new
{
	my ($class, %config) = @_;
	my $self = \%config;
	$self->{base}                 =
		       ($config{protocol} || "http")
		."://".($config{host}     || "localhost")
		.":"  .($config{port}     || 4444)
		."/wd/hub";
	$self->{error}                = {};
	$self->{window_list}          = ();
	$self->{host}                 = $self->{base};
	$self->{connection_timeout} ||= 3;
	$self->{window_tracking}    ||= "noop";
	$self->{LWP} = LWP::UserAgent->new(
		agent     => __PACKAGE__,
		use_eval  => 0,
	);
	$self->{LWP}->default_header(
		Content_Type => "application/json;charset=UTF-8");
	# pretty sure this violates RFC 2616
	push @{$self->{LWP}->requests_redirectable}, 'POST';
	bless $self, $class;
}
use strict 'refs';

sub connect
{
	my ($self, $url) = @_;
	$url ||= $self->{site};
	debug "Starting ". __PACKAGE__ ." connection...";
	debug "Probing connection to ".$self->{host};
	local $SIG{ALRM} = sub { die 1; };
	# This happens three other times, but in order for eval to not get over
	# written have to disable it in LWP.
	alarm $self->{connection_timeout};
	eval {
		my $url = $self->{base};
		$url =~ s/\/wd\/hub$//;
		my $not_connected = 1;
		while ($not_connected) {
			debug "Getting $url/sessions & ".$self->{base}."/sessions";
			if ($self->{LWP}->get("$url/sessions")->is_success||
				$self->{LWP}->get($self->{base}."/sessions")->is_success
			) {
				$not_connected = 0;
			}
			sleep 0.1;
		}
		alarm 0;
		1;
	} or do {
		alarm 0;
		error "Unable to connect to webdriver at host [".$self->{base}."]";
		return 0;
	};
	my $capabilities = $self->_post(host => "session",
		{ desiredCapabilities => $self->_capabilities });
	return (undef, error "Unable to match desired capabilities") unless $capabilities;
	$self->{base}          = $capabilities->{node}
		if $capabilities->{node};
	$self->{capabilities}  = $capabilities;
	$self->{base}          = $self->{base}.'/session/'.$self->{session_id};
	my $ret = $self->open(url => $url, timeout => 3);
	error "Error loading '$url'" unless $ret;
	$url = $ret;
	$self->window_size();
	$self->{url}           = $self->url;
	$self->{url} =~ s/\/+$//;
	debug "Current url: ".$self->{url};
	debug "Driver instantiated with:";
	dump $self;
	$self->{current_title} = $self->title;
	1;
}

sub disconnect
{
	my ($self) = @_;
	debug "Dumping driver object";
	dump $self;
	debug "Disconnecting from ".$self->{host};
	my $ret_val = $self->_delete(host => "/session/$self->{session_id}");
	if ($ret_val) {
		debug "Disconect ok";
		return 1;
	}
	return 0;
}

################################################################################

sub _capabilities
{
	my ($self) = @_;
	if ($self->{browser} =~ m/phantomjs/i) {
		if($self->{ua}) {
			debug "setting capabilities in Phantom Driver";
			my ($ua_platform, $ua_browser) = split m/\s*[-_ ]\s*/, $self->{ua};
			$ua_platform = lc $ua_platform if $ua_platform;
			$ua_browser  = lc $ua_browser if $ua_browser;
			if ($ua_platform && $ua_browser && $user_agents->{$ua_platform}{$ua_browser}) {
				$self->{ua} = $user_agents->{$ua_platform}{$ua_browser};
				debug "Setting user-agent to: $self->{ua}";
				return {
					browserName => $self->{browser},
					"phantomjs.page.settings.userAgent" => $self->{ua},
					"phantomjs.page.settings.resourceTimeout" => 10,
				};
			} else {
				return { browserName => $self->{browser},};
			}
		} else {
			return { browserName => $self->{browser},};
		}
	}
	return {
		browserName => $self->{browser},
		platform    => $self->{platform},
	};
}

sub _parse_error
{
	my ($self, $error) = @_;
	my $msg = $error;
	eval {
		$error = decode_json $error;
		$self->{error} = $error;
		delete $error->{value}{screen};
		$msg = $error->{value}{message};
	};
	$msg ||= "Unknown error occurred talking to selenium.";
	$msg =~ s/caused\s+by\s+Request.*//;
	$msg =~ s/Error\s+Message\s+=>\s+//;
	$msg =~ s/^\s+//;
	chomp $msg;
	$self->{error}{msg} = $msg;
	debug $msg;
}

sub _get_uri
{
	my ($self, $method, $path) = @_;
	return $method unless $path;
	$path = "/$path" if $path !~ m/^\//;
	my $uri;
	if ($method =~ m/path/) {
		$uri = $self->{base}.$path;
	} elsif ($method =~ m/host/) {
		$uri = $self->{host}.$path;
	} else {
		error "Unimplemented uri abbreviation: $method";
		exit 1;
	}
	$uri =~ s/\/$//;
	return $uri;
}

sub _session_id
{
	my ($self, $value) = @_;
	if (!$self->{session_id} && $value->{sessionId}) {
		$self->{session_id} = $value->{sessionId};
	} else {
		if ($self->{session_id} ne $value->{sessionId}){
			debug "Detected Session ID change from:\n".
				"\t$self->{session_id}".
				"to:\n\t".$value->{sessionId};
			$self->{session_id} = $value->{sessionId};
		}
	}
}

sub _get
{
	my ($self, $base, $path) = @_;
	my $uri = $self->_get_uri($base, $path);
	debug "Getting: $uri";
	my $res = $self->{LWP}->get($uri);
	$self->{last_res} = $res;
	if ($res->is_success) {
		$res = decode_json $res->content;
		$self->_session_id($res);
		return $res->{value};
	} else {
		$self->_parse_error($res->content);
		return undef;
	}
}

sub _delete
{
	my ($self, $base, $path) = @_;
	my $uri = $self->_get_uri($base, $path);
	debug "Deleting: $uri";
	my $res = $self->{LWP}->delete($uri);
	$self->{last_res} = $res;
	if ($res->code == 204) {
		return 1;
	} elsif ($res->is_success){
		$res = decode_json $res->content;
		if ($res->{status} != 0) {
			return _error_status($res->{status});
		}
		$self->_session_id($res);
		return $res->{value};
	} else {
		$self->_parse_error($res->content);
		return undef;
	}
}

sub _post
{
	my ($self, $base, $path, $obj) = @_;
	$obj ||= {};
	my $uri = $self->_get_uri($base, $path);
	if (!%$obj){
		debug "Posting to: $uri, no payload";
	} else {
		debug "Posting to: $uri\npayload is:";
		dump $obj;
	}
	$self->_window_id_list
		if $base ne 'host' && $self->{window_tracking} ne 'noop';
	my $res = $self->{LWP}->post($uri, Content => encode_json($obj));
	$self->{last_res} = $res;
	if ($res->code == 204) {
		return 1;
	} elsif ($res->is_success){
		$res = decode_json $res->content;
		if ($res->{status} != 0) {
			return _error_status($res->{status});
		}
		$self->_session_id($res);
		return $res->{value};
	} else {
		$self->_parse_error($res->content);
		return undef;
	}
}

########################### Window Functions ##################################

sub _window_id_list
{
	my ($self) = @_;
	# Pull a list of opaque windows each post, maintaining the order
	# in which they were opened
	my $new_windows    = $self->window_handles;
	if ($new_windows) {
		for my $new_window (@{$new_windows}) {
			my $match = 0;
			for my $old_window (@{$self->{window_list}}) {
				$match = 1 if $old_window eq $new_window;
				last if $match;
			}
			next if $match;
			push @{$self->{window_list}}, $new_window;
		}
	}
	return $self->{window_list};
}

sub update_windows
{
	my ($self) = @_;
	$self->_window_id_list();
}

sub _wait_for_page
{
	my ($self, %params) = @_;
	debug "Waiting for page to load"
		.", checking readystate and url";
	$params{timeout} ||= 3;
	debug "Page load timeout set to: $params{timeout} (ms)";
	my $url   = $self->url;
	debug "Current url: $url";
	my $readiness = $self->run(js => "return document.readyState;");
	debug "Document state: $readiness";
	my $title = $self->title;
	debug "Assumed new page, no longer in iframe.";
	$self->{in_frame} = undef;
	local $SIG{ALRM} = sub { die 1; };
	alarm $params{timeout};
	eval {
		while (!$readiness || $readiness !~ m/complete|interactive/ || $url =~ m/about\:blank/ ) {
			$readiness = $self->run(js => "return document.readyState;") || '';
			debug "Document ready state: $readiness";
			$url = $self->url || '';
			debug "Url: $url";
			$title = $self->title || '';
			debug "title is: $title";
			sleep 0.1;
		}
		alarm 0;
		1;
	} or do {
		alarm 0;
		debug "Timed out waiting for current window to load";
		return 0;
	};
	return 1;
}

sub _window_looper
{
	my ($self) = @_;
	my $window_list_new = $self->windows;
	$self->{current_window} = $self->window;
	for my $new_window (@$window_list_new) {
		my $match = 0;
		if (!$self->{window_titles}{$new_window}) {
			debug "Missing window title for ID: $new_window";
			my $title;
			if ($new_window eq $self->{current_window}) {
				$title = $self->title ;
			} else {
				debug "Switching to new window and getting title";
				my $original_window = $self->{current_window};
				$self->_window_id_list
					if $self->{window_tracking} eq 'noop';
				$self->_post(path => "/window", { name => $new_window});
				$title = $self->title;
				$self->_post(path => "/window", { name => $original_window });
			}
			$self->{window_titles}{$new_window} = $title if $title && $self->url ne "about:blank";
		}
		for my $old_window (@{$self->{window_list}}) {
			$match = 1 if $old_window eq $new_window;
			last if $match;
		}
		next if $match;
		push @{$self->{window_list}}, $new_window;
	}
}

sub window_names
{
	my ($self) = @_;
	debug "Getting a list of window titles";
	my $window_titles;
	my $original_window = $self->window;
	sleep 0.2;
	$self->_window_id_list;
	$self->_window_looper;
	debug "Window list is:";
	dump  $self->{window_list};
	for my $window_id (@{$self->{window_list}}) {
		debug "Window id: $window_id";
		my $window_title;
		if(defined $self->{window_titles}{$window_id} && $self->{window_titles}{$window_id} ne "") {
			$window_title = $self->{window_titles}{$window_id};
		} else {
			if ($original_window eq $window_id) {
				my $title = $self->title;
				if (defined $title && $title ne "" && $self->url ne "about:blank") {
					$window_title = $title;
				} else {
					$self->_wait_for_page();
					$window_title = $self->title;
				}
				$self->{window_titles}{$window_id} = $window_title;
			} else {
				debug "Switching to window: $window_id to get title";
				$self->_post(path => "/window", { name => $window_id});
				$self->_wait_for_page;
				$window_title = $self->title;
				$self->{window_titles}{$window_id} = $window_title;
				$self->_window_id_list
					if $self->{window_tracking} eq 'noop';
				$self->_post(path => "/window", { name => $original_window });
			}
		}
		push @$window_titles, $window_title;
	}
	dump $window_titles;
	my $name = $self->_post(path => "/window", { name => $original_window });
	return 0 unless $name;
	return $window_titles;
}

sub open
{
	my ($self, %params) = @_;
	(return 0, error "Window url required") unless $params{url};
	$params{url} = $self->{url} if $params{url} eq "/";
	$params{url} = "/$params{url}" unless ($params{url} =~ m/^(\/|https?:\/\/)/ || $self->{url} =~ m/\/$/);
	$params{url} =   $self->{url}.$params{url} unless $params{url} =~ m/^https?:\/\//;
	$self->_window_id_list
		if $self->{window_tracking} eq 'noop';
	my $status   =   $self->_post(path => "/url", {url => $params{url}});
	return 0 unless defined $status;
	$self->_wait_for_page(%params);
}
sub visit { &open(@_); }

sub open_window
{
	my ($self, %params) = @_;
	(return 0, error "Window url required") unless $params{url};
	debug "Getting list of current windows";
	my $old_windows = $self->windows;
	$self->_window_id_list if $self->{window_tracking} eq 'noop';
	$params{js} = "return window.open('$params{url}', '$params{url}', 'resizable,status');";
	my $ret = $self->run(%params);
	# my $window = $ret->{WINDOW};
	$params{method} = 'last';
	$params{value} = 'last';
	$ret = $self->select_window(%params);
	$self->_wait_for_page(%params);
	return 1 if $ret;
	return 0;
}

sub select_window
{
	my ($self, %params) = @_;
	if ($params{method} && ($params{method} eq 'last' || $params{method} eq 'first')) {
		debug "select_window - Attempting to switch focus to the $params{method} window";
	} else {
		debug "select_window - Attempting to switch focus to: $params{value}";
	}
	sleep 0.2;
	# default to first
	my $name;
	if ($params{method} && $params{method} eq 'last') {
		debug "Getting the last window";
		$self->_window_id_list if $self->{window_tracking} eq 'noop';
		$name = $self->_post(path => "/window", { name => $self->{window_list}[-1] });
	} elsif ($params{method} && $params{method} eq 'num') {
		(return 0, debug "Num requires a value parameter (window number to switch to)")
			unless defined $params{value};
		debug "Getting the $params{value} (th) window";
		$self->_window_id_list if $self->{window_tracking} eq 'noop';
		$name = $self->_post(
			path => "/window",
			{ name => $self->{window_list}[$params{value}] });
	} elsif ($params{method} && $params{method} eq 'title') {
		(return 0, debug "Title requires a value parameter") unless $params{value};
		debug "Method is title";
		debug "Dumping window list";
		dump $self->{window_list};
		$self->window_names;
		debug "Window titles:";
		dump $self->{window_titles};
		for my $window_id (@{$self->{window_list}}) {
			debug "Window id: $window_id";
			debug "Window title: ".$self->{window_titles}{$window_id};
			if ($self->{window_titles}{$window_id} =~ m/$params{value}/i) {
				debug "$window_id matches $params{value}, returning";
				$name = $self->_post(path => "/window", { name => $window_id });
				debug "Name var is: $name";
				last;
			}
		}
	} else {
		debug "Getting the first window (default)";
		$name = $self->_post(path => "/window", { name => $self->{window_list}[0]});
	}
	debug "Name is:";
	dump $name;
	return 1 if $name;
	return 0;
}

sub close_window
{
	my ($self, %params) = @_;
	my $ret;
	if ($params{method}) {
		$ret = $self->select_window(%params);
		return undef unless defined $ret;
		$ret = $self->_delete(path => "/window");
	} else {
		$ret = $self->_delete(path => "/window");
	}
	return $ret;
}

sub refresh
{
	my ($self, %params) = @_;
	debug "Refreshing the current page";
	$self->_post(path => "/refresh", {});
	$self->_wait_for_page(%params);
}

sub maximize
{
	my ($self, %params) = @_;
	debug "Maximizing the current window";
	my $ret_val = $self->_post(path => "/window/current/maximize", {});
	return 1 if $ret_val;
	debug "Maximize failed";
	return 0;
}

sub window_size
{
	my ($self, %params) = @_;
	$params{width}  ||= 1920;
	$params{height} ||= 1080;
	debug "Setting window size to x [$params{width}] by y [$params{height}]";
	my $ret = $self->_post(path => "/window/current/size",
		{width => $params{width}, height => $params{height}});
	return 1 if $ret;
	return 0;
}

sub frame
{
	my ($self, %params) = @_;
	(return 0, error "CSS element selector required") unless $params{selector};
	my ($id, $ret);
	# Right now ghostdriver does not support the parent method
	# if ($params{selector} =~ m/parent/i) {
	#	$ret = $self->_post(path => "/frame/parent");
	#	return $self->{last_res}->is_success;
	# }
	if ($params{selector} !~ m/default/i) {
		my $el = $self->_element_id(%params);
		return 0 unless $el;
		$params{x} = 0;
		$params{y} = 0;
		$self->mouseover(%params);
		$id = { ELEMENT => $el };
		$self->{in_frame} = 1;
	} else {
		$id = undef;
		$self->{in_frame} = undef;
	}
	$ret = $self->_post(path => "/frame", {id => $id});
	$self->{last_res}->is_success;
}

sub reset_frame
{
	my ($self) = @_;
	$self->_post(path => "/frame", {id => undef});
	$self->{in_frame} = undef;
	return $self->{last_res}->is_success;
}

sub window_tracking
{
	my ($self, $track) = @_;
	if ($track eq 'noop') {
		debug "Disabling strict window tracking";
		$self->{window_tracking} = 'noop';
	} else {
		if ($track ne 'strict') {
			debug "Defaulting to strict window tracking";
		} else {
			debug "Enabling strict window tracking";
		}
		$self->{window_tracking} = 'strict';
	}

}

###############################################################################

sub wait_for_it
{
	my ($self, $code, $timeout) = @_;
	$timeout ||= 30;
	local $SIG{ALRM} = sub { die 1; };
	alarm $timeout;
	eval {
		while (!$code->()) {
			sleep 0.1;
		}
		alarm 0;
		1;
	} or do {
		alarm 0;
		debug "Timed out executing codeblock in 'wait_for_it'";
		return 0;
	}
}

sub _element_id
{
	my ($self, %params) = @_;
	(return 0, error "CSS element selector required") unless $params{selector};
	debug "Looking for css descriptor: [$params{selector}], and getting opaque ID";
	$params{selector} =~ s/^css=?//;
	my $el = $self->_post(
		path => "/element", { using  => "css selector", value => $params{selector} });
	debug "Element object:";
	dump $el;
	debug "The opaque element ID for: [$params{selector}] is: [".$el->{ELEMENT}."]"
		if $el;
	return $el ? $el->{ELEMENT} : undef;
}

sub implicit_wait
{
	my ($self, $wait) = @_;
	$wait *= 1000; #convert sec to ms
	$wait ||= 200;
	debug "Timeout is: $wait (ms)";
	my $ret = $self->_post(path => "/timeouts/implicit_wait", { ms => $wait });
	$self->{last_res}->is_success;
}

sub wait_timeout
{
	my ($self, $wait) = @_;
	$wait *= 1000; #convert sec to ms
	$wait ||= 200;
	debug "Timeout is: $wait (ms)";
	my $ret = $self->_post(path => "/timeouts", { type => "implicit", ms => $wait });
	$self->{last_res}->is_success;
}

sub run
{
	my ($self, %params) = @_;
	(return undef, error "Please define something for me to run (param: js)") unless $params{js};
	$params{js} = "return $params{js}" unless $params{js} =~ m/^return/;
	$params{js} = "$params{js};" unless $params{js} =~ m/;$/;
	debug "Executing modified js: $params{js}";
	return $self->_post(path => "/execute", {script => $params{js}, args => ['ret']});
}

sub attribute
{
	my ($self, %params) = @_;
	(return 0, error "Html attribute required") unless $params{attr};
	my $id = $self->_element_id(%params);
	return undef unless defined $id;
	return 1 if $params{attr} eq 'exist' || $params{attr} eq 'present';
	$params{attr} =~ s/^html$/innerHTML/;
	my $path = "/element/$id/attribute/$params{attr}";
	   $path = "/element/$id/text"      if $params{attr} eq   "text";
	   $path = "/element/$id/selected"  if $params{attr} eq   "selected";
	   $path = "/element/$id/displayed" if $params{attr} =~ m/^displayed|visible$/;
	   $path = "/element/$id/location"  if $params{attr} eq   "location";
	debug "Getting attribute [$params{attr}] for element [$params{selector}] identified by [$id]";
	my $value = $self->_get(path => $path);
	return undef unless defined $value;
	if ($params{attr} eq 'location') {
		return ($value->{x}, $value->{y});
	}
	debug "Return attribute value: $value" if $value;
	return $value;
}

for my $sub (qw/text value html present visible/) {
	no strict 'refs';
	*$sub = sub {
		my ($self, $selector) = @_;
		$self->attribute(
			selector => $selector,
			attr     => $sub,
		);
	};
}

sub type
{
	my ($self, %params) = @_;
	my $id = $self->_element_id(%params);
	return undef unless defined $id;
	if ($params{clear}) {
		debug "Clearing text field before typing";
		my $retval = $self->_post(path => "/element/$id/clear");
		debug "The last response is:";
		dump $self->{last_res};
		return undef unless $self->{last_res}->is_success;
	}
	my @arr = split("", $params{value});
	debug "Posting array:";
	dump @arr;
	my $ret = $self->_post(path => "/element/$id/value", {value => \@arr});
	debug "Return value of typing in $params{selector}";
	dump $ret;
	unless ($params{retain_focus}) {
		# Simulate moving focus off the element just typed in
		$ret = $self->_post(path => "/element/$id/value", { value => [ "\t" ] });
		debug "Return value of tabbing out of $params{selector}";
		dump $ret;
	}
	return 1;
}

for my $sub (qw/url source title window_handles window_handle/){
	no strict 'refs';
	*$sub = sub { $_[0]->_get(path => "/$sub"); };
}
no warnings 'once';
*windows = \&window_handles;
*window  = \&window_handle;
use warnings 'once';

for my $sub (qw/sessions status/){
	no strict 'refs';
	*$sub = sub { $_[0]->_get(host => "/$sub"); };
}

sub log_types
{
	my ($self) = @_;
	my @arr = $self->_get(path => "/log/types");
	return @arr if @arr;
	return ["NONE"];
}

sub browser_logs
{
	my ($self) = @_;
	my @log_types = $self->log_types();
	my $log_data;
	for (@log_types) {
		debug "type found: $_\n";
		if ($_ eq 'browser') {
			$log_data = $self->_post(path => "/log", {type => 'browser'});
			dump $log_data;
		}
	}
	return $log_data;
}

sub har_logs
{
	my ($self, %params) = @_;
	my @log_types = $self->log_types();
	my $log_data;
	for (@log_types) {
		debug "type found: $_\n";
		if ($_ eq 'har') {
			$log_data = $self->_post(path => "/log", {type => 'har'});
		}
	}
	return 0 unless $log_data;
	if ($params{type} && $params{type} eq 'error') {
		$log_data = decode_json($log_data->[0]{message});
		my @ret_array;
		for (@{$log_data->{log}{entries}}) {
			my $status = $_->{response}{status} ? $_->{response}{status} : "Unknown";
			if ($status !~ m/^[23]\d\d/) {
				my $url =  $_->{request}{url};
				   $url =~ s/\?.*$//;
				debug "Method: ".$_->{request}{method}
					.", Url: ".$url
					.", Status: ".$status
					.", Reason: ".$_->{response}{statusText};
				push @ret_array, {
					method => $_->{request}{method},
					url    => $url,
					status => $status,
					msg    => $_->{response}{statusText},
				};
			}
		}
		return \@ret_array;
	} elsif ($params{type} && $params{type} eq 'info') {
		$log_data = decode_json($log_data->[0]{message});
		my @ret_array;
		for (@{$log_data->{log}{entries}}) {
			my $status = $_->{response}{status} ? $_->{response}{status} : "Unknown";
			my $url =  $_->{request}{url};
			   $url =~ s/\?.*$//;
			debug "Method: ".$_->{request}{method}
				.", Url: ".$url
				.", Status: ".$status
				.", Reason: ".$_->{response}{statusText};
			push @ret_array, {
				method => $_->{request}{method},
				url    => $url,
				status => $status,
				msg    => $_->{response}{statusText},
			};
		}
		return \@ret_array;
	} else {
		return decode_json($log_data->[0]{message});
	}
}

sub mouseover
{
	my ($self, %params) = @_;
	return 0 if $self->{in_frame};
	my $id = $self->_element_id(%params);
	return 0 unless defined $id;
	if ($params{x} && $params{y}) {
		$self->_post(path => "/moveto", {
				element => $id,
				xoffset => $params{x},
				yoffset => $params{y}});
	} else {
		$self->_post(path => "/moveto", {element => $id});
	}
	return $self->{last_res}->is_success;
}

sub click
{
	my ($self, %params) = @_;
	my $ret = $self->mouseover(%params);
	if(!$self->{last_res}->is_success || $params{force} || !$ret) {
		debug "Force clicking on element $params{selector}";
		my $id = $self->_element_id(%params);
		return 0 unless $id;
		return $self->_post(path => "/element/$id/click",{});
	}
	return 0 unless defined $ret;
	$ret =  $self->_post(path => "/click", {});
	return 0 unless defined $ret;
	return 1;
}


sub dropdown
{
	my ($self, %params) = @_;
	my $parent = $self->_element_id(%params);
	return 0 unless defined $parent;
	$params{method} ||= "value";
	debug "[$params{selector}] getting $params{method}";
	my $els = $self->_post(path => "/element/$parent/elements", {using => "css selector", value => "option"});
	debug "Children of [$params{selector}] identfied by opaque ID: $parent:";
	dump $els;
	my @elements;
	my $el;
	for my $id (@$els) {
		my $val;
		if ($params{method} && $params{method} eq 'label') {
			$val = $self->_get(path => "/element/".$id->{ELEMENT}."/text");
		} else {
			$val = $self->_get(path => "/element/".$id->{ELEMENT}."/attribute/value");
		}
		debug "The $params{method} for [".$id->{ELEMENT}."] is $val";
		$el = $id->{ELEMENT} if ($params{value} && $val =~ m/$params{value}/);
		push @elements, $val;
	}
	debug "Return elements is:";
	dump @elements;
	return @elements unless $params{value};
	return 0 unless defined $el && defined $self->_post(path => "/element/$el/click", {});
	1;
}

sub check
{
	my ($self, %params) = @_;
	$params{attr} = 'selected';
	debug "check parameters";
	dump \%params;
	my $checked = $self->attribute(%params);
	return 0 unless defined $checked;
	$self->click(%params) unless $checked;
	return 1;
}

sub uncheck
{
	my ($self, %params) = @_;
	$params{attr} = 'selected';
	my $checked = $self->attribute(%params);
	return 0 unless defined $checked;
	$self->click(%params) if $checked;
	return 1;
}

sub confirm
{
	my ($self) = @_;
	$self->_post(path => '/accept_alert', {});
	return $self->{last_res}->is_success;
}

sub cancel
{
	my ($self) = @_;
	$self->_post(path => '/dismiss_alert', {});
	return $self->{last_res}->is_success;
}

sub alert_text
{
	my ($self, $string) = @_;
	my $val;
	if (defined $string) {
		$val = $self->_post(path => '/alert_text', { text => $string });
	} else {
		$val = $self->_get(path => '/alert_text',);
	}
	return wantarray ? ($self->{last_res}->is_success, $val) : $val;
}

sub screenshot
{
	my ($self, $fn) = @_;
	(return 0, error "You MUST provide a file handle") unless $fn;
	$fn =~ s/\.+/\./g;
	if ($fn  !~ m/\.png$/) {
		$fn  =~ s/\.(jpg|jpeg|gif)$//;
		$fn .=   "\.png";
	}
	CORE::open my $fh, '>', $fn or return "Unable to save screenshot to $fn: $!";
	print $fh decode_base64($self->_get(path => "/screenshot"));
	CORE::close $fh;
}


=head1 NAME

Lithium::WebDriver - A WebDriver Client

=head1 DESCRIPTION

The Lithium::WebDriver module is accessed by the Synacor::Test::Selenium
module to ensure commonality with existing tests.

=head1 FUNCTIONS

External functions are called with a parameterized format ie:
DRIVER->some_function(timeout=> $some_timeout, selector => 'some css string')

=head2 new

Instantiate a new Web Driver object,

=over

B<Calling>

=over

my $DRIVER = Lithium::WebDriver->new(
  connection_timeout => <INT>,
  host               => <STRING>,
  port               => <INT>,
  protocol           => <STRING>,
  window_tracking    => ['noop', 'strict'],
);

=back

B<Return Values>

A webdriver object.

B<Parameters>

=over

=item I<protocol>

Either http or https defaults to http

=item I<host>

A host string to connect to, defaults to localhost.

=item I<port>

Port to connect over.

=item I<connection_timeout>

Given in seconds, defaults to 3.

=back

=back

=head2 connect

Connect to webdriver and open url. The url parameter is optional, if one was specified when creating the driver
object.

=over

B<Calling>

=over

$DRIVER->connect(
  $url,
);

=back

B<Return Values>

B<Parameters>

=over

=item I<url>

Unkeyed parameter denoting the url for the webdriver to connect to and test.

=back

=back

=head2 disconnect

Stop the webdriver gracefully.

=head2 maximize

Maximize the currently selected window.

=head2 open

Navigate to a URL in the currently active window. The url does not need to be
qualified as it will then be taken as the path parameter to the uri.

=over

B<Calling>

=over

$DRIVER->open(
  url     => <STRING>,
  timeout => <INT>,
);

=back

B<Return Values>

False if the webdriver status is negative

B<Parameters>

=over

=item I<url>

The url to navigate to, paths without hostnames are valid.

=item I<timeout>

Optional keyed parameter in seconds, defaults to 3.

=back

=back

=head2 visit

This is an alias for open.

=head2 open_window

Navigate to a URL in a new window. The url does not need to be
qualified as it will then be taken as the path parameter to the uri.

=head2 window_tracking

Turn on, or off window tracking strictness (local window list).
The only parameter is noop for off, or strict for maintaining the
most up-to-date local window list.

The only parameters are 'noop' or 'strict' strings. Noop disables
window list updating for most calls, and 'strict' is the legacy
behavior.

=head2 update_windows

Manually update the window list. This function takes no paramters, and
has no return values. This function has no parameters or return values.
This is a useful function when window_tracking is set to noop.

=head2 select_window

given a method navigate to a differnet (or same) opened window.

=over

B<Calling>

=over

$DRIVER->select_window(
  method  => <STRING>,
  value   => <STRING>,
  timeout => <INT>,
);

=back

B<Return Values>

B<Parameters>

=over

=item I<method>

Available methods are last, num, title and first. Title and num require a value parameter,
otherwise first and last do not require a value parameter.

=item I<value>

Either the title or window number to switch to.

=item I<timeout>

Timeout on waiting for windows to get their document readiness. Defaults to 3 seconds.

=back

=back

=head2 close_window

Close a window by either switching to it and closing it or closing the current window,
if no parameters are set.

=over

B<Calling>

=over

$DRIVER->close_window(
  [method => <STRING>,]
  [value  => <STRING>,]
  [timeout => <INT>,]
);

=back

B<Return Value>

=over

=item I<1>

on successful close

=item I<0>

on failure

=back

B<Parameters>

See I<select_window> for parameter descriptions

=back

=head2 window_size

Set the window size, given no parameters defaults to Full 1080 HD :)

=head2 window_handle

return the opaque window ID of the currently active window.

=head2 window

Alias of window_handle

=head2 window_handles

return an array of opaque window ids

=head2 windows

Alias of window_handles

=head2 window_names

Get an array of all the currently opened windows.

=head2 source

Get the current html source of the currently focused page. This chould change depending
on javascript calls.

=head2 refresh

Refresh the current page, equivelent to hitting the f5 key or ctrl+R, there is also a
built in waiting for the document (current page) to finish loading (document.ready)

=head2 implicit_wait

When searching for a HTML element, wait on the server (page to load/javascript). Takes
a time in seconds.

=head2 sessions

Get a list of all the current sessions

=head2 status

Get the webdriver status, useful to see if it's up, without instantiating a session.

=head2 title

Get the title of the currently focused window

=head2 url

Get the url of the currently focused window.

=head2 run

run javascript function represented by string input.

=over

B<Calling>

=over

$DRIVER->run(
  js => "SOME javascript here",
);

=back

B<Return Values>

The return value of the executed javascript.

B<Parameters>

=over

=item I<js>

A string representation of the javascript to run.

=back

=back

=head2 run_async

run asyncronus javascript (XHR?), similar to run.

=head2 attribute

Given a css identifier, get a html attribute of the first found element.

=over

B<Calling>

=over

$DRIVER->attribute(
  attr     => <STRING>,
  timeout  => <INT>,
  selector => <STRING>
);

=back

B<Return Values>

False on unable to find or unable to find element attribute.

B<Parameters>

=over

=item I<selector>

The css string element identifier.

=item I<attr>

The specific attribute to get, options are: exist/present, html, text, selected,
location, displayed/visible, otherwise any valid html attribute can be used.

=item I<timeout>

Time in seconds to wait for the webdriver to find the element using the css string.

=back

=back

=head2 present($selector)

Alias to $attribute( attr => 'present', selector => $selector);

=head2 visible

Alias to $attribute( attr => 'visible', selector => $selector);

=head2 text

Alias to $attribute( attr => 'text', selector => $selector);

=head2 value

Alias to $attribute( attr => 'value', selector => $selector);

=head2 html

Alias to $attribute( attr => 'html', selector => $selector);

=head2 dropdown

manipulate dropdowns.

=over

B<Calling>

=over

$DRIVER->dropdown(
  selector => $selector,
  timeout  => $timeout,
  method   => 'label|value',
  value    => $label_name,
);

=back

B<Return Value>

False on unable to find element. False on unexistent option.
If no value is given return a list of options values or labels.

B<Parameters>

=over

=item I<selector>

The CSS element selector for the dropdown element.

=item I<timeout>

Timeout after this many seconds if unable to find this element.

=item I<method>

The method to use to return the dropdown options can be label or value, where label is the text label that shows
up and value is the value that would be set on selection

=item I<value>

The option to pick by means of method, this parameter is optional. If unset an array of values/labels will be
returned.

=back

=back

=head2 log_types

Get the log types from the webdriver.

=over

B<Calling>

$DRIVER->log_types();

B<Return Values>

The log types represented by and array of strings.

B<Parameters>

None

=back

=head2 browser_logs

Get the WebBrowser logs from the connected driver.

=over

B<Calling>

$DRIVER->browser_logs();

B<Return Values>

A perl data structure representing the web-console, log lines.

The log lines, represent by an array of the following element structure:

{
	level:     The log level of the message ie: INFO, WARN, CRIT.
	timestamp: Milliesecond unix timestamp.
	message:   Character string of the message.
}

B<Parameters>

None.

=back

=head2 har_logs

Get HAR logs (Http Archive).

=over

B<Calling>

$DRIVER->har_logs(type => <STRING>);

B<Return Values>

If a type [error, info] is given then the return object is an array of http calls, that
consist of the follow object:

{
	method: Http method ie: GET
	status: The http code (204)
	reason: The string explaination of the http code.
	url:    The url of the http call
}

Otherwise if no type is set a perl object of the complete, HAR is returned.

B<Parameters>

=over

=item type <STRING> (OPTIONAL)

The search type is either 'error' or 'info', error, will return http calls,
that are not a 200 or 300 status code, 'info' will return a structure of all
http calls.

=back

=back

=head2 mouseover

By using a css selector ($selector), find a html input element and move the mouse to hover over it.

=over

B<Calling>

B<Return Values>

B<Parameters>

=over

=item I<selector>

A css selector for a html input element, can be of any sort of input (text area or otherwise).

=item I<timeout>

Time out and return false after a given amount of seconds.

=back

=back

=head2 click

By using a css selector ($selector), find a html element and attempt to click on it. This function also supports
clicking on the element at a given location (x, y from the upper left corner).

=over

B<Calling>

=over

$DRIVER->click(
  selector => $selector,
  timeout  => $timeout,
  x        => $x,
  y        => $y,
);

=back

B<Return Value>

False on unable to find $selector

B<Parameters>

=over

=item I<selector>

A css selector for a clickable html element.

=item I<timeout>

Time out and return false after a given amount of seconds.

=item I<x>

The x cordinate from the upper left corner of the html element (OPTIONAL).

=item I<y>

The y cordinate from the upper left corner of the html element (OPTIONAL).

=back

=back

=head2 type

By using a css selector ($selector), find a html input element and type a string ($value) into it.
This check times out after the set timeout ($timeout) in seconds.

=over

B<Calling>

=over

$DRIVER->type(
  selector => $selector,
  timeout  => $timeout,
  value    => $value,
);

=back

B<Return Value>

False on unable to find $selector

=over

B<Parameters>

=over

=item I<selector>

A css selector for a html input element, can be of any sort of input (text area or otherwise).

=item I<value>

The string you wish to type into the selector element.

=item I<timeout>

Time out and return false after a given amount of seconds.

=back

=back

=back


=head2 check

Check a checkbox. Will leave a checked checkbox checked.

=over

B<Calling>

=over

$DRIVER->check(
  selector => $selector,
  timeout  => $timeout,
);

=back

B<Return Value>

False on unable to find $selector

B<Parameters>

=over

=item I<selector>

The css selector string that will match the first element

=item I<timeout>

time out in seconds, will return false on timeout.

=back

=back

=head2 uncheck

Un-check a checkbox.

=head2 screenshot

Get a screenshot of the currently active window.

=over

B<Parameters>

=over

=item I<filename>

The file name to save the screenshot to.

=back

=back

=head2 frame

Change the DOM context to that of an iframe. A selector value of default will change to the
beginning frame context, IE the Top Level parent, and a selector value of parent will go up one
level.
When switching frames, the entire DOM context is switched to the newly selected iframe.
You will have to reset your context to go to select any elements outside of the current iframe.

=over

B<Calling>

=over

$DRIVER->frame(
	selector => 'css selector|default|parent',
	timeout  => INT);

=back

B<Return Values>

=over

=item I<0>

Indicates the function failed to switch context, or the frame id was not found.

=item I<1>

Indicates successful context switching.

=back

B<Parameters>

=over

=item I<selector>

The CSS Selector of the iframe to switch context to. The other possible value is
'default' which will reset the context to the main/top level frame, or the original DOM.

=item I<timeout>

The time to wait for search for an iframe by CSS selector.

=back

=back

=head2 reset_frame

When a frame is selected, then the flow is continued, often, the original page has been left,
either by form submittal or page reload, this function provides a failsafe, to reset the
internal state machine to before an iframe was entered.

=over

B<Calling>

=over

$DRIVER->reset_frame();

=back

B<Return Values>

=over

=item I<1>

The call to /frame was a success

=item I<0>

The call to /frame was not successful, but this will not affect future calls.

=back

B<Parameter>

None.

=back

=head2 wait_for_it

Given another function in this module, turn it into a waiting function, until either a timeout
or a successful return.

=over

B<Calling>

=over

$DRIVER->wait_for_it(
	sub { <code returning a boolean value> },
	$timeout);

=back

B<Return Values>

=over

=item I<0>

Indicates the subroutine passed in never returned positively, and wait_for_it timed out.

=item I<1>

Expected the subroutine passed in returned positively.

=back

B<Parameters>

Add all parameters for the called sub to the end of the function call.

=over

=item I<subroutine>

An anonymous sub to be executed until it returns a true value.

=item I<timeout>

Time to wait for sub to return true.

=back

=back

=head2 wait_timeout

Sets the implicit wait timeout of the WebDriver instance. Takes a time
in seconds.

=head2 cancel

Used to cancel a JS alert() dialog.

=head2 confirm

Used to confirm a JS alert() dialog.

=head2 alert_text

Used to set or get the text of a JS alert() dialog.

If passed a string, it will set the alert text and pop up
a new alert. Otherwise, will return the current alert text.

=head1 BUGS

Early in development it was found that after setting a useragent string,
with phantomjs it would get dropped when a new window was manually created or
created by a website (think target='_blank'). A bug was filed with ghostdriver
project but little progress has been made.

A possible work around is to determine the redirection url, and navigate your first
window to it, as this window still has the "fake" user agent. A second one is to not
use target="_blank" in your anchor tags, as this is commonally seen as poor website
design, ie: that choice should be left up to the user.

=head1 AUTHOR

Written by Dan Molik C<< <dan at d3fy dot net> >>

=cut

1;
