#!/usr/bin/perl

use warnings;
use strict;
use Test::More;

#
# Check the binary file
#
ok -x "_build/apps/nat-pre" => "nat-pre is compiled and executable exists";

#
# Check that nat-pre creates the files it should create
#
my @prefiles = qw!t/PT.lex t/EN.lex t/PT.crp t/PT.crp.index t/EN.crp.index t/EN.crp!;
for (@prefiles) {
    unlink if -f;
}

`_build/apps/nat-pre -q -i t/input/PT-tok t/input/EN-tok t/PT.lex t/EN.lex t/PT.crp t/EN.crp`;

for (@prefiles) {
  ok -f, "Checking if file $_ was correctly created";
}

#
# Check that nat-lex2perl does anything for PT and EN
#
`$^X -Mblib scripts/nat-lex2perl t/PT.lex > t/PT.perl`;
ok(-f "t/PT.perl", "nat-lex2perl worked");


`$^X -Mblib scripts/nat-lex2perl t/EN.lex > t/EN.perl`;
ok(-f "t/EN.perl", "nat-lex2perl worked");


#
# Check contents for PT.perl
#
{
  my $GENERATED = {};
  my $ORIGINAL = do "t/input/PT-tok.wc";
  eval{$GENERATED = do "t/PT.perl"};
  ok(!$@, "DO done correctly");

  for (keys %$ORIGINAL) {
    next if $_ eq '$';
    print STDERR "\n\nPT: $_\n\n" unless $ORIGINAL->{$_} == $GENERATED->{$_};
    is($GENERATED->{$_}, $ORIGINAL->{$_}, "Testing word '$_'");
  }
}

#
# Check contents for EN.perl
#
{
  my $GENERATED = {};
  my $ORIGINAL = do "t/input/EN-tok.wc";
  eval{$GENERATED = do "t/EN.perl"};
  ok(!$@, "DO done correctly");

  for (keys %$ORIGINAL) {
    next if $_ eq '$';
    print STDERR "\n\nEN: $_\n\n" unless $ORIGINAL->{$_} == $GENERATED->{$_};
    is($GENERATED->{$_}, $ORIGINAL->{$_}, "Testing word '$_'");
  }
}

for (@prefiles, qw!t/PT.perl t/EN.perl!) {
    unlink if -f
}
done_testing();
