#!/usr/bin/perl -w

# Copyright 2010, 2011 Kevin Ryde

# This file is part of Image-Base-Prima.
#
# Image-Base-Prima is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Prima is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Prima.  If not, see <http://www.gnu.org/licenses/>.

use 5.005;
use strict;
use Test;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

# uncomment this to run the ### lines
#use Smart::Comments;

use Prima::noX11; # without connecting to the server
use Prima;
MyTestHelpers::diag ("Prima version ",Prima->VERSION);

my $test_count = (tests => 17)[1];
plan tests => $test_count;

{
  my $d = Prima::Image->new;
  my $codecs = $d->codecs;
  MyTestHelpers::diag ("codecs: ",
                       join(' ',map {$_->{'fileShortType'}} @$codecs));

  my $have_png = 0;
  foreach my $codec (@$codecs) {
    if ($codec->{'fileShortType'} eq 'PNG') {
      $have_png = 1;
    }
  }
  if (! $have_png) {
    foreach (1 .. $test_count) {
      skip ('due to no PNG codec', 1, 1);
    }
    exit 0;
  }
}

require Image::Base::Prima::Image;

#------------------------------------------------------------------------------
# load() errors

my $filename = 'tempfile.png';
MyTestHelpers::diag ("Tempfile ", $filename);
unlink $filename;
ok (! -e $filename, 1, "removed any existing $filename");
END {
  if (defined $filename) {
    MyTestHelpers::diag ("Remove tempfile ",$filename);
    unlink $filename
      or MyTestHelpers::diag ("Oops, cannot remove $filename: $!");
  }
}

{
  my $eval_ok = 0;
  my $ret = eval {
    my $image = Image::Base::Prima::Image->new
      (-file => $filename);
    $eval_ok = 1;
    $image
  };
  my $err = $@;
  MyTestHelpers::diag ("new() error [expected] is \"",$err,"\"");
  ok ($eval_ok, 0, 'new() error for no file - doesn\'t reach end');
  ok ($ret, undef, 'new() error for no file - return undef');
  ok (!! scalar($err =~ /^Cannot/), 1,
      'new() error for no file - error string "Cannot"');
}
{
  my $eval_ok = 0;
  my $image = Image::Base::Prima::Image->new;
  my $ret = eval {
    $image->load ($filename);
    $eval_ok = 1;
    $image
  };
  my $err = $@;
  MyTestHelpers::diag ("load() error [expected] is \"",$err,"\"");
  ok ($eval_ok, 0, 'load() error for no file - doesn\'t reach end');
  ok ($ret, undef, 'load() error for no file - return undef');
  ok (!! scalar($err =~ /^Cannot/), 1,
      'load() error for no file - error string "Cannot"');
}

#-----------------------------------------------------------------------------
# save() errors

if (eval { Prima->VERSION(1.29); 1 }) {
  my $eval_ok = 0;
  my $nosuchdir = 'no/such/directory/foo.png';
  my $image = Image::Base::Prima::Image->new (-width => 1,
                                              -height => 1);
  my $ret = eval {
    $image->save ($nosuchdir);
    $eval_ok = 1;
    $image
  };
  my $err = $@;
  MyTestHelpers::diag ("save() error [expected] is \"",$err,"\"");
  ok ($eval_ok, 0, 'save() error for no dir - doesn\'t reach end');
  ok ($ret, undef, 'save() error for no dir - return undef');
  ok (!! scalar($err =~ /^Cannot/), 1,
      'save() error for no dir - error string "Cannot"');
} else {
  skip (1,0,0, 'due to save() segvs before Prima 1.29, have only'.Prima->VERSION);
  skip (1,0,0, 'due to save() segvs before Prima 1.29, have only'.Prima->VERSION);
  skip (1,0,0, 'due to save() segvs before Prima 1.29, have only'.Prima->VERSION);
}


#------------------------------------------------------------------------------
# save() / load()

{
  my $prima_image = Prima::Image->new (width => 10, height => 10);
  my $image = Image::Base::Prima::Image->new (-drawable => $prima_image);
  $image->save ($filename);
  ok (-e $filename, 1, "save() to $filename");
}
{
  my $image = Image::Base::Prima::Image->new (-file => $filename);
  ok ($image->get('-file_format'), 'PNG',
     'load() with new(-file)');
}
{
  my $image = Image::Base::Prima::Image->new;
  $image->load ($filename);
  ok ($image->get('-file_format'), 'PNG',
      'load() method');
}

#------------------------------------------------------------------------------
# save -file_format

{
  my $prima_image = Prima::Image->new (width => 10, height => 10);
  my $image = Image::Base::Prima::Image->new (-drawable => $prima_image,
                                              -file_format => 'png');
  $image->save ($filename);
  ok (-e $filename, 1);
}
{
  my $image = Image::Base::Prima::Image->new (-file => $filename);
  ok ($image->get('-file_format'), 'PNG',
      'written to explicit -file_format not per extension');
}

#------------------------------------------------------------------------------
# save_fh()

{
  my $image = Image::Base::Prima::Image->new (-width => 1, -height => 1,
                                              -file_format => 'png');
  unlink $filename;
  open OUT, "> $filename" or die;
  $image->save_fh (\*OUT);
  close OUT or die;
  ok (-s $filename > 0, 1, 'save_fh() not empty');
}

#------------------------------------------------------------------------------
# load_fh()

{
  my $image = Image::Base::Prima::Image->new;
  open IN, "< $filename" or die;
  $image->load_fh (\*IN);
  close IN or die;
  ok ($image->get('-file_format'), 'PNG',
      'load_fh() -file_format');
}

exit 0;
