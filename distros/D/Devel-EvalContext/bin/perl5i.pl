#!perl

use strict;
use warnings;

use Getopt::Long;
use Devel::EvalContext;

my $cxt = Devel::EvalContext->new;

GetOptions(
  "trace" => sub { $cxt->trace(1) },
) or die "argument parsing error";

sub prompt {
  print "> ";
  <STDIN>;
}

while(defined(my $code = prompt("> "))) {
  if (my ($cmd) = $code =~ /^\s*:(\S*)/) {
    if ($cmd =~ /^q(?:u(?:it?)?)?$|^e(?:x(?:it?)?)?$/) {
      exit;
    } elsif ($1 eq "dump") {
      require YAML;
      print YAML::Dump $cxt;
    } elsif ($1 eq "trace") {
      $cxt->trace(not $cxt->trace);
    } else {
      print "unknown command\n";
    }
    next;
  }

  my ($err, $ret) = eval { $cxt->run($code) };
  if (ref $@ or $@ ne '') {
    $@ = "$@"; chomp $@;
    print "Compile error: $@\n";
  } elsif (defined $err) {
    $err = "$err"; chomp $err;
    print "User error: $err\n";
  } elsif (defined $ret) {
    $ret = "$ret"; chomp $ret;
    print "User return value: $ret\n";
  }
}
