#!/usr/bin/perl -w

# Copyright 2014 Kevin Ryde

# This file is part of LWP-Protocol-rsync.
#
# LWP-Protocol-rsync is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# LWP-Protocol-rsync is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with LWP-Protocol-rsync.  If not, see <http://www.gnu.org/licenses/>.


require 5;
use strict;
use Test;
plan tests => 218;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

use FindBin;
use File::Spec;
use File::Slurp;
use IPC::Run;
use LWP::UserAgent;
use POSIX ();
use Taint::Util;
use File::chdir;
  
# uncomment this to run the ### lines
# use Smart::Comments;

my $conf_filename = File::Spec->catfile($FindBin::Bin, 'rsyncd-test.conf');
untaint($conf_filename);

# for exec
untaint($ENV{'PATH'});
delete @ENV{qw(IFS CDPATH ENV BASH_ENV)};
# $ENV{'PATH'} = '/bin:/usr/bin';

MyTestHelpers::diag ("conf_filename ", $conf_filename);
my $h;
# rsync -vvv --daemon --no-detach --config=rsyncd-test.conf
{
  local $CWD = $FindBin::Bin;
  $h = IPC::Run::start(['rsync',
                        '-vvv',  # verbosity
                        '--daemon',
                        '--no-detach',
                        "--config=$conf_filename"
                       ],
                       '<', File::Spec->devnull,
                       '>', '/dev/tty',
                       '2>&1',
                      );
}
sleep 1;

END {
  if ($h) {
    MyTestHelpers::diag ("kill rsync daemon");
    $h->signal('INT');
    $h->finish();
    undef $h;
  }
}

my $ua = LWP::UserAgent->new;
my $rsyncd_test_html_str = "<html><body>\nhello\n</body></html>";
File::Slurp::write_file('/tmp/rsyncd-test.html', $rsyncd_test_html_str);
File::Slurp::write_file('/tmp/rsyncd-motd.txt', "this is a message today\n");

my $enoent_str = POSIX::strerror(POSIX::ENOENT());


#------------------------------------------------------------------------------
# HEAD of directory
# 200 Ok but no info

foreach my $url ('rsync://localhost:9999/top/tmp',
                 'rsync://localhost:9999/top/tmp/',
                ) {
  MyTestHelpers::diag ("HEAD of a directory ", $url);
  my $resp = $ua->head($url);
  ok ($resp->code, 200);
  ok ($resp->header('Content-Type'), 'text/plain');
  ok ($resp->header('Last-Modified'), undef);
  ok ($resp->header('Content-Length'), undef);
}

#------------------------------------------------------------------------------
# HEAD of root directory
# 200 Ok but no info

foreach my $url ('rsync://localhost:9999/top',
                 'rsync://localhost:9999/top/',
                ) {
  MyTestHelpers::diag ("HEAD of a directory ", $url);
  my $resp = $ua->head($url);
  ok ($resp->code, 200);
  ok ($resp->header('Content-Type'), "text/plain");
  ok ($resp->header('Last-Modified'), undef);
  ok ($resp->header('Content-Length'), undef);
  ok ($resp->content, "");
  # MyTestHelpers::diag ($resp->as_string);
}

#------------------------------------------------------------------------------
# GET or HEAD of .png

{
  my $last_modified = HTTP::Date::time2str(LWP::Protocol::rsync::_stat_mtime('/usr/share/pixmaps/debian-logo.png'));
  my $resp = $ua->head('rsync://localhost:9999/top/usr/share/pixmaps/debian-logo.png');
  ok ($resp->code, 200);
  ok ($resp->content_type, "image/png");
  ok ($resp->header('Content-Length'), -s '/usr/share/pixmaps/debian-logo.png');
  ok ($resp->header('Last-Modified'), $last_modified);
  ok ($resp->content, "");
}
{
  my $last_modified = HTTP::Date::time2str(LWP::Protocol::rsync::_stat_mtime('/usr/share/pixmaps/debian-logo.png'));
  my $resp = $ua->get('rsync://localhost:9999/top/usr/share/pixmaps/debian-logo.png');
  ok ($resp->code, 200);
  ok ($resp->content_type, "image/png");
  ok ($resp->header('Content-Length'), -s '/usr/share/pixmaps/debian-logo.png');
  ok ($resp->header('Last-Modified'), $last_modified);
  ok ($resp->content, File::Slurp::slurp('/usr/share/pixmaps/debian-logo.png'));
}

#------------------------------------------------------------------------------
# GET or HEAD of directory which is actually a file

foreach my $method ('get','head') {
  my $resp = $ua->$method('rsync://localhost:9999/top/rsyncd-test.html/');
  ok ($resp->code, 404, "$method() on dir actually a file");
  ok ($resp->header('Content-Type'), 'text/plain');
  ok ($resp->content =~ /\Q$enoent_str/, 1);
  MyTestHelpers::diag ($resp->as_string);
}

#------------------------------------------------------------------------------
# HEAD no such directory

{
  my $resp = $ua->head('rsync://localhost:9999/top/no/such/dir/dummy.html');
  # MyTestHelpers::diag ($resp->as_string);
  ok ($resp->code, 404);
  ok ($resp->header('Content-Type'), 'text/plain');
  ok ($resp->content =~ /\Q$enoent_str/, 1);
}

#------------------------------------------------------------------------------
# GET and HEAD strange filenames

foreach my $filename ("\n",
                      " ",
                      ",",
                      "\\",
                      "\\nnn\\t",
                      "\\.txt",
                      "%") {
  MyTestHelpers::diag ("filename ", $filename);
  my $content = rand()."\n";
  $content x= int(rand(10));
  File::Slurp::write_file("/tmp/$filename", $content);
  require LWP::Protocol::rsync;
  my $last_modified = HTTP::Date::time2str(LWP::Protocol::rsync::_stat_mtime("/tmp/$filename"));
  my $url = 'rsync://localhost:9999/top/tmp/'.URI::Escape::uri_escape($filename);
  MyTestHelpers::diag ("URL ", $url);
  {
    my $resp = $ua->get($url);
    ok ($resp->code, 200, "filename '$filename'");
    # ok ($resp->header('Content-Type'), undef);
    ok ($resp->header('Content-Length'), length($content));
    ok ($resp->header('Last-Modified'), $last_modified);
    ok ($resp->content, $content);
  }
  {
    my $resp = $ua->head($url);
    ok ($resp->code, 200, "filename '$filename'");
    # ok ($resp->header('Content-Type'), undef);
    ok ($resp->header('Content-Length'), length($content));
    ok ($resp->header('Last-Modified'), $last_modified);
    ok ($resp->content, "");
  }
}

#------------------------------------------------------------------------------
# GET of root directory listing

foreach my $url ('rsync://localhost:9999/top',
                 'rsync://localhost:9999/top/',
                ) {
  MyTestHelpers::diag ("GET of root directory ", $url);
  my $resp = $ua->get($url);
  my $content = $resp->content;
  ok ($resp->code, 200);
  ok ($resp->header('Content-Type'), 'text/plain');
  ok ($resp->header('Content-Length'), length($content));
  ok ($resp->header('Last-Modified'), undef);
  ok ($content =~ /^drwx.*\.\n/, 1); # directory entry for "."
  ok ($content =~ /etc/, 1);
  ok ($content =~ /opt/, 1);
  ok ($content =~ /usr/, 1);
  MyTestHelpers::diag ($resp->as_string);
}

#------------------------------------------------------------------------------
# GET with If-Modified-Since

{
  MyTestHelpers::diag ("If-Modified-Since");
  require HTTP::Date;
  require LWP::Protocol::rsync;
  my $mtime = LWP::Protocol::rsync::_stat_mtime('/tmp/rsyncd-test.html');
  my $last_modified_str = HTTP::Date::time2str($mtime);
  my $content_length = -s '/tmp/rsyncd-test.html';

  foreach my $offset (0, 1) {
    my $ims_str = HTTP::Date::time2str($mtime + $offset);
    my $resp = $ua->get('rsync://localhost:9999/top/tmp/rsyncd-test.html',
                        'If-Modified-Since' => $ims_str);
    ok ($resp->code, 304); # not modified
    ok ($resp->header('Content-Type'), 'text/html');
    ok ($resp->header('Last-Modified'), $last_modified_str);
    ok ($resp->header('Content-Length'), $content_length);
    ok ($resp->content, "");
  }

  {
    my $ims_str = HTTP::Date::time2str($mtime - 1);  # an older time
    my $resp = $ua->get('rsync://localhost:9999/top/tmp/rsyncd-test.html',
                        'If-Modified-Since' => $ims_str);
    ok ($resp->code, 200);
    ok ($resp->header('Last-Modified'), $last_modified_str);
    ok ($resp->header('Content-Length'), $content_length);
    ok ($resp->header('Content-Type'), 'text/html');
    ok ($resp->content, $rsyncd_test_html_str);
  }
}

#------------------------------------------------------------------------------
# GET of directory listing

mkdir '/tmp/rsyncd-test-dir';
File::Slurp::write_file('/tmp/rsyncd-test-dir/abcd.txt', "this is abcd\n");
File::Slurp::write_file('/tmp/rsyncd-test-dir/efgh.txt', "not empty\n");

foreach my $url ('rsync://localhost:9999/top/tmp/rsyncd-test-dir',
                 'rsync://localhost:9999/top/tmp/rsyncd-test-dir/',
                ) {
  MyTestHelpers::diag ("GET of a directory ", $url);
  my $resp = $ua->get($url);
  my $content = $resp->content;
  ok ($resp->code, 200);
  ok ($resp->header('Content-Type'), 'text/plain');
  ok ($resp->header('Content-Length'), length($content));
  ok ($resp->header('Last-Modified'), undef);
  ok ($content =~ /^drwx.*\.\n/, 1); # directory entry for "."
  ok ($content =~ /abcd/, 1);
  ok ($content =~ /efgh/, 1);
  MyTestHelpers::diag ($resp->as_string);
}

#------------------------------------------------------------------------------
# GET of modules listing

foreach my $url ('rsync://localhost:9999',
                 'rsync://localhost:9999/',
                ) {
  MyTestHelpers::diag ("GET of modules listing ", $url);
  my $resp = $ua->get($url);
  my $content = $resp->content;
  ok ($resp->code, 200);
  ok ($resp->header('Content-Type'), 'text/plain');
  ok ($resp->header('Content-Length'), length($content));
  ok ($resp->header('Last-Modified'), undef);
  ok ($content =~ /^top\s/, 1);
  MyTestHelpers::diag ($resp->as_string);
}

#------------------------------------------------------------------------------
# HEAD of text file

{
  my $resp = $ua->head('rsync://localhost:9999/top/tmp/rsyncd-test.html');
  ok ($resp->code, 200);
  ok ($resp->header('Last-Modified'),
      HTTP::Date::time2str(LWP::Protocol::rsync::_stat_mtime('/tmp/rsyncd-test.html')));
  ok ($resp->header('Content-Length'), -s '/tmp/rsyncd-test.html');
  ok ($resp->header('Content-Type'), "text/html");
  ok ($resp->content, "");
}

#------------------------------------------------------------------------------
# HEAD of modules listing
# 200 Ok but no info

foreach my $url ('rsync://localhost:9999',
                 'rsync://localhost:9999/',
                ) {
  MyTestHelpers::diag ("HEAD of modules listing ", $url);
  my $resp = $ua->head($url);
  ok ($resp->code, 200);
  ok ($resp->header('Content-Type'), "text/plain");
  ok ($resp->header('Content-Length'), undef);
  ok ($resp->header('Last-Modified'), undef);
  ok ($resp->content, "");
}

#------------------------------------------------------------------------------
# GET with user and password

foreach my $method ('get','put','head') {
  MyTestHelpers::diag ("$method  bad username/password");
  {
    # with no password
    my $resp = $ua->$method('rsync://fred@localhost:9999/topauth/tmp/rsyncd-test.html');
    ok ($resp->code, 401, "$method() no password");  # Unauthorized
    ok ($resp->header('Content-Type'), 'text/plain');
    if ($resp->code != 401) {
      MyTestHelpers::diag ($resp->as_string);
    }
  }
  {
    # with wrong password
    my $resp = $ua->$method('rsync://fred:zzz@localhost:9999/topauth/tmp/rsyncd-test.html');
    ok ($resp->code, 401, "$method() wrong password");  # Unauthorized
    ok ($resp->header('Content-Type'), 'text/plain');
    if ($resp->code != 401) {
      MyTestHelpers::diag ($resp->as_string);
    }
  }
}
{
  # GET with correct password
  my $resp = $ua->get('rsync://fred:abcde@localhost:9999/topauth/tmp/rsyncd-test.html');
  ok ($resp->code, 200, "GET with correct password");
  if ($resp->code != 200) {
    MyTestHelpers::diag ($resp->as_string);
  }
  ok ($resp->header('Content-Type'), "text/html");
  ok ($resp->content, $rsyncd_test_html_str);
}

#------------------------------------------------------------------------------
# PUT to unwritable, fails

foreach my $module ('top') {
  my $content = 'something uploaded';
  unlink('/test-upload.txt');
  die if -e '/test-upload.txt';
  my $resp = $ua->put("rsync://localhost:9999/$module/test-upload.txt",
                      Content => $content);
  MyTestHelpers::diag ("PUT to read-only");
  MyTestHelpers::diag ($resp->as_string);
  ok ($resp->code != 201, 1);  # not Created
  ok ($resp->header('Content-Type'), 'text/plain');
}

#------------------------------------------------------------------------------
# HEAD no hostname
#
# "rsync rsync:///module/path/foo.txt" gives error
#     rsync: getaddrinfo:  873: Name or service not known
# which is just a 404 for now

{
  my $resp = $ua->head('rsync:///top/foo.txt');
  ok ($resp->code, 404);
  ok ($resp->header('Content-Type'), "text/plain");
}

#------------------------------------------------------------------------------
# PUT to writable

foreach my $module ('writable','writeonly') {
  my $content = 'something uploaded';
  unlink('/test-upload.txt');
  die if -e '/test-upload.txt';
  my $resp = $ua->put("rsync://localhost:9999/$module/test-upload.txt",
                      Content => $content);
  ok ($resp->code, 201);  # Created
  ok (File::Slurp::slurp('/tmp/test-upload.txt'), $content);
}

#------------------------------------------------------------------------------
# GET from writeonly fails

foreach my $method ('get','head') {
  foreach my $module ('writeonly','topauth') {
    my $resp = $ua->$method("rsync://localhost:9999/$module/tmp/rsyncd-test.html");
    ok ($resp->code != 200, 1);  # not Ok
    ok ($resp->header('Content-Type'), "text/plain");
    MyTestHelpers::diag ($resp->as_string);
  }
}

#------------------------------------------------------------------------------
# bad port number

{
  my $resp = $ua->head('rsync://localhost:0/nosuchport/foo.txt');
  ok ($resp->code, 404);
  ok ($resp->header('Content-Type'), "text/plain");
  ok ($resp->content =~ /Connection refused/, 1);
  unless ($resp->content =~ /Connection refused/) {
    MyTestHelpers::diag ($resp->as_string);
  }
}

#------------------------------------------------------------------------------
# bad module name

{
  my $resp = $ua->head('rsync://localhost:9999/nosuchmodule/foo.txt');
  # MyTestHelpers::diag ($resp->as_string);
  ok ($resp->code, 404);
  ok ($resp->header('Content-Type'), "text/plain");
  ok ($resp->content =~ /Unknown module/, 1);
}

#------------------------------------------------------------------------------
# GET various

# expecting success
foreach my $url ('rsync://localhost:9999/top/tmp/rsyncd-test.html',
                 'rsync://[::ffff:127.0.0.1]:9999/top/tmp/rsyncd-test.html',

                 # FIXME: is explicit ip6 supposed to work?
                 # 'rsync://[::ffff:127.0.0.1]:9999/top-v6/tmp/rsyncd-test.html',
                ) {
  my $resp = $ua->get($url);
  ok ($resp->code, 200, "URL $url");
  ok ($resp->content, $rsyncd_test_html_str);
  ok ($resp->header('Content-Type'), "text/html");
}

# expecting failure
foreach my $url ('rsync://localhost:9999/top-v6/tmp/rsyncd-test.html',
                ) {
  MyTestHelpers::diag ("URL ",$url);
  my $resp = $ua->get($url);
  ok ($resp->code, 404, "no fetch $url");
  ok ($resp->header('Content-Type'), "text/plain");
}

foreach (1, 2) {
  my $resp = $ua->get('rsync://localhost:9999/top/tmp/rsyncd-test.html',
                      ':content_file' => "/tmp/rsyncd-test-out.txt");
  ok ($resp->code, 200);
  ok ($resp->header('Content-Type'), "text/html");
  ok (File::Slurp::slurp("/tmp/rsyncd-test-out.txt"), $rsyncd_test_html_str);
}

#------------------------------------------------------------------------------
# wildcards in filenames Not Implemented

foreach my $filename ("*",   # wilds not supported
                      "\\*",
                      "[",
                      "?",
                     ) {
  MyTestHelpers::diag ("filename ", $filename);
  my $content = rand()."\n";
  { open my $fh, ">/tmp/$filename" or die;
    print $fh $content;
    close $fh or die;
  }
  my $url = 'rsync://localhost:9999/top/tmp/'.URI::Escape::uri_escape($filename);
  MyTestHelpers::diag ("url ", $url);
  my $resp = $ua->get($url);
  ok ($resp->code, 501,  # Not Implemented
      "filename $filename URL $url");
}

# # no fetch x* when x[*] exists
# {
#   mkdir '/tmp/xstar';
#   open my $fh, '>/tmp/xstar/x[*]' or die;
#   print $fh "X bracket star\n";
#   close $fh or die;
# }
# {
#   my $resp = $ua->get('rsync://localhost:9999/top/tmp/xstar/x*');
#   MyTestHelpers::diag ($resp->as_string);
#   ok ($resp->code, 404);
#   ok ($resp->content =~ /\Q$enoent_str/, 1);
# }

#------------------------------------------------------------------------------
exit 0;

# $url = 'rsync://fred@localhost:9999/topauth/etc/ucf.conf';
