#!/usr/bin/env  perl
use strict;

our $JAVAPERL;
BEGIN{
  use File::Basename;
  use Env::Path;
  my $fconfig=dirname($0);
  $JAVAPERL= Env::Path->JAVAPERL;
  $JAVAPERL->Assign("$fconfig/javaperldir");
}

use Test::More tests => 5;
use File::Temp qw(tempdir);
use_ok('Dynamic::Loader' );

my @list=Dynamic::Loader::listScripts();
warn "@list";
ok(scalar(@list)==4, "check total number of scripts");

@list=Dynamic::Loader::listScripts('aaa*.pl');
warn "@list" if $ENV{DEBUG};
ok(scalar(@list)==3, 'check number of scripts with pattern aaa*.pl');


@list=Dynamic::Loader::listScripts('*-x.pl');
warn "@list" if $ENV{DEBUG};
ok(scalar(@list)==2, 'check number of scripts with pattern *-x.pl');

@list=Dynamic::Loader::listScripts();
warn "@list" if $ENV{DEBUG};
ok(scalar(@list)==4, "check total number of scripts");
