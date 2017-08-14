package MToken::Client; # $Id: Client.pm 44 2017-07-31 14:44:24Z minus $
use strict;
use feature qw/say/;

=head1 NAME

MToken::Client - Client for interaction with MToken server

=head1 VIRSION

Version 1.00

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

=head1 METHODS

=over 8

=item B<new>

    my $client = new MToken::Client(
        uri     => "http://localhost/mtoken",
        user    => $user, # optional
        password    => $password, # optional
        timeout => $timeout, # default: 180
    );

Returns client

=item B<check>

    my $status = $client->check;

Returns check-status of server. 0 - Error; 1 - Ok

See README file for details of data format

=item B<code>

    my $code = $clinet->code;

Returns HTTP code of the response

=item B<credentials>

    $client->credentials("username", "password", "realm")

Set credentials for User Agent by Realm (name of basic authentication)

=item B<del>

    my $status = $clinet->del(
        file => $filename,
    );

Request for deleting of the file on server by filename.
The method returns status of operation: 0 - Error; 1 - Ok

See README file for details of data format

=item B<download>

    my $status = $clinet->download(
        file => $filename,
    );

Request for download file on server by filename.
The method returns status of operation: 0 - Error; 1 - Ok

See README file for details of data format

=item B<error>

    print $clinet->error;

Returns error string

=item B<info>

    my $status = $clinet->info(
        file => $filename,
    );

Request for getting information about file on server by filename.
The method returns status of operation: 0 - Error; 1 - Ok

See README file for details of data format

=item B<list>

    my $status = $clinet->list();

Request for getting list of files on server.
The method returns status of operation: 0 - Error; 1 - Ok

See README file for details of data format

=item B<remove>

    my $status = $clinet->remove("filename");

Remove file from server by name and returns status value

=item B<req>

    my $request = $clinet->req;

Returns request hash

=item B<request>

    my $json = $clinet->request("METHOD", "PATH", "DATA");

Send request

=item B<res>

    my $response = $clinet->res;

Returns response hash

=item B<status>

    my $status = $clinet->status;

Returns object status value. 0 - Error; 1 - Ok

=item B<update>

    my $status = $clinet->update("filename");

Update file on server by name and returns status value

=item B<upload>

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

=back

=head1 HISTORY

See C<CHANGES> file

=head1 DEPENDENCIES

L<LWP>, C<mod_perl2>, L<CTK>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>, L<CTK>, L<mod_perl2>

=head1 AUTHOR

Sergey Lepenkov (Serz Minus) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2017 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

See C<LICENSE> file

=cut

use vars qw/ $VERSION /;
$VERSION = '1.00';

use CTK::Util qw/ :API /;
use CTK::TFVals qw/ :ALL /;
use CTK::ConfGenUtil;
use Try::Tiny;
use MToken::Util;
use JSON;
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
        TRANSACTION_MASK    => "%s %s >>> %s %s for %d sec",
        CONTENT_TYPE        => "application/json",
        NO_JSON_RESPONSE    => 1,
    };

$SIG{INT} = sub { die "Interrupted\n"; };
$| = 1;  # autoflush

sub new {
    my $class = shift;
    my %args  = @_;

    # General
    $args{status} = 1; # Ok
    $args{error} = "";
    $args{code} = 0;

    # Debugging
    $args{debug} ||= 0; # Display transaction headers
    $args{verbose} ||= 0; # Display content

    # Other defaults
    $args{req} = undef;
    $args{res} = undef;

    # Initial URI & URL
    if ($args{uri}) {
        $args{url} = scalar($args{uri}->as_string);
    } else {
        if ($args{url}) {
            $args{uri} = new URI($args{url});
        } else {
            croak("Can't defined URL or URI");
        }
    }

    # User Agent
    $args{timeout} ||= HTTP_TIMEOUT; # TimeOut
    unless ($args{ua}) {
        my %uaopt = (
                agent                   => __PACKAGE__."/".$VERSION,
                max_redirect            => 10,
                timeout                 => $args{timeout},
                #requests_redirectable   => ['GET','HEAD','POST','PUT','DELETE'],
                requests_redirectable   => ['GET','HEAD'],
                protocols_allowed       => ['http', 'https'],
            );
        my $ua = new MToken::Client::UserAgent(%uaopt);
        $ua->default_header('Cache-Control' => "no-cache");
        $args{ua} = $ua;
    }

    # Credentials: Set User & Password
    $args{user} //= '';
    $args{password} //= '';
    $args{realm} //='';
    #$args{ua}->credentials($args{uri}->host_port, $args{realm}, $args{user}, $args{password}) if defined $args{user};
    #$args{ua}->add_handler( request_prepare => sub {
    #        my($req, $ua, $h) = @_;
    #        $req->authorization_basic( $args{user}, $args{password} ) if defined $args{user};
    #        return $req;
    #    } );


    # URL Replacement (Redirect)
    $args{redirect} = {};
    my $turl = $args{url};
    if ($args{redirect}->{$turl}) {
        $args{url} = $args{redirect}->{$turl};
        $args{uri} = new URI($args{url});
    } else {
        my $tres = $args{ua}->head($args{url});
        my $dst_url;
        foreach my $r ($tres->redirects) { # Redirects detected!
            next unless $r->header('location');
            $dst_url = $r->header('location');
            my $src_uri = $r->request->uri; my $src_url = $src_uri->as_string;
            say(sprintf("Redirect detected (%s): %s ==> %s", $r->status_line, $src_url, $dst_url));
        }
        if ($dst_url) {
            $args{redirect}->{$turl} = $dst_url; # Set SRC_URL -> DST_URL
            $args{url} = $dst_url;
            $args{uri} = new URI($dst_url);
            #$args{ua}->credentials($args{uri}->host_port, $args{realm}, $args{user}, $args{password}) if defined $args{user};
        }
    }

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
sub request {
    my $self = shift;
    my $method = shift || "GET";
    my $path = shift;
    my $data = shift;
    my $no_json_response = shift;

    # UserAgent
    my $ua = $self->{ua};

    # URI
    my $uri = $self->{uri}; # Get default
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
        if (defined($req_content)) {
            $req->header('Content-Length' => length($req_content)) unless ref($req_content);
            $req->content($req_content);
        } else {
            $req->header('Content-Length' => 0);
        }
        #say(Dumper({parameters => \@parameters, }));
    } elsif ($method eq "PUT") {
        $req->header('Content-Type', 'application/octet-stream');
        if (length($data)) {
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
    my ($stat, $line, $code);
    my $req_string = sprintf("%s %s", $method, $res->request->uri->as_string);
    $stat = $res->is_success ? 1 : 0;
    $code = $res->code;
    $self->code($code);
    $line = $res->status_line;

    # Debugging
    if ($self->{debug}) {
        # Request
        say($req_string);
        say($res->request->headers_as_string);
        if ($self->{verbose}) {
            say(sprintf("-----BEGIN REQUEST CONTENT-----\n%s\n-----END REQUEST CONTENT-----", $req->content));
        }
        # Response
        say($line);
        say($res->headers_as_string);
        if ($self->{verbose}) {
            say(sprintf("-----BEGIN RESPONSE CONTENT-----\n%s\n-----END RESPONSE CONTENT-----", $res->content));
        }
    }

    # Response
    $self->status($stat);
    $self->error(sprintf("%s >>> %s", $req_string, $line)) unless $stat;
    if ($no_json_response || $method eq "HEAD") {
        return ( json => "", status => 1 ) if $stat;
        return ( json => "", status => $stat, error  => [{code => $code, message => $res->message}] );
    }
    my %json = _read_json($stat ? $res->decoded_content : undef);
    if ($stat) {
        my $err = _check_response(\%json);
        if ($err) {
            $self->status(0);
            $self->error($err);
            return %json;
        }
    }
    return %json;
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
sub req {
    my $self = shift;
    return $self->{req};
}
sub res {
    my $self = shift;
    return $self->{res};
}

sub check {
    my $self = shift;
    $self->request("HEAD", @_);
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
        return 0;
    }

    my %json = $self->request("GET");
    return unless $self->status;
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
sub upload { # Returns status
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
        md5     => md5sum($file),
        sha1    => sha1sum($file),
        size    => filesize($file),
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
sub download { # Returns message or undef
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
            $self->error(srintf("Error. %s of %s received", _fbytes($size), _fbytes($length)));
            $self->status(0);
            return;
        } else {
            $msg = sprintf("%s received", _fbytes($size));
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
sub remove {
    my $self = shift;
    my $file = shift;
    unless (defined($file) && length($file)) {
        $self->error("Incorrect file");
        $self->status(0);
        return;
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
sub update {
    my $self = shift;
    my $file = shift;
    unless (defined($file) && length($file)) {
        $self->error("Incorrect file");
        $self->status(0);
        return;
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
        my $in_md5 = md5sum($file) || '';
        unless ($in_md5 eq $out_md5) {
            $self->status(0);
            $self->error(sprintf("File md5sum mismatch: Expected: %s; Got: %s", $in_md5, $out_md5));

        }
    }
    my $out_sha1 = $json{data}{out}{out_sha1};;
    if ($out_sha1) {
        my $in_sha1 = sha1sum($file);
        unless ($in_sha1 eq $out_sha1) {
            $self->status(0);
            $self->error(sprintf("File sha1sum mismatch: Expected: %s; Got: %s", $in_sha1, $out_sha1));
        }
    }

    return $self->status;
}

sub _read_json { # JSON -> Structure
    my $json = shift;
    my $out = {
            json    => "",
            status  => 0,
            error   => [{code => 204, message => "No input data"}],
        };
    return %$out unless $json;
    try {
        my $in = from_json($json, {utf8 => 0});
        if ($in && ((ref($in) eq 'HASH') || ref($in) eq 'ARRAY')) {
            if (ref($in) eq 'ARRAY') {
                $out = shift(@$in) || {};
            } else { # HASH
                $out = $in;
            }
        } else {
            $out = { error => [{code => 1002, message => "Bad JSON format"}] };
        }
        $out->{error} ||= [{code => 1001, message => "Incorrect input data"}];
    } catch {
        $out = { error => [{code => 1003, message => sprintf("Can't load JSON from request: %s", $_)}] };
    };
    $out->{json} = $json;
    $out->{status} ||= 0;
    return %$out;
}
sub _check_response { # Returns error string when status = 0 and error is not empty
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
                push @error, sprintf("[%04d] %s", uv2zero(value($err => "code")), uv2null(value($err => "message")));
            }
        }
    } else {
        return "The response has not valid JSON format";
    }
    return join "; ", @error;
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

1;

# We make our own specialization of LWP::UserAgent that asks for
# user/password if document is protected.
package # Hide it from PAUSE
    MToken::Client::UserAgent;
use LWP::UserAgent;
use MToken::Config;
use MToken::Const;
use base 'LWP::UserAgent';
sub get_basic_credentials {
    my($self, $realm, $uri, $proxy) = @_;
    my ($user, $password);
    my $netloc = $uri->host_port;
    my $config = new MToken::Config;

    if (!$config->get("server_ask_credentials") and defined $config->get("server_user")) {
        return ($config->get("server_user"), $config->get("server_password"));
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
        return ($user, $password);
    } else {
        return (undef, undef);
    }
    return if $proxy;
    return $self->credentials($uri->host_port, $realm);
}

1;

