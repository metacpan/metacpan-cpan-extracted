use strict;
use warnings;
use Test::More;
use IO::FD;


{
  my $template="this_is_a_template_XXXXXX";
  my $path=IO::FD::mktemp $template;
  ok $path;
  ok $path=~/this_is_a_template_(.{6,6})/;
  ok $1 ne "XXXXXX";
  #unlink $path;
}
{
  # list context 
  my $template="this_is_a_template_XXXXXX";
  my ($fd,$path)=IO::FD::mkstemp $template;
  ok defined($fd), "Created temp file";

  ok $path;
  ok $path=~/this_is_a_template_(.{6,6})/;
  ok $1 ne "XXXXXX";
  IO::FD::close $fd;
  unlink $path;
}
{
  # Testing scalar context
  my $template="this_is_a_template_XXXXXX";
  my $fd=IO::FD::mkstemp $template;
  ok defined($fd), "Created temp file";
  my @_paths= <this_is_a_template_*>;
  unlink $_ for @_paths;

  #ok $path;
  #ok $path=~/this_is_a_template_(.{6,6})/;
  #ok $1 ne "XXXXXX";
  IO::FD::close $fd;
  #unlink $path;
}
done_testing;
