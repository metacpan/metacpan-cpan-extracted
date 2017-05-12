#!/usr/bin/env bash

source "`dirname $0`/setup"
use Test::More
BAIL_ON_FAIL

{
  perl -MInline::Module=makestub,Foo::Bar
  ok "`[ -f lib/Foo/Bar.pm ]`" "Stub file was generated into lib"
  rm -fr lib
}

done_testing
teardown

# vim: set ft=sh:
