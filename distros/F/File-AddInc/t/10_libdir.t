#!/usr/bin/env perl
use strict;
use warnings;

use rlib "../lib";

#========================================

use File::AddInc ();

use Test::Kantan;
use File::Spec;
use Cwd;

describe "File::AddInc->libdir(\$packName, \$fileName)", sub {

  it "should return leading part of absolute filename", sub {

    expect(File::AddInc->libdir('My::App', "/somewhere/lib/My/App.pm"))
      ->to_be(File::Spec->rel2abs("/somewhere/lib")); #rel2abs used for compatibility with Windows

  };

  it "should handle relative path correctly", sub {
    expect(File::AddInc->libdir('My::App', "./My/App.pm"))
      ->to_be(File::Spec->canonpath(Cwd::getcwd())); #canonpath used for compatibility with Windows

  };
};

done_testing();
