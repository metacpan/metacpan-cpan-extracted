#!/usr/bin/perl
package Subtle;

sub new {
  my $test;
  $test = \$test;
  warn "CREATING " . \$test;
  return bless \$test;
}

sub DESTROY {
  my $self = shift;
  warn "DESTROYING $self";
}

package main;

warn "starting program";
{
  my $a = Subtle->new;
  my $b = Subtle->new;
  $$a = 0;			# break selfref
  warn "leaving block";
}

warn "just exited block";
warn "time to die...";
exit;
