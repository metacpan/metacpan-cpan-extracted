package Dendral::HTTP::Request;

use strict;
use warnings;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT = qw(

);

@EXPORT_OK = qw(

);

$VERSION = '0.1.0';

bootstrap Dendral::HTTP::Request $VERSION;

# Thread-safe
sub CLONE_SKIP { return 1; }

# Autoload methods go after =cut, and are processed by the autosplit program.
1;
__END__;

=head1 NAME

  Dendral::HTTP::Request - Perl interface for Apache request variables

=head1 SYNOPSIS

  # Mod_perl handler
  use Dendral::HTTP::Request;

  sub handler
  {
      my $r = shift;
      my $req = new Dendral::HTTP::Request($r, POST_MAX      => -1,
                                               MAX_FILES     => -1,
                                               MAX_FILE_SIZE => -1,
                                               TMP_DIR       => '/tmp');
      # Retrieve parameter, sigle value
      my $foo = $req -> param('foo');

      # Retrieve array or params
      my @foo = $req -> param('foo');

      # Retrieve all given parameters
      my $all_params_hashref = $req -> params();

      # Retrieve cookie by name
      my $bar_cookie = $req -> cookie('bar');

      # Retrieve all given cookies
      my $all_cookies_hashref = $req -> cookies();

      # Retrieve header value
      my $accept = $req -> header('Accept');

      # Retrieve all given headers
      my $all_headers_hashref = $req -> headers();

      # Get other request parameters such as host, method, query string, etc
      my $req_info = {
                       host         => $req -> host,
                       method       => $req -> method,
                       request_time => $req -> request_time,
                       the_request  => $req -> the_request,
                       protocol     => $req -> protocol,
                       unparsed_uri => $req -> unparsed_uri,
                       uri          => $req -> uri,
                       filename     => $req -> filename,
                       path_info    => $req -> path_info,
                       args         => $req -> args,
                       remote_ip    => $req -> remote_ip,
                       local_ip     => $req -> local_ip,
                       port         => $req -> port
                     };

  }

=head1 DESCRIPTION

    Dendral::HTTP::Request is a part of Dendral - fast, reliable and lightweight MVC framework.

    This module is very similar to well-known Apache::Request.

=head1 METHODS

=head2 new - Constructor

    Create a new Dendral::HTTP::Request object with an Apache request_rec object:

    my $req = new Dendral::HTTP::Request($r, POST_MAX      => -1,
                                             MAX_FILES     => -1,
                                             MAX_FILE_SIZE => -1,
                                             TMP_DIR       => '/tmp');

    MAX_POST, POST_MAX - Limit of POST request size, bytes; -1 means no limit, 0 - POST method is disabled.

    TMP_DIR, TEMP_DIR, TEMPFILE_DIR - Directory where upload files are spooled, default is /tmp.

    MAX_FILES - Limit of number of files; -1 means no limit, 0 - uploading of files is disabled.

    MAX_FILE_SIZE - Uploaded file size limit, bytes; -1 means no limit, 0 - uploading of files is disabled.

    DIE_ON_ERRORS - If set, module should die if any error occured.

=head2 param - Get request parameter(s)

    my $foo = $req -> param('foo');
    my @foo = $req -> param('foo');
    my $all_params_hashref = $req -> param();

=head2 params - Get all request parameters

    my $all_params_hashref = $req -> params();

=head2 cookie - Get request cookie(s)

    my $bar_cookie = $req -> cookie('bar');
    my @bar_cookie = $req -> cookie('bar');
    my $all_cookies_hashref = $req -> cookie();

=head2 cookies - Get all request cookies

    my $all_cookies_hashref = $req -> cookies();

=head2 header - Get request header(s)

    my $accept_header = $req -> header('Accept');
    my @accept_header = $req -> header('Accept');
    my $all_headers_hashref = $req -> header();

=head2 headers - Get all request headers

    my $all_headers_hashref = $req -> headers();

=head2 port - Get server port

    my $port = $req -> port();

=head2 host - Get server host, as set by full URI or Host

    my $host = $req -> host();

=head2 protocol - Get protocol, as given to Apache, or HTTP/0.9

    my $protocol = $req -> protocol();

=head2 method - Get request method: GET, HEAD, POST, etc.

    my $method = $req -> method();

=head2 args - Get query string arguments

    my $query_string_args = $req -> args();

=head2 path_info - Path part

    my $path_info = $req -> path_info();

=head2 filename - filename if found, otherwise undef

    my $filename = $req -> filename();

=head2 uri - the path portion of the URI

    my $uri = $req -> uri();

=head2 unparsed_uri - The URI without any parsing performed

    my $unparsed_uri = $req -> unparsed_uri();

=head2 the_request -  First line of request

    my $the_request = $req -> the_request();

=head2 request_time - Time, when the request started

    my $request_time = $req -> request_time();

=head2 local_ip - Get local (server) IP address

    my $local_ip = $req -> local_ip();

=head2 remote_ip - Get remote IP address

    my $remote_ip = $req -> remote_ip();

=head2 raw - Get raw request data

    my $raw_post_data = $req -> raw();

=head2 file - Get uploaded file(s) info by input name. 

    my $file = $req -> file('upload_file');
    my @files = $req -> file();

    my $file_name      = $file -> {'file_name'};
    my $tmp_name       = $file -> {'tmp_name'};
    my $full_filename  = $file -> {'full_filename'};
    my $filesize       = $file -> {'filesize'};
    my $content_type   = $file -> {'content_type'};
    my $content_tr_enc = $file -> {'content_transfer_encoding'};

=head1 EXAMPLES

    See file examples/Mytest.pm

=head1 AUTHOR

Andrei V. Shetuhin (reki@reki.ru)

=head1 SEE ALSO

perl(1), Apache(3), Apache::Request(3)

=head1 WEBSITE

http://dendral.havoc.ru/en/ - in English

http://dendral.havoc.ru/    - for Russian speakers

=head1 LICENSE

 Copyright (c) 2005 - 2011 CAS Dev Team
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
 4. Neither the name of the CAS Dev. Team nor the names of its contributors
    may be used to endorse or promote products derived from this software
    without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED.  IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

=cut

