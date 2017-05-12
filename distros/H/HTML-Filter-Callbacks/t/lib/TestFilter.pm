package TestFilter;

use strict;
use warnings;
use Test::More;
use base 'Exporter';
use HTML::Filter::Callbacks;

our @EXPORT = (@Test::More::EXPORT, qw/test_all add_callbacks/);
our %CALLBACKS;

sub add_callbacks { %CALLBACKS = @_ }

sub test_all {
  my @blocks;
  my $test;
  my $fh = do {
    my $caller = caller;
    no strict 'refs';
    *{"$caller\::DATA"};
  };
  while (<$fh>) {
    if (/^===(?:\s+(.+))?/) {
      push @blocks, $test if $test;
      $test = { mes => $1, reading => '' };
      next;
    }
    if (/^---(?:\s+(.+))?/) {
      if ($test->{reading} eq '') {
        $test->{reading} = 'input';
      }
      elsif ($test->{reading} eq 'input') {
        $test->{reading} = 'expected';
      }
      $test->{$test->{reading}}->{cb} = $1;
      next;
    }
    $test->{$test->{reading}}->{body} .= $_;
  }
  push @blocks, $test if $test;

  plan tests => scalar @blocks;
  _test($_) foreach @blocks;
}

sub _test {
  my $test = shift;
  my $input    = $test->{input}->{body};
  my $expected = $test->{expected}->{body};
  $input    =~ s/\n\n+$/\n/s;
  $expected =~ s/\n\n+$/\n/s;

  my $filter = HTML::Filter::Callbacks->new;
  foreach my $key (split /\s/, $test->{input}->{cb}) {
    $filter->add_callbacks(%{ $CALLBACKS{$key} });
  }

  is $filter->process($input) => $expected,
     defined $test->{mes} ? $test->{mes} : '';
}

1;
