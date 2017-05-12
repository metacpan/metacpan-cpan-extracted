#!/usr/bin/perl -w

# Copyright 2012, 2014 Kevin Ryde

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


# rsync --verbose --daemon --no-detach --config=rsyncd.conf

use strict;

# uncomment this to run the ### lines
# use Smart::Comments;

{
  my $path = "/tmp/\n";
  print $path =~ /\/$/ ? "match\n" : "no match";
  ### $path
  # $path =~ s{/$}{}; # strip trailing slash
  $path =~ s/\/$//; # strip trailing slash
  ### $path
  exit 0;
}

{
  # directory mtime
  require LWP::Protocol::rsync;
  mkdir '/tmp/dir-mtime', 0777;
  system ('touch /tmp/dir-mtime/foo.txt');
  system ('touch /tmp/dir-mtime/bar.txt');
  system ('ls -l /tmp/dir-mtime/');
  my $t1 = LWP::Protocol::rsync::_stat_mtime('/tmp/dir-mtime');
  print "$t1\n";
  sleep 3;
  system ('echo blah >>/tmp/dir-mtime/bar.txt');
  system ('ls -l /tmp/dir-mtime/');
  my $t2 = LWP::Protocol::rsync::_stat_mtime('/tmp/dir-mtime');
  print "$t2\n";
  exit 0;
}

{
  my $url;
  # my $url = 'rsync://download.tuxfamily.org/pub/user42/quick-yes.el';
  # my $url = 'rsync://localhost:9999/top/usr/share/fluxbox/styles/Squared_blue/pixmaps/close.xpm';
  # my $url = 'rsync://localhost:9999/top/usr/share/fluxbox/styles/Squared_blue/pixmaps/copy of stick.xpm';
  # my $url = 'rsync://localhost:9999/top/so/kernel/linux-2.6.32.59/drivers/block/smart1,2.h';
  # $url = 'file:///so/kernel/linux-2.6.32.59/drivers/block/smart1%2C2.h';
  # $url = 'rsync://localhost:9999/top/so/kernel/linux-2.6.32.59/drivers/block/smart1%2C2.h';
  $url = 'rsync://localhost:9999/writeonly/dummy.txt';
  $url = 'rsync://localhost:9999/unlistable/etc/ucf.conf';
  $url = 'rsync://fred@localhost:9999/topauth/etc/ucf.conf';
  # { my $uri = URI->new('rsync://localhost:9999/top/so/');
  #   $uri->path('/top/so/kernel/linux-2.6.32.59/drivers/block/smart1,%32.h');
  #   $url = $uri->as_string;
  # }
  $url = 'rsync://[::ffff:127.0.0.1]:9999/top/etc/ucf.conf';
  $url = 'rsync://fred:abcde@localhost:9999/topauth/etc/ucf.conf';
  $url = 'rsync://:9999/top/etc/ucf.conf';
  $url = 'rsync://localhost:9999/top/so/kernel/linux-2.6.32.59/drivers/block/smart1%2C%32.h';
  $url = 'rsync://localhost:9999/top/tmp/*.txt';
  $url = 'rsync://localhost:9999/top/tmp/bar';
  $url = 'rsync://localhost:9999/top/etc/ucf.conf';
  $url = 'rsync://localhost:9999/top/tmp/x.txt';
  $url = 'rsync://fred@localhost:9999/topauth/etc/ucf.conf';
  $url = 'rsync://localhost:9999/top/tmp';  # directory

  print $url,"\n";
  require LWP::UserAgent;
  my $ua = LWP::UserAgent->new;
  $ua->add_handler('response_header' => sub { print "response_header\n"; });
  $ua->add_handler('response_data' => sub { print "response_data\n"; });

  {
    my $resp = $ua->head($url);
    print "HEAD status_line: ",$resp->status_line,"|||\n";
    print $resp->as_string;
  }
  {
    my $resp = $ua->get($url,
                        # ':content_file' => '/tmp/out.txt',
                        # ':content_cb' => sub { print "content_cb: ",$_[0]; },
                        # ':read_size_hint' => 50,
                        'If-Modified-Since' => 'Thu, 20 Mar 2014 06:39:13 GMT',
                       );
    print "GET status_line: ",$resp->status_line,"|||\n";
    print $resp->as_string;
  }
  exit 0;
}

{
  require HTTP::Response;
  my $resp = HTTP::Response->new(404, "message\nwith\nnewlines\n");
  print $resp->status_line,"\n";
  print "--\n";
  print "status line:\n";
  print $resp->as_string;
  print "--\n";
  print $resp->content;
  exit 0;
}

{
  require POSIX;
  print "can WIFEXITED", POSIX->can('WIFEXITED'), "\n";
  print "call ", POSIX::WIFEXITED(0), "\n";
  exit 0;
}

{
  # when no rsync program available
  require LWP::UserAgent;
  my $ua = LWP::UserAgent->new;
  {
    local %ENV = (%ENV, PATH => '/no/such/dir');
    my $resp = $ua->get('rsync://localhost:9999/top/etc/ucf.conf');
    print "status_line: ",$resp->status_line,"|||\n";
    print $resp->as_string;
  }
  {
    my $resp = $ua->get('rsync://localhost:9999/top/etc/ucf.conf');
    print "status_line: ",$resp->status_line,"|||\n";
    print $resp->as_string;
  }
  exit 0;
}

{
  # client side TZ gives the timezone for listing
  system ('rsync rsync://localhost:9999/top/etc/ucf.conf');
  system ('TZ=GMT+0 rsync rsync://localhost:9999/top/etc/ucf.conf');
  system ('TZ=FOO+1 rsync rsync://localhost:9999/top/etc/ucf.conf');
  exit 0;  
}

{
  # RsyncP
  require File::RsyncP;

  my $rs = File::RsyncP->new({
                              logLevel   => 1,
                              rsyncCmd   => "/bin/rsync",
                              rsyncArgs  => [
                                             "--numeric-ids",
                                             "--perms",
                                             "--owner",
                                             "--group",
                                             "--devices",
                                             "--links",
                                             "--ignore-times",
                                             "--block-size=700",
                                             "--relative",
                                             "--recursive",
                                             "-v",
                                             "-v",
                                             "-v",
                                            ],
                             });
  ### $rs
  my $host = 'localhost';
  my $port = 9999;
  my $module = 'top';
  my $authUser;
  my $authPasswd;
  my $destDirectory = 'tmp';
  my $srcFile = "/etc/ucf.conf";
  $rs->serverConnect($host, $port);
  $rs->serverService($module, $authUser, $authPasswd, 0);
  $rs->serverStart(1, ".");
  $rs->serverStart(1, $srcFile);
  $rs->go('/tmp');
  $rs->go($destDirectory);
  $rs->serverClose;

  exit 0;
}



{
  # PUT

  # rsync --checksum -vvv -i x.txt rsync://localhost:9999/writable/dummy.txt

  my $url;
  $url = 'rsync://localhost:9999/writeonly/nosuchdir/dummy.txt';
  $url = 'rsync://localhost:9999/top/tmp/dummy.txt';
  $url = 'rsync://localhost:9999/writeonly/dummy.txt';
  $url = 'rsync://localhost:9999/writable/dummy.txt';
  $url = 'rsync://localhost:9999/writable/~gg/x.txt';
  $url = 'rsync://localhost:9999/writable/[z].txt';

  my $ua = LWP::UserAgent->new;
  {
    # my $resp = $ua->put($url, Content => "hello world\n");
    my $resp = $ua->put($url, ':content_file' => '/usr/bin/rsync');
    print "PUT status_line: ",$resp->status_line,"|||\n";
    print $resp->as_string;
  }
  exit 0;
}
{
  require URI;
  my $uri = URI->new('rsync://foo:pass@localhost:9999/writable/dummy.txt');
  print "user: ``",$uri->user,"''\n";
  $uri->password(undef);
  ### password: scalar($uri->password)
  exit 0;
}


