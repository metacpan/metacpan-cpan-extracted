#!D:\Programme\indigoperl-5.6\bin\perl.exe -w

use Test::More 'no_plan';

package Catch;

sub TIEHANDLE {
    my($class, $var) = @_;
    return bless { var => $var }, $class;
}

sub PRINT  {
    my($self) = shift;
    ${'main::'.$self->{var}} .= join '', @_;
}

sub OPEN  {}    # XXX Hackery in case the user redirects
sub CLOSE {}    # XXX STDERR/STDOUT.  This is not the behavior we want.

sub READ {}
sub READLINE {}
sub GETC {}
sub BINMODE {}

my $Original_File = 'D:lib\List\Sliding\Changes.pm';

package main;

# pre-5.8.0's warns aren't caught by a tied STDERR.
$SIG{__WARN__} = sub { $main::_STDERR_ .= join '', @_; };
tie *STDOUT, 'Catch', '_STDOUT_' or die $!;
tie *STDERR, 'Catch', '_STDERR_' or die $!;

SKIP: {
    # A header testing whether we find all prerequisites :
      # Check for module List::Sliding::Changes
  eval { require List::Sliding::Changes };
  skip "Need module List::Sliding::Changes to run this test", 1
    if $@;

  # Check for module Tie::File
  eval { require Tie::File };
  skip "Need module Tie::File to run this test", 1
    if $@;

  # Check for module strict
  eval { require strict };
  skip "Need module strict to run this test", 1
    if $@;


    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;
eval q{
  my $example = sub {
    local $^W = 0;

#line 20 lib/List/Sliding/Changes.pm

  use strict;
  use Tie::File;
  use List::Sliding::Changes qw(find_new_elements);

  my $filename = 'log.txt';
  my @log;
  tie @log, 'Tie::File', $filename
    or die "Couldn't tie to $filename : $!\n";

  # See what has happened since we last polled
  my @status = get_last_20_status_messages();

  # Find out what we did not already communicate
  my (@new) = find_new_elements(\@log,\@status);
  print "New log messages : $_\n"
    for (@new);

  # And update our log with what we have seen
  push @log, @new;

;

  }
};
is($@, '', "example from line 20");

};
SKIP: {
    # A header testing whether we find all prerequisites :
    
    # The original POD test
        undef $main::_STDOUT_;
    undef $main::_STDERR_;

};
