#!/usr/bin/perl -w

# Copyright 2011, 2012 Kevin Ryde

# This file is part of Image-Base-Wx.
#
# Image-Base-Wx is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Wx is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Wx.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use Wx;

# uncomment this to run the ### lines
use Smart::Comments;

{
  my $app = Wx::SimpleApp->new;
  Wx::InitAllImageHandlers();

  require "devel/LogCapture.pm";
  require "devel/LogSaver.pm";
  my $log = Wx::Perl::LogCapture->new;

  {
    my $logsaver = Wx::Perl::LogSaver->new($log);

    # $wximage->SaveFile('/tmp/x/x.png',Wx::wxBITMAP_TYPE_PNG());
    # system ('ls -l /tmp');

    my $wximage = Wx::Image->new(10,10);
    $wximage->LoadFile('/tmp/nosuch.png',Wx::wxBITMAP_TYPE_PNG());
    Wx::LogError('my message');
  }

  ### pending: $log->HasPendingMessages
  ### content: $log->content

  $app->MainLoop;
  exit 0;


  # require IO::String;
  # my $fh = IO::String->new;
  # my $log = Wx::LogStream->new($fh);
}

{

  # my ($log,$tmpfh,$guard) = _logtmpfile();
  # my $good = $wximage->LoadFile($filename,$type);
  # undef $guard;
  # undef $log;
  # if ($good) {
  #   $self->{'-file_format'} = $file_format;
  #   return;
  # }
  # # my $err = _slurp($tmpfh) || ("Cannot load file ".$filename);
  # # ### $err

  sub _logtmpfile {
    require File::Temp;
    require Scope::Guard;
    my $fh = File::Temp->new;
    my $log = Wx::LogStderr->new($fh);
    my $oldlog = Wx::Log::SetActiveTarget($log);
    my $guard = Scope::Guard->new(sub { Wx::Log::SetActiveTarget($oldlog) });
    return ($log, $fh, $guard);
  }
  sub _slurp {
    my ($fh) = @_;
    seek $fh, 0, 0;
    return do { local $/; <$fh> }; # slurp
  }

}
