package MToken::Client; # $Id: Client.pm 107 2021-10-10 20:04:42Z minus $
use strict;
use feature qw/say/;
use utf8;

=encoding utf-8

=head1 NAME

MToken::Client - Client for interaction with MToken server

=head1 VIRSION

Version 1.02

=head1 SYNOPSIS

    use MToken::Client;

    my $clinet = MToken::Client->new(
        url => "https://localhost:8642",
        username            => "username", # optional
        password            => "password", # optional
        pwcache             => "/path/to/pwcache.tmp",
        pwcache_ttl         => 300, # 5 min. Default
        max_redirects       => 2, # Default: 10
        connect_timeout     => 3, # Default: 10 sec
        inactivity_timeout  => 5, # Default: 30 sec
        request_timeout     => 10, # Default: 5 min (300 sec)
    );
    my $status = $client->check();

    if ($status) {
        print STDOUT $client->res->body;
    } else {
        print STDERR $clinet->error;
    }

=head1 DESCRIPTION

Client for interaction with MToken server

=head2 new

    my $clinet = MToken::Client->new(
        url => "https://localhost:8642",
        username            => "username", # optional
        password            => "password", # optional
        pwcache             => "/path/to/pwcache.tmp",
        pwcache_ttl         => 300, # 5 min. Default
        max_redirects       => 2, # Default: 10
        connect_timeout     => 3, # Default: 10 sec
        inactivity_timeout  => 5, # Default: 30 sec
        request_timeout     => 10, # Default: 5 min (300 sec)
    );

Returns client

=over 8

=item B<max_redirects>

Maximum number of redirects the user agent will follow before it fails. Default - 10

=item B<password>

Default password for basic authentication

=item B<pwcache>

Full path to file of password cache

=item B<pwcache_ttl>

Time to Live of pwcache file. Default - 300 sec

=item B<*timeout>

Timeout for connections, requests and inactivity periods in seconds.

=item B<ua>

The Mojo UserAgent object

=item B<url>

Full URL of the WEB Server

=item B<username>

Default username for basic authentication

=back

=head1 METHODS

=head2 check

    my $status = $client->check;
    my $status = $client->check(URL);

Returns check-status of server. 0 - Error; 1 - Ok

=head2 cleanup

    $client->cleanup;

Cleanup all variable data in object and returns client object

=head2 code

    my $code = $clinet->code;

Returns HTTP code of the response

=head2 credentials

    my $userinfo = $client->credentials($MOJO_URL_OBJECT, 1)

Gets credentials for User Agent

=head2 download

    my $status = $client->download(TOKEN_NAME => TARBALL_FILE_PATH);

Request for download file from server by file path.
The method returns status of operation: 0 - Error; 1 - Ok

=head2 error

    print $clinet->error;

Returns error string

=head2 info

    my $status = $clinet->info();
    my $status = $clinet->info( TOKEN_NAME );

Request for getting information about token storage or about list of stored token tarballs.

=head2 remove

    my $status = $client->remove(TOKEN_NAME => TARBALL_FILE_NAME);

Request for deleting of the file on server by filename.
The method returns status of operation: 0 - Error; 1 - Ok

=head2 req

    my $request = $clinet->req;

Returns Mojo::Message::Request object

=head2 request

    my $json = $clinet->request("METHOD", "PATH", ...ATTRIBUTES...);

Send request

=head2 res

    my $response = $clinet->res;

Returns Mojo::Message::Response object

=head2 status

    my $status = $clinet->status;

Returns object status value. 0 - Error; 1 - Ok

=head2 trace

    my $trace = $client->trace;
    print $client->trace("New trace record");

Gets trace stack or pushes new trace record to trace stack

=head2 tx

    my $status = $clinet->tx($tx);

Works with Mojo::Transaction object, interface with it

=head2 ua

    my $ua = $clinet->ua;

Returns Mojo::UserAgent object

=head2 upload

    my $status = $client->upload(TOKEN_NAME => TARBALL_FILE_PATH);

Request for uploading of tarball on server.
The method returns status of operation: 0 - Error; 1 - Ok

=head2 url

    my $url_object = $clinet->url;

Returns Mojo::URL object

=head1 HISTORY

See C<Changes> file

=head1 DEPENDENCIES

L<Mojolicious>

=head1 TO DO

See C<TODO> file

=head1 SEE ALSO

L<CTK>, L<Mojo::UserAgent>

=head1 AUTHOR

Serż Minus (Sergey Lepenkov) L<http://www.serzik.com> E<lt>abalama@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2021 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See C<LICENSE> file and L<https://dev.perl.org/licenses/>

=cut

use vars qw/ $VERSION /;
$VERSION = '1.02';

use Mojo::UserAgent;
use Mojo::Asset::File;
use Mojo::File qw/path/;
use Mojo::URL;
use Mojo::Util qw/steady_time/;

use CTK::Util qw/dtf lf_normalize touch/;

use MToken::Util qw/md5sum parse_credentials tcd_save tcd_load/;
use MToken::Const;

use constant {
        MAX_REDIRECTS       => 10,
        CONNECT_TIMEOUT     => 10,
        INACTIVITY_TIMEOUT  => 30,
        REQUEST_TIMEOUT     => 180,
        TRANSACTION_MASK    => "%s %s >>> %s %s [%s in %s%s]", # GET /auth >>> 200 OK [1.04 KB in 0.0242 seconds (43.1 KB/sec)]
        CONTENT_TYPE        => "application/json",
        PWCACHE_TTL         => 300, # 5 min (Time to Live)
    };


sub new {
    my $class = shift;
    my %args  = @_;

    # General
    $args{url} ||= ""; # base url
    $args{prefix} = "";
    if ($args{url}) {
        $args{url} =~ s/\/+$//; $args{url} .= "/"; # Correct slash
        $args{url} =~ s/mtoken\///; # Delete mtoken prefix
        $args{url} = Mojo::URL->new($args{url});
        $args{prefix} = $args{url}->path;
    }
    $args{status} = 1; # 0 - error, 1 - ok
    $args{error} = ""; # string
    $args{code} = 0;   # integer
    $args{trace} = []; # trace pool
    $args{tx_time} = 0;
    $args{req} = undef;
    $args{res} = undef;
    $args{user} ||= "";
    $args{password} ||= "";
    if ($args{url} && $args{user}) { # Set userinfo
        $args{url}->userinfo(sprintf("%s:%s", $args{user}, $args{password}))
    } elsif ($args{url}) {
        ($args{user}, $args{password}) = (parse_credentials($args{url}->to_unsafe_string));
    }
    $args{pwcache} ||= ""; # pwcache file
    $args{pwcache_ttl} //= PWCACHE_TTL;
    if ($args{pwcache} && -e $args{pwcache}) { # Set pwcache
        my $pwcache_path = path($args{pwcache});
        if ($args{pwcache_ttl} && ($pwcache_path->stat->mtime + $args{pwcache_ttl}) < time) { # expired
            $pwcache_path->remove;
        } else {
            touch($args{pwcache});
        }
    }

    # User Agent
    my $ua = $args{ua};
    unless ($ua) {
        # Create the instance
        $ua = Mojo::UserAgent->new(
                max_redirects       => $args{max_redirects} || MAX_REDIRECTS,
                connect_timeout     => $args{connect_timeout} || CONNECT_TIMEOUT,
                inactivity_timeout  => $args{inactivity_timeout} || INACTIVITY_TIMEOUT,
                request_timeout     => $args{request_timeout} || REQUEST_TIMEOUT,
                insecure            => $args{insecure} || 0,
            );
        $args{ua} = $ua;
    }

    my $self = bless {%args}, $class;
    return $self;
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
    $self->{status} = 1;
    $self->{error} = "";
    $self->{code} = 0;
    undef $self->{req};
    $self->{req} = undef;
    undef $self->{res};
    $self->{res} = undef;
    undef $self->{trace};
    $self->{trace} = [];
    return $self;
}
sub req {
    my $self = shift;
    return $self->{req};
}
sub res {
    my $self = shift;
    return $self->{res};
}
sub url {
    my $self = shift;
    return $self->{url};
}
sub ua {
    my $self = shift;
    return $self->{ua};
}
sub tx {
    my $self = shift;
    my $tx = shift;

    # Check Error
    my $err = $tx->error;
    unless (!$err || $err->{code}) {
        $self->error($err->{message});
        $self->status(0);
    }
    $self->code($tx->res->code || "000");
    $self->status($tx->res->is_success ? 1 : 0);
    $self->error($tx->res->json("/message") || $err->{message} || "Unknown error" )
        if $tx->res->is_error && !$self->error;

    # Tracing
    my $length = $tx->res->body_size || 0;
    my $rtime = $self->{tx_time} // 0;
    $self->trace(sprintf(TRANSACTION_MASK,
        $tx->req->method, $tx->req->url->to_abs, # Method & URL
        $self->code, $tx->res->message || $err->{message} || "Unknown error", # Line
        _fbytes($length), # Length
        _fduration($rtime), # Duration
        $rtime ? sprintf(" (%s/sec)", _fbytes($length/$rtime)) : "",
      ));
    my $req_hdrs = $tx->req->headers->to_string;
    if ($req_hdrs) {
        $self->trace(join("\n", map {$_ = "> $_"} split(/\n/, $req_hdrs)));
        $self->trace(">");
    }
    my $res_hdrs = $tx->res->headers->to_string;
    if ($res_hdrs) {
        $self->trace(join("\n", map {$_ = "< $_"} split(/\n/, $res_hdrs)));
        $self->trace("<");
    }

    # Request And Response
    $self->{req} = $tx->req;
    $self->{res} = $tx->res;

    return $self->status;
}
sub request {
    my $self = shift;
    my $meth = shift;
    my $_url = shift;
    my @params = @_;
    $self->cleanup(); # Cleanup first

    # Set URL + credentials
    my $url = $_url
        ? Mojo::URL->new("$_url")
        : $self->{url}
            ? $self->url->clone
            : Mojo::URL->new(DEFAULT_URL);
    $url->userinfo($self->credentials($url)) if $_url;

    # Request #1
    my $start_time = steady_time() * 1;
    my $tx = $self->ua->build_tx($meth, $url, @params); # Create transaction (tx) #1
    my $status = $self->tx($self->ua->start($tx)); # Run it and validate!);
    $self->{tx_time} = sprintf("%.*f",4, steady_time()*1 - $start_time) * 1;

    # Auth test
    if (!$status && $self->code == 401) {
        $self->cleanup();
        # Request #2
        $url->userinfo($self->credentials($url, 1));
        $tx = $self->ua->build_tx($meth, $url, @params); # Create transaction (tx) #2
        $status = $self->tx($self->ua->start($tx)); # Run it and validate!);
        $self->{tx_time} = sprintf("%.*f",4, steady_time()*1 - $start_time) * 1;
        if (!$status && $self->code == 401) {
            $self->{user} = "";
            $self->{password} = "";
            path($self->{pwcache})->remove if $self->{pwcache} && -e $self->{pwcache};
        } elsif ($status && $self->{pwcache}) {
            tcd_save($self->{pwcache}, $url->userinfo);
        }
    }

    return $status;
}
sub credentials {
    my $self = shift;
    my $url = shift;
    my $ask = shift(@_) ? 1 : 0;
    $url ||= $self->{url};
    my ($user, $password);

    # return predefined credentials
    return sprintf("%s:%s", $self->{user}, $self->{password}) if $self->{user};

    # return if url contains credentials
    ($user, $password) = (parse_credentials($url->to_unsafe_string));
    return sprintf("%s:%s", $user, $password) if $user;

    # Get from cache
    if ($self->{pwcache} && -e $self->{pwcache}) {
        my $pair = tcd_load($self->{pwcache}) // "";
        ($user, $password) = split(/\:/, $pair);
        return sprintf("%s:%s", $user, $password) if $user;
        unlink($self->{pwcache});
    }

    # prompt if ask flag is true and is terminal
    if ($ask && -t STDIN) {
        my $realm = 'server';
        printf STDERR "Enter username for %s at %s: ", $realm, $url->host_port;
        $user = <STDIN>;
        chomp($user);
        if (length($user)) {
            print STDERR "Password: ";
            system("stty -echo") unless IS_MSWIN;
            $password = <STDIN>;
            system("stty echo") unless IS_MSWIN;
            print STDERR "\n";  # because we disabled echo
            chomp($password);
            $self->{user} = $user;
            $self->{password} = $password;
        } else {
            return "";
        }
        return sprintf("%s:%s", $user, $password);
    }
    return "";
}
sub check {
    my $self = shift;
    my $url = shift;
    if (!$url && $self->{url}) {
        $url = $self->url->clone;
        $url->path("mtoken/");
    }
    return $self->request(HEAD => $url);
}
sub upload {
    my $self = shift;
    my $token = shift;
    my $file = shift;
    my $filepath = path($file);
    my $filename = $filepath->basename;
    my $url = $self->url->clone->path(sprintf("mtoken/%s/%s", $token, $filename));

    my $asset_file = Mojo::Asset::File->new(path => $file);
    $self->request(PUT => $url =>
        { # Headers
            'User-Agent' => sprintf("%s/%s", __PACKAGE__, $self->VERSION),
            'Content-Type' => 'multipart/form-data',
        },
        form => {
            size => $asset_file->size,
            md5 => md5sum($asset_file->path),
            tarball => {
                file        => $asset_file,
                filename    => $filename,
                'Content-Type' => 'application/octet-stream',
            },
        },
    );
}
sub info {
    my $self = shift;
    my $token = shift;
    my $url = $token
        ? $self->url->clone->path(sprintf("mtoken/%s", $token))
        : $self->url->clone->path("mtoken");
    return $self->request(GET => $url);
}
sub remove {
    my $self = shift;
    my $token = shift;
    my $file = shift;
    my $filepath = path($file);
    my $filename = $filepath->basename;
    my $url = $self->url->clone->path(sprintf("mtoken/%s/%s", $token, $filename));
    return $self->request(DELETE => $url);
}
sub download {
    my $self = shift;
    my $token = shift;
    my $file = shift;
    my $filepath = path($file);
    my $filename = $filepath->basename;
    my $url = $self->url->clone->path(sprintf("mtoken/%s/%s", $token, $filename));
    my $status = $self->request(GET => $url);
    return $status unless $status;
    $self->res->save_to($file);
    return 1 if $filepath->stat->size;
    $self->error("Can't download file");
    return $self->status(0);
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

1;

__END__
