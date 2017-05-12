#  (C)  Simon Drabble  2002,2003
#  sdrabble@cpan.org  2002/03/22

#  $Id: Yahoo.pm,v 1.31 2003/10/19 03:55:50 simon Exp $
#

package Mail::Webmail::Yahoo;

require 5.006_000;


#BEGIN { open SIMONLOG, ">simon.$$.tmp" }
#END   { close SIMONLOG }


use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);


# This is an object-based package. We export nothing except for some flag
# values.
our @EXPORT_OK = ();
our @EXPORT = qw(
		YAHOO_MSG_FLAGS
		SAVE_COPY_TO_SENT_FOLDER
		SUPPRESS_BANNERS
		DELETE_ON_READ
		MOVE_ON_READ
		ATTACH_SIG
		SEND_AS_HTML
);


use Carp qw(carp);


use LWP::UserAgent;
# Turn on for mondo debugging oh yeah.
#use LWP::Debug qw(+);
use URI::URL;
use HTTP::Request;
use HTTP::Headers;
use HTTP::Cookies;
use HTML::LinkExtor;
use HTML::Entities;
use Mail::Internet;
use MIME::Base64;
use HTML::FormParser;
use HTML::TableContentParser;
use Mail::Webmail::MessageParser;
use CGI qw(escape unescape);



our $VERSION = 0.601;

use Class::MethodMaker
	get_set => [qw(trace cache_messages cache_headers)];


# These next bits should ideally go in a config file or something. Or be
# passable on the command line, or overrideable in the calling app. They will
# (hopefully) never change, but if they do, it would be better for the user to
# edit a simple configuration file than modify (possibly system-wide) code.

# TODO: future ver: have all relevant items in resource file (localisable?)
# thus few (if any) code changes needed if Yahoo change page layout (again)

# Config specific to this package.
our $USER_AGENT = "Yahoo-Webmail/$VERSION";
our $ENV_PROXY  = 0;


# Would prefer to 'use constant...' but that doesn't work well in regexps.
our $SERVER               = 'http://mail.yahoo.com';	
our $LOGIN_SERVER         = 'http://mail.yahoo.com';	

our $FOLDER_APP_NAME      = 'Folders';
our $SHOW_FOLDER_APP_NAME = 'ShowFolder';
our $EMPTY_FOLDER_APP_NAME= 'ShowFolder';
our $SHOW_MSG_APP_NAME    = 'ShowLetter';
our $SHOW_TOC             = qr{toc=[^\&]*};

our $ATTACH_SECTION       = '#attachments';

our $FULL_HEADER_FLAG     = 'Nhead=f&head=f';
our $EMPTY_FULL_HEADER_FLAG = qr{head=[^\&]*&?};

our $LOGIN_FIELD          = 'login';
our $PASSWORD_FIELD       = 'passwd';
our $SAVE_USER_INFO_FIELD = '.persistent';


# Should only get the 'check mail' option if logged in..
our $WELCOME_PAGE_CHECK   = qr{<a\s+href="/ym/ShowFolder?[^>]*>Check Mail</a>};


our $DATE_MOLESTERED_STRING = 'Date header was inserted';

our $COMPOSE_APP_NAME    = 'Compose';
our $COMPOSE_TO_FIELD    = 'To';
our $COMPOSE_CC_FIELD    = 'Cc';
our $COMPOSE_BCC_FIELD   = 'Bcc';
our $COMPOSE_SUBJ_FIELD  = 'Subj';
our $COMPOSE_BODY_FIELD  = 'Body';
our $COMPOSE_SAVE_COPY   = 'SaveCopy';
our $COMPOSE_ATTACH_SIG  = 'SigAtt';
our $COMPOSE_SEND_HTML   = 'Format';
our $COMPOSE_MONEY_FIELD = 'Money';
our $COMPOSE_SEND_MONEY_CHK = 'SendMoney';

##our $COMPOSE_SENT_OK_PRE = 'Your\s+mail\s*';
##our $COMPOSE_SENT_OK_POST= '\s*has\s+been\s+sent\s+to';
# New Version of Yahoo
our $COMPOSE_SENT_OK_PRE = '<td class=mtitle>Message Sent</td>';
our $COMPOSE_SENT_OK_POST= '';



# Fields for performing group operations - delete, move to, etc.
our $ACTION_FORM_NAME    = 'messageList';
our $DELETE_FLAG_NAME    = 'DEL';
our $MOVE_FLAG_NAME      = 'MOV';
our $MOVE_TO_FOLDER_NAME = 'destBox';


## Flag names & values. Used when sending, among other things.
use constant SAVE_COPY_TO_SENT_FOLDER =>  1;
use constant SUPPRESS_BANNERS         =>  2;
use constant DELETE_ON_READ           =>  4; # This and MOVE_ON_READ are
use constant MOVE_ON_READ             =>  8; # mutually exclusive.
use constant ATTACH_SIG               => 16;
use constant SEND_AS_HTML             => 32;
##use constant GET_UNREAD_ONLY          => 64; # Not Yet Implemented..

use constant YAHOO_MSG_FLAGS => qw(
		SAVE_COPY_TO_SENT_FOLDER
		SUPPRESS_BANNERS
		DELETE_ON_READ
		MOVE_ON_READ
		ATTACH_SIG
		SEND_AS_HTML
		);


# ick.
our $ATTACH_PRE = q{\s*<a href="?(/ym/ShowLetter/[^"]+)"?\s*>};
our $ATTACH_POST= q{(?<!</a>)</a>};
our $DOWNLOAD_FILE_LINK  = qr{${ATTACH_PRE}Download File${ATTACH_POST}};
our $DOWNLOAD_FILE_LINK2 = qr{${ATTACH_PRE}Download Without Scan${ATTACH_POST}};


# Used for matching (actually, removing anything not) email addresses
our $NAME_PART  = qr{("?[\w\s]+"?)?};
our $EMAIL_PART = qr{(<?[\w.]+\@\w+\.[\w.]+>?)};
#our $CLEAN_FROM = qr{(^From:)(?!$NAME_PART)?($NAME_PART)(?!$EMAIL_PART)?($EMAIL_PART).*};


## http://us.f406.mail.yahoo.com/ym/ShowFolder?Search=&Npos=1&next=1&YY=88041&inc=200&order=down&sort=date&pos=0&view=a&head=b&box=Inbox
our $NEXT_MESSAGES_LINK = qr{[^<"]*ShowFolder\?Search.*?&next=1[^>"']*};
our $PREV_MESSAGES_LINK = qr{[^<"]*ShowFolder\?Search.*?&previous=1[^>"']*};



sub new
{
	my $class = shift;

	my %args = @_;

	my $ua = new LWP::UserAgent(agent => $USER_AGENT, env_proxy => $ENV_PROXY);
	
	my $self = bless {
		_server        => $args{server}   || $SERVER,
		_username      => $args{username} || carp('No username defined'),
		_password      => $args{password} || carp('No password defined'),
		_login_server  => $args{login_server}|| $args{server} || $LOGIN_SERVER,
		_cookie_file   => $args{cookie_file},
		_logged_in     => 0,
		_connected     => 0,
		_ua            => $ua,
		_html_parser   => new Textractor,
	}, $class;


	if ($args{retrieve}) {
		warn __PACKAGE__, ": new: use of 'retrieve' parameter is deprecated and will be ignored.\n";
	}


	if (!$self->{_ua}->is_protocol_supported('https')) {
		die "https not supported by LWP. This application will not work.\n";
	}

	$self->{_ua}->env_proxy;

	my $cookie_jar = new HTTP::Cookies::Netscape(
			File => $self->{_cookie_file},
			AutoSave => 1);

	$cookie_jar->load;

	$self->{_cookie_jar} = $cookie_jar;

	$self->{_ua}->cookie_jar($cookie_jar);

	$self->cache_messages(1);
	$self->cache_headers(1);

# FIXME: why?
	$self->trace(0);
	
	return $self;
}


sub connect
{
	my ($self) = @_;
	return 0 if $self->{_connected};

# FIXME: really connect if necessary.
	$self->debug("connected.") if $self->trace;
	$self->{_connected} = 1;
}


sub login
{
	my ($self) = @_;
	return 0 if $self->{_logged_in};

	$self->connect unless $self->{_connected};

	my $uri = $self->{_login_server};
	$self->debug(" requesting login page '$uri'.") if $self->trace > 3;
	my $info = $self->_get_a_page($uri, 'GET');
	my $login_page = $info->content;

	unless ($login_page) {
		$@ = "Problem getting login page.";
		return undef;
	}

	my $p = new HTML::FormParser;

	my @login_params;

	$self->debug(" parsing login page.") if $self->trace > 4;

# Parse the returned 'welcome' page looking for a suspicious link to login
# with. This is kindly provided by (as of 2002-04-06 at least) the only form
# in the page. So hurrah.
# Note we don't store the login info in a cookie since it kinda makes no sense
# -- the only reason for doing so is to remove the need to enter a username in
# the login page; we provide this username in the object parameters.
# It might speed things up a little, but until Yahoo stops retiring sessions
# every eight hours or so, I'm not gonna bother re-using cookies.
	my $pobj = $p->parse($login_page, 
				start_form => sub {
					my ($attr, $origtext) = @_;
					$self->{STORED_URIS}->{login} = $attr; 
				},
				input => sub {
					my ($attr, $origtext) = @_;
					if ($attr->{name} eq $LOGIN_FIELD) {
						$attr->{value} = $self->{_username};
					} elsif ($attr->{name} eq $PASSWORD_FIELD) {
						$attr->{value} = $self->{_password};
					} elsif ($attr->{name} eq $SAVE_USER_INFO_FIELD) {
						$attr->{value} = '';
						$attr->{name} = '';
					}
					push @login_params, $attr;
				}
			);


	my @params;
	for (@login_params) {
		next unless $_->{name};
		push @params, "$_->{name}=$_->{value}";
	}


# This bit makes the actual request to login, having stuffed the @params array
# with the fields gleaned from the login page (plus our username and password
# of course). Note that there is some feature in LWP that doesn't like
# redirects from https, so we have to give it an insecure URI here.
# (might be a POST issue - worked ok in other code)
# FIXME: track this down; provide a secure work-around.
	$uri = $self->{STORED_URIS}->{login}->{action};
	$uri =~ s/https/http/g;
	my $meth = $self->{STORED_URIS}->{login}->{method};
#	for (@params) { warn "$_\n" }

	$info = $self->_get_a_page($uri, $meth, \@params);
	my $welcome_page = $info->content;

	unless ($welcome_page) {
		$@ = "Unable to log in (No welcome page).";
		$self->debug($@) if $self->trace;
		return undef;
	}

## welcome_page could be the login page returned, in the event of login
## failure.
	if ($welcome_page !~ /$WELCOME_PAGE_CHECK/) {
		$@ = "Unable to log in (welcome page did not contain welcome text).";
		$self->debug($@) if $self->trace;
#		$self->debug($welcome_page) if $self->trace > 9;
		return undef;
	}


	$self->{STORED_PAGES}->{welcome} = $welcome_page;

	$self->debug("Welcome page is ($welcome_page)") if $self->trace > 9;

	my $logged_in_uri = $info->request->url;

	$self->{STORED_URIS}->{base} = make_host($logged_in_uri);
	$self->{STORED_URIS}->{welcome} = $logged_in_uri;

	$self->debug("logged in.") if $self->trace;
	$self->debug("Base URI is $self->{STORED_URIS}->{base}") if $self->trace > 4;
	$self->debug("Welcome URI is $self->{STORED_URIS}->{welcome}") if $self->trace > 4;
	$self->{_logged_in} = 1;

	return 1;
}




sub get_mail_messages
{
	my ($self, $mbox, $msg_list, $flags, $newfol) = @_;
	$flags ||= 0;


	if (!$self->{_logged_in}) {
# Although ideally login() should print some diagnostics, it might be called
# from an application with "no" stderr. At this point, however, we are
# acting as an application function, so we die with the generated error here.
# If the application author wishes to live through this, perhaps to ask the
# user for another password, the call to get_mail_messages() can be eval'd.
		if (!$self->login) {
			die "get_mail_messages: $@\n";
		}
	}

	$self->get_folder_list;
	my @msgs = $self->get_folder_index($mbox);

	if ($flags & DELETE_ON_READ && $flags & MOVE_ON_READ) {
		warn "DELETE_ON_READ and MOVE_ON_READ are mutually incompatible.\n";
		warn "MOVE_ON_READ takes precedence.\n";
		$flags ^= DELETE_ON_READ;
	}

	if ($flags & DELETE_ON_READ) {
		my $l = $self->get_folder_action_link($mbox, $DELETE_FLAG_NAME);
		if (!$l) {
			warn "Unable to get 'Delete' URI - messages will NOT be deleted.\n";
			$flags ^= DELETE_ON_READ;
		}
	}

	if ($flags & MOVE_ON_READ) {
		die "No folder to move to!\n" unless $newfol;
		my $l = $self->get_folder_action_link($mbox, $MOVE_FLAG_NAME);
		if (!$l) {
			warn "Unable to get 'Move' URI - messages will NOT be moved.\n";
			$flags ^= MOVE_ON_READ;
		}
	}

	my @messages;

	my @message_nums;

# FIXME: confusing? bleh. could be construed as 'message numbers' or
# 'start..end'.
	if (ref($msg_list) eq 'ARRAY') { 
		@message_nums = @{$msg_list};
		$self->debug("Fetching messages numbered @message_nums") if $self->trace;
	} elsif (lc($msg_list) eq 'all' || !$msg_list) {
		@message_nums = (1..@msgs);
	}

	my $mcount = 0;

	for (@msgs) {
		++$mcount;
		next unless @message_nums && grep { $_ == $mcount } @message_nums;

# Change the program name to display the number of the current message, if
# supported.
		(my $prog = $0) =~ s/\s+\d+\s+messages//g;
		$prog .= ' ' . (0+@messages) . ' messages';
		$0 = $prog;


		my $uri = $_->{uri};
		$uri =~ s/$EMPTY_FULL_HEADER_FLAG//g;
		$uri .= "&" . $FULL_HEADER_FLAG;
		$uri =~ s/inc=\d+\&?//g;
		my ($yahoo_msg_id) = $uri =~ /MsgId=([^&]+)&/;

		my $info = $self->_get_a_page($uri);
		my $page = $info->content;
		
		if ($page) {

			$self->debug("Processing page at $uri") if $self->trace;
			push @messages, $self->_process_message($page, $yahoo_msg_id);

			if ($flags & DELETE_ON_READ) {
				my $uri = $self->{STORED_URIS}->{base} .
					$self->{STORED_URIS}->{DEL_action};
				$uri .= "&Mid=$yahoo_msg_id";
				$self->debug("Deleting $yahoo_msg_id") if $self->trace;
				my $page = $self->_get_a_page($uri, 'GET');
			}


			if ($flags & MOVE_ON_READ) {
				my $uri = $self->{STORED_URIS}->{base} .
					$self->{STORED_URIS}->{MOV_action};
				$uri .= "&$MOVE_TO_FOLDER_NAME=$newfol&Mid=$yahoo_msg_id";
				$self->debug("Moving $yahoo_msg_id to $newfol with $uri")
					if $self->trace;
				my $page = $self->_get_a_page($uri, 'GET');
			}

		} else {

			warn "Couldn't retrieve message id $_->{id}\n";

		}
	}

	return @messages;
}



sub _process_message
{
	my ($self, $page, $yahoo_msg_id) = @_;

	my $mhdr = $self->_extract_headers($page, $yahoo_msg_id);
	if ($mhdr) {
		$self->_extract_body($mhdr, $page);
	}

###	push @messages, $mhdr;
###	print 0+@messages, " messages\n" if (!(@messages % 20));

	return $mhdr;
}



sub _extract_headers
{
	my ($self, $page, $yahoo_msg_id) = @_;
	my @hdrs;

	my $p = new HTML::TableContentParser;
	my $stored_tables = $p->parse($page);

	my $from_date = '';


#			print SIMONLOG "sdd 025.$mcount; ($page)\n";

	for my $t (@$stored_tables) {
		next unless $t->{rows};

		for my $r (@{$t->{rows}}) {
			next unless $r->{cells};

			for my $c (0..@{$r->{cells}}-1) {

# We're only interested in data that contains a message header, and the field
# associated with it -- but there may be a bunch of other crap stuck in by
# yahoo that 'looks like' a message header. So we validate against a known
# list of message headers. The first check is faster than examining every item
# of data through the grep.

				next unless my $field = $r->{cells}->[$c]->{data};
				my $data  = $r->{cells}->[$c+1]->{data};

				my $mp = new Mail::Webmail::MessageParser;
				$mp->{_debug} = $self->trace;
				my $hdr = $mp->parse_header($field, $data);
				$mp->delete(); # Free allocated memory
				next unless $hdr;
				++$c;

# 'From' header has 'block address' and other crap in it..
				if ($hdr =~ /^From/) {
# Remove everything not looking like an email address..
# Make no attempt to validate the address; just remove non-compliant
# characters (actually quite hard.. the address itself is all we care about,
# really, but we'll try and get the "name" part)
#							$hdr =~ s/((\&nbsp;)|(\s*))?(\||\240).*//g;
#							$hdr =~ s/$CLEAN_FROM/$1 $2 $3/;
					my ($from, $name) = $hdr =~ /(From:?)\s*($NAME_PART)/i;
					$name ||= '';
					my ($email)       = $hdr =~ /($EMAIL_PART)/i;
					$hdr = "$from $name $email";

# Also add a 'From' line so pine et al recognise it as a message.
					$from = "$name $email";
#							$from =~ s/".*"//g;
#							$from =~ s/<|>//g;

					push @hdrs, "From $from";

				} elsif ($hdr =~ /Date/) {
# Sometimes the date field gets molestered..
					if ($hdr =~ /$DATE_MOLESTERED_STRING/) {
						$hdr = ' ' . scalar localtime time;
					}
#							($from_date = $data) =~ s/,//g;
					$from_date =  ' ' . scalar localtime time;
				}

				push @hdrs, $hdr;
			}
		}
	}
# Add the Yahoo message Id - this might come in useful.
	push @hdrs, "X-Yahoo-MsgId: $yahoo_msg_id";

# Add our own header - might be useful
	push @hdrs, "X-Mail-Webmail-Yahoo-Version: $VERSION";

# Sort the headers so 'From' comes first..
	my $hdr = [sort { $a =~ /^From\s+/ ? -1 : 1 } @hdrs];
# ..and add the date to the 'From' header, so it looks like mail.
	$hdr->[0] .= $from_date;


# Finally construct a new Mail object containing our headers and return it.
	my $mhdr = new Mail::Internet($hdr);
	return $mhdr;
}



sub _extract_body
{
	my ($self, $mhdr, $page) = @_;
# So much for the header, now for the body.. Yahoo kindly provides 
# <div id=message> at the top, but the bottom is just a </div>. So we have to
# hope the HTML is correctly formed, or at least those parts of it - a stray
# </div> inside the message body will cause problems. See the documentation
# for MessageParser for more.
	my $mp = new Mail::Webmail::MessageParser;
	$mp->{_debug} = $self->trace;
# Gets the part of the page that contains the message, as defined by Yahoo..
	$mp->message_start(_tag => 'div', id => 'message');
	$mp->message_read($page);

# Yahoo quite decently provides a way to remove inlined attachments..
	$mp->remove_matching(_tag => 'a', name => 'attachments');

# Remove any extra HTML that might appear around the delivered body..
	$mp->extract_body([_tag => 'table'], [_tag => 'tr'], [_tag => 'td']);
# Yahoo gives text messages 'pre' tags..
# Ha! We don't need to do this - the <pre> tags will get swallowed in the
# conversion to text (as_text). Of course, this relies on the content-type
# being set correctly..
########	$mp->extract_body([_tag => 'pre'], [_tag => 'tt']);
# And finally get the body text in the required form.
	my $body = $mp->body_as_appropriate($mhdr);
	$mp->delete();


# Set the body. Grue. I kinda think it would be nice if $mhdr->print_body
# could be given a delimiter to print between each pair of elements.
	my @body = map { "$_\n" } split /\n/, $body;
	$mhdr->body(@body);

# Check for downloadable attachments, mime-encode, and stuff into the message
# using some magic to set content types etc.
	while ($page =~ s{$DOWNLOAD_FILE_LINK}{}si ||
				 $page =~ s{$DOWNLOAD_FILE_LINK2}{}si) {
		my $download_link = $1;
		$self->debug("Attachment link: $download_link") if $self->trace > 3;
		my $url = make_host($_->{uri});
		$download_link .= $FULL_HEADER_FLAG;
		my $link = $url . $download_link;
		$self->download_attachment($link, $mhdr);
	}
	return 1; # no errors?
}




sub download_attachment
{
	my ($self, $download_link, $snagmsg) = @_;

	my ($filename) = $download_link =~ /filename=([^\&]*)/;
	my $info = $self->_get_a_page($download_link);

	if ($snagmsg) {
		$self->add_attachment_to_message($snagmsg, $info, $filename);
	}

	return $info;
}




sub add_attachment_to_message
{
	my ($self, $msg, $att, $filename) = @_;

	my $filedata = $att->content;

	my $ct = $msg->get('Content-Type') || '';
	$self->debug("Content-Type for $filename: $ct") if $self->trace > 3;

# This shouldn't happen, but can if we can't, for some reason, get the full
# header page. 
# TODO: write make_multipart_boundary!
	if ($ct !~ /multipart\/mixed/i) {
		$msg->replace('Content-Type', $self->make_multipart_boundary($msg));
		$ct = $msg->get('Content-Type');
	} 

	$ct =~ s/boundary="?([^"]+)"?//i;
	my $bndry = $1;
	$msg->replace('MIME-Version', '1.0');

##		--0-1260933182-1019570195=:33950
##			Content-Type: text/plain; charset=us-ascii
##			Content-Disposition: inline

# TODO: tidy this up a bit
	my @body = @{$msg->body};
	unless ($body[0] =~ m{This is a multi-part message in MIME format.}) {
		unshift @body,
			"This is a multi-part message in MIME format.\n\n",
			"--$bndry\n",  
			"Content-Type: $ct;  charset=us-ascii\n",
			"Content-Disposition: inline;\n\n";
	}
	
	my $encoded_data = MIME::Base64::encode_base64($filedata);

	push @body, "--$bndry\n",
		"Content-Type: ", join('; ', $att->content_type), "\n",
		"Content-Transfer-Encoding: base64\n",
		"Content-Disposition: attachment; filename=$filename\n\n",
 		$encoded_data;
	$msg->body(@body);
	
}



sub make_multipart_boundary
{
}




sub get_folder_action_link
{
	my ($self, $mbox, $linktype, $force) = @_;

	$self->login unless $self->{_logged_in};

	if (!$self->{STORED_URIS}->{folder_list}->{$mbox}) {
		die "No such folder '$mbox' found in list.\n";
	}

	my $index;
	if (!($index = $self->{STORED_PAGES}->{message_index}->{$mbox}->[0])
			|| $force) {
		my $uri = $self->{STORED_URIS}->{folder_list}->{$mbox};
		$self->debug("INDEX URI for $mbox: $uri") if $self->trace() > 1;
		my $info = $self->_get_a_page($uri);
		$index = $info->content;

		$self->{STORED_PAGES}->{message_index}->{$mbox}->[0] = $index;
	}


	my $form_uri = '';
	my @params = ();
	my $start_collecting = 0;
	my $p = new HTML::FormParser;

	my $pobj = $p->parse($index, 
				start_form  => sub {
					my ($attr, $origtext) = @_;
					if ($attr->{name} eq $ACTION_FORM_NAME) {
						$form_uri = $attr->{action};
						$start_collecting = 1;
					}
				},

				start_input => sub {
					my ($attr, $origtext) = @_;
					return unless $start_collecting;
					return unless $attr->{name};
					if ($attr->{name} eq '.crumb' || $attr->{name} eq $linktype) {
						$attr->{value} = 1 if $attr->{name} eq $linktype;
						push @params, "$attr->{name}=$attr->{value}";
					}
				},
		);

	return undef unless $form_uri;
	
#		store link as well as return it
	my $plist = join '&', @params;
	$form_uri .= $form_uri =~ /\?/ ? "&$plist" : "?$plist";
	$self->{STORED_URIS}->{"${linktype}_action"} = $form_uri;
	return $form_uri;

}




sub get_folder_index
{
	my ($self, $mbox) = @_;

	$mbox ||= 'Inbox';
	$self->login unless $self->{_logged_in};

	if (!$self->{STORED_URIS}->{folder_list}->{$mbox}) {
		die "No such folder '$mbox' found in list.\n";
	}

	my $uri = $self->{STORED_URIS}->{folder_list}->{$mbox};
	$self->debug("INDEX URI for $mbox: $uri") if $self->trace() > 1;
	my $info = $self->_get_a_page($uri);
	my $index = $info->content;

	$self->{STORED_PAGES}->{message_index}->{$mbox}->[0] = $index;

	my @msgs;

	if ($index) { push @msgs, $self->_get_message_links($index) }


# Handle 'next' and 'previous' - mail box might be set up to display in
# reverse. We'll continue to follow the first of either type found.
# If 'next', has_more = 1. If 'prev', has_more = -1, otherwise 0.
	my $has_more = 0;
	my $more_page;
	do {
		if ($has_more >= 0) {
			$more_page = ($index =~ /($NEXT_MESSAGES_LINK)/i)[0];
			$has_more = $more_page ?  1 : 0;
		}
		if ($has_more <= 0) {
			$more_page = ($index =~ /($PREV_MESSAGES_LINK)/i)[0];
			$has_more = $more_page ? -1 : 0;
		}
		
		if ($has_more) {
			$self->debug(" following link for more messages") if $self->trace > 4;
			my $url = new URI::URL($uri);
			my $link = $url->scheme . '://' . $url->host . $more_page;
			$index = $self->_get_a_page($link)->content;
			if ($index) { push @msgs,  $self->_get_message_links($index) }
		}

	} while ($has_more != 0);

	return @msgs;
}



sub _get_message_links
{
	my ($self, $page) = @_;
	my @msgs;
	my $p = new HTML::LinkExtor(
			sub
			{
				my ($tag, $type, $uri) = @_;
# Attachment links are shown before the message subject-link.
				if ($type eq 'href'                                 &&
						$uri =~ /$SHOW_MSG_APP_NAME\?.*MsgId=([^\&]*)/i &&
						$uri !~ /$SHOW_TOC/i                            && 
						$uri !~ /$ATTACH_SECTION/i) {
					$self->debug(" get_message_list: $uri") if $self->trace > 4;
					$self->{STORED_URIS}->{messages}->{$1} = $uri;
# Use a separate array here rather than simply returning the keys of the
# STORED_URIS->message hash since we're only interested in one folder.
					push @msgs, {
						id => $1,
						uri => $uri,
						};
				}
			},
			$self->{STORED_URIS}->{base});

	$p->parse($page);

	return @msgs;
}


sub get_folder_list
{
	my ($self) = @_;
	$self->login unless $self->{_logged_in};

	my $index = $self->{STORED_PAGES}->{welcome};
	if (!$index) {
		my $info = $self->_get_a_page($self->{_server});
		my $server = $info->request->uri;
		$index = $info->content;
		$self->{STORED_URIS}->{folder} = $server;
	}


	if (!$self->{STORED_URIS}->{front_page}) {
		my $p = new HTML::LinkExtor(
				sub
				{
					my ($tag, $type, $uri) = @_;
					if ($type eq 'href' && $uri =~ /$FOLDER_APP_NAME\?/) {
						$self->debug("FRONT PAGE: $uri") if $self->trace > 4;
						$self->{STORED_URIS}->{front_page} = 
							$uri;
					}
				},
				$self->{STORED_URIS}->{base});

		$p->parse($index);
	}

# TODO: inefficient to get this more than once per session - check for folders
# already before collecting/ parsing page again.

	if ($self->{STORED_URIS}->{front_page}) {
		my $indp = $self->{STORED_PAGES}->{index_page} ||
			$self->_get_a_page($self->{STORED_URIS}->{front_page})->content;

		my $p = new HTML::LinkExtor(
				sub
				{
					my ($tag, $type, $uri) = @_;
					if ($type eq 'href') {
						if ($uri =~ /$SHOW_FOLDER_APP_NAME\?.*box=([^\&]*)/) {
							$self->{STORED_URIS}->{folder_list}->{$1} = $uri;
							$self->debug(" get_folder_list: $uri for $1") if $self->trace > 4;
# Yahoo has these two special folders - Bulk & Trash. 'Empty' works magically
# on them..
						} elsif ($uri =~ /$EMPTY_FOLDER_APP_NAME\?.*\b?EB=1/) {
# For some reason Yahoo names the bulk folder '%40B%40Bulk' (@B@Bulk)
							$self->{STORED_URIS}->{empty_folder_list}->{Bulk} = $uri;
							$self->debug(" get_folder_list: Empty: $uri for Bulk") if $self->trace > 4;
						} elsif ($uri =~ /$EMPTY_FOLDER_APP_NAME\?.*\b?ET=1/) {
							$self->{STORED_URIS}->{empty_folder_list}->{Trash} = $uri;
							$self->debug(" get_folder_list: Empty: $uri for Trash") if $self->trace > 4;
						}
					}
				},
				$self->{STORED_URIS}->{base});

		$p->parse($indp);
	}

	return keys %{$self->{STORED_URIS}->{folder_list}};
}







sub send
{
	my ($self, $to, $subject, $body, $cc, $bcc, $flags) = @_;

	$cc  ||= '';
	$bcc ||= '';
	$flags ||= 0;

	my $really_to  = ref($to)  eq 'ARRAY' ? join ',', @$to  : $to;
	my $really_cc  = ref($cc)  eq 'ARRAY' ? join ',', @$cc  : $cc;
	my $really_bcc = ref($bcc) eq 'ARRAY' ? join ',', @$bcc : $bcc;

	unless ($self->{_logged_in}) {
		if (!$self->login) {
# Although ideally login() should print some diagnostics, it might be called
# from an application with "no" stderr. At this point, however, send() is
# acting as an application function, so we die with the generated error here.
# If the application author wishes to live through this, perhaps to ask the
# user for another password, the call to send() can be eval'd.
			die "send: $@\n";
		}
	}

	my $compose_uri = $self->{STORED_URIS}->{compose};


	if (!$compose_uri) {
		my $p = new HTML::LinkExtor(
				sub
				{
					my ($tag, $type, $uri) = @_;
					if ($type eq 'href' && $uri =~ /$COMPOSE_APP_NAME/i) {
						$self->{STORED_URIS}->{compose} = $uri;
						$compose_uri = $uri;
					}
				},
				$self->{STORED_URIS}->{base});

		$p->parse($self->{STORED_PAGES}->{welcome});
	}

	if (!$compose_uri) {
		warn "send: Couldn't get compose URI.\n";
		return undef;
	}

	my $compose_page = $self->{STORED_PAGES}->{compose};
	
	unless ($compose_page) {
		my $compose_resp = $self->_get_a_page($compose_uri);
		$compose_page = $compose_resp->content;
	}

	unless ($compose_page) {
		warn "send: Unable to retrieve compose page.\n";
		return undef;
	}


	my $p = new HTML::FormParser;

	my @compose_params;

	my $pobj = $p->parse($compose_page, 
				start_form => sub {
					my ($attr, $origtext) = @_;
					$self->{STORED_URIS}->{send} = $attr; 
				},
				start_input => sub {
					my ($attr, $origtext) = @_;
					if (my $name = $attr->{name}) {
						if ($name eq $COMPOSE_TO_FIELD) {
							$attr->{value} = $really_to;
						} elsif ($name eq $COMPOSE_CC_FIELD) {
							$attr->{value} = $really_cc;
						} elsif ($name eq $COMPOSE_BCC_FIELD) {
							$attr->{value} = $really_bcc;
						} elsif ($name eq $COMPOSE_SUBJ_FIELD) {
							$attr->{value} = $subject;
						} elsif ($name eq $COMPOSE_BODY_FIELD) {
							$attr->{value} = $body;
						} elsif ($name eq $COMPOSE_MONEY_FIELD) {
							$attr->{value} = "";
						} elsif ($name eq $COMPOSE_SEND_MONEY_CHK) {
							$attr->{value} = "";
						} elsif ($name eq $COMPOSE_ATTACH_SIG) {
							$attr->{value} = $flags & ATTACH_SIG ? 'yes' : 'no'; 
						} elsif ($name eq $COMPOSE_SEND_HTML) {
							$attr->{value} = $flags & SEND_AS_HTML ? 'yes' : 'no'; 
						} elsif ($name eq $COMPOSE_SAVE_COPY) {
							$attr->{value} = $flags & SAVE_COPY_TO_SENT_FOLDER ? 'yes' : 'no';
						}
						push @compose_params, $attr;
					}
				},
				start_textarea => sub {
					my ($attr, $origtext) = @_;
					if ($attr->{name} eq $COMPOSE_BODY_FIELD) {
						$attr->{value} = $body;
					}
					push @compose_params, $attr;
				}
				

			);


	my @params;
	for (@compose_params) {
		next unless $_->{name};
		$_->{value} ||= '';
		push @params, "$_->{name}=$_->{value}";
	}

	my $uri = make_host($self->{STORED_URIS}->{welcome});
	$uri .= $self->{STORED_URIS}->{send}->{action};
	$uri =~ s/https/http/g;
	my $meth = $self->{STORED_URIS}->{send}->{method};

	$self->debug("Sending '$subject' to ", join(';', $really_to, $really_cc, $really_bcc)) if $self->trace;

	my $info = $self->_get_a_page($uri, $meth, \@params);
	my $recvd = $info->content;

	open MSGSENT, ">sent";
	print MSGSENT $recvd;
	close MSGSENT;

##	my $check_sent_ok = $COMPOSE_SENT_OK_PRE . "\\($subject\\)"
##			. $COMPOSE_SENT_OK_POST;

## New version of Yahoo doesn't use the subject in sent confirmation..
	my $check_sent_ok = $COMPOSE_SENT_OK_PRE . $COMPOSE_SENT_OK_POST;

	if ($recvd =~ /$check_sent_ok/) {
		$self->debug("Sent '$subject' to ", join(';',$really_to, $really_cc, $really_bcc)) if $self->trace;
		return 1;
	}
	warn "send: Sent message page did not contain expected string. Message may not have been sent successfully.\n";
	return 0;

}



# Empties the specified magic folder - only Bulk | Trash as of 2003/10/08
# Returns 1 on 'successful' empty, 0 otherwise.
sub empty
{
	my ($self, $folder) = @_;
	unless ($self->{_logged_in}) {
		if (!$self->login) {
# See notes for 'send'
			die "empty: $@\n";
		}
	}
	$self->get_folder_list;


	my $uri = $self->{STORED_URIS}->{empty_folder_list}->{$folder};
	if (!exists $self->{STORED_URIS}->{empty_folder_list}->{$folder}) {
		$@ = "Can't empty folder '$folder'.";
		return 0;
	}

	$self->_get_a_page($uri);

	return 1;
}





# TODO: allow $params to be a hashref perhaps
sub _get_a_page
{
	my ($self, $uri, $method, $params) = @_;

	return undef unless $uri;

	$method ||= 'GET';
	$method =~ tr/a-z/A-Z/;


	my $req = new HTTP::Request($method, $uri);

  my $post_content = '';
	if (ref($params) eq 'ARRAY') {
		my @vars;
		for (@$params) {
			my ($name, $value) = $_ =~ /([^=]*)=?(.*)/s;
			push @vars, "$name=" . CGI::escape($value);
		}
		my $char = $method eq 'GET' ? '&' : "\r\n";
# POST doesn't like \r\n-separated content :/
		$char = '&';
		$post_content = join $char, @vars;
		$post_content .= $char if $char ne '&';
	}


	if ($post_content) {
		if ($method =~ /POST/) {
			$req->content($post_content);
			$req->content_type('application/x-www-form-urlencoded');
			$req->content_length(length $post_content);
		} elsif ($method =~ /GET/) {
			$uri .= "?$post_content";
			$uri =~ s/\?([^\?]*)\?/?$1&/g;
		}

	}

	$self->debug(" requesting uri '$uri' via $method.") if $self->trace > 1;
	$self->debug(" parameters: $post_content")
		if $post_content && $self->trace > 3;

	$self->debug(" Request: === \n", $req->as_string, "===\n")
		if $self->trace > 4;

	$req->header(pragma => 'no-cache');

	$req->header(Accept => 'text/html, text/plain, application/x-director, application/x-shockwave-flash, image/x-quicktime, video/quicktime, image/jpeg, image/*, application/x-gunzip, application/x-gzip, application/x-bunzip2, application/x-tar-gz, audio/*, video/*, text/sgml, video/mpeg, image/jpeg, image/tiff, image/x-rgb, image/png, image/x-xbitmap, image/x-xbm, image/gif, application/postscript, */*;q=0.01');


#	$req->header(Accept_Encoding => 'gzip, compress');
	$req->header(Accept_Language => '*');
	$req->header(Cache_Control => 'no-cache');
	$req->header(Referer => 'file://none.html');
	
##	$self->{_cookie_jar}->add_cookie_header($req);
	my $resp = $self->{_ua}->request($req);

	$self->{_cookie_jar}->extract_cookies($resp);
	$self->{_cookie_jar}->save;
	
##	$self->debug(" Response:\n", $resp->as_string, "\n\n") if $self->trace > 9;
	$self->debug(" returned code ", $resp->code, ".")      if $self->trace > 2;

	$self->debug(" request uri ", $resp->request->url)     if $self->trace > 4;
	$self->debug(" request contents ", $resp->content)     if $self->trace > 9;

# FIXME: Not sure about this guy. Seems like redirects are always gonna be
# GETs even if the original request was a POST. Little bit of hokum from Yahoo
# with their multiple-302 chain.
	if ($resp->code == 302) {
		$uri = $resp->header('Location');
		$self->debug(" 302 (Moved Temporarily) to $uri encountered.")
			if $self->trace > 2;
		return $self->_get_a_page($uri, 'GET', $params);
	}
	
	return $resp;
}




sub debug
{
	my $self = shift;
	warn __PACKAGE__, ": @_\n";
}



sub make_host
{
	my ($self, $uri) = @_;
	
	if (ref($self) ne __PACKAGE__) {
		$uri = $self;
	}
	my $url = new URI::URL($uri);
	return $url->scheme . '://' . $url->host . ':' . $url->port;
}


1;


# Minimal package for extracting & storing message text

package Textractor;

use base 'HTML::Parser';

sub parse_text 
{
	my ($self, $html) = @_;
	$self->{stored_text} = '';
	$self->parse($html);
	return $self->{stored_text};
}


sub text
{
	my ($self, $text) = @_;
	$self->{stored_text} .= $text;
}


1;




__END__

=head1 NAME

Mail::Webmail::Yahoo - Enables bulk download of yahoo.com -based webmail.

=head1 SYNOPSIS

  use Mail::Webmail::Yahoo;
  $yahoo = Mail::Webmail::Yahoo->new(%options);
  @folders = $yahoo->get_folder_list();
  @messages = $yahoo->get_mail_messages('Inbox', 'all');
  # Write messages to disk here, or do something else.

=head1 DESCRIPTION

This module grew out of the need to download a large archive of web mail in
bulk. As of the module's creation Yahoo did not provide a simple method of
performing bulk operations. 

This module is intended to make up for that shortcoming. 

=head2 METHODS

=over 4

=item $yahoo = new Mail::Webmail::Yahoo(...)

Creates a new Mail::Webmail::Yahoo object. Pass parameters in key => value form,
and these must include, at a minimum:

  username
  password

You may also pass an optional cookie file as cookie_file => '/path/to/file'.	


=item $yahoo->connect();

Connects the application with the site. Really this is not necessary, but it's
in here for hysterical raisins.



=item $yahoo->login();

Method which performs the 'login' stage of connecting to the site. This
method can take a while to complete since there are at least several
re-directs when logging in to Yahoo. 

Returns 0 if already logged in, 1 if successful, otherwise sets $@ and returns
undef.


=item @headers = $yahoo->get_mail_headers($folder);

***REMOVED***

=item @messages = $yahoo->get_mail_messages($folder);

Returns an array of message headers for the $folder folder. These are mostly
in Mail::Internet format, which is nice but involves constructing them from what
Yahoo provides -- which ain't much. When an individual message is requested,
we can get more info via turning on the headers, so this method requests each
method in turn (caching for future use, unless cache_messages is turned off)
and builds a Mail::Internet object from each message.

You can get the 'raw' headers from get_folder_index().

Note that for reasons of efficiency this method collects headers and the full
text of the message, and this is cached to avoid having to go back to the
network each time. To force a refresh, set the Snagmail object's cache to 0
with 

  $yahoo->cache_messages(0);
  $yahoo->cache_headers(0);

Note: There used to be a $callback parameter to this method, but since it was
never used it has been removed.


=item my $msg = $yahoo->_process_message($page, $yahoo_msg_id);

Extracts and returns as a Mail::Internet object the headers and message body
from the provided HTML ($page).


=item my $msg = $yahoo->_extract_headers($page, $yahoo_msg_id);

Performs the actual extraction of the message headers from the given HTML in
$page. Pushes the $yahoo_msg_id into the headers as 'X-Yahoo-MsgId'. Also adds
a version header.

=item my $ok = $yahoo->_extract_body($mhdr, $page);

Extracts and adds to the Mail::Internet object in $mhdr the message body,
including any attachments parsed out of $page. Returns 1 to indicate success,
although no error conditions are currently checked for/ handled.

=item $page = $yahoo->download_attachment($download_uri, $mailmsg);

Downloads an attachment from the specified URI. $mailmsg is a reference to a
Mail::Internet object. The downloaded attachment is added to the mailmsg via
add_attachment_to_message()

=item $yahoo->add_attachment_to_message($msg, $attachment, $filename);

Adds the $attachment to $msg, adjusting Content-Type and MIME-Version as
necessary.

=item $yahoo->make_multipart_boundary()

Currently does nothing useful. So far all messages have had correct types.


=item $yahoo->get_folder_action_link($mbox, $linktype, $force);

Returns and stores the 'action link' for the given $linktype. This is a URI
that will cause an action to be performed on a message set, such as DELETE or
MOVE.

=item @message_headers = $yahoo->get_folder_index($folder);

Returns a list of all the messages in the specified folder. These messages are
stored as URIs. Logs the user in if necessary.


=item @messages = $yahoo->_get_message_links($page)

(Private instance method)

Returns the actual links (as an array) needed to pull down the messages. This
method is used internally and is not intended to be used from applications,
since the messages returned are not in a very friendly form. This method
returns only the messages referenced on a given page, and is called from
get_folder_index() to build up a complete list of all messages in a folder.


=item @folders = $yahoo->get_folder_list();

Returns a list of folders in the account. Logs the user in if necessary. Also
stores the two special folders ('Trash' and 'Bulk') so they can be emptied
later.


=item $ok = $yahoo->send($to, $subject, $body, $cc, $bcc, $flags);

Attempts to send a message to the recipients listed in $to, $cc, and $bcc,
with the specified subject and body text. $to,$cc, and $bcc can be scalars or
arrayrefs containing lists of recipients.

Logs the user in if necessary.

$flags may contain any combination of the constants exported by this package.
Currently, these constants are:

  SAVE_COPY_TO_SENT_FOLDER  :    saves a copy of a sent message
  ATTACH_SIG                :    attaches the sender's Yahoo signature
  SEND_AS_HTML              :    sends the message in HTML format.

cc and bcc come after subject and body in the parameter list (instead of with
'to') since it is expected that
  
  send(to, subject, body)

will be more common than sending to Cc or BCc recipients - at least, this is
how it is in my experience.

As of this version, address-book lookups are not supported.

As of this version, mail attachments are not supported.


=item $resp = $yahoo->_get_a_page($uri, $method, $params);

(Private instance method)

Requests and returns a page found at the specified $uri via the specified
$method. If $params (an arrayref) is present it will be formatted according to
the method. 

If method is empty or undefined, it defaults to GET. The ordering of the
parameters, while seemingly counter-intuitive, allows one of the great virtues
of programming (laziness) by not requiring that the method be passed for every
call.

Returns the response object if no error occurs, undef on error.


=item $current_trace_level = $yahoo->trace($new_trace_level);

if $new_trace_level exists, sets the new level for tracing the operation of
the object. Returns the current trace level (i.e. before setting a new one).

Trace levels are:

   0   no tracing output; warning messages only.
 > 0   informative messages ("what I am doing")
 > 1   URIs being fetched
 > 2   request response codes
 > 3   request parameters
 > 4   any other 'extra' debugging info.
 > 9   request response content


=item $yahoo->debug(...);

Sends debugging messages to STDERR, appended with a newline.


=item $yahoo->make_host($uri)   or   Yahoo::make_host($uri)

Returns a string consisting of just the scheme, host, and port parts of the URI.
The URI::URL::as_string method returns the full URI (including path) but
leaves out the port number, which is why it's unsuitable here.

=back


=head2 EXPORTS

Nothing but a few constants. The module is intended to be object-based, and
functions should be called as such.

=head2 CAVEATS

There is an issue somewhere that prevents https redirects from succeeding.
Until this is fixed, the login procedure WILL expose the username and password
in plain text over the network. 


The user interface of Yahoo webmail is fairly configurable. It is possible the
module may not work out-of-the-box with some configurations. It should,
however, be possible to tweak the settings at the top of the file to allow
conformance to any configuration. 

=head1 AUTHOR

  Simon Drabble  E<lt>sdrabble@cpan.orgE<gt>


=head1 SEE ALSO


=cut
