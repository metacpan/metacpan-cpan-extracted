package HTTP::DAV::Resource;

use strict;
use vars qw($VERSION);

$VERSION = '0.31';

use HTTP::DAV;
use HTTP::DAV::Utils;
use HTTP::DAV::Lock;
use HTTP::Date qw(str2time);
use HTTP::DAV::ResourceList;
use Scalar::Util ();
use URI::Escape;

###########################################################################

# Construct a new object and initialize it
sub new {
    my $class = shift;
    my $self = bless {}, ref($class) || $class;
    $self->_init(@_);
    return $self;
}

sub _init {
    my ($self, @p) = @_;

    ####
    # This is the order of the arguments unless used as
    # named parameters
    my ($uri, $lockedresourcelist, $comms, $client)
        = HTTP::DAV::Utils::rearrange(
        [ 'URI', 'LOCKEDRESOURCELIST', 'COMMS', 'CLIENT' ], @p);

    # Optionally add a scheme.
    $uri =~ s/^\s*(.*?)\s*$/$1/g;    # Remove leading and trailing slashes
    $uri = "http://$uri" if ($uri ne "" && $uri !~ /^https?:\/\//);

    $self->{"_uri"}                = $uri                || "";
    $self->{"_lockedresourcelist"} = $lockedresourcelist || "";
    $self->{"_comms"}              = $comms              || "";
    $self->{"_dav_client"}         = $client             || "";

    # Avoid circular references between
    # - HTTP::DAV -> {_workingresource} and
    # - HTTP::DAV::Resource -> {_dav_client}
    Scalar::Util::weaken($self->{"_dav_client"});

    ####
    # Set the _uri
    $self->{_uri} = HTTP::DAV::Utils::make_uri($self->{_uri});
    die "HTTP URL required when creating a Resource object\n"
        if (!$self->{_uri}->scheme);

    ####
    # Check that the required objects exist

    die("Comms object required when creating a Resource object")
        unless (defined $self->{_comms}
        && $self->{_comms} =~ /HTTP::DAV::Comms/);

    die("Locked ResourceList object required when creating a Resource object")
        unless (defined $self->{_lockedresourcelist}
        && $self->{_lockedresourcelist} =~ /HTTP::DAV::ResourceList/);

    die("DAV Client required when creating a Resource object")
        unless (defined $self->{_dav_client}
        && $self->{_dav_client} =~ /HTTP::DAV/);
}

###########################################################################

# GET/SET
#sub set_lockpolicy { cluck("Can't reset the lockpolicy on a Resource"); 0; }

sub set_parent_resourcelist {
    my ($self, $resource_list) = @_;

    # Avoid circular references between the
    # parent resource list and this child resource
    Scalar::Util::weaken($self->{_parent_resourcelist} = $resource_list);
}

sub set_property { $_[0]->{_properties}{ $_[1] } = $_[2]; }

sub set_uri { $_[0]->{_uri} = HTTP::DAV::Utils::make_uri($_[1]); }

# PRIVATE SUBROUTINES
sub _set_content    { $_[0]->{_content}    = $_[1]; }
sub _set_options    { $_[0]->{_options}    = $_[1]; }
sub _set_compliance { $_[0]->{_compliance} = $_[1]; }

sub set_locks {
    my ($self, @locks) = @_;

    # Unset any existing locks because we're about to reset them
    # But keep their name temporarily because some of them
    # may be ours.
    my @old_lock_tokens = keys %{ $self->{_locks} } || ();

    #if (@locks && defined $self->{_locks}) {
    if (defined $self->{_locks}) {
        delete $self->{_locks};
    }

    foreach my $lock (@locks) {
        my $token = $lock->get_locktoken();

        #print "Adding $token\n";

        # If it exists, we'll set it to owned and reapply
        # it (it may have changed since we saw it last.
        # Like it might have timed out?
        if (grep($token, @old_lock_tokens)) {
            $lock->set_owned(1);
        }
        $self->{_locks}{$token} = $lock;
    }

    #print "Locks: " . join(' ',keys %{$self->{_locks}} )."\n";
}

sub is_option {
    my ($self, $option) = @_;
    $self->options if (!defined $self->{_options});
    return ($self->{_options} =~ /\b$option\b/i) ? 1 : 0;
}

sub is_dav_compliant {
    my $resp = $_[0]->options if (!defined $_[0]->{_options});
    $_[0]->{_compliance};
}

sub get_options { $_[0]->{_options}; }

sub get_content     { $_[0]->{_content}; }
sub get_content_ref { \$_[0]->{_content}; }

sub get_username {
    my ($self) = @_;
    my $ra = $self->{_comms}->get_user_agent();
    my @userpass = $ra->get_basic_credentials(undef, $self->get_uri());
    return $userpass[0];
}

#sub get_lockpolicy { $_[0]->{_lockpolicy}; }
sub get_client              { $_[0]->{_dav_client}; }
sub get_resourcelist        { $_[0]->{_resource_list}; }
sub get_lockedresourcelist  { $_[0]->{_lockedresourcelist}; }
sub get_comms               { $_[0]->{_comms}; }
sub get_property            { $_[0]->{_properties}{ $_[1] } || ""; }
sub get_uri                 { $_[0]->{_uri}; }
sub get_uristring           { $_[0]->{_uri}->as_string; }
sub get_parent_resourcelist { $_[0]->{_parent_resourcelist}; }

# $self->get_locks( -owned => [0|1] );
#  '1'  = return any locks owned be me
#  '0'   = return any locks NOT owned be me
#  no value = return all locks
#
sub get_locks {
    my ($self, @p) = @_;
    my ($owned) = HTTP::DAV::Utils::rearrange(['OWNED'], @p);
    $owned = "" unless defined $owned;

    #print "owned=$owned,\@p=\"@p\"\n";

    my @return_locks = ();

    foreach my $token (sort keys %{ $self->{_locks} }) {
        my $lock = $self->{_locks}{$token};
        if ($owned eq "1" && $lock->is_owned) {
            push(@return_locks, $lock);
        }
        elsif ($owned eq "0" && !$lock->is_owned) {
            push(@return_locks, $lock);
        }
        elsif ($owned eq "") {
            push(@return_locks, $lock);
        }
    }

    return @return_locks;
}

sub get_lock {
    my ($self, $token) = @_;
    return $self->{_locks}{$token} if ($token);
}

# Just pass through to get_locks all of our parameters.
# Then count how many we get back. >1 lock returns 1.
sub is_locked {
    my ($self, @p) = @_;
    return scalar $self->get_locks(@p);
}

sub is_collection {
    my $type = $_[0]->get_property("resourcetype");
    return (defined $type && $type =~ /collection/) ? 1 : 0;
}

sub _unset_properties { $_[0]->{_properties} = (); }
sub _unset_lock { delete $_[0]->{_locks}{ $_[1] } if $_[1]; }
sub _unset_locks { $_[0]->{_locks} = (); }

sub _unset_my_locks {
    my ($self) = @_;
    my @locks = $self->get_locks(-owned => 1);
    foreach my $lock (@locks) {
        $self->_unset_lock($lock->get_locktoken);
    }
    $self->get_lockedresourcelist->remove_resource($self);
}

###########################################################################
sub lock {
    my ($self, @p) = @_;

    my $lock = HTTP::DAV::Lock->new(-owned => 1);

    #my $existing_lock = $self->get_lockedresourcelist->get_member($self->uri);

    my ($owner, $depth, $timeout, $scope, $type, @other)
        = HTTP::DAV::Utils::rearrange(
        [ 'OWNER', 'DEPTH', 'TIMEOUT', 'SCOPE', 'TYPE' ], @p);

    ####
    # Set the defaults

    # 'owner' default is DAV.pm/v0.1 (ProcessId)
    $owner ||= "DAV.pm/v$HTTP::DAV::VERSION ($$)";

    # Sanity check. If it ain't 0, then make it infinity.
    $depth = (defined $depth && $depth eq "0") ? 0 : "infinity";

    # 'scope' default is exclusive
    $scope ||= "exclusive";

    # 'type' default is write
    $type ||= "write";

    ####
    # Setup the headers for the lock request
    my $headers = HTTP::DAV::Headers->new;
    $headers->header("Content-type", "text/xml; charset=\"utf-8\"");
    $headers->header("Depth",        $depth);
    my $timeoutval = $lock->timeout($timeout);
    $headers->header("Timeout", $timeoutval) if ($timeoutval);

    # Add any If headers required
    #$self->_setup_if_headers($headers);

    ####
    # Setup the XML content for the lock request
    my $xml_request = HTTP::DAV::Lock->make_lock_xml(
        -owner   => $owner,
        -timeout => $timeout,
        -scope   => $scope,
        -type    => $type,
    );

    #print "$xml_request\n";

    ####
    # Put the lock request to the remote server
    my $resp = $self->{_comms}->do_http_request(
        -method  => "LOCK",
        -url     => $self->{_uri},
        -headers => $headers,
        -content => $xml_request,
    );

    ###
    # Handle the lock response

    # Normal spec scenario
    if ($self->content_type_is_xml($resp)) {

        # use XML::DOM to parse the result.
        my $parser = new XML::DOM::Parser;
        my $doc    = $parser->parse($resp->content);

        ###
        # Multistatus response. Generally indicates a failure
        if ($resp->code == 207) {

            # We're only interested in the error codes that come
            # out of the multistatus $resp.
            eval { $self->_XML_parse_multistatus($doc, $resp) };
            print "XML error: " . $@ if $@;
        }

        ###
        # Lock succeeded
        # 1. I assume from RFC2518 that if it successsfully locks
        # then we will only get back the lockdiscover element
        # for MY lock. If not, I will warn the user.
        #
        # 2. I am fairly sure that my client should only ever be able to
        # take out one lock on a resource. As such this program assumes
        # that a resource can only have one lock held against it (locks
        # owned by other people do not get stored here).
        #
        elsif ($resp->is_success) {
            my $node_prop
                = HTTP::DAV::Utils::get_only_element($doc, "D:prop");
            my $lock_discovery
                = HTTP::DAV::Utils::get_only_element($node_prop,
                "D:lockdiscovery");
            my @locks
                = HTTP::DAV::Lock->XML_lockdiscovery_parse($lock_discovery);

            # Degenerate case for bad server mydocsonline.
            # Doesn't return a proper lockdiscovery.
            # Just use the Lock-Token in the header instead.
            if (!@locks && $resp->header('Lock-Token')) {
                print
                    "Using degenerate case of getting Lock-Token from Header.\n"
                    if $HTTP::DAV::DEBUG > 2;
                $locks[0] = HTTP::DAV::Lock->new(-owned => 1);
                $locks[0]->set_locktoken($resp->header('Lock-Token'));
            }

            if ($#locks > 0) {
                warn(
                    "Serious protocol error, expected 1 lock back from request "
                        . "but got more than one. Don't know which one is mine"
                );
            }
            else {
                $self->set_locks(@locks);
                foreach my $lock (@locks) { $lock->set_owned(1); }
                $self->{_lockedresourcelist}->add_resource($self);

                #print $self->{_lockedresourcelist}->as_string;
            }
        }

        # Discard of XML doc safely.
        $doc->dispose;
    }

    return $resp;
}

###########################################################################
sub unlock {
    my ($self, @p) = @_;
    my ($opaquelocktoken) = HTTP::DAV::Utils::rearrange(['TOKEN'], @p);
    my $resp;

    my $uri = $self->get_uri();

    # If you passed no lock token then I'll try
    # and unlock with any tokens I own.
    if (!$opaquelocktoken) {
        my @locks = $self->get_locks(-owned => 1);
        my $num_locks = $#locks + 1;
        if ($num_locks == 0) {

            # Just use a dummy token. They're unique anyway.
            #$opaquelocktoken = "opaquelocktoken:dummytoken-82d32fa22932";
            $opaquelocktoken = "";
        }
        if ($num_locks == 1) {
            $opaquelocktoken = $locks[0]->get_locktoken;
        }
        else {
            foreach my $lock (@locks) {
                $resp = $self->unlock(-token => $lock->get_locktoken);
                return $resp if $resp->is_error();
            }
        }
    }

    my $headers = HTTP::DAV::Headers->new;

    #$headers->header("Lock-Token", "<${opaquelocktoken}>") if $opaquelocktoken;
    $headers->header("Lock-Token", "<${opaquelocktoken}>");

    if ($opaquelocktoken) {
        warn "UNLOCKING with '$opaquelocktoken'\n" if $HTTP::DAV::DEBUG > 2;

        # Put the unlock request to the remote server
        $resp = $self->{_comms}->do_http_request(
            -method  => "UNLOCK",
            -url     => $self->get_uri,
            -headers => $headers,

            #-content => no content required
        );
    }
    else {

        #print "START\n";
        $resp = HTTP::Response->new(500, "Client error. No lock held.");
        $resp = HTTP::DAV::Response->clone_http_resp($resp);

        #print $resp->as_string();
        #print "END\n";
    }

    if ($resp->is_success) {
        $self->_unset_lock($opaquelocktoken);
    }

    return $resp;
}

###########################################################################
sub forcefully_unlock_all {
    my ($self) = @_;
    my $resp;

    my $discovery_resp = $self->lockdiscovery;
    if ($discovery_resp->is_success) {
        my @locks = $self->get_locks();
        foreach my $lock (@locks) {
            my $token = $lock->get_locktoken;
            $resp = $self->unlock(-token => $token) if $token;
            return $resp if $resp->is_error;
        }
    }

    # In the event that there were no locks to steal,
    # then just send a dud request out and let the
    # server fail it.
    if (!$resp) {
        $resp = $self->unlock();
    }

    return $resp;
}
###########################################################################
sub steal_lock {
    my ($self) = @_;

    $self->forcefully_unlock_all;
    return $self->lock;
}

###########################################################################
sub lockdiscovery {
    my ($self, @p) = @_;
    my ($depth, @other) = HTTP::DAV::Utils::rearrange(['DEPTH'], @p);

    return $self->propfind(
        -depth => $depth,
        -text  => "<D:prop><D:lockdiscovery/></D:prop>"
    );
}

###########################################################################
sub propfind {
    my ($self, @p) = @_;

    my ($depth, $text, @other)
        = HTTP::DAV::Utils::rearrange([ 'DEPTH', 'TEXT' ], @p);

    # 'depth' default is 1
    $depth = 1 unless (defined $depth && $depth ne "");

    ####
    # Setup the headers for the request
    my $headers = new HTTP::Headers;
    $headers->header("Content-type", "text/xml; charset=\"utf-8\"");
    $headers->header("Depth",        $depth);

    # Create a new XML document
    #   <D:propfind xmlns:D="DAV:">
    #       <D:allprop/>
    #   </D:propfind>
    my $xml_request = qq{<?xml version="1.0" encoding="utf-8"?>};
    $xml_request .= '<D:propfind xmlns:D="DAV:">';
    $xml_request .= $text || "<D:allprop/>";
    $xml_request .= "</D:propfind>";

    ####
    # Put the propfind request to the remote server
    my $resp = $self->{_comms}->do_http_request(
        -method  => "PROPFIND",
        -url     => $self->{_uri},
        -headers => $headers,
        -content => $xml_request,
    );

    # Reset the resource list, in case of intermediate errors,
    # to keep object state consistent
    $self->{_resource_list} = undef;

    if (! $self->content_type_is_xml($resp)) {
        $resp->add_status_line(
            "HTTP/1.1 422 Unprocessable Entity, no XML body.",
            "", $self->{_uri}, $self->{_uri}
        );
        return $resp;
    }

    # use XML::DOM to parse the result.
    my $parser = XML::DOM::Parser->new();
    my $xml_resp = $resp->content;
    my $doc;

    if (! $xml_resp) {
        $resp->add_status_line(
            "HTTP/1.1 422 Unprocessable Entity, no XML body.",
            "", $self->{_uri}, $self->{_uri}
        );
        return $resp;
    }

    eval {
        $doc = $parser->parse($xml_resp);
    } or do {
        warn "Unparsable XML received from server (" . length($xml_resp) . " bytes)\n";
        warn "ERROR: $@\n";
        return $resp;
    };

    # Setup a ResourceList in which to pump all of the collection
    my $resource_list;
    eval {
        $resource_list = $self->_XML_parse_multistatus($doc, $resp)
    } or do {
        warn "Error parsing PROPFIND response XML: $@\n";
    };

    if ($resource_list && $resource_list->count_resources()) {
        $self->{_resource_list} = $resource_list;
    }

    $doc->dispose;

    return $resp;
}

###########################################################################
# get/GET the body contents
sub get {
    my ($self, @p) = @_;

    my ($save_to, $progress_callback, $chunk)
        = HTTP::DAV::Utils::rearrange(
        [ 'SAVE_TO', 'PROGRESS_CALLBACK', 'CHUNK' ], @p);

    #$save_to = URI::Escape::uri_unescape($save_to);
    my $resp = $self->{_comms}->do_http_request(
        -method   => "GET",
        -uri      => $self->get_uri,
        -save_to  => $save_to,
        -callback => $progress_callback,
        -chunk    => $chunk
    );

    # What to do with all of the headers in the response. Put
    # them into this object? If so, which ones?
    if ($resp->is_success) {
        $self->_set_content($resp->content);
    }

    return $resp;
}
sub GET { shift->get(@_); }

###########################################################################
# put/PUT the body contents

sub put {
    my ($self, $content, $custom_headers) = @_;
    my $resp;

    # Setup the If: header if it is locked
    my $headers = HTTP::DAV::Headers->new();

    $self->_setup_if_headers($headers);
    $self->_setup_custom_headers($custom_headers);

    if (!defined $content) {
        $content = $self->get_content();

        # if ( ! $content ) {
        #    #$resp = HTTP::DAV::Response->new;
        #    #$resp->code("400"); ??
        #    return $resp;
        # }
    }

    $resp = $self->{_comms}->do_http_request(
        -method  => "PUT",
        -uri     => $self->get_uri,
        -headers => $headers,
        -content => $content,
    );

    #my $unlockresp = $self->unlock;

    # What to do with all of the headers in the response. Put
    # them into this object? If so, which ones?
    # $self->_set_content( $resp->content );

    return $resp;
}
sub PUT { my $self = shift; $self->put(@_); }

###########################################################################
# Make a collection
sub mkcol {
    my ($self) = @_;

    # Setup the If: header if it is locked
    my $headers = HTTP::DAV::Headers->new();
    $self->_setup_if_headers($headers);

    my $resp = $self->{_comms}->do_http_request(
        -method  => "MKCOL",
        -uri     => $self->get_uri,
        -headers => $headers,
    );

    # Handle a multistatus response
    if ($self->content_type_is_xml($resp) &&    # XML body
        $resp->is_multistatus()                 # Multistatus
        )
    {

        # use XML::DOM to parse the result.
        my $parser = new XML::DOM::Parser;
        my $doc    = $parser->parse($resp->content);

        # We're only interested in the error codes that come out of $resp.
        eval { $self->_XML_parse_multistatus($doc, $resp) };
        warn "XML error: " . $@ if $@;
        $doc->dispose;
    }

    return $resp;
}

###########################################################################
# Get OPTIONS available on a resource/collection
sub options {
    my ($self, $entire_server) = @_;

    my $uri = $self->get_uri;

    # Doesn't work properly. Sets it as /*
    # How do we get LWP to send through just
    # OPTIONS * HTTP/1.1
    # ??
    #$uri->path("*") if $entire_server;

    my $resp = $self->{_comms}->do_http_request(
        -method => "OPTIONS",
        -uri    => $uri,
    );

    if ($resp->header("Allow")) {

        #print "Allow: ". $resp->header("Allow") . "\n";
        $self->_set_options($resp->header("Allow"));
    }

    # Get the "DAV" header and look for
    # either "DAV:1" or "DAV:1,2"
    my $compliance = 0;
    if ($resp->header("DAV")) {

        $compliance = $resp->header("DAV");
        if ($compliance =~ /^\s*1\s*,\s*2/) {
            $compliance = 2;
        }

        elsif ($compliance =~ /^\s*1/) {
            $compliance = 1;
        }

    }
    $self->_set_compliance($compliance);

    return $resp;
}

sub OPTIONS { my $self = shift; $self->options(@_); }

###########################################################################
# Move or copy a resource/collection
sub move { return shift->_move_copy("MOVE", @_); }
sub copy { return shift->_move_copy("COPY", @_); }

sub _move_copy {
    my ($self, $method, @p) = @_;
    my ($dest_resource, $overwrite, $depth, $text, @other)
        = HTTP::DAV::Utils::rearrange(
        [ 'DEST', 'OVERWRITE', 'DEPTH', 'TEXT' ], @p);

    # Sanity check. If depth ain't 0, then make it infinity.
    # Only infinity allowed for move.
    # 0 or infinity allowed for copy.
    if ($method eq "MOVE") {
        $depth = "infinity";
    }
    else {
        $depth = (defined $depth && $depth eq "0") ? 0 : "infinity";
    }

    # Sanity check. If overwrite ain't F or 0, then make it T
    $overwrite = "F" if (defined $overwrite && $overwrite eq "0");
    $overwrite = (defined $overwrite && $overwrite eq "F") ? "F" : "T";

    ####
    # Setup the headers for the lock request
    my $headers = new HTTP::Headers;
    $headers->header("Depth",     $depth);
    $headers->header("Overwrite", $overwrite);

    # Destination Resource must have a URL
    my $dest_url = $dest_resource->get_uri;
    my $server_type
        = $self->{_comms}->get_server_type($dest_url->host_port());
    my $dest_str = $dest_url->as_string;

    # Apache, Bad Gateway workaround
    if ($server_type =~ /Apache/i && $server_type =~ /DAV\//i) {

        #my $dest_str = "http://" . $dest_url->host_port . $dest_url->path;
        $dest_str
            = $dest_url->scheme . "://"
            . $dest_url->host_port
            . $dest_url->path;

        if ($HTTP::DAV::DEBUG) {
            warn
                "*** INSTIGATING mod_dav WORKAROUND FOR DESTINATION HEADER BUG IN Resource::_move_copy\n";
            warn "*** Server type of "
                . $dest_url->host_port()
                . ": $server_type\n";
            warn "*** Adding port number :"
                . $dest_url->port
                . " to given url: $dest_url\n";
        }

    }

    # Apache2 mod_dav, Permenantly Moved workaround
    # If the src is a collection, then the dest must have a trailing
    # slash or mod_dav2 gives a strange "bad url" error in a
    # "Moved Permenantly" response.
    if ($self->is_collection || $self->get_uri =~ /\/$/) {
        $dest_str =~ s#/*$#/#;
    }

    $headers->header("Destination", $dest_str);

    # Join both the If headers together.
    $self->_setup_if_headers($headers, 1);
    my $if1 = $headers->header('If');
    $if1 ||= "";
    warn "COPY/MOVE If header for source: $if1\n" if $HTTP::DAV::DEBUG > 2;
    $dest_resource->_setup_if_headers($headers, 1);
    my $if2 = $headers->header('If');
    $if2 ||= "";
    warn "COPY/MOVE If header for dest  : $if2\n" if $HTTP::DAV::DEBUG > 2;
    $if1 = "$if1 $if2" if ($if1 || $if2);
    $headers->header('If', $if1) if $if1;

    # See from RFC 12.12.
    # Valid values for '$text':
    #
    #    <D:keepalive>*</D:keepalive>
    # or
    #    <D:keepalive>
    #       <D:href>...url1...</D:href>
    #       <D:href>...url2...</D:href>
    #    </D:keepalive>
    # or
    #    <D:omit/>
    #
    my $xml_request;
    if ($text) {
        $headers->header("Content-type", "text/xml; charset=\"utf-8\"");
        $xml_request = qq{<?xml version="1.0" encoding="utf-8"?>};
        $xml_request .= '<D:propertybehavior xmlns:D="DAV:">';
        $xml_request .= $text;
        $xml_request .= "</D:propertybehavior>";
    }

    ####
    # Put the copy request to the remote server
    my $resp = $self->{_comms}->do_http_request(
        -method  => $method,
        -url     => $self->{_uri},
        -headers => $headers,
        -content => $xml_request,
    );

    if ($resp->is_multistatus()) {
        my $parser = new XML::DOM::Parser;
        my $doc    = $parser->parse($resp->content);
        eval { $self->_XML_parse_multistatus($doc, $resp) };
        warn "XML error: " . $@ if $@;
        $doc->dispose;
    }

    # MOVE EATS SOURCE LOCKS
    if ($method eq "MOVE") {
        $self->_unset_my_locks();

        # Well... I'm baffled.
        # I previousy had this commented out because my
        # undestanding was that the dest lock stayed in tact.
        # But mod_dav seems to remove it after a move. So,
        # I'm going to fall in line, but if another server
        # implements this differently, then I'm going to have
        # to pipe up and get them to sort out their differences :)
        #$dest_resource->_unset_my_locks();
    }

    return $resp;
}

###########################################################################
# proppatch a resource/collection
sub proppatch {
    my ($self, @p) = @_;

    my ($namespace, $propname, $propvalue, $action, $use_nsabbr)
        = HTTP::DAV::Utils::rearrange(
        [ 'NAMESPACE', 'PROPNAME', 'PROPVALUE', 'ACTION', 'NSABBR' ], @p);

    $use_nsabbr ||= 'R';

    # Sanity check. If action ain't 'remove' then set it to 'set';
    $action = (defined $action && $action eq "remove") ? "remove" : "set";

    ####
    # Setup the headers for the lock request
    my $headers = new HTTP::Headers;
    $headers->header("Content-type", "text/xml; charset=\"utf-8\"");
    $self->_setup_if_headers($headers);

    my $xml_request = qq{<?xml version="1.0" encoding="utf-8"?>};

    #   $xml_request .= "<D:propertyupdate xmlns:D=\"DAV:\">";
    #   $xml_request .= "<D:$action>";

    $xml_request .= "<D:propertyupdate xmlns:D=\"DAV:\"";
    $namespace ||= "";
    my $nsabbr = 'D';

    if ($namespace =~ /dav/i || $namespace eq "") {

        #     $xml_request .= "<D:prop>";
        #     if ($action eq "set" ) {
        #        $xml_request .= "<D:$propname>$propvalue</D:$propname>";
        #     } else {
        #        $xml_request .= "<D:$propname/>";
        #     }
        $xml_request .= ">";
    }
    else {
        $nsabbr = $use_nsabbr;
        $xml_request .= " xmlns:$nsabbr=\"$namespace\">";
    }

    #   else {
    #     $xml_request .= "<D:prop xmlns:R=\"".$namespace."\">";
    #     if ($action eq "set" ) {
    #        $xml_request .= "<R:$propname>$propvalue</R:$propname>";
    #     } else {
    #        $xml_request .= "<R:$propname/>";
    #     }
    $xml_request .= "<D:$action>";
    $xml_request .= "<D:prop>";

    if ($action eq "set") {
        $xml_request .= "<$nsabbr:$propname>$propvalue</$nsabbr:$propname>";
    }
    else {
        $xml_request .= "<$nsabbr:$propname/>";
    }

    $xml_request .= "</D:prop>";
    $xml_request .= "</D:$action>";
    $xml_request .= "</D:propertyupdate>";

    ####
    # Put the proppatch request to the remote server
    my $resp = $self->{_comms}->do_http_request(
        -method  => "PROPPATCH",
        -url     => $self->{_uri},
        -headers => $headers,
        -content => $xml_request,
    );

    if ($resp->is_multistatus) {
        my $parser = new XML::DOM::Parser;
        my $doc    = $parser->parse($resp->content);
        eval { $self->_XML_parse_multistatus($doc, $resp) };
        warn "XML error: " . $@ if $@;
        $doc->dispose;
    }

    return $resp;
}

###########################################################################
# Delete a resource/collection
sub delete {
    my ($self) = @_;

    # Setup the If: header if it is locked
    my $headers = HTTP::DAV::Headers->new();
    $self->_setup_if_headers($headers);

    # Setup the Depth for the delete request
    # The only valid depth is infinity.
    #$headers->header("Depth", "infinity");

    my $resp = $self->{_comms}->do_http_request(
        -method  => "DELETE",
        -uri     => $self->get_uri,
        -headers => $headers,
    );

    # Handle a multistatus response
    if ($self->content_type_is_xml($resp) &&    # XML body
        $resp->is_multistatus()                 # Multistatus
    ) {

        # use XML::DOM to parse the result.
        my $parser = new XML::DOM::Parser;
        my $doc    = $parser->parse($resp->content);

        # We're only interested in the error codes that come out of $resp.
        eval { $self->_XML_parse_multistatus($doc, $resp) };
        warn "XML error: " . $@ if $@;
        $doc->dispose;
    }

    if ($resp->is_success) {
        $self->_unset_my_locks();
    }

    return $resp;
}

sub content_type_is_xml {
    my ($self, $resp) = @_;

    return unless $resp;

    my $type = $resp->content_type;
    return unless $type;

    if ($type =~ m{(?:application|text)/xml}) {
        return 1;
    }

    return;
}

###########################################################################
###########################################################################
# parses a <D:multistatus> element.
# This is the root level element for a
# PROPFIND body or a failed DELETE body.
# For example. The following is the result of a DELETE operation
# with a locked progeny (child).
#
# >> DELETE /test/dir/newdir/ HTTP/1.1
# << HTTP/1.1 207 Multistatus
# <?xml version="1.0" encoding="utf-8"?>
# <D:multistatus xmlns:D="DAV:">
#   <D:response>
#      <D:href>/test/dir/newdir/locker/</D:href>
#      <D:status>HTTP/1.1 423 Locked</D:status>
#      <D:responsedescription>Twas locked baby</D:responsedescription>
#   </D:response>
#   <D:response>
#      <D:href>/test/dir/newdir/</D:href>
#      <D:propstat>
#         <D:prop><D:lockdiscovery/></D:prop>
#         <D:status>HTTP/1.1 424 Failed Dependency</D:status>
#         <D:responsedescription>Locks here somewhere</D:status>
#      </D:propstat>
#      <D:responsedescription>Can't delete him. Lock here</D:responsedescription>
#   </D:response>
#   <D:responsedescription>Failed delete</D:responsedescription>
# </D:multistatus>
#
sub _XML_parse_multistatus {
    my ($self, $doc, $resp) = @_;
    my $resource_list = HTTP::DAV::ResourceList->new;

    # <!ELEMENT multistatus (response+, responsedescription?) >
    # Parse     I            II         III

    ###
    # Parse I
    my $node_multistatus
        = HTTP::DAV::Utils::get_only_element($doc, "D:multistatus");

    ###
    # Parse III
    # Get the overarching responsedescription for the
    # multistatus and set it into the DAV:Response object.
    my $node_rd = HTTP::DAV::Utils::get_only_element($node_multistatus,
        "D:responsedescription");
    if ($node_rd) {
        my $rd = $node_rd->getFirstChild->getNodeValue();
        $resp->set_responsedescription($rd) if $rd;
    }

    ###
    # Parse II
    # Get all the responses in the multistatus element
    # <!ELEMENT multistatus (response+,responsedescription?) >
    my @nodes_response
        = HTTP::DAV::Utils::get_elements_by_tag_name($node_multistatus,
        "D:response");

    # Process each response object
    #<!ELEMENT  response (href, ((href*, status)|(propstat+)), responsedescription?) >
    # Parse     1         2       2a     3        4            5

    ###
    # Parse 1.
    for my $node_response (@nodes_response) {

        ###
        # Parse 2 and 2a (one or more hrefs)
        my @nodes_href
            = HTTP::DAV::Utils::get_elements_by_tag_name($node_response,
            "D:href");

        # Get href <!ELEMENT href (#PCDATA) >
        my ($href, $href_a, $resource);
        foreach my $node_href (@nodes_href) {

            $href = $node_href->getFirstChild->getNodeValue();

            # The href may be relative. If so make it absolute.
            # With the uri data "/mydir/myfile.txt"
            # And the uri of "this" object, "http://site/dir",
            # return "http://site/mydir/myfile.txt"
            # See the rules of URI.pm
            my $href_uri = HTTP::DAV::Utils::make_uri($href);
            my $res_url  = $href_uri->abs($self->get_uri);

            # Just store the first one for later use
            $href_a = $res_url unless defined $href_a;

            # Create a new Resource to put into the list
            # Remove trailing slashes before comparing.
            #warn "Am about to compare $res_url and ". $self->get_uri . "\n" ;
            if (HTTP::DAV::Utils::compare_uris($res_url, $self->get_uri)) {
                $resource = $self;

                #warn " Exists. $resource\n";
            }
            else {
                $resource = $self->get_client->new_resource(-uri => $res_url);
                $resource_list->add_resource($resource);

                #warn " New. $resource\n";
            }
        }

        ###
        # Parse 3 and 5
        # Get the values out of each Response
        # <!ELEMENT status (#PCDATA) >
        # <!ELEMENT responsedescription (#PCDATA) >

        my ($response_status, $response_rd)
            = $self->_XML_parse_status($node_response);

        if ($response_status) {
            $resp->add_status_line(
                $response_status,
                $response_rd,
                "$href_a:response:$node_response",
                $href_a
            );
        }

        ###
        # Parse 4.
        # Get the propstat+ list to be processed below
        # Process each propstat object within this response
        #
        # <!ELEMENT propstat (prop, status, responsedescription?) >
        # Parse     a         b     c       d

        ###
        # Parse a
        my @nodes_propstat
            = HTTP::DAV::Utils::get_elements_by_tag_name($node_response,
            "D:propstat");

        # Unset any old properties
        $resource->_unset_properties();

        foreach my $node_propstat (@nodes_propstat) {

            ###
            # Parse b
            my $node_prop = HTTP::DAV::Utils::get_only_element($node_propstat,
                "D:prop");
            my $prop_hashref
                = $resource->_XML_parse_and_store_props($node_prop);

            ###
            # Parse c and d
            my ($propstat_status, $propstat_rd)
                = $self->_XML_parse_status($node_propstat);

            # If there is no rd for this propstat, then use the
            # enclosing rd from the actual response.
            $propstat_rd = $response_rd unless $propstat_rd;

            if ($propstat_status) {
                $resp->add_status_line(
                    $propstat_status,
                    $propstat_rd,
                    "$href_a:propstat:$node_propstat",
                    $href_a
                );
            }

        }    # foreach propstat

    }    # foreach response

    #warn "\nEND MULTI:". $self->as_string . $resource_list->as_string;
    return $resource_list;
}

###
# This routine takes an XML node and:
# Extracts the D:status and D:responsedescription elements.
# If either of these exists, sets messages into the passed HTTP::DAV::Response object.
# The handle should be unique.
sub _XML_parse_status {
    my ($self, $node) = @_;

    # <!ELEMENT status (#PCDATA) >
    # <!ELEMENT responsedescription (#PCDATA) >
    my $node_status = HTTP::DAV::Utils::get_only_element($node, "D:status");
    my $node_rd
        = HTTP::DAV::Utils::get_only_element($node, "D:responsedescription");
    my $status = $node_status->getFirstChild->getNodeValue()
        if ($node_status);
    my $rd = $node_rd->getFirstChild->getNodeValue() if ($node_rd);

    return ($status, $rd);
}

###
# Pass in the XML::DOM prop node Element and it will
# parse and store all of the properties. These ones
# are specifically dealt with:
# creationdate
# getcontenttype
# getcontentlength
# displayname
# getetag
# getlastmodified
# resourcetype
# supportedlock
# lockdiscovery
# source

sub _XML_parse_and_store_props {
    my ($self, $node) = @_;
    my %return_props = ();

    return unless ($node && $node->hasChildNodes());

    # These elements will just get copied straight into our properties hash.
    my @raw_copy = qw(
        creationdate
        getlastmodified
        getetag
        displayname
        getcontentlength
        getcontenttype
    );

    my $props = $node->getChildNodes;
    my $n     = $props->getLength;
    for (my $i = 0; $i < $n; $i++) {

        my $prop = $props->item($i);

        # Ignore anything in the <prop> element which is
        # not an Element. i.e. ignore comments, text, etc...
        next if ($prop->getNodeTypeName() ne "ELEMENT_NODE");

        my $prop_name = $prop->getNodeName();

        $prop_name = HTTP::DAV::Utils::XML_remove_namespace($prop_name);

        if (grep (/^$prop_name$/i, @raw_copy)) {
            my $cdata = HTTP::DAV::Utils::get_only_cdata($prop);
            $self->set_property($prop_name, $cdata);
        }

        elsif ($prop_name eq "lockdiscovery") {
            my @locks = HTTP::DAV::Lock->XML_lockdiscovery_parse($prop);
            $self->set_locks(@locks);
        }

        elsif ($prop_name eq "supportedlock") {
            my $supportedlock_hashref
                = HTTP::DAV::Lock::get_supportedlock_details($prop);
            $self->set_property("supportedlocks", $supportedlock_hashref);
        }

        # Work in progress
        #      elsif ( $prop_name eq "source" ) {
        #         my $links = $self->_XML_parse_source_links( $prop );
        #         $self->set_property( "supportedlocks", $supportedlock_hashref );
        #      }

        #resourcetype and others
        else {
            my $node_name = HTTP::DAV::Utils::XML_remove_namespace(
                $prop->getNodeName());
            my $str   = "";
            my @nodes = $prop->getChildNodes;
            foreach my $node (@nodes) { $str .= $node->toString; }
            $self->set_property($node_name, $str);
        }
    }

    ###
    # Cleanup work

    # set collection based on resourcetype
    #my $getcontenttype = $self->get_property("getcontenttype");
    #($getcontenttype && $getcontenttype =~ /directory/i  ) ||
    my $resourcetype = $self->get_property("resourcetype");
    if (($resourcetype && $resourcetype =~ /collection/i)) {
        $self->set_property("resourcetype", "collection");
        my $uri = HTTP::DAV::Utils::make_trail_slash($self->get_uri);
        $self->set_uri($uri);
    }

    # Clean up the date work.
    my $creationdate = $self->get_property("creationdate");
    if ($creationdate) {
        my ($epochgmt) = HTTP::Date::str2time($creationdate);
        $self->set_property("creationepoch", $epochgmt);
        $self->set_property("creationdate",  HTTP::Date::time2str($epochgmt));
    }

    my $getlastmodified = $self->get_property("getlastmodified");
    if ($getlastmodified) {
        my ($epochgmt) = HTTP::Date::str2time($getlastmodified);
        $self->set_property("lastmodifiedepoch", $epochgmt);
        $self->set_property("lastmodifieddate",
            HTTP::Date::time2str($epochgmt));
    }
}

sub _setup_custom_headers {
    my ($self, $headers, $custom_headers) = @_;

    if ($custom_headers && ref $custom_headers eq 'HASH') {
        for my $hdr_name (keys %{$custom_headers}) {
            my $hdr_value = $custom_headers->{$hdr_name};
            warn "Setting custom header $hdr_name to '$hdr_value'\n";
            $headers->header($hdr_name => $hdr_value);
        }
    }

    return;
}

###########################################################################
# $self->_setup_if_headers( $headers_obj, [0|1] );
# used by at least PUT,MKCOL,DELETE,COPY/MOVE
sub _setup_if_headers {
    my ($self, $headers, $tagged) = @_;

    # Setup the If: header if it is locked
    my $tokens = $self->{_lockedresourcelist}
        ->get_locktokens(-uri => $self->get_uri, -owned => 1);
    $tagged = 1 unless defined $tagged;
    my $if
        = $self->{_lockedresourcelist}->tokens_to_if_header($tokens, $tagged);
    $headers->header("If", $if) if $if;
    warn "Setting if_header to \"If: $if\"\n" if $if && $HTTP::DAV::DEBUG;
}

###########################################################################
# Dump the objects contents as a string
sub as_string {
    my ($self, $space, $depth) = @_;

    $depth = 1 if (!defined $depth || $depth eq "");
    $space = "" unless $space;
    my $return;

    # Do lock only
    if ($depth == 2) {
        $return = "${space}'Url': ";
        $return .= $self->{_uri}->as_string . "\n";
        foreach my $lock ($self->get_locks()) {
            $return .= $lock->pretty_print("$space   ");
        }
        return $return;
    }

    $return .= "${space}Resource\n";
    $space  .= "   ";
    $return .= "${space}'Url': ";
    $return .= $self->{_uri}->as_string . "\n";

    $return .= "${space}'Options': " . $self->{_options} . "\n"
        if $self->{_options};

    $return .= "${space}Properties\n";
    foreach my $prop (sort keys %{ $self->{_properties} }) {
        next if $prop =~ /_ls$/;
        my $prop_val;
        if ($prop eq "supportedlocks" && $depth > 1) {
            use Data::Dumper;
            $prop_val = $self->get_property($prop);
            $prop_val = Data::Dumper->Dump([$prop_val], ['$prop_val']);
        }
        else {
            $prop_val = $self->get_property($prop);
            $prop_val =~ s/\n/\\n/g;
        }
        $return .= "${space}   '$prop': $prop_val\n";
    }

    if (defined $self->{_content}) {
        $return .= "${space}'Content':"
            . substr($self->{_content}, 0, 50) . "...\n";
    }

    # DEEP PRINT
    if ($depth) {
        $return .= "${space}'_locks':\n";
        foreach my $lock ($self->get_locks()) {
            $return .= $lock->as_string("$space   ");
        }

        $return .= $self->{_resource_list}->as_string($space)
            if $self->{_resource_list};
    }

    # SHALLOW PRINT
    else {
        $return .= "${space}'_locks': ";
        foreach my $lock ($self->get_locks()) {
            my $locktoken = $lock->get_locktoken();
            my $owned = ($lock->is_owned) ? "owned" : "not owned";
            $return .= "${space}   $locktoken ($owned)\n";
        }
        $return
            .= "${space}'_resource_list': " . $self->{_resource_list} . "\n";
    }

    $return;
}

######################################################################
# Dump myself as an 'ls' might.
# Requires you to have already performed a propfind
sub build_ls {
    my ($self, $parent_resource) = @_;

    # Build some local variables that have been sanitised.
    my $exec           = $self->get_property("executable")        || "?";
    my $contenttype    = $self->get_property("getcontenttype")    || "";
    my $supportedlocks = $self->get_property("supportedlocks")    || ();
    my $epoch          = $self->get_property("lastmodifiedepoch") || 0;
    my $size           = $self->get_property("getcontentlength")  || "";
    my $is_coll        = $self->is_collection()                   || "?";
    my $is_lock        = $self->is_locked()                       || "?";

    # Construct a relative URI;
    my $abs_uri = $self->get_uri();
    my $rel_uri = $abs_uri->rel($parent_resource->get_uri());
    $rel_uri = uri_unescape($rel_uri);

    ####
    # Build up a long display name.

    # 1.
    my $lls = "URL: $abs_uri\n";
    foreach my $prop (sort keys %{ $self->{_properties} }) {
        next
            if ($prop eq "lastmodifiedepoch"
            || $prop eq "creationepoch"
            || $prop eq "supportedlocks");
        $lls .= "$prop: ";
        if ($prop =~ /Content-Length/) {
            $lls .= $self->get_property($prop) . " bytes";
        }
        else {
            $lls .= $self->get_property($prop);
        }
        $lls .= "\n";
    }

    # 2. Build a supportedlocks string
    if (defined $supportedlocks and ref($supportedlocks) eq "ARRAY") {
        my @supported_locks = @{$supportedlocks};
        $supportedlocks = "";
        foreach my $lock_type_hash (@supported_locks) {
            $supportedlocks .= $$lock_type_hash{'type'} . "/"
                . $$lock_type_hash{'scope'} . " ";
        }
    }
    else {
        $supportedlocks = '"No locking supported"';
    }

    $lls .= "Locks supported: $supportedlocks\n";

    # 3. Print all of the locks.
    my @my_locks     = $self->get_locks(-owned => 1);
    my @not_my_locks = $self->get_locks(-owned => 0);
    if ($is_lock) {
        $lls .= "Locks: \n";
        if (@my_locks) {
            $lls .= "   My locks:\n";
            foreach my $lock (@my_locks) {
                $lls .= $lock->pretty_print("      ") . "\n";
            }
        }
        if (@not_my_locks) {
            $lls .= "   Others' locks:\n";
            foreach my $lock (@not_my_locks) {
                $lls .= $lock->pretty_print("      ") . "\n";
            }
        }

    }
    else {
        $lls .= "Locks: Not locked\n";
    }

    ######################################################################
    ####
    # Build up a list of useful information

    $self->set_property('rel_uri', $rel_uri);

    my @props = ();
    push(@props, "<exe>")    if ($exec    eq "T");
    push(@props, "<dir>")    if ($is_coll eq "1");
    push(@props, "<locked>") if ($is_lock eq "1");
    $self->set_property('short_props', join(',', @props));

    # Build a (short) display date in either
    # "Mmm dd  yyyy" or "Mmm dd HH:MM" format.

    my $display_date = "?";
    if ($epoch > 1) {

        my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
            = localtime($epoch);
        my %mons = (
            0 => 'Jan', 1 => 'Feb', 2  => 'Mar', 3  => 'Apr',
            4 => 'May', 5 => 'Jun', 6  => 'Jul', 7  => 'Aug',
            8 => 'Sep', 9 => 'Oct', 10 => 'Nov', 11 => 'Dec'
        );
        $year += 1900;
        my $month = $mons{$mon};

        # If the last modified time is older than six months
        # then display in "Mmm dd  yyyy" format.
        # else display in "Mmm dd HH:MM" format.
        if (time - $epoch > (3600 * 24 * 30 * 6)) {
            $self->set_property(
                'display_date',
                sprintf(
                    "%3s %0.2d  %4d",
                    $month, $mday, $year
                )
            );
        }
        else {
            $self->set_property(
                'display_date',
                sprintf(
                    "%3s %0.2d %0.2d:%0.2d",
                    $month, $mday, $hour, $min
                )
            );
        }
    }

    $self->set_property('long_ls', $lls);

    # Preset this, but it will be overwritten below
    # if it is a collection
    $self->set_property('short_ls', $lls);

    # Build the short listing if it is a collection
    if ($self->is_collection) {
        my $short = "";
        $short .= "Listing of " . $self->get_uri() . "\n";

        my $child_resource_list = $self->get_resourcelist;
        if (defined $child_resource_list) {
            my @resources = $child_resource_list->get_resources;

            foreach my $child_res (@resources) {
                $child_res->build_ls($self);
            }

            # Get the maximum uri length for pretty printing.
            my $max_uri_length   = 0;
            my $max_bytes_length = 0;
            foreach my $r ($self, sort by_URI @resources) {
                my $l;
                $l = length($r->get_property('rel_uri'));
                $max_uri_length = $l if $l > $max_uri_length;

                $l = length($r->get_property('getcontentlength'));
                $max_bytes_length = $l if $l > $max_bytes_length;
            }

            # Print the listing
            foreach my $r ($self, sort by_URI @resources) {
                $short .= sprintf(
                    " %${max_uri_length}s  %${max_bytes_length}s  %12s  %s\n",
                    $r->get_property('rel_uri'),
                    $r->get_property('getcontentlength'),
                    $r->get_property('display_date'),
                    $r->get_property('short_props')
                );
            }
        }    # if defined resource_list

        $self->set_property('short_ls', $short);
    }

    sub by_URI {
        my $a_str = $a->get_uri;
        my $b_str = $b->get_uri;
        return $a_str cmp $b_str;
    }
}

1;

__END__

=head1 NAME

HTTP::DAV::Resource - Represents and interfaces with WebDAV Resources

=head1 SYNOPSIS

Sample

=head1 DESCRIPTION

Description here

=head1 CONSTRUCTORS

=over 4

=item B<new>

Returns a new resource represented by the URI.

$r = HTTP::DAV::Resource->new( 
        -uri => $uri, 
        -LockedResourceList => $locks, 
        -Comms => $comms 
        -Client => $dav_client 
     );

On creation a Resource object needs 2 other objects passed in:

1. a C<ResourceList> Object. This list will be added to if you lock this Resource.

2. a C<Comms> Object. This object will be used for HTTP communication.

2. a C<HTTP::DAV> Object. This object is where all locks are stored

=back

=head1 METHODS

=over 4 


=item B<get/GET>

Performs an HTTP GET and returns a DAV::Response object.        

 $response = $resource->get;
 print $resource->get_content if ($response->is_success);

=item B<put/PUT>

Performs an HTTP PUT and returns a DAV::Response object.        

$response = $resource->put( $string );

$string is be passed as the body.

 e.g.
 $response = $resource->put($string);
 print $resource->get_content if ($response->is_success);

Will use a Lock header if this resource was previously locked.

=item B<copy>

Not implemented 

=item B<move>

Not implemented 

=item B<delete>

Performs an HTTP DELETE and returns a DAV::Response object.

 $response = $resource->delete;
 print "Delete successful" if ($response->is_success);

Will use a Lock header if this resource was previously locked.

=item B<options>

Performs an HTTP OPTIONS and returns a DAV::Response object.

 $response = $resource->options;
 print "Yay for PUT!" if $resource->is_option("PUT");

=item B<mkcol>

Performs a WebDAV MKCOL request and returns a DAV::Response object.

 $response = $resource->mkcol;
 print "MKCOL successful" if ($response->is_success);

Will use a Lock header if this resource was previously locked.

=item B<proppatch>

xxx

=item B<propfind>

Performs a WebDAV PROPFIND request and returns a DAV::Response object.

 $response = $resource->propfind;
 if ($response->is_success) {
    print "PROPFIND successful\n";
    print $resource->get_property("displayname") . "\n";
 }

A successful PROPFIND fills the object with much data about the Resource.  
Including:
   displayname
   ...
   TODO


=item B<lock>

Performs a WebDAV LOCK request and returns a DAV::Response object.

 $resource->lock(
        -owner   => "Patrick Collins",
        -depth   => "infinity"
        -scope   => "exclusive",
        -type    => "write" 
        -timeout => TIMEOUT',
     )

lock takes the following arguments.


B<owner> - Indicates who locked this resource

The default value is: 
 DAV.pm/v$DAV::VERSION ($$)

 e.g. DAV.pm/v0.1 (123)

If you use a URL as the owner, the module will
automatically indicate to the server that is is a 
URL (<D:href>http://...</D:href>)


B<depth> - Indicates the depth of the lock. 

Legal values are 0 or infinity. (1 is not allowed).

The default value is infinity.

A lock value of 0 on a collection will lock just the collection but not it's members, whereas a lock value of infinity will lock the collection and all of it's members.


B<scope> - Indicates the scope of the lock.

Legal DAV values are "exclusive" or "shared".

The default value is exclusive. 

See section 6.1 of RFC2518 for a description of shared vs. exclusive locks.


B<type> - Indicates the type of lock (read, write, etc)

The only legal DAV value currently is "write".

The default value is write.


B<timeout> - Indicates when the lock will timeout

The timeout value may be one of, an Absolute Date, a Time Offset from now, or the word "infinity". 

The default value is "infinity".

The following are all valid timeout values:

Time Offset:
    30s          30 seconds from now
    10m          ten minutes from now
    1h           one hour from now
    1d           tomorrow
    3M           in three months
    10y          in ten years time

Absolute Date:

    timeout at the indicated time & date (UTC/GMT)
       2000-02-31 00:40:33   

    timeout at the indicated date (UTC/GMT)
       2000-02-31            

You can use any of the Absolute Date formats specified in HTTP::Date (see perldoc HTTP::Date)

Note: the DAV server may choose to ignore your specified timeout. 


=item B<unlock>

Performs a WebDAV UNLOCK request and returns a DAV::Response object.

 $response = $resource->unlock()
 $response = $resource->unlock( -force => 1 )
 $response = $resource->unlock( 
    -token => "opaquelocktoken:1342-21423-2323" )

This method will automatically use the correct locktoken If: header if this resource was previously locked.

B<force> - Synonymous to calling $resource->forcefully_unlock_all.

=item B<forcefully_unlock_all>

Remove all locks from a resource and return the last DAV::Response object. This method take no arguments.

$response = $resource->forcefully_unlock_all;

This method will perform a lockdiscovery against the resource to determine all of the current locks. Then it will UNLOCK them one by one. unlock( -token => locktoken ). 

This unlock process is achievable because DAV does not enforce any security over locks.

Note: this method returns the LAST unlock response (this is sufficient to indicate the success of the sequence of unlocks). If an unlock fails, it will bail and return that response.  For instance, In the event that there are 3 shared locks and the second unlock method fails, then you will get returned the unsuccessful second response. The 3rd unlock will not be attempted.

Don't run with this knife, you could hurt someone (or yourself).

=item B<steal_lock>

Removes all locks from a resource, relocks it in your name and returns the DAV::Response object for the lock command. This method takes no arguments.

$response = $resource->steal_lock;

Synonymous to forcefully_unlock_all() and then lock().

=item B<lockdiscovery>

Discover the locks held against this resource and return a DAV::Response object. This method take no arguments.

 $response = $resource->lockdiscovery;
 @locks = $resource->get_locks if $response->is_success;

This method is in fact a simplified version of propfind().

=item B<as_string>

Returns a string representation of the object. Mainly useful for debugging purposes. It takes no arguments.

print $resource->as_string

=back

=head1 ACCESSOR METHODS (get, set and is)

=over 4 

=item B<is_option>

Returns a boolean indicating whether this resource supports the option passed in as a string. The option match is case insensitive so, PUT and Put are should both work.

 if ($resource->is_option( "PUT" ) ) {
    $resource->put( ... ) 
 }

Note: this routine automatically calls the options() routine which makes the request to the server. Subsequent calls to is_option will use the cached option list. To force a rerequest to the server call options()

=item B<is_locked>

Returns a boolean indicating whether this resource is locked.

  @lock = $resource->is_locked( -owned=>[1|0] );

B<owned> - this parameter is used to ask, is this resource locked by me?

Note: You must have already called propfind() or lockdiscovery()

e.g. 
Is the resource locked at all?
 print "yes" if $resource->is_locked();

Is the resource locked by me?
 print "yes" if $resource->is_locked( -owned=>1 );

Is the resource locked by someone other than me?
 print "yes" if $resource->is_locked( -owned=>0 );

=item B<is_collection>

Returns a boolean indicating whether this resource is a collection. 

 print "Directory" if ( $resource->is_collection );

You must first have performed a propfind.

=item B<get_uri>

Returns the URI object for this resource.

 print "URL is: " . $resource->get_uri()->as_string . "\n";

See the URI manpage from the LWP libraries (perldoc URI)

=item B<get_property>

Returns a property value. Takes a string as an argument.

 print $resource->get_property( "displayname" );

You must first have performed a propfind.

=item B<get_options>

Returns an array of options allowed on this resource.
Note: If $resource->options has not been called then it will return an empty array.

@options = $resource->get_options

=item B<get_content>

Returns the resource's content/body as a string.
The content is typically the result of a GET. 

$content = $resource->get_content

=item B<get_content_ref>

Returns the resource's content/body as a reference to a string.
This is useful and more efficient if the content is large.

${$resource->get_content_ref} =~ s/\bfoo\b/bar/g;

Note: You must have already called get()

=item B<get_lock>

Returns the DAV::Lock object if it exists. Requires opaquelocktoken passed as a parameter.

 $lock = $resource->get_lock( "opaquelocktoken:234214--342-3444" );

=item B<get_locks>

Returns a list of any DAV::Lock objects held against the resource.

  @lock = $resource->get_locks( -owned=>[1|0] );

B<owned> - this parameter indicates which locks you want.
 - '1', requests any of my locks. (Locked by this DAV instance).
 - '0' ,requests any locks not owned by us.
 - any other value or no value, requests ALL locks.

Note: You must have already called propfind() or lockdiscovery()

e.g. 
 Give me my locks
  @lock = $resource->get_locks( -owned=>1 );

 Give me all locks
  @lock = $resource->get_locks();

=item B<get_lockedresourcelist>

=item B<get_parentresourcelist>

=item B<get_comms>

=item B<set_parent_resourcelist>

$resource->set_parent_resourcelist( $resourcelist )

Sets the parent resource list (ask the question, which collection am I a member of?). See L<HTTP::DAV::ResourceList>.

=cut

