use strict;
use warnings;
use lib 't/lib';
use MiniTest tests => 6;
use File::Spec;
use IPC::Open3;

for my $layers ( 0, 3 ) {
  my $pid = open3 my $stdin, my $stdout, undef,
    $^X, (map "-I$_", @INC), 't/segfault.pl', "--layers=$layers"
    or die "can't run t/segfault.pl: $!";

  my $out = do { local $/; <$stdout> };
  $out =~ s/[\r\n]+\z//;
  waitpid $pid, 0;
  my $signal = $? & 255;
  my $exit = $? >> 8;
  is $signal, 0, "eval+subgen+exit+END, $layers layers, exitted without signal";
  is $exit, 0, "eval+subgen+exit+END, $layers layers, exitted without error";
  local $TODO = "can't accurately detect END without possible segfault on perl 5.8.9 to 5.12"
    if "$]" >= 5.008009 && "$]" < 5.014000;
  is $out, 'END', "eval+subgen+exit+END, $layers layers, detected correct phase";
}
