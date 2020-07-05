#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use Carp;
use FindBin; BEGIN { do "$FindBin::Bin/t_lib.pl" }

use Test::Kantan;
use Scalar::Util qw/isweak/;

use rlib qw!../..!;

use MOP4Import::t::t_lib qw/no_error expect_script_error/;

use Capture::Tiny qw(capture);

describe "MOP4Import::Base::CLI", sub {
  describe "package MyApp1 {use ... -as_base;...}", sub {

    it "should have no error"
      , no_error q{
package MyApp1;
use MOP4Import::Base::CLI -as_base, -inc, [fields => qw/foo/];

sub cmd_bar : Doc("This prints contents of foo and also args") {
  (my MY $self, my @args) = @_;
  print join(" ", $self->{foo}, @args), "\n";
}

sub bar {
  Carp::croak("Not reached!");
}

sub qux {
  (my MY $self, my @args) = @_;
  [$self->{foo} => [@args]];
}

1;
};

    describe "MyApp1->run([--foo,bar])", sub {
      expect(capture {MyApp1->run(['--foo','bar','baz'])})->to_be("1 baz\n");
    };

    describe "MyApp1->run([--foo=ok,qux,quux])", sub {
      expect(capture {MyApp1->run(['--foo=ok','qux','quux'])})->to_be("['ok',['quux']]\n");
    };

  };

  describe "--help, -h and help()", sub {
    my $runner = sub {
      local $@;
      eval { MyApp1->run(@_); };
      $@;
    };

    expect($runner->(['--help']))->to_match(qr/^Usage: /);
    expect($runner->(['-h'], {h => 'help'}))->to_match(qr/^Usage: /);
    expect($runner->(['help']))->to_match(qr/^Usage: /);
  };

  describe "cli_... APIs", sub {

    describe "MyApp1->cli_inspector->info_command_doc_of(MyApp1, bar)", sub {
      expect(MyApp1->cli_inspector->info_command_doc_of('MyApp1', 'bar'))->to_be("This prints contents of foo and also args");
    };
  };
};

done_testing();
