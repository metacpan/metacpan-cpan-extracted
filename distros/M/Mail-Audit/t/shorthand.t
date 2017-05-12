#!perl
use strict;
use warnings;

use Mail::Audit;
use Test::More;

plan skip_all => 'these tests are not yet useful on Win32' if $^O =~ /MSWin/;
plan 'no_plan';

sub readfile {
  my ($name) = @_;
  local *MESSAGE_FILE;
  open MESSAGE_FILE, "<$name" or die "coudn't read $name: $!";
  my @lines = <MESSAGE_FILE>;
  close MESSAGE_FILE;
  return \@lines;
}

my $message = readfile('t/messages/simple.msg');

my $audit = Mail::Audit->new(
  data      => $message,
  log       => "/dev/null",
);

use File::HomeDir;
my $home = File::HomeDir->my_home;
my $ymd  = do {
  my @localtime = localtime;
  sprintf "%04u%02u%02u",
    ($localtime[5] + 1900),
    ($localtime[4] + 1),
    ($localtime[3]);
};

is_deeply(
  [ $audit->_shorthand_expand("~/log/%Y%m%d/") ],
  [ "$home/log/%Y%m%d/" ],
  "'nifty interpolated' ~ only",
);

is_deeply(
  [ $audit->_shorthand_expand("~/log/%Y%m%d/", { interpolate_strftime => 1 }) ],
  [ "$home/log/$ymd/" ],
  "'nifty interpolated' ~ and date",
);

