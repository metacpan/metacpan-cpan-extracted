package LWP::Protocol::sftp;

our $VERSION = '0.05';

# BEGIN { local $| =1; print "loading LWP::Protocol::sftp\n"; }


use strict;
use warnings;

use base qw(LWP::Protocol);
LWP::Protocol::implementor(sftp => __PACKAGE__);

require LWP::MediaTypes;
require HTTP::Request;
require HTTP::Response;
require HTTP::Status;
require HTTP::Date;

require URI::Escape;
require HTML::Entities;

use Net::SFTP::Foreign;
use Net::SFTP::Foreign::Constants qw(:flags :status);
use Fcntl qw(S_ISDIR);

use constant PUT_BLOCK_SIZE => 8192;

our %DEFAULTS = ( ls  => [],
                  new => [] );

my $dont_escape_in_paths = '^A-Za-z0-9\-\._~/';

sub request
{
    my($self, $request, $proxy, $arg, $size) = @_;

    # print __PACKAGE__."->request($self, $request, $proxy, $arg, $size)\n";

    $size = 4096 unless defined $size and $size > 0;

    # check proxy
    defined $proxy and
	return HTTP::Response->new(HTTP::Status::RC_BAD_REQUEST,
				  'You can not proxy through the sftp subsystem');

    # check method
    my $method = $request->method;

    # check url
    my $url = $request->url;

    my $scheme = $url->scheme;
    if ($scheme ne 'sftp') {
	return HTTP::Response->new(HTTP::Status::RC_INTERNAL_SERVER_ERROR,
				   "LWP::Protocol::sftp::request called for '$scheme'")
    }

    my $host = $url->host;
    my $port = $url->port;
    my $user = $url->user;
    my $password = $url->password;

    my $path  = $url->path;
    $path = '/' unless defined $path and length $path;

    my $sftp = Net::SFTP::Foreign->new(host => $host,
                                       user => $user,
                                       port => $port,
                                       password => $password,
                                       @{$DEFAULTS{new}});
    if ($sftp->error) {
	return HTTP::Response->new(HTTP::Status::RC_SERVICE_UNAVAILABLE,
				   "unable to establish SSH connection to remote machine (".$sftp->error.")")
    }

    # handle GET and HEAD methods

    my $response = eval {

	if ($method eq 'GET' || $method eq 'HEAD') {

	    my $stat = $sftp->stat($path) or die "remote file stat failed";

	    # check if-modified-since
	    my $ims = $request->header('If-Modified-Since');
	    if (defined $ims) {
		my $time = HTTP::Date::str2time($ims);
		if (defined $time and $time >= $stat->mtime) {
		    return HTTP::Response->new(HTTP::Status::RC_NOT_MODIFIED,
					       "$method $path")
		}
	    }

	    # Ok, should be an OK response by now...
	    my $response = HTTP::Response->new(HTTP::Status::RC_OK);

	    # fill in response headers
	    $response->header('Last-Modified', HTTP::Date::time2str($stat->mtime));

	    if (S_ISDIR($stat->perm)) {         # If the path is a directory, process it
		# generate the HTML for directory
		my $ls = $sftp->ls($path, ordered => 1,
                                   @{$DEFAULTS{ls}}) or die "remote ls failed";

		# Make directory listing
		my @lines = map {
                    my $fn = $_->{filename};
                    $fn .= '/' if S_ISDIR($_->{a}->perm);
                    my $furl = URI::Escape::uri_escape($fn, $dont_escape_in_paths);
		    my $desc = HTML::Entities::encode($fn);
		    qq{<li><a href="$furl">$desc</a>}
		} @$ls;

                $path =~ s|/?$|/|;
                my $ue_path = URI::Escape::uri_escape($path, $dont_escape_in_paths);
                my $ee_path = HTML::Entities::encode($path);

                # regenerate base url without password
                my $base = 'sftp://';
                $base .= URI::Escape::uri_escape($user) . '@' if defined $user;
                $base .= URI::Escape::uri_escape($host);
                $base .= ':' . URI::Escape::uri_escape($port) if defined $port;
                $base .= $ue_path;

                my $html = join("\n",
				"<HTML>\n<HEAD>",
				"<TITLE>Directory $ee_path</TITLE>",
				"<BASE HREF=\"$base\">",
				"</HEAD>\n<BODY>",
				"<H1>Directory listing of $ee_path</H1>",
				"<UL>", @lines, "</UL>",
				"</BODY>\n</HTML>\n");

		$response->header('Content-Type',   'text/html');
		$response->header('Content-Length', length $html);
		$html = "" if $method eq "HEAD";

		return $self->collect_once($arg, $response, $html);
	    }

	    # path is a regular file
	    my $file_size = $stat->size;
	    $response->header('Content-Length', $file_size);
	    LWP::MediaTypes::guess_media_type($path, $response);

	    # read the file
	    if ($method ne "HEAD") {
		my $fh = $sftp->open($path) or die "remote file open failed";
		$response = $self->collect($arg, $response, sub {
                                               my $content = $sftp->read($fh, $size);
                                               defined $content ? \$content : \"" });
		$sftp->close($fh) or die "remote file read failed";
	    }
	    return $response;
	}

	# handle PUT method
	if ($method eq 'PUT') {
	    my $fh = $sftp->open($path, SSH2_FXF_WRITE | SSH2_FXF_CREAT | SSH2_FXF_TRUNC) or die "remote file open failed";

	    my $content = $request->content;
	    while (length $content) {
		my $bytes = $sftp->write($fh, $content) or die "remote file write failed";
                substr($content, 0, $bytes, '');
	    }

	    $sftp->close($fh) or die "remote file write failed";

	    return HTTP::Response->new(HTTP::Status::RC_OK);
	}

	# unsupported method
	return HTTP::Response->new(HTTP::Status::RC_BAD_REQUEST,
                                   "Library does not allow method $method for 'sftp:' URLs");
    };

    if ($@) {
	my $error = $sftp->error;
	return HTTP::Response->new(HTTP::Status::RC_INTERNAL_SERVER_ERROR,
				   "SFTP error: $@ - $error");
    }
    return $response;
}

1;
__END__

=head1 NAME

LWP::Protocol::sftp - adds support for SFTP uris to LWP package

=head1 SYNOPSIS

  use LWP::Simple;
  my $content = get('sftp://me@myhost:29/home/me/foo/bar');


=head1 DESCRIPTION

After this module is installed, LWP can be used to access remote file
systems via SFTP.

This module is based on L<Net::SFTP::Foreign>.

The variable C<%LWP::Protocol::sftp::DEFAULTS> can be used to pass
extra arguments to Net::SFTP::Foreign methods. For instance:

  $LWP::Protocol::sftp::DEFAULTS{new} = [more => '-oBatchMode=yes'];

=head1 SEE ALSO

L<LWP> and L<Net::SFTP::Foreign> documentation. L<ssh(1)>, L<sftp(1)>
manual pages. OpenSSH web site at L<http://www.openssh.org>.

=head1 COPYRIGHT

Copyright (C) 2005, 2006, 2008, 2009, 2012 by Salvador FandiE<ntilde>o
(sfandino@yahoo.com).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
