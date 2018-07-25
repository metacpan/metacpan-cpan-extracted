#!/usr/bin/env perl
use strict;
use warnings;

use rlib "../lib";

#========================================

use File::AddInc ();

use Test::Kantan;
use Cwd;

describe "File::AddInc->libdir(\$packName, \$fileName)", sub {

  it "should return leading part of absolute filename", sub {

    expect(File::AddInc->libdir('My::App', "/somewhere/lib/My/App.pm"))
      ->to_be("/somewhere/lib");

  };

  it "should handle relative path correctly", sub {
    expect(File::AddInc->libdir('My::App', "./My/App.pm"))
      ->to_be(Cwd::getcwd());

  };
};

done_testing();
