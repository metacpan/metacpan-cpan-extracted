# Copyright 2012, 2013, 2014 Kevin Ryde

# This file is part of LWP-Protocol-rsync.
#
# LWP-Protocol-rsync is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# LWP-Protocol-rsync is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with LWP-Protocol-rsync.  If not, see <http://www.gnu.org/licenses/>.


# RFC 5781 rsync schema
# RFC 3986 URI general
# RFC 2518 WebDAV
# RFC 2068 HTTP 1.1
#    - reason phrase in status line can be changed without affecting protocol
# RFC 2616 HTTP 1.1
#
# cf LWP::Protocol::ftp
#    LWP::Protocol::http
#    LWP::Protocol::file


package LWP::Protocol::rsync;
use strict;
use 5.005;  # for \z
use File::Spec;
use HTTP::Date ();
use HTTP::Response;
use HTTP::Status ();
use IPC::Run;
use LWP::MediaTypes ();
use URI::Escape ();

use vars '$VERSION','@ISA';
$VERSION = 1;

use LWP::Protocol;
@ISA = ('LWP::Protocol');

# uncomment this to run the ### lines
# use Smart::Comments;


# $arg is 
#    undef -- use HTTP::Request / HTTP::Response ->content()
#    scalar -- filename
#    coderef -- func to call with data blocks of $size bytes
#
sub request {
  my($self, $request, $proxy, $arg, $size) = @_;
  $size = 4096 unless defined $size and $size > 0;

  if (defined $proxy) {
    return HTTP::Response->new(HTTP::Status::RC_BAD_REQUEST(),
                               'No proxy support for rsync');
  }

  # URI::rsync documented in URI.pm
  my $uri = $request->uri;
  ### $uri

  my $scheme = $uri->scheme;
  if ($scheme ne 'rsync') {
    return HTTP::Response->new(HTTP::Status::RC_INTERNAL_SERVER_ERROR(),
                               "URI scheme not rsync");
  }

  my $hostport = $uri->host_port;  # eg "localhost:9999"
  my $user = $uri->user;           # or undef if no "fred@" part present
  my $password = $uri->password;
  my $path = $uri->path;
  ### $path

  foreach ($hostport, $user, $password, $path) {
    if (defined $_) {
      $_ = URI::Escape::uri_unescape($_);   # mutate to undo %20 etc
    }
  }
  ### path unescaped: $path

  # wildcards bad in $path (but ok in $hostport as "[::1]" etc IPv6)
  if ($path =~ /[*?[]/) {
    return HTTP::Response->new(HTTP::Status::HTTP_NOT_IMPLEMENTED(),
                               "Characters * ? [ not allowed in path");
  }

  my $uri_str = "rsync://".(defined $user ? "$user@" : "").$hostport.$path;
  ### $uri_str

  my $method = $request->method;
  ### $method

  my $dir_listing = ($uri_str =~ m{/\z}
                     || _path_is_modules_or_root($path));
  my $content_type;
  if ($dir_listing) {
    $content_type = 'text/plain';
  }
  ### $dir_listing
  ### $content_type

  if ($method eq 'HEAD') {
    # With --no-dirs a directory sets $listing to either
    #     skipping directory foo         # no trailing /
    #     skipping directory .           # if trailing /
    # Without --no-dirs and without trailing slash is
    #     drwxrwxrwt         69,632 2014/03/26 19:18:01 tmp
    #
    # For the root directory "rsync://hostname/module/" or
    # "rsync://hostname/module" both give the full listing of the root
    # directory, not just the root "/" itself.  Use --quiet to suppress that
    # so as to check just the existence.  Likewise the module listing is
    # suppressed with --quiet.

    $uri_str =~ s{/+\z}{}; # strip trailing slashes
    ### uri strip trailing slashes: $uri_str

    my $listing;
    if (my $resp = _run_rsync($password,
                              [ 'rsync',
                                '--no-dirs',
                                (_path_is_modules_or_root($path)
                                 ? '--quiet'
                                 : ()),
                                $uri_str,   # single arg means --list-only
                              ],
                              \$listing)) {
      return $resp;
    }

    my ($perms, $length, $mtime) = _parse_listing($listing);
    ### $perms
    ### $length
    ### $mtime

    # No Content-Length for directory.  The size in the listing is the
    # directory size on disk and is not the length the GET listing will
    # give.  Could fetch the whole listing like GET to find the size, but
    # the reason for HEAD is not to do a full fetch like that.
    my $dir_listing ||= ($listing =~ /^(d|skipping directory)/);
    if ($dir_listing) {
      undef $length;
      $content_type = 'text/plain';
    }
    my $resp = HTTP::Response->new(HTTP::Status::RC_OK(),
                                   undef,
                                   [ _content_headers($length, $mtime, $content_type) ]);
    unless ($content_type) {
      LWP::MediaTypes::guess_media_type($uri, $resp->headers);
    }
    return $resp;
  }

  # If :content_file then rsync directly to or from it, otherwise a temp
  # file.
  my $temp_fh;   # if a temp file is used
  my $filename;  # either $arg or $temp_fh->filename()
  if ($arg && ! ref $arg) {
    ### arg is content_file ...
    $filename = $arg;
    # $arg = \&_content_cb_noop;
  } else {
    ### arg not a file, make a temp file ...
    require File::Temp;
    $temp_fh = File::Temp->new;
    $filename = $temp_fh->filename;
    binmode($temp_fh)
      or return HTTP::Response->new(HTTP::Status::RC_INTERNAL_SERVER_ERROR(),
                                    "Cannot binmode on $filename: $!");
  }
  ### $filename

  if ($method eq 'GET') {
    ### _path_is_modules_or_root: _path_is_modules_or_root($path)

    # No If-Modified-Since check on a directory or on the modules listing
    # "rsync://hostname/module".
    #
    if (! $dir_listing
        && defined (my $ims_str = $request->header('If-Modified-Since'))) {
      if (defined (my $ims_time = HTTP::Date::str2time($ims_str))) {
        my $listing;
        _run_rsync($password,
                   [ 'rsync', $uri_str ],   # same as HEAD above
                   \$listing);
        if (defined $listing) {  # if rsync ran successfully
          my ($perms, $length, $mtime) = _parse_listing($listing);
          ### mtime   : $mtime
          ### ims_time: $ims_time
          if (! (defined $perms && $perms =~ /^d/)  # no check of directory listing
              && defined $mtime && $mtime <= $ims_time) {
            my $resp = HTTP::Response->new (HTTP::Status::RC_NOT_MODIFIED(),
                                            undef,
                                            [ _content_headers($length, $mtime) ]);
            LWP::MediaTypes::guess_media_type($uri, $resp->headers);
            return $resp;
          }
        }
      }
    }

    my $mtime;

    if (! $dir_listing) {
      my $stdout;
      if (my $resp = _run_rsync($password,
                                [ 'rsync',
                                  '--checksum',  # no date/size quick check
                                  '-t',          # -t set destination $filename modtime
                                  '--inplace',   # write into $filename rather than renaming
                                  $uri_str,
                                  $filename ],
                                \$stdout)) {
        return $resp;
      }
      # if the path was in fact a directory then re-run to get its listing
      $dir_listing = ($stdout =~ /^skipping directory/mi);
    }

    # For non-root directory listing must have trailing slash like
    # "rsync://hostname/module/dirname/" otherwise the listing is just the
    # directory itself like
    #     "drwxrwxrwt         69,632 2014/03/26 19:38:01 tmp"
    #
    if ($dir_listing) {
      unless ($uri_str =~ m{/\z}) { $uri_str .= '/'; }
      if (my $resp = _run_rsync($password,
                                [ 'rsync', $uri_str ],
                                $filename)) {
        return $resp;
      }
      $content_type = 'text/plain';
    } else {
      $mtime = _stat_mtime($filename)
    }

    my $resp = HTTP::Response->new(HTTP::Status::RC_OK(),
                                   undef,
                                   [ _content_headers(-s $filename, $mtime, $content_type) ]);
    unless ($content_type) {
      LWP::MediaTypes::guess_media_type($uri, $resp->headers);
    }

    # If not read directly into :content_file $arg filename then collect
    # from $temp_fh into $resp.  collect() enforces max_size and has
    # some callbacks.
    #
    # FIXME: Should we worry about those for the :content_file case?  For
    # the max_size we already have the full content, would there be any
    # merit in truncating it?
    #
    if ($temp_fh) {
      my $readerr;
      $self->collect($arg, $resp, sub {
                       my $content = "";
                       my $bytes = sysread($temp_fh, $content, $size);
                       ### $bytes
                       if (! defined $bytes) {
                         $readerr = "$!";
                         return '';
                       }
                       return \$content;
                     });
      if (defined $readerr) {
        return HTTP::Response->new(HTTP::Status::RC_INTERNAL_SERVER_ERROR(),
                                   "Error reading $filename: $readerr");
      }
    }

    return $resp;
  }

  if ($method eq 'PUT') {
    ### PUT ...

    # ENHANCE-ME: Does "Content-Range" mean ->content() is only that part of
    # the data?

    if ($temp_fh) {
      if (defined (my $err = _http_message_content_to_fh($request, $temp_fh,
                                                         $filename))) {
        return HTTP::Response->new(HTTP::Status::RC_INTERNAL_SERVER_ERROR(),
                                   "Error writing $filename: $err");
      }
    }
    ### ls: system("ls -d $filename")

    if (my $resp = _run_rsync($password,
                              [ 'rsync',
                                '--checksum', # full check, not date/size quick
                                '--inplace',  # write into file, not rename
                                $filename,
                                $uri_str ])) {
      return $resp;
    }

    # Per RFC 2616 and webdav RFC 2518
    # "201 Created" is for newly created destination resource.
    # ENHANCE-ME: Supposed to be "200 OK" for existing destination modified.
    #
    return HTTP::Response->new(HTTP::Status::RC_CREATED());
  }

  return HTTP::Response->new(HTTP::Status::RC_NOT_IMPLEMENTED(),
                             "Unrecognised rsync method: $method");
}

sub _run_rsync {
  my ($password, $command_line, $stdout_ref) = @_;
  ### _run_rsync() ...
  # ### diagnostic -ivvvv: splice @$command_line, 1,0, '-ivv'

  if (! $stdout_ref) {
    my $stdout;
    $stdout_ref = \$stdout;
  }
  my $stderr;
  my $eval;
  {
    # Always set $ENV{RSYNC_PASSWORD}, to an empty string if nothing else.
    # Otherwise rsync will prompt for a password with getpass() or similar
    # (which opens and read /dev/tty).
    #
    # Does --protect-args do anything when talking to the daemon?  Turn it
    # on since certainly don't want space splitting etc.  Do this by
    # $ENV{'RSYNC_PROTECT_ARGS'} since the option is only in rsync 3.1 up.
    #
    # $ENV{'TZ'} set to GMT so that the date/time in the listing output will
    # be in GMT.  If the local timezone has any daylight savings then when
    # the clocks go back times are duplicated and so are ambiguous.
    #
    if (! defined $password) { $password = ''; }
    local %ENV = (%ENV,
                  RSYNC_PROTECT_ARGS => 1,
                  RSYNC_PASSWORD => $password,
                  TZ => 'GMT+0');

    ### $command_line
    ### RSYNC_PASSWORD: $ENV{'RSYNC_PASSWORD'}
    $eval = eval {
      IPC::Run::run ($command_line,
                     '<', File::Spec->devnull,
                     (defined $stdout_ref
                      ? ('>', $stdout_ref, '2>', \$stderr)
                      : ('>', \$stderr, '2>&1')));
      1 };
  }
  if (! $eval) {
    my $err = $@;
    return HTTP::Response->new(HTTP::Status::RC_INTERNAL_SERVER_ERROR(),
                               "Cannot run rsync program",
                               [ 'Content-Type' => 'text/plain' ],
                               $err);
  }

  # "401 Unauthorized" here applies to all rsync runs, GET, HEAD and PUT.
  my $wstat = $?;
  ### wstat: sprintf '0x%X', $wstat
  ### $stdout_ref
  ### $stderr
  if ($wstat != 0) {
    return HTTP::Response->new(($stderr =~ /\@ERROR: auth failed/
                                ? HTTP::Status::RC_UNAUTHORIZED()
                                : HTTP::Status::RC_NOT_FOUND()),
                               undef,
                               [ 'Content-Type' => 'text/plain' ],
                               join ('',
                                     "rsync program ", _wstat_str($wstat), "\n",
                                     (ref $stdout_ref && defined $$stdout_ref ? ($$stdout_ref, "\n") : ()),
                                     $stderr, "\n"));
  }

  return;
}

# POSIX::WIFEXITED() and friends either croak (Perl 5.8 up) or don't exist
# at all (5.6.x and earlier) if not available from the system.
#
sub _wstat_str {
  my ($wstat) = @_;
  require POSIX;
  if (eval { POSIX::WIFEXITED($wstat) }
      && defined (my $exit_code = eval { POSIX::WEXITSTATUS($wstat) })) {
    return "exit code $exit_code";
  }
  if (eval { POSIX::WIFSIGNALED($wstat) }
      && defined (my $signal_number = eval { POSIX::WTERMSIG($wstat) })) {
    return "signal $signal_number";
  }
  return sprintf "exit status 0x%X", $wstat;
}

# $request is a HTTP::Message.
# Write its $request->content() bytes to file handle $fh.
# If successful return undef.
# If error then return a string describing the problem.
# $filename is used in the error message.
#
sub _http_message_content_to_fh {
  my ($request, $fh, $filename) = @_;
  ### _http_message_content_to_fh() ...

  my $content = $request->content;
  if (! defined $content) {
    return "no content in request";
  }

  if (ref($content) eq 'SCALAR') {
    ### scalar ref ...
    if (print $fh $$content) {
      return;  # good
    }
    # write error

  } elsif (ref($content) eq 'CODE') {
    ### coderef ...
    for (;;) {
      my $buf = &$content();
      if (length($buf) == 0) {
        return; # good
      }
      print $fh $buf
        or last; # write error
    }

  } elsif (! ref $content) {
    ### plain scalar ...
    if (print $fh $content) {
      return;  # good
    }
    # write error

  } else {
    return "unrecognised request content()";
  }

  return "Cannot write $filename: $!";
}

# sub _content_cb_noop {
# }

# Return the mtime modification time of a filename or file handle.
sub _stat_mtime {
  my ($fh_or_filename) = @_;
  my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$filesize,
      $atime,$mtime,$ctime,$blksize,$blocks) = stat $fh_or_filename;
  return $mtime;
}

# $listing is a file info string from rsync.
# Return ($perms, $length, $mtime), possibly with undefs if parts not
# recognised.
#   $perms is a string
#   $length is an integer number
#   $mtime is a time_t number
#
# $listing is like
#   -rw-r--r--          1,260 2004/10/29 04:50:12 foo.txt
# or for a symlink
#   lrwxrwxrwx              3 2014/03/20 17:21:21 bar -> foo
#
# rsync 3.1 introduces commas as digit grouping for the size.  Or dots if
# the decimal point is not a dot in the locale.  The "k" etc abbreviations
# are confined to --human-readable so don't occur.  Code in rsync
# lib/compat.c.  Any dots or commas are removed for the returned $length.
#
# Date/time in the listing is in the client-side system timezone.
# _run_rsync() above forces it to GMT and that's how it's treated here when
# converting to time_t $mtime.
#
# rsync code in generator.c list_file_entry().
#
sub _parse_listing {
  my ($listing) = @_;
  ### $listing

  my ($perms, $length, $mtime);
  if (($perms, $length, my $mtime_str)
      = ($listing =~ m{\s*(\S+)\s+([0-9,.]+)\s+([0-9/]+ [0-9:]+)})) {
    $length =~ tr/.,//d;   # delete commas and dots
    $mtime = HTTP::Date::str2time($mtime_str, 'GMT');
  }
  return ($perms, $length, $mtime);
}

# return a list
sub _content_headers {
  my ($length, $mtime, $content_type) = @_;
  return ('Content-Length' => $length,
          (defined $mtime ? ('Last-Modified' => HTTP::Date::time2str($mtime)) : ()),
          'Content-Type' => $content_type,
          # 'X-Rsync-Perms'  => $perms,  # any good?
         );
}

# Return true if $path has no module part, hence giving a modules listing,
# or has a module part but only the root directory.
sub _path_is_modules_or_root {
  my ($path) = @_;
  return scalar($path !~ m{^/[^/]+  # module part
                           /.*
                           [^./]*   # some non-. or / means not root dir
                        }x);
}

1;
__END__

=for stopwords Ryde rsync LWP checksums URIs URI unwritable wildcards multi IPv6 hostname Username username modtime filenames Ok unescaped filename

=head1 NAME

LWP::Protocol::rsync - rsync protocol for LWP

=head1 SYNOPSIS

=for test_synopsis BEGIN { die "SKIP: don't run an rsync download"; }

 use LWP::UserAgent;
 my $ua = LWP::UserAgent->new;
 $res = $ua->get('rsync://example.com/pub/some/thing.txt');
 # (module loaded automatically)

=head1 DESCRIPTION

This module adds C<rsync://> protocol scheme to C<LWP::UserAgent> by running
the external L<rsync(1)> program.

=over

L<http://rsync.samba.org/>

=back

The rsync protocol uploads or downloads files by sending only changed file
blocks if possible.  (The receive side calculates MD4 checksums over
existing content and tells the send side what it already has.)

See RFC 5781 on the C<rsync://> schema and see the Perl L<URI> module for
manipulations of such URIs.

=over

=item *

C<GET> downloads a file from an rsync server.

If an existing C<:content_file> is specified as the local destination (see
L<LWP::UserAgent/REQUEST METHODS>) then that file is updated as necessary
per the rsync protocol.  C<GET> to an ordinary C<HTTP::Response> downloads
the full source content.

C<If-Modified-Since> is implemented by getting a listing from the server and
comparing the desired time.  The response is "304 Not Modified" in the usual
way if the server time is not newer.

C<Last-Modified> response is the modification time of the file on the
server.  For C<:content_file> the destination file modification time is set
too.

C<Content-Type> response is guessed from the URI by L<LWP::MediaTypes>.
This is slightly experimental.  The rsync server has no notion of
C<Content-Type> as such.

=item *

C<HEAD> retrieves information about a file by asking for a listing from the
server.  C<Content-Length> and C<Last-Modified> response headers are parsed
out of the listing.

=item *

C<PUT> uploads content to a file on the server.  The rsync protocol means
only changed parts of the content are actually sent.

An upload requires a writable destination on the server (see
L<rsyncd.conf(5)>).  If it's not writable then C<rsync> version 3.1.0 server
has been seen simply dropping the connection, resulting in a rather
uninformative error message "Connection reset by peer".  The intention would
be "405 Method Not Allowed" or some such if unwritable can be distinguished
from actual connection trouble.

=back

Characters C<*> C<?> C<[> are not permitted in paths.  The intention is for
this interface to access a single file resource (read or write), but
C<rsync> interprets these characters as shell style wildcards for multi-file
transfers.  IPv6 style brackets C<[::1]> in the hostname part are allowed.

The C<rsync> program has many options for things like mirroring whole
directory trees and that sort of thing is best done by running C<rsync>
directly, or perhaps the C<File::Rsync> front-end or C<File::RsyncP>
protocol.

=head2 Username and Password

Any username and password in the URI are sent to the server.  This can be
used for servers or server modules which require a username and/or password
for read or write or both.

    rsync://username:password@hostname/module/dir1/dir2/foo.txt

If the username or password is incorrect the response code is 401
"Unauthorized" in the usual way.  The server checks authorization before
other module restrictions or path existence, so expect "Unauthorized" for
anything without a valid username and password.

(The rsync program can take passwords from a file but there's nothing here
for that.)

=head2 Directory Listing

C<GET> of a directory gives the C<rsync> text listing of the files in that
directory.

    rsync://hostname/module/dir/        # for directory contents
    rsync://hostname/module/dir

The format generated by C<rsync> is a text listing like

    -rw-r--r--             24 2014/03/26 19:54:15 foo.txt
    -rw-r--r--              6 2014/03/26 19:54:15 bar.txt

C<Last-Modified> is not returned for a directory because there's no
particularly good date/time for the listing.  The directory has a modtime,
but that's just the filenames, not the dates, sizes and perms which appear
in the listing content.

C<HEAD> of a directory doesn't give a C<Content-Length> since getting that
would require getting the full listing.  "200 Ok" from C<HEAD> means the
directory exists, but no further information.

Putting a trailing C</> on an ordinary file, attempting to treat it as a
directory, currently gives a 404

    rsync://hostname/module/filename.txt/    # will be 404

=head2 Module Listing

C<GET> with no module name gives a text listing of the available modules.

    rsync://hostname/               # for modules list
    rsync://hostname

The descriptions are from the C<comment> part of F<rsyncd.conf>.

    pub             public access
    private         authorized users only
    incoming        uploads by arrangement

C<HEAD> of the module listing doesn't give a C<Content-Length> since getting
that would be the same as getting the whole listing.  There's no notion of
C<Last-Modified> for the modules list.

=head1 ENVIRONMENT VARIABLES

=over 4

=item C<TMPDIR>

Temporary directory as per C<File::Temp> and C<File::Spec> (and which
consider other which on some systems too).

In the current implementation uploading and downloading both go through a
temporary file unless given a C<:content_file> already.

=back

C<RSYNC_PASSWORD> environment variable is not used in the current
implementation.  The rationale is that this module is expected to act on
C<rsync://> URIs to various hosts so a single password is unlikely to be
useful.  Is that reasonable?

=head1 IMPLEMENTATION

The password part of a URI (C<$uri-E<gt>password()>) is extracted and passed
to the C<rsync> program in C<$ENV{'RSYNC_PASSWORD'}>.  The C<rsync://>
command line form doesn't take a password part.  C<rsync> expects either
$ENV{'RSYNC_PASSWORD'} or prompts the user (with L<getpass(3)>).  A prompt
is avoided as this interface is meant to be non-interactive.

Any C<%20> etc URL escapes are unescaped to the relevant characters since
C<rsync> doesn't take those forms in its C<rsync://> command line.  (Any any
% is a literal part of the filename.)

C<*> C<?> C<[> characters as literals in filenames probably need help from
C<rsync> itself, perhaps even on the server side.  Some C<\*> or C<[*]>
escaping can read an existing file, but will result in reading a file C<\*>
or C<[*]> if there's no C<*>.  It would be bad to read or write a wrong
file.

The C<rsync> C<--checksum> option is always used so the file contents are
compared.  Perhaps there could be some special control header to do only the
rsync "quick check" of date and size.  That would only be useful for
C<:content_file> upload or download.

Each request is a separate C<rsync> program run so there's no connection
keep-alive.  Does the rsync protocol allow connection re-use?  The
C<If-Modified-Since> implementation is two rsync runs.  Maybe the
quick-check algorithm could be asked to look at the time but not the size,
though the rsync 3.1 code in its C<unchanged_file()> suggests not.

C<File::RsyncP> could be an alternative to the C<rsync> program.  The
advantage would be "more than one way to do it" and it would be Perl-only.
But C<File::RsyncP> version 0.70 says it doesn't have the delta-transfer of
changes, and not sure whether it likes speaking to newer server versions.

It's not possible to rsync through C<ssh> here, only to an C<rsync://>
server daemon.  This corresponds to C<rsync://> on the rsync command line
meaning the daemon, and should be usual for publicly available URLs.  Would
an C<ssh> mode be of use too?

The various C<--delete> options to C<rsync> are for deleting files no longer
present when mirroring a directory.  Could it be used to delete an
individual file?  If so perhaps a C<DELETE> method could be implemented.

The directory and module listings are presented as C<text/plain> since
that's what rsync gives.  It would be possible to parse it and convert to
HTML (in the manner of C<LWP::Protocol::ftp>, though rsync itself has a
tighter grip on which part is the filename etc if strange characters or
C<-E<gt>> sequence in symlink etc.

=head1 SEE ALSO

L<LWP::UserAgent>,
L<LWP::Protocol>,
L<URI>

L<File::Rsync>,
L<File::RsyncP>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/lwp-protocol-rsync/index.html>

=head1 LICENSE

Copyright 2012, 2013, 2014 Kevin Ryde

LWP-Protocol-rsync is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

LWP-Protocol-rsync is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
LWP-Protocol-rsync.  If not, see L<http://www.gnu.org/licenses/>.

=cut
