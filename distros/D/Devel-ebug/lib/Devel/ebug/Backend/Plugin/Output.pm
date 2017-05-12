package Devel::ebug::Backend::Plugin::Output;
$Devel::ebug::Backend::Plugin::Output::VERSION = '0.59';
use strict;
use warnings;

my $stdout = "";
my $stderr = "";

if ($ENV{PERL_DEBUG_DONT_RELAY_IO}) {
  open NULL, ">/dev/null";
  open NULL, '>', \$stdout;
  open NULL, '>', \$stderr;
}
else {
  close STDOUT;
  open STDOUT, '>', \$stdout or die "Can't open STDOUT: $!";
  close STDERR;
  open STDERR, '>', \$stderr or die "Can't open STDOUT: $!";
}

sub register_commands {
  return (output => { sub => \&output });
}

sub output {
  my($req, $context) = @_;
  return {
    stdout => $stdout,
    stderr => $stderr,
  };
}
1;
