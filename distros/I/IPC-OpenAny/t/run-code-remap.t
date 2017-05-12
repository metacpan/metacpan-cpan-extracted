#!/usr/bin/env perl
use strict;
use warnings;
use autodie;
use File::Slurp qw(read_file);
use Data::Dumper;
use Capture::Tiny qw(capture);
use File::Temp qw(tmpnam);
use Test::More;

use lib 'lib';
use IPC::OpenAny;

my $fd3_file = tmpnam;
open my $fd3_fh, '>', $fd3_file;

my $cmd_sub = sub {
  print STDOUT "foo1";
  print STDERR "foo2";
  print $fd3_fh "foo3";
};

# run the above subref, closing STDIN, swapping STDERR and STDOUT,
# and mapping FD3 to a filehandle. wait for the process to end
# before returning.
my %opt = (
  cmd_spec => $cmd_sub, # can be subref, string, or array of strings
  fds => {         # vals can be filehandles or undef, or ref to string (TBD)
    0 => undef,    # close this
    1 => \*STDERR, # foo1
    2 => \*STDOUT, # foo2
    3 => $fd3_fh,  # foo3
  },
  wait => 1,
);

my ($stdout, $stderr) = capture {
  my $pid = IPC::OpenAny->run(%opt);
};
close $fd3_fh;

is $stderr, "foo1", "got foo1 on stderr";
is $stdout, "foo2", "got foo2 on stdout";
is scalar read_file($fd3_file), "foo3", "got foo3 in file on FD3";

($stdout, $stderr) = capture {
  my $pid = IPC::OpenAny->run(
    cmd_spec => sub { print STDOUT "foo1"; print STDERR "foo2" },
    fds => {
      1 => \*STDOUT,
      2 => \*STDERR,
    },
    wait => 1,
  );
};
is $stdout, "foo1", "got foo1 on stdout";
is $stderr, "foo2", "got foo2 on stderr";

unlink $fd3_file;

done_testing;
__END__
