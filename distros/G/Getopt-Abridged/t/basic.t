#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;#<

use Getopt::Abridged;

{
  my $go = Getopt::Abridged->new(
    'w|world=s=World',
    'g|greeting=s=Hello',
    'foo=@s',
    'bar=@s=this,that,then',
    'baz=%s=foo=bar,x=8',
    'v|verbose=1',
    'q|quiet=!verbose',
    -positional => ['world'],
  );

  ok($go, 'constructor');

  {
    my $opt = $go->process([]);
    can_ok($opt, 'world');
    can_ok($opt, 'greeting');
    can_ok($opt, 'verbose');
    is($opt->world, 'World');
    is($opt->greeting, 'Hello');
    is_deeply([$opt->bar], [qw(this that then)]); 
    is_deeply({$opt->baz}, {foo => bar => x => 8});
    is($opt->verbose, 1);
  }
  {
    my $opt = $go->process(['You']);
    is($opt->world, 'You');
  }
  {
    my $opt = $go->process(['--verbose', '-g', 'bah']);
    is($opt->verbose, 1);
    is($opt->greeting, 'bah');
  }
  {
    my $opt = $go->process(['-q']);
    is($opt->verbose, 0);
  }
  {
    my $opt = $go->process(['--quiet']);
    is($opt->verbose, 0);
  }

}

{ # now with this conversion business
  my $was = Getopt::Abridged->can('process');
  Getopt::Abridged->import('pod');
  ok(Getopt::Abridged->can('process') != $was, 'replaced');
  Getopt::Abridged->unimport();
  ok(Getopt::Abridged->can('process') == $was, 'restored');

  Getopt::Abridged->import('pod');

  my $go = Getopt::Abridged->new(
    'w|world=s=World',
    'g|greeting=s=Hello',
    'f|foo=@n',
    'verbose',
    'q|quiet=!verbose',
  );
  eval {$go->process('foo') };
  like($@, qr/should have no arguments/);

  my $string = '';
  open(my $fh, '>', \$string) or die "cannot open string ref - $!";
  # TODO a package variable is ok for testing, but not much of an API
  local $Getopt::Abridged::PODHANDLE = $Getopt::Abridged::PODHANDLE = $fh;
  is($go->process(), undef);
  my @exp = map({s/^  //; $_} split(/\n/, <<'  ---'));
  =head1 Usage

    basic.t [options]

  =head1 Options

  =over

  =item -w, --world WORLD

  The world.

  DEFAULT: World

  =item -g, --greeting GREETING

  The greeting.

  DEFAULT: Hello

  =item -f, --foo FOO [--foo ...] (number)

  The foo.

  =item --verbose

  The verbose.

  DEFAULT: 0

  =item -q, --quiet, --no-verbose

  The no_verbose.

  =item --version

  Print version number and quit.

  =item -h, --help

  Show help about options.

  =back

  =cut

  ---

  close($fh);
  my @got = split(/\n/, $string);
  is_deeply(\@got, \@exp);

}

# vim:ts=2:sw=2:et:sta
