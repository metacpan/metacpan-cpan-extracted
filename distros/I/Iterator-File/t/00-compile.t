#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 9;

BEGIN {
  use_ok( "Iterator::File" );
  use_ok( "Iterator::File::Utility" );
  use_ok( "Iterator::File::Status" );
  use_ok( "Iterator::File::State::Interface" );
  use_ok( "Iterator::File::State::TempFile" );
  use_ok( "Iterator::File::Source::Interface" );
  use_ok( "Iterator::File::Source::FlatFile" );
  use_ok( "Iterator::File" );
};

 SKIP: { 
     if(eval "use IPC::Shareable; 1") {
         ok (eval "use Iterator::File::State::IPCShareable; 1");
     } else {
         skip("Skipping 'Iterator::File::State::IPCShareable' tests as IPC::Shareable is not installed", 1);
     }
}
