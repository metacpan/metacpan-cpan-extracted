#!/usr/bin/env perl
use strict;
use warnings;
use autodie;
use File::Slurp qw(read_file write_file);
use Data::Dumper;
use Capture::Tiny qw(capture);
use File::Temp qw(tmpnam);
use Test::More;

use_ok 'IPC::OpenAny';

my $test_script = tmpnam;
write_file $test_script => <<'EOT';
#!/usr/bin/env perl
use IO::Handle;
print STDOUT "foo1";
print STDERR "foo2";
my $fd3 = IO::Handle->new_from_fd(3, '>');
print $fd3 "foo3";
EOT
chmod 0700, $test_script;

my $fd3_file = tmpnam;
open my $fd3_fh, '>', $fd3_file;

# run the above subref, closing STDIN, swapping STDERR and STDOUT,
# and mapping FD3 to a filehandle. wait for the process to end
# before returning.
my %opt = (
  cmd_spec => ["$test_script"],
  fds => {
    0 => undef,
    1 => \*STDERR,
    2 => \*STDOUT,
    3 => $fd3_fh,
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

unlink $fd3_file, $test_script;

done_testing;
__END__
