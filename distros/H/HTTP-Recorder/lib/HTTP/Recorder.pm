package HTTP::Recorder;

our $VERSION = "0.07";

=head1 NAME

HTTP::Recorder - record interaction with websites

=head1 SYNOPSIS

=head2 This module is deprecated

It works by tagging links in a page, and then when a link is clicked
looking on the submitted tag to see which link was clicked

It can not handle Javascript-created links or JS manipulation of the page
so it works only for fairly static websites

For better options check out Selenium

Patchs are welcome, and I'll fix bugs as much as I can, but please don't 
expect me to implement new features

=head2 Using HTTP::Recorder as a Web Proxy

Set HTTP::Recorder as the user agent for a proxy, and it rewrites HTTP
responses so that additional requests can be recorded.

=head3 The Proxy Script

For quick start, run the httprecorder script

    httprecorder

This will open a local proxy on port 8080, and will dump the recorded traffic
to a file named http_traffic in the current directory. use the -help parameter
for usage info

Start the proxy script, then change the settings in your web browser
so that it will use this proxy for web requests.  For more information
about proxy settings and the default port, see L<HTTP::Proxy>.

The script will be recorded in the specified file, and can be viewed
and modified via the control panel.

For better control, use this example:

    #!/usr/bin/perl

    use HTTP::Proxy;
    use HTTP::Recorder;

    my $proxy = HTTP::Proxy->new();

    # create a new HTTP::Recorder object
    my $agent = new HTTP::Recorder;

    # set the log file (optional)
    $agent->file("/tmp/myfile");

    # set HTTP::Recorder as the agent for the proxy
    $proxy->agent( $agent );

    # start the proxy
    $proxy->start();

=head3 Start Recording

Now you can use your browser as your normally would, and your actions
will be recorded in the file you specified.  Alternatively, you can
start recording from the Control Panel.

=head3 Using the Control Panel

If you have Javascript enabled in your browser, go to the
L<HTTP::Recorder> control URL (http://http-recorder by default),
optionally type a URL into the "Goto page" field, and click "Go".

In the new window, interact with web sites as you normally do,
including typing a new address into the address field.  The Control
Panel will be updated after each recorded action.

The Control Panel allows you to modify, delete, or save your script.

=head2 SSL sessions

As of version 0.03, L<HTTP::Recorder> can record SSL sessions.

To begin recording an SSL session, go to the control URL
(http://http-recorder/ by default), and enter the initial URL.
Then, interact with the web site as usual.

=head2 Script output

By default, L<HTTP::Recorder> outputs L<WWW::Mechanize> scripts.

However, you can override HTTP::Recorder::Logger to output other types
of scripts.

=cut

use strict;
use warnings;
use LWP::UserAgent;
use HTML::TokeParser;
use HTTP::Recorder::Logger;
use URI::Escape qw(uri_escape uri_unescape);
use URI::QueryParam;
use HTTP::Request::Params;

our @ISA = qw( LWP::UserAgent );

=head1 Functions

=head2 new

Creates and returns a new L<HTTP::Recorder> object, referred to as the 'agent'.

=cut

sub new {
    my $class = shift;

    my %args = ( @_ );

    my $self = $class->SUPER::new( %args );
    bless $self, $class;

    $self->{prefix} = $args{prefix} || "rec";
    $self->{control} = $args{control} || "http-recorder";
    $self->{logger} = $args{logger} || 
	new HTTP::Recorder::Logger(file => $args{file});
    $self->{ignore_favicon} = $args{ignore_favicon} || 1;

    return $self;
}

=head2 $agent->prefix([$value])

Get or set the prefix string that L<HTTP::Recorder> uses for rewriting
responses.

=cut

sub prefix { shift->_elem('prefix',      @_); }

=head2 $agent->control([$value])

Get or set the URL of the control panel.  By default, the control URL
is 'http-recorder'.

The control URL will display a control panel which will allow you to
view and edit the current script.

=cut

sub control { shift->_elem('control',      @_); }

=head2 $agent->logger([$value])

Get or set the logger object.  The default logger is a
L<HTTP::Recorder::Logger>, which generates L<WWW::Mechanize> scripts.

=cut

sub logger { 
    my $self = shift;
    $self->_elem('logger',      @_);
}

=head2 $agent->ignore_favicon([0|1])

Get or set ignore_favicon flag that causes L<HTTP::Recorder> to skip
logging requests favicon.ico files.  The value is 1 by default.

=cut

sub ignore_favicon { shift->_elem('ignore_favicon',      @_); }

=head2 $agent->file([$value])

Get or set the filename for generated scripts.  The default is
'/tmp/scriptfile'.

=cut

sub file {
    my $self = shift;
    my $file = shift;

    $self->{logger}->file($file) if $file;
}

sub send_request {
    my $self = shift;
    my $request = shift;

    my $response;

    # special handling if the URL is the control URL
    if ($request->uri->host eq $self->{control}) {

	# get the arguments passed from the form
	my $arghash;
	$arghash = extract_values($request);

	# there may be an action we need to perform
	if (exists $arghash->{updatescript}) {
	    my $script = $arghash->{ScriptContent};
	    $self->{logger}->SetScript($script || '');
	} elsif (exists $arghash->{clearscript}) {
	    $self->{logger}->SetScript("");
	} 

	my ($h, $content);
	if (exists $arghash->{goto}) {
	    my $url = $arghash->{url};

	    if ($url) {
		my $r = new HTTP::Request("GET", $url);
		my $response = $self->send_request( $r );

		return $response;
	    } else {
		$h = HTTP::Headers->new(Content_Type => 'text/html');
		$content = $self->get_start_page();
	    }
	} elsif (exists $arghash->{savescript}) {
	    $h = HTTP::Headers->new(Content_Type => 'text/plain',
				    Content_Disposition => 'attachment; filename=recorder-script.pl');
	    my @script = $self->{logger}->GetScript();
	    $content = join('', @script);
	} else {
	    $h = HTTP::Headers->new(Content_Type => 'text/html');
	    $content = $self->get_recorder_content();
	}

	$response = HTTP::Response->new(200,
					"",
					$h,
					$content,
					);
    } else {
	$request = $self->modify_request ($request)
            unless $self->{ignore_favicon}
                && $request->uri->path =~ /favicon\.ico$/i;

	$response = $self->SUPER::send_request( $request );

	my $content_type = $response->headers->header('Content-type') || "";

	# don't try to modify the content unless it's text/<something>
	if ($content_type =~ m#^text/#i) {
	    $self->modify_response($response);
	}
    }

    return $response;
}

sub modify_request {
    my $self = shift;
    my $request = shift;

    my $values = extract_values($request);

    # log the actions
    my $action = $values->{"$self->{prefix}-action"};

    my $referer = $request->headers->referer;
    if (!$action) {
	if (!$referer) {
	    my $uri = $self->unmodify($request->uri);;

	    # log a blank line to give the code a little breathing room
	    $self->{logger}->LogLine();
	    $self->{logger}->GotoPage(url => $uri);
	}
    } elsif ($action eq "follow") {
	$self->{logger}->FollowLink(text => $values->{"$self->{prefix}-text"} || "",
			    index => $values->{"$self->{prefix}-index"} || "",
			    url => $values->{"$self->{prefix}-url"});
    } elsif ($action eq "submitform") {
	my %fields;
	my ($btn_name, $btn_value, $btn_number);
	foreach my $param (keys %$values) {
	    my %fieldhash;
	    my ($fieldtype, $fieldname);
	    if ($param =~ /^$self->{prefix}-form(\d+)-(\w+)-(.*)$/) {
		$fieldtype = $2;
		$fieldname = $3;

		if ($fieldtype eq 'submit') {
		    next unless $values->{$fieldname};
		    $btn_name = $fieldname;
		    $btn_value = $values->{$fieldname};
		} else {
		    next if ($fieldtype eq 'hidden');
		    next unless $fieldname && exists $values->{$fieldname};
		    $fieldhash{'name'} = $fieldname;
		    $fieldhash{'type'} = $fieldtype;
		    if (ref($values->{$fieldname}) eq 'ARRAY') {
			my @tempvalues = @{$values->{$fieldname}};
			for (my $i = 0 ; $i < scalar @tempvalues ; $i++) {
			    $fieldhash{'value'} = $tempvalues[$i];
			    my %temphash = %fieldhash;
			    $fields{"$fieldname-$i"} = \%temphash;
			}
		    } else {
			$fieldhash{'value'} = $values->{$fieldname};
			$fields{$fieldname} = \%fieldhash;
		    }
		}
	    }
	}

	$self->{logger}->SetFieldsAndSubmit(name => $values->{"$self->{prefix}-formname"}, 
					    number => $values->{"$self->{prefix}-formnumber"},
					    fields => \%fields,
					    button_name => $btn_name,
					    button_value => $btn_value);

	# log a blank line to give the code a little breathing room
	$self->{logger}->LogLine();
    }

    # undo what we've done
    $request->uri($self->unmodify($request->uri));
    $request->content($self->unmodify($request->content));

    # reset the Content-Length (if needed) to prevent warnings from
    # HTTP::Protocol
    if ($action && ($action eq "submitform")) {
	$request->headers->header('Content-Length' => length($request->content()) );
	
    }

    my $https = $values->{"$self->{prefix}-https"};
    if ( $https && $https == 1) {
	my $uri = $request->uri;
	$uri->scheme('https') if $uri->scheme eq 'http';

	$request = new HTTP::Request($request->method, 
				     $uri, 
				     $request->headers, 
				     $request->content);
	
    }	    

    return $request;
}

sub unmodify {
    my $self = shift;
    my $content = shift;

    return $content unless $content;

	# get rid of the arguments we added
    my $prefix = $self->{prefix};

	# workaround: the content can be a simple string
	if (not ref $content) {
		$content =~ s/(?:^|(?<=\&))\Q$prefix\E-[^=]+=[^\&]*(\&|$)//g;
		return $content;
	}

    for my $key ($content->query_param) {
	if ($key =~ /^$prefix-/) {
	    $content->query_param_delete($key);
	}
    }
    return $content;
}

sub extract_values {
    my $request = shift;

    my $parser = HTTP::Request::Params->new({
	req => $request,
    });

    # un-escape all params
    for my $key (keys %{$parser->params}) {
	$parser->params->{$key} = uri_unescape($parser->params->{$key});
    }

    return $parser->params;
}

sub modify_response {
    my $self = shift;
    my $response = shift;
    my $formcount = 0;
    my $formnumber = 0;
    my $linknumber = 1;

    $response->headers->push_header('Cache-Control', 'no-store, no-cache');
    $response->headers->push_header('Pragma', 'no-cache');

    my $content = $response->content();
    my $p = HTML::TokeParser->new(\$content);
    my $newcontent = "";
    my %links;
    my $formname;

    my $js_href = 0;
    my $in_head = 0;
    my $basehref;
    while (my $token = $p->get_token()) {
        if (@$token[0] eq 'S') {
            my $tagname = @$token[1];
            my $attrs = @$token[2];
            my $oldaction;
            my $text;

            if ($tagname eq 'head') {
                $in_head = 1;
            } elsif ($in_head && $tagname eq 'base') {
                $basehref = new URI($attrs->{'base'});
            } elsif (($tagname eq 'a' || $tagname eq 'link') && $attrs->{'href'}) {
                my $t = $p->get_token();
                if (@$t[0] eq 'T') {
                    $text = @$t[1];
                } else {
                    undef $text;
                }
                $p->unget_token($t);

                # up the counter for links with the same text
                my $index;
                if (defined $text) {
                    $links{$text} = 0 if !(exists $links{$text});
                    $links{$text}++;
                    $index = $links{$text};
                } else {
                    $index = $linknumber;
                }
                if ($attrs->{'href'} =~ m/^javascript:/i) {
                    $js_href = 1;
                } else {
                    if ($tagname eq 'a') {
                    $attrs->{'href'} = 
                        $self->rewrite_href($attrs->{'href'}, 
                                $text, 
                                $index,
                                $response->base);
                    } elsif ($tagname eq 'link') {
                    $attrs->{'href'} = 
                        $self->rewrite_linkhref($attrs->{'href'}, 
                                    $response->base);
                    }
                }
                $linknumber++;
            } elsif ($tagname eq 'form') {
                $formcount++;
                $formnumber++;
            }

            # put the hidden field before the real field
            # so that it won't be inside
            if (!$js_href && $tagname ne 'form' && ($formcount == 1)) {
                my ($formfield, $fieldprefix, $fieldtype, $fieldname);
                $fieldprefix = "$self->{prefix}-form" . $formnumber;
                $fieldtype = lc($attrs->{type} || 'unknown');
                if ($attrs->{name}) {
                    $fieldname = $attrs->{name};
                    $formfield = ($fieldprefix . '-' . 
                          $fieldtype . '-' . $fieldname);
                    $newcontent .= "<input type=\"hidden\" name=\"$formfield\" value=1>\n";
                }
            }

            $newcontent .= ("<".$tagname);

            # keep the attributes in their original order
            my $attrlist = @$token[3];
            foreach my $attr (@$attrlist) {
                # only rewrite if 
                # - it's not part of a javascript link
                # - it's not a hidden field
                $newcontent .= (" ".$attr."=\"".$attrs->{$attr}."\"");
            }
            $newcontent .= (">\n");
            if ($tagname eq 'head') {
                # add the javascript to update the script, right after the head opening tag
                $newcontent .= $self->script_update();
            }
            if ($tagname eq 'form') {
                if ($formcount == 1) {
                    $newcontent .= $self->rewrite_form_content($attrs->{name} || "", $formnumber, $response->base);
                }
            }
        } elsif (@$token[0] eq 'E') {
            my $tagname = @$token[1];
            if ($tagname eq 'head') {
                if (!$basehref) {
                    $basehref = $response->base;
                    $basehref->scheme('http') if $basehref->scheme eq 'https';
                    $newcontent .= "<base href=\"" . $basehref . "\">\n";
                }
                $basehref = "";
                $in_head = 0;
            }
            $newcontent .= ("</");
            $newcontent .= ($tagname.">\n");
            if ($tagname eq 'form') {
                $formcount--;
            } elsif ($tagname eq 'a' || $tagname eq 'link') {
                $js_href = 0;
            }
        } elsif (@$token[0] eq 'PI') {
            $newcontent .= (@$token[2]);
        } else {
            $newcontent .= (@$token[1]);
        }
    }

    $response->content($newcontent);

    return;
}

sub rewrite_href {
    my $self = shift;
    my $href = shift || "";
    my $text = shift || "";
    my $index = shift || 1;
    my $base = shift;

    my $newhref = new URI($href);
    my $prefix = $self->{prefix};

    if ($base->scheme eq 'https') {
	$newhref->query_param_append( "$prefix-https", 1);
	$newhref->scheme('http');
    }

    # the original URL
    $newhref->query_param_append( "$prefix-url", uri_escape($href));
    
    # the action (i.e. follow link)
    $newhref->query_param_append( "$prefix-action", 'follow');

    # the link information
    $text = uri_escape($text); # might have special characters
    $newhref->query_param_append( "$prefix-text", $text);
    $newhref->query_param_append( "$prefix-index", $index);

    return $newhref;
}

sub rewrite_linkhref {
    my $self = shift;
    my $href = shift || "";
    my $base = shift;

    my $newhref = new URI($href);
    my $prefix = $self->{prefix};

    $newhref->query_param_append( "$prefix-https", 1) 
				  if $base->scheme eq 'https';

    # the original URL
    $newhref->query_param_append( "$prefix-url", uri_escape($href));
    
    # the action (i.e. don't record)
    $newhref->query_param_append( "$prefix-action", 'norecord');

    return $newhref;
}

sub rewrite_form_content {
    my $self = shift;
    my $name = shift || "";
    my $number = shift;
    my $url = shift;
    my $fields;

    my $https = 1 if ($url->scheme eq 'https');

    $fields .= ("<input type=hidden name=\"$self->{prefix}-action\" value=\"submitform\">\n");
    $fields .= ("<input type=hidden name=\"$self->{prefix}-formname\" value=\"$name\">\n");
    $fields .= ("<input type=hidden name=\"$self->{prefix}-formnumber\" value=\"$number\">\n");
    if ($https) {
    $fields .= ("<input type=hidden name=\"$self->{prefix}-https\" value=\"$https\">\n");
    }

    return $fields;
}

sub get_start_page {
    my $self = shift;

    my $content = <<EOF;
<html>
<head>
<title>HTTP::Recorder Start Page</title>
<SCRIPT LANGUAGE="JavaScript">
<!-- // start
    self.focus(); // bring this window to the front
// end -->
</SCRIPT>
</head>
<body>
<h1>Start Recording</h1>
<p>Type a url into the browser's adddress field to begin recording.
</html>
EOF

    return $content;
}

sub get_recorder_content {
    my $self = shift;

    my @script = $self->{logger}->GetScript();
    my $script = "";
    foreach my $line (@script) {
	next unless $line;
	$line =~ s/\n//g;
	$script .= "$line\n";
    }

    my $content = <<EOF;
<SCRIPT LANGUAGE="JavaScript">
<!-- // start
function scrollScriptAreaToEnd() {
    scriptarea = document.forms['ScriptForm'].elements['ScriptContent'];
    scriptarea.scrollTop = scriptarea.scrollHeight;
    scriptarea.focus();
}
// end -->
</SCRIPT>

<html>
<head>
<title>HTTP::Recorder Control Panel</title>
<STYLE type="text/css">
   table {font-family:Helvetica,sans-serif; font-size:14px}
   input {font-family:Helvetica,sans-serif; font-size:12px}
 </STYLE>
</head>
<body bgcolor="lightgrey" 
      onLoad="javascript:scrollScriptAreaToEnd()"
>
<table width=100% height=98%>
<FORM name="GotoForm" method="POST" action="http://$self->{control}/" target="recording">
  <tr>
    <td>
      Goto page: <input name="url" size=30>
      <input type=submit name="goto" value="Go">
      <hr>
    </td>
  </tr>
</FORM>
  <tr>
    <td width="100%" height="100%">
      <table width="100%" height="100%">
        <FORM name="ScriptForm" method="POST" action="http://$self->{control}/">
        <tr>
	  <td>
Current Script:
          </td>
        </tr>
        <tr>
          <td height=100%>
<textarea style="font-size: 10pt;font-family:monospace;width:100%;height:100%" name="ScriptContent">$script</textarea>
          </td>
        </tr>
        <tr>
          <td align=center>
            <INPUT TYPE="SUBMIT" name="updatescript" VALUE="Apply">
            <INPUT TYPE="RESET">
            <INPUT TYPE="BUTTON" VALUE="Refresh" onClick="window.location='http://$self->{control}/'">
          </td>
        </tr>
        <tr>
          <td align=center>
             <INPUT TYPE="SUBMIT" name="clearscript" VALUE="Delete"
            onClick="if (!confirm('Do you really want to delete the script?')){ return false; }">
            <INPUT TYPE="SUBMIT" name="savescript" VALUE="Save As">
          </td>
        </tr>
      </FORM>
      </table>
    </td>
  </tr>
      </table>
</body></html>
EOF

    return $content;
}

sub script_update {
    my $self = shift;

    my $url = "http://" . $self->control . "/";
    my $js = <<EOF;
// find the top-level opener window
var opwindow = window.opener;
while (opwindow.opener) {
  opwindow = opwindow.opener;
}
// update it with HTTP::Recorder's control panel
if (opwindow) {
 opwindow.location = "http://http-recorder/";
}
EOF

return <<EOF;
<SCRIPT LANGUAGE="JavaScript">
<!-- // start
$js
// end -->
</SCRIPT>
EOF
}

=head1 Bugs, Missing Features, and other Oddities

=head2 Javascript

L<WWW::Mechanize> can't play back Javascript actions, and
L<HTTP::Recorder> doesn't record them.

=head2 Why are my images corrupted?

HTTP::Recorder only tries to rewrite responses that are of type
text/*, which it determines by reading the Content-Type header of the
HTTP::Response object.  However, if the received image gives the wrong
Content-Type header, it may be corrupted by the recorder.  While this
may not be pleasant to look at, it shouldn't have an effect on your
recording session.

=head1 See Also

See also L<LWP::UserAgent>, L<WWW::Mechanize>, L<HTTP::Proxy>.

=head1 Requests & Bugs

Please submit any feature requests, suggestions, bugs, or patches at
http://rt.cpan.org/, or email to bug-HTTP-Recorder@rt.cpan.org.

If you're submitting a bug of the type "X doesn't record correctly,"
be sure to include a (preferably short and simple) HTML page that
demonstrates the problem, and a clear explanation of a) what it does
that it shouldn't, and b) what it should do instead.

=head1 Author

Copyright 2003-2005 by Linda Julien <leira@cpan.org>

Maintained by Shmuel Fomberg <semuelf@cpan.org>

Released under the GNU Public License.

=cut

1;
