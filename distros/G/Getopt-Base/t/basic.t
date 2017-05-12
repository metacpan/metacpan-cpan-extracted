#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;

use Getopt::Base;

# sanity-check check
{
  eval {
    Getopt::Base->new(
      positional => [qw(input)],
      options => [],
    );
  };
  like($@, qr/positional 'input' is not an option/);
}
########################################################################

# empty option set, '--' termination
{
  my $go = Getopt::Base->new();
  ok($go);
  {
    my @arg = (1..3);
    my $o = $go->process(\@arg);
    ok($o);
    is_deeply(\@arg, [1..3], 'no options');
  }
  {
    my @arg = ('--', '--foo');
    $go->process(\@arg);
    is_deeply(\@arg, ['--foo'], '--');
  }
  {
    my @arg = (7, '--', '--foo');
    $go->process(\@arg);
    is_deeply(\@arg, [7, '--foo'], '--');
  }
}
########################################################################

# simple setup, positional support
{
  my $go = Getopt::Base->new(
    positional => [qw(input)],
    options => [
      input => {
        type => 'string',
      },
    ],
  );
  foreach my $set (
    ['--input', 'foo', 'bar'],
    ['foo', 'bar'],
    ['bar', '--input', 'foo'],
    ['foo', '--', 'bar'],
  ) {
    my @arg = @$set;
    my $o = $go->process(\@arg);
    is($o->input, 'foo', 'got --input');
    is_deeply(\@arg, ['bar']);
  }
}
########################################################################
# more with positionals
{
  my $go = Getopt::Base->new(
    positional => [qw(input output)],
    options => [
      input  => { type => 'string', },
      output => { type => 'string', },
    ],
  );
  {
    my @args = qw(foo bar);
    my $o = $go->process(\@args);
    is($o->input, 'foo');
    is($o->output, 'bar');
    is(scalar @args, 0);
  }
  {
    my @args = qw(foo);
    my $o = $go->process(\@args);
    is($o->input, 'foo');
    ok(! exists($o->{output}), 'no output key');
    is($o->output, undef);
    is(scalar @args, 0);
  }
}
########################################################################

# aliases, shortening
{
  my $go = Getopt::Base->new(
    positional => [qw(input)],
    options => [
      input => {
        aliases => ['something_something', 'extra_sausages'],
        short => ['q', 'r', 's'],
        type => 'string',
      },
    ],
  );
  foreach my $try (
    [qw(--input foo 42)],
    [qw(--in foo 42)],
    [qw(42 --something-something foo)],
    [qw(42 --extra-sausages foo)],
    [qw(--ex foo 42)],
    [qw(42 -q foo)],
    [qw(-q foo 42)],
    [qw(-r foo 42)],
    [qw(-s foo 42)],
    ) {
    my @pass = @$try;
    my $o = $go->process(\@pass);
    is($o->input, 'foo');
    is_deeply(\@pass, [42]);
  }
  my @args = qw(foo 42);
  my $o = $go->process(\@args);
  is($o->input, 'foo');
  is_deeply(\@args, [42]);
}
########################################################################

# boolean on/off
{
  my $go = Getopt::Base->new();
  $go->add_option(verbose => short => ['v'], default => 1);
  $go->add_aliases(no_verbose => ['q'], 'quiet', 'hush');
  foreach my $args (
    [],
    ['-v'],
    ['--verbose'],
    ['--ve'],
    ['--v'],
  ) {
    my $o = $go->process($args);
    ok($o->verbose);
  }
  foreach my $args (
    ['-q'],
    ['--hush'],
    ['--hu'],
    ['--qui'],
    ['--quiet'],
    ['--verbose', '--no-verbose'],
    ['--verbose', '--no-ve'],
  ) {
    my $o = $go->process($args);
    ok(! $o->verbose);
  }
}
########################################################################
# hashes and arrays
{
  my $go = Getopt::Base->new();
  $go->add_option(array => default => []);
  $go->add_option(also  => form => 'ARRAY');
  $go->add_option(ahash => default => {});
  my $o = $go->process([
    '--array', 'foo', '--ahash', 'x=y',
    '--array', 'y', '--ahash', 'y=x',
    '--also', 7, '--also', 8,
    '--array=bar', '--ahash=n=9',
  ]);
  is_deeply([$o->array], [foo => y => bar =>]);
  is_deeply({$o->ahash}, {x => 'y' => y => 'x', n => 9});
  is_deeply([$o->also], [7,8]);
}
########################################################################
# isa
{
  my $did_req;
  my $source = 'package xthbbt;
    no warnings "redefine"; # silly TAP::Harness -w junk
    sub new {bless [@_, 19], "xthbbt"}
    sub x {$_[0]->[1]} 1;';
  local @INC = (
    sub {
      my ($code, $mod) = @_;
      return unless($mod eq 'xthbbt.pm');
      $did_req = 1;
      open(my $fh, '<', \$source) or die $!;
      return($fh);
    },
    @INC
  );
  { # no default
    my $go = Getopt::Base->new(
      options => [xx => { type => 'string', isa => 'xthbbt' }]
    );
    my $o = $go->process(my $args = ['--xx', 'foo']);
    ok($o);
    is(scalar(@$args), 0);
    ok($did_req, 'require ok');
    is($o->xx->x, 'foo');
    delete($INC{'xthbbt.pm'});
  }
  { # simple default
    my $go = Getopt::Base->new(
      options => [xx => { type => 'string', isa => 'xthbbt',
        default => 'nnn'}]
    );
    my $o = $go->process(my $args = []);
    ok($o);
    is(scalar(@$args), 0);
    ok($did_req, 'require ok');
    is($o->xx->x, 'nnn', 'default');
    delete($INC{'xthbbt.pm'});
  }
  { # code default
    my $go = Getopt::Base->new(
      options => [xx => { type => 'string', isa => 'xthbbt',
        default => sub {'nnn'} }]
    );
    my $o = $go->process(my $args = []);
    ok($o);
    is(scalar(@$args), 0);
    ok($did_req, 'require ok');
    is($o->xx->x, 'nnn', 'coderef default');
    delete($INC{'xthbbt.pm'});
  }
  { # code default 2
    my $go = Getopt::Base->new(
      options => [xx => { type => 'string', isa => 'xthbbt',
        default => sub {xthbbt->new('nnn')} }]
    );
    my $o = $go->process(my $args = []);
    ok($o);
    is(scalar(@$args), 0);
    ok($did_req, 'require ok');
    is($o->xx->x, 'nnn', 'coderef default');
    delete($INC{'xthbbt.pm'});
  }
}

########################################################################
# errors
{
  eval {Getopt::Base->new(
    positional => [qw(input)],
    options => [ thing => { type => 'boolean', }, ],
  )};
  like($@, qr/^positional 'input' is not an option/);

  eval {Getopt::Base->new(
    positional => [qw(thing)],
    options => [ thing => { type => 'boolean', }, ],
  )};
  like($@, qr/^positional 'thing' cannot be a boolean/);

  eval {Getopt::Base->new(
    options => [ -thing => { }, ],
  )};
  like($@, qr/^options cannot contain dashes \('-thing'\)/);

  eval {Getopt::Base->new(
    options => [ thing => { aliases => ['--foo']}, ],
  )};
  like($@, qr/^aliases cannot contain dashes \('--foo'\)/);

  eval {Getopt::Base->new(
    options => [thing => {short => ['x', 'yyy']}, ],
  )};
  like($@, qr/^short options must be only one character \('yyy'\)/);

  {
    my $go = Getopt::Base->new(
      options => [xx => { type => 'string', isa => 'xthbbt' }]
    );
    eval { $go->process(my $args = ['--xx', 'foo']); };
    like($@, qr/Can't locate xthbbt\.pm/);
  }
}

########################################################################

ok(Getopt::Base->new(
  positional => [qw(deal)],
  options => [
    thing => {
      short     => ['t'],
      type      => 'boolean',
      default   => 0,
    },
    deal  => {
      short   => ['d'],
      type    => 'string',
      default => '',
    },
    stuff => {
      type    => 'string',
      default => [],
    },
    things => {
      type    => 'string',
      default => {},
    },
  ],
));

# vim:ts=2:sw=2:et:sta
