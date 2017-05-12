#!/usr/bin/perl -w

# Copyright 2011 Kevin Ryde

# This file is part of Image-Base-Tk.
#
# Image-Base-Tk is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# Image-Base-Tk is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Image-Base-Tk.  If not, see <http://www.gnu.org/licenses/>.

use 5.006;
use strict;
use warnings;
use Test::More;
use Tk;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

diag "Tk version ", Tk->VERSION;

my $mw;
eval { $mw = MainWindow->new }
  or plan skip_all => "due to no display -- $@";

eval { require Module::Util; 1 }
  or plan skip_all => "due to Module::Util not available -- $@";

if (! Module::Util::find_installed('Tk::CanvasFig')) {
  plan skip_all => "due to Tk::CanvasFig not available";
}

plan tests => 5;

require Image::Base::Tk::Canvas;
diag "Image::Base version ", Image::Base->VERSION;


#------------------------------------------------------------------------------
# save() as "fig"

my $test_filename = 'testfile.tmp';

{
  my $image = Image::Base::Tk::Canvas->new (-for_widget => $mw,
                                            -width  => 2,
                                            -height => 1,
                                            -file_format => "fig");
  $image->xy (0,0, '#FFFFFF');
  $image->xy (1,0, '#000000');

  unlink $test_filename;
  $image->save($test_filename);

  ok (-e $test_filename, "save() fig target file exists");
  cmp_ok (-s $test_filename, '>', 0, "save() fig target file not empty");
  is ($image->get('-file'), $test_filename, "save() fig sets -file");
}


#------------------------------------------------------------------------------
# save() to no such dir

{
  my $bad_filename = 'no/such/directory/testfile.tmp';
  unlink $test_filename;

  my $image = Image::Base::Tk::Canvas->new (-for_widget => $mw,
                                            -width  => 2,
                                            -height => 1,
                                            -file_format => "fig");
  $image->xy (0,0, '#FFFFFF');
  my $eval = eval {
    $image->save($bad_filename);
    1;
  };
  is ($eval, undef,
      "save() fig bad filename throw error");
  is ($image->get('-file'), $bad_filename,
      "save() fig bad filename still sets -file");
}


#------------------------------------------------------------------------------

unlink $test_filename;
exit 0;
