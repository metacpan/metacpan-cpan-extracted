package MToken::Client; # $Id: Client.pm 69 2019-06-09 16:17:44Z minus $
use strict;
use feature qw/say/;
use utf8;

=encoding utf-8

=head1 NAME

MToken::Client - Client for interaction with MToken server

=head1 VIRSION

Version 1.01

=head1 SYNOPSIS

    use MToken::Client;

    my $clinet = new MToken::Client(
        uri => "http://localhost/mtoken",
    );
    my $status = $clinet->check;

    if ($status) {
    print STDOUT $client->response;
    } else {
    print STDERR $clinet->error;
    }

=head1 DESCRIPTION

Client for interaction with MToken server

=head2 new

    my $client = new MToken::Client(
        uri     => "http://localhost/mtoken",
        user    => $user, # optional
        password    => $password, # optional
        timeout => $timeout, # default: 180
    );

Returns client

=over 8

=item B<timeout>

Timeout for LWP requests, in seconds.

Default: 180 seconds (5 mins)

=item B<ua>

The LWP::UserAgent object

=item B<uri>

URI object, that describes URL of the WEB Server. See B<url> attribute

=item B<url>

Full URL of the WEB Server. See B<uri> attribute

=item B<verbose>

Enable verbose mode. Possible boolean value: 0 or 1

Add request and response data to trace stack if verbose is true

Default: false

=back

=head1 METHODS

=head2 check

    my $status = $client->check;

Returns check-status of server. 0 - Error; 1 - Ok

=head2 cleanup

    $client->cleanup;

Cleanup all variable data in object and returns client object

=head2 code

    my $code = $clinet->code;

Returns HTTP code of the response

=head2 credentials

    $client->credentials("username", "password", "realm")

Set credentials for User Agent by Realm (name of basic authentication)

=head2 del

    my $status = $clinet->del(
        file => $filename,
    );

Request for deleting of the file on server by filename.
The method returns status of operation: 0 - Error; 1 - Ok

See README file for details of data format

=head2 download

    my $status = $clinet->download(
        file => $filename,
    );

Request for download file on server by filename.
The method returns status of operation: 0 - Error; 1 - Ok

See README file for details of data format

=head2 error

    print $clinet->error;

Returns error string

=head2 info

    my $status = $clinet->info( $filename );

Request for getting information about file on server by filename or file id.
The method returns info as hash

=head2 line

    my $status_line = $clinet->line;

Returns HTTP status line of response

=head2 list

    my $status = $clinet->list( $filter );

Request for getting list of files on server.
The method returns array of files

=head2 remove

    my $status = $clinet->remove("filename");

Remove file from server by name and returns status value

=head2 req

    my $request = $clinet->req;

Returns HTTP::Request object

=head2 request

    my $json = $clinet->request("METHOD", "PATH", "DATA");

Send request

=head2 res

    my $response = $clinet->res;

Returns HTTP::Response object

=head2 status

    my $status = $clinet->status;

Returns object status value. 0 - Error; 1 - Ok

=head2 trace

    my $trace = $client->trace;
    print $client->trace("New trace record");

Gets trace stack or pushes new trace record to trace stack

=head2 transaction

    print $client->transaction;

Gets transaction string

=head2 update

    my $status = $clinet->update("filename");

Update file on server by name and returns status value

=head2 upload

    $status = $clinet->upload(
        file    => $file,
        filename=> $filename,
        sha1    => $sha1, # Optional
        md5     => $md5,  # Optional
        size    => $filesize,
    );

Request for uploading of backup on server.
The method returns status of operation: 0 - Error; 1 - Ok

See README file for details of data format

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<CTK>, L<LWP>, L<HTTP::Message>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

L<CTK>, L<LWP>, L<HTTP::Message>, L<URI>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2019 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.01';

use Carp;
use CTK::Util qw/ :BASE /;
use CTK::TFVals qw/ :ALL /;
use CTK::ConfGenUtil;
use Time::HiRes qw/gettimeofday/;
use Try::Tiny;
use MToken::Util;
use MToken::Const qw/DIR_TMP PWCACHE_FILE/;
use CTK::Serializer;
use File::Basename qw/basename/;

# LWP (libwww)
use URI;
use HTTP::Request;
use HTTP::Response;
use HTTP::Headers;
use HTTP::Headers::Util;
use HTTP::Request::Common qw//;

use constant {
        HTTP_TIMEOUT        => 180,
        MAX_REDIRECT        => 10,
        TRANSACTION_MASK    => "%s%s >>> %s [%s in %s%s]", # GET /auth >>> 200 OK [1.04 KB in 0.0242 seconds (43.1 KB/sec)]
        SERIALIZE_FORMAT    => 'json',
        CONTENT_TYPE        => "application/json",
        NO_JSON_RESPONSE    => 1,
        SR_ATTRS            => {
            json => [
                { # For serialize
                    utf8 => 0,
                    pretty => 1,
                    allow_nonref => 1,
                    allow_blessed => 1,
                },
                { # For deserialize
                    utf8 => 0,
                    allow_nonref => 1,
                    allow_blessed => 1,
                },
            ],
        },
    };

$SIG{INT} = sub { die "Interrupted\n"; };
$| = 1;  # autoflush

sub new {
    my $class = shift;
    my %args  = @_;

    # General
    $args{verbose} ||= 0; # Display content
    $args{status} = 1; # 0 - error, 1 - ok
    $args{error} = ""; # string
    $args{code} = 0;   # integer
    $args{line} = "";  # line
    $args{res_time} = 0;
    $args{trace_redirects} = [];
    $args{trace} = [];

    # TimeOut
    $args{timeout} ||= HTTP_TIMEOUT; # TimeOut

    # Other defaults
    $args{req} = undef;
    $args{res} = undef;

    # Serializer
    my $sr = new CTK::Serializer(SERIALIZE_FORMAT, attrs => SR_ATTRS);
    croak(sprintf("Can't create json serializer: %s", $sr->error)) unless $sr->status;
    $args{sr} = $sr;

    # Initial URI & URL
    if ($args{uri}) {
        $args{url} = scalar($args{uri}->canonical->as_string);
    } else {
        if ($args{url}) {
            $args{uri} = new URI($args{url});
        } else {
            croak("Can't defined URL or URI");
        }
    }
    my $userinfo = $args{uri}->userinfo;

    # User Agent
    my $ua = $args{ua};
    unless ($ua) {
        my %uaopt = (
                agent                   => __PACKAGE__."/".$VERSION,
                max_redirect            => MAX_REDIRECT,
                timeout                 => $args{timeout},
                requests_redirectable   => ['GET','HEAD'],
                protocols_allowed       => ['http', 'https'],
            );
        $ua = new MToken::Client::UserAgent(%uaopt);
        $ua->default_header('Cache-Control' => "no-cache");
        $args{ua} = $ua;
    }
    $ua->{x_userinfo} = $userinfo;

    # URL Replacement (Redirect)
    $args{redirect} = {};
    my @trace_redirects = ();
    my $turl = $args{url};
    if ($args{redirect}->{$turl}) {
        $args{url} = $args{redirect}->{$turl};
        $args{uri} = new URI($args{url});
    } else {
        my $tres = $args{ua}->head($args{url});
        my $dst_url;
        foreach my $r ($tres->redirects) { # Redirects detected!
            next unless $r->header('location');
            my $dst_uri = new URI($r->header('location'));
            $dst_uri->userinfo($userinfo) if $userinfo;
            $dst_url = $dst_uri->canonical->as_string;
            my $src_url = $r->request->uri->canonical->as_string;
            push @trace_redirects, sprintf("Redirect detected (%s): %s ==> %s", $r->status_line, $src_url, $dst_url);
        }
        if ($dst_url) {
            $args{redirect}->{$turl} = $dst_url; # Set SRC_URL -> DST_URL
            $args{url} = $dst_url;
            $args{uri} = new URI($dst_url);
        }
    }
    $args{trace_redirects} = [@trace_redirects];

    my $self = bless {%args}, $class;
    return $self;
}
sub credentials {
    my $self = shift;
    my $user = shift;
    my $password = shift;
    my $realm = shift || $self->{realm};

    $self->{user} = $user;
    $self->{password} = $password;
    #$self->req->authorization_basic( $user, $password ) if defined $user;
    $self->{ua}->credentials($self->{uri}->host_port, $realm, $user, $password) if defined $user;
    #$self->{ua}->add_handler( request_prepare => sub {
    #        my($req, $ua, $h) = @_;
    #        $req->authorization_basic( $user, $password ) if defined $user;
    #        return $req;
    #    } );

    return 1;
}

sub error {
    my $self = shift;
    my $e = shift;
    $self->{error} = $e if defined $e;
    return $self->{error};
}
sub status {
    my $self = shift;
    my $s = shift;
    $self->{status} = $s if defined $s;
    return $self->{status};
}
sub code {
    my $self = shift;
    my $c = shift;
    $self->{code} = $c if defined $c;
    return $self->{code};
}
sub line {
    my $self = shift;
    my $l = shift;
    $self->{line} = $l if defined $l;
    return $self->{line};
}
sub req {
    my $self = shift;
    return $self->{req};
}
sub res {
    my $self = shift;
    return $self->{res};
}
sub transaction {
    my $self = shift;
    my $res = $self->res;
    return 'NOOP' unless $res;
    my $length = $res->content_length || 0;
    my $rtime = $self->{res_time} // 0;
    return sprintf(TRANSACTION_MASK,
        $self->req->method, # Method
        sprintf(" %s", _hide_pasword($res->request->uri)->canonical->as_string), # URL
        $self->line // "ERROR", # Line
        _fbytes($length), # Length
        _fduration($rtime), # Duration
        $rtime ? sprintf(" (%s/sec)", _fbytes($length/$rtime)) : "",
      )
}
sub trace {
    my $self = shift;
    my $v = shift;
    if (defined($v)) {
        my $a = $self->{trace};
        push @$a, lf_normalize($v);
        return lf_normalize($v);
    }
    my $trace = $self->{trace} || [];
    return join("\n",@$trace);
}

sub cleanup {
    my $self = shift;
    my $status = shift || 0;
    $self->{status} = $status;
    $self->{error} = "";
    $self->{code} = 0;
    $self->{line} = "";
    $self->{res_time} = 0;
    undef $self->{req};
    $self->{req} = undef;
    undef $self->{res};
    $self->{res} = undef;
    undef $self->{trace};
    my $trace = $self->{trace_redirects} || [];
    $self->{trace} = [@$trace];
    return $self;
}

sub request {
    my $self = shift;
    my $method = shift || "GET";
    my $path = shift;
    my $data = shift;
    my $no_json_response = shift;
    $self->cleanup;

    my $ua = $self->{ua}; # UserAgent
    my $sr = $self->{sr}; # Serializer
    my $start_time = gettimeofday()*1;

    # URI
    my $uri = $self->{uri}->clone;
    $uri->path($path) if defined $path;

    # Prepare Request
    my $req = new HTTP::Request(uc($method), $uri);
    if ($method eq "POST") {
        unless (defined($data) && ( is_hash($data) or !ref($data) )) {
            croak("Data not specified! Please use HASH-ref or text data");
        }
        my ($req_content, $boundary);
        if (is_hash($data)) { # form-data
            my $ct = "multipart/form-data"; # "application/x-www-form-urlencoded"
            ($req_content, $boundary) = HTTP::Request::Common::form_data($data, HTTP::Request::Common::boundary(6), $req);
            $req->header('Content-Type' =>
                    HTTP::Headers::Util::join_header_words( $ct, undef, boundary => $boundary )
                ); # might be redundant
        } else {
            $req->header('Content-Type', CONTENT_TYPE);
            $req_content = $data;
        }
        if (defined($req_content) && !ref($req_content)) {
            Encode::_utf8_on($req_content);
            $req->header('Content-Length' => length(Encode::encode("utf8", $req_content)));
            $req->content(Encode::encode("utf8", $req_content));
        } else {
            $req->header('Content-Length' => 0);
        }
    } elsif ($method eq "PUT") {
        $req->header('Content-Type', 'application/octet-stream');
        if (length($data)) { # File for uploading!
            my $file = $data;
            my $sizef = (-s $file) || 0;
            $req->header('Content-Length', $sizef);
            my $fh;
            $req->content(sub {
                unless ($fh) {
                    open($fh, "<", $file) || croak("Can't open file $file: $!");
                    binmode($fh);
                }
                my $buf = "";
                my $n = read($fh, $buf, 1024);
                if ($n) {
                    $sizef -= $n;
                    #say(sprintf("sizef=%d; n=%d", $sizef, $n));
                    return $buf;
                }
                close($fh);
                return "";
            });
        } else {
            $req->header('Content-Length', 0);
        }
    }
    $self->{req} = $req;

    # Send Request
    my $is_callback = ($data && ref($data) eq 'CODE') ? 1 : 0;
    my $res = $is_callback ? $ua->request($req, $data) : $ua->request($req);
    $self->{res} = $res;
    $self->{res_time} = sprintf("%.*f",4, gettimeofday()*1 - $start_time) * 1;
    my ($stat, $line, $code);
    my $req_string = sprintf("%s %s", $method, _hide_pasword($res->request->uri)->canonical->as_string);
    $stat = $res->is_success ? 1 : 0;
    $self->status($stat);
    $code = $res->code;
    $self->code($code);
    $line = $res->status_line;
    $self->line($line);
    $self->error(sprintf("%s >>> %s", $req_string, $line)) unless $stat;

    # Tracing
    {
        # Request
        $self->trace($req_string);
        $self->trace($res->request->headers_as_string);
        $self->trace(
            sprintf("-----BEGIN REQUEST CONTENT-----\n%s\n-----END REQUEST CONTENT-----", $req->content)
        ) if ($self->{verbose} && defined($req->content) && length($req->content));

        # Response
        $self->trace($line);
        $self->trace($res->headers_as_string);
        $self->trace(
            sprintf("-----BEGIN RESPONSE CONTENT-----\n%s\n-----END RESPONSE CONTENT-----", $res->content)
        ) if ($self->{verbose} && defined($res->content) && length($res->content));
    }

    # Return
    return () if $no_json_response || $method eq "HEAD";

    # DeSerialization
    my $content = $res->decoded_content // '';
    return () unless length($content);
    my $structure = $sr->deserialize($content);
    unless ($sr->status) {
        if ($stat) {
            $self->status(0);
            $self->error($sr->error);
        }
        return ();
    }
    my %json = %$structure if $structure && ref($structure) eq 'HASH';
    if ($stat) {
        my $err = _check_response($structure);
        if ($err) {
            $self->status(0);
            $self->error($err);
            return %json;
        }
    }
    return %json;
}

sub check {
    my $self = shift;
    $self->request("HEAD", @_);
	unless ($self->status) {
		my $code = $self->code || 500;
		if ($code >=400) {
			my $cachefn = File::Spec->catfile(DIR_TMP, PWCACHE_FILE);
			if (-e $cachefn and -f $cachefn) {
				unlink $cachefn;
				$self->request("HEAD", @_);
			}
		}
	}
    return 0 unless $self->status;
    return 1;
}
sub list {
    my $self = shift;
    my $filter = shift;
    my %json = $self->request("GET");
    return unless $self->status;
    my $files = $json{data}{files} || [];
    return @$files unless defined $filter and $filter ne "";
    return grep { $_->{filename} && index($_->{filename}, $filter) >= 0 } @$files;
}
sub info {
    my $self = shift;
    my $filename_or_id = shift;
    my ($id,$filename);
    if ($filename_or_id && $filename_or_id =~ /^([0-9]{8})$/) {
        $id = $1
    } elsif ($filename_or_id) {
        $filename = basename($filename_or_id);
    } else {
        $self->error("Incorrect filename or ID");
        $self->status(0);
        return ();
    }

    my %json = $self->request("GET");
    return () unless $self->status;
    my $files = $json{data}{files} || [];
    my $ret;
    if ($id) {
        ($ret) = grep { $_->{date_sfx} && $_->{date_sfx} == $id } @$files;
        return () unless $ret;
        return %$ret;
    }
    ($ret) = grep { $_->{filename} && $_->{filename} eq $filename } @$files;
    return () unless $ret;
    return %$ret;
}
sub upload {
    # Returns status
    my $self = shift;
    my $file = shift;
    unless (defined($file) && length($file)) {
        $self->error("Incorrect file");
        $self->status(0);
        return 0;
    }
    my $filename = basename($file);
    my $req_object = "index_post";
    my %json = $self->request("POST", undef, {
        object  => $req_object,
        md5     => MToken::Util::md5sum($file),
        sha1    => MToken::Util::sha1sum($file),
        size    => MToken::Util::filesize($file),
        file1   => [
                $file, $filename,
                #"Content-Type" => 'text/html',
            ],
    });
    my $res_object = $json{response_object} || '';
    if ($req_object ne $res_object) {
        $self->status(0);
        $self->error(sprintf("Object mismatch: Expected: %s; Got: %s", $req_object, $res_object));
    }
    return $self->status;
}
sub update {
    my $self = shift;
    my $file = shift;
    unless (defined($file) && length($file)) {
        $self->error("Incorrect file");
        $self->status(0);
        return 0;
    }
    my $filename = basename($file);

    my $curpath = "";
    if ($self->{updpath}) {
        $curpath = $self->{updpath};
    } else {
        $curpath = $self->{uri}->path || "";
        $curpath =~ s/\/+$//;
        $self->{updpath} = $curpath;
    }

    my $req_object = "file_put";
    my %json = $self->request("PUT", join("/", $curpath, $filename), $file);
    my $res_object = $json{response_object} || '';
    if ($req_object ne $res_object) {
        $self->status(0);
        $self->error(sprintf("Object mismatch: Expected: %s; Got: %s", $req_object, $res_object));
        return 0;
    }

    my $out_md5 = $json{data}{out}{out_md5};
    if ($out_md5) {
        my $in_md5 = MToken::Util::md5sum($file) || '';
        unless ($in_md5 eq $out_md5) {
            $self->status(0);
            $self->error(sprintf("File md5sum mismatch: Expected: %s; Got: %s", $in_md5, $out_md5));

        }
    }
    my $out_sha1 = $json{data}{out}{out_sha1};;
    if ($out_sha1) {
        my $in_sha1 = MToken::Util::sha1sum($file);
        unless ($in_sha1 eq $out_sha1) {
            $self->status(0);
            $self->error(sprintf("File sha1sum mismatch: Expected: %s; Got: %s", $in_sha1, $out_sha1));
        }
    }

    return $self->status;
}
sub remove {
    my $self = shift;
    my $file = shift;
    unless (defined($file) && length($file)) {
        $self->error("Incorrect file");
        $self->status(0);
        return 0;
    }
    my $filename = basename($file);

    my $curpath = "";
    if ($self->{rmvpath}) {
        $curpath = $self->{rmvpath};
    } else {
        $curpath = $self->{uri}->path || "";
        $curpath =~ s/\/+$//;
        $self->{rmvpath} = $curpath;
    }

    my %json = $self->request("DELETE", join("/", $curpath, $filename));
    return $self->status;
}
sub download {
    # Returns message or undef
    my $self = shift;
    my $file = shift; # name of file we download into
    unless (defined($file) && length($file)) {
        $self->error("Incorrect file");
        $self->status(0);
        return;
    }
    my $filename = basename($file);

    my $curpath = "";
    if ($self->{dldpath}) {
        $curpath = $self->{dldpath};
    } else {
        $curpath = $self->{uri}->path || "";
        $curpath =~ s/\/+$//;
        $self->{dldpath} = $curpath;
    }

    my $f_init;
    my $length;    # total number of bytes to download
    my $size = 0;  # number of bytes received

    $self->request("GET", join("/", $curpath, $filename), sub {
        my $buf = shift;
        unless(defined $f_init) {
            my $res = shift;
            $f_init = 1;
            unless(fileno(FILE_DOWNLOAD)) {
                open(FILE_DOWNLOAD, ">", $file) || croak("Can't open $file: $!");
            }
            binmode FILE_DOWNLOAD;
            $length = $res->content_length;
        }
        print FILE_DOWNLOAD $buf or croak("Can't write to $file: $!");
        $size += length($buf);
    }, NO_JSON_RESPONSE);
    my $msg;
    if (fileno(FILE_DOWNLOAD)) {
        close(FILE_DOWNLOAD) || croak("Can't write to $file: $!");
        if ($length && $size != $length) {
            unlink($file);
            $self->error(srintf("File %s error. %s of %s received", $file, _fbytes($size), _fbytes($length)));
            $self->status(0);
            return;
        } else {
            $msg = sprintf("File %s: %s received", $file, _fbytes($size));
        }
    }
    my $res = $self->res;
    if ($res->header("X-Died") || !$res->is_success) {
        if (my $died = $res->header("X-Died")) {
            $self->error($died);
        } else {
            $self->error("Can't get file");
        }
        unlink($file);
        $self->status(0);
        return;
    }

    return $self->status ? $msg : undef;
}

sub _check_response {
    # Returns error string when status = 0 and error is not empty
    my $res = shift;
    # Returns:
    #  "..." - errors!
    #  undef - no errors
    my @error;
    if (is_hash($res)) {
        return undef if value($res => "status"); # OK
        my $errors = array($res => "error");
        foreach my $err (@$errors) {
            if (is_hash($err)) {
                push @error, sprintf("E%04d %s", uv2zero(value($err => "code")), uv2null(value($err => "message")));
            }
        }
    } else {
        return "The response has not valid JSON format";
    }
    return join "; ", @error;
}
sub _fduration {
    my $msecs = shift || 0;
    my $secs = int($msecs);
    my $hours = int($secs / (60*60));
    $secs -= $hours * 60*60;
    my $mins = int($secs / 60);
    $secs %= 60;
    if ($hours) {
        return sprintf("%d hours %d minutes", $hours, $mins);
    } elsif ($mins >= 2) {
        return sprintf("%d minutes", $mins);
    } elsif ($secs < 2*60) {
        return sprintf("%.4f seconds", $msecs);
    } else {
        $secs += $mins * 60;
        return sprintf("%d seconds", $secs);
    }
}
sub _fbytes {
    my $n = int(shift);
    if ($n >= 1024 * 1024) {
        return sprintf "%.3g MB", $n / (1024.0 * 1024);
    } elsif ($n >= 1024) {
        return sprintf "%.3g KB", $n / 1024.0;
    } else {
        return "$n bytes";
    }
}
sub _hide_pasword {
    my $src = shift;
    my $uri_wop = $src->clone;
    my $info = $uri_wop->userinfo();
    if ($info) {
        $info =~ s/:.*//;
        $uri_wop->userinfo(sprintf("%s:*****", $info));
    }
    return $uri_wop;
}

1;

# We make our own specialization of LWP::UserAgent that asks for
# user/password if document is protected.
package # Hide it from PAUSE
    MToken::Client::UserAgent;
use LWP::UserAgent;
use MToken::Const;
use MToken::Util qw/parse_credentials tcd_save tcd_load/;
use base 'LWP::UserAgent';
sub get_basic_credentials {
    my($self, $realm, $uri, $proxy) = @_;
    my $uri2 = $uri->clone;
    $uri2->userinfo($self->{x_userinfo}) if $self->{x_userinfo};
    my $netloc = $uri->host_port;
    my ($user, $password) = (parse_credentials($uri2->as_string));
	my $cachefn = File::Spec->catfile(DIR_TMP, PWCACHE_FILE);
    if ($user) {
        return ($user, $password);
	} elsif (-f $cachefn and -r _ and -s _) {
		my $pair = tcd_load($cachefn) // "";
		($user, $password) = split(/\:/, $pair);
		unless (defined($user) && length($user)) {
			unlink($cachefn);
			return (undef, undef);
		}
		return ($user, $password);
    } elsif (-t) {
        print STDERR "Enter username for $realm at $netloc: ";
        $user = <STDIN>;
        chomp($user);
        return (undef, undef) unless length $user;
        print STDERR "Password: ";
        system("stty -echo") unless MSWIN;
        $password = <STDIN>;
        system("stty echo") unless MSWIN;
        print STDERR "\n";  # because we disabled echo
        chomp($password);
		tcd_save($cachefn, sprintf("%s:%s", $user, $password))
			if $password !~ /\:/; # See also MToken::Client::check function!
        return ($user, $password);
    } else {
        return (undef, undef);
    }
    #return if $proxy;
    #return $self->credentials($uri->host_port, $realm);
}

1;
