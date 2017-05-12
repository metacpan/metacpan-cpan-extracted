package Capture;
use strict;
use warnings;

use File::Temp qw(tempfile);
use IPC::Open3;
use File::Spec;

my @PERL5OPTS = map "-I$_", @INC;

sub import {
  my $class = shift;
  my $target = caller;
  my @args = @_ ? @_ : 'capture';
  while (my $sub = shift @args) {
    die "bad option: $sub"
      if ref $sub;
    my @opts;
    @opts = @{ shift @args }
      if ref $args[0];
    my $export = sub ($) { _capture($_[0], @opts) };
    no strict 'refs';
    *{"${target}::${sub}"} = $export;
  }
}

sub _capture {
    my ($code, @opts) = @_;

    my ($fh, $filename) = tempfile()
      or die "can't open temp file: $!";
    print { $fh } $code;
    close $fh;

    open my $in, '<', File::Spec->devnull or die "can't open null: $!";
    my $pid = open3( $in, my $out, undef, $^X, @PERL5OPTS, @opts, $filename);
    my $output = do { local $/; <$out> };
    close $in;
    close $out;
    waitpid $pid, 0;

    $output =~ s/\r\n?/\n/g;

    unlink $filename
      or die "Couldn't unlink $filename: $!\n";

    return $output;
}

1;
