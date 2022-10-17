use Test2::V0;
use Getopt::App;
use Getopt::App -capture;

my $app = run(
  'h|help # Output help',
  'v+     # Verbose output',
  'x',
  sub {
    my ($app, $section) = @_;
    return print extract_usage($section ? $section : ()) if $app->{h};
    return $app->{v} // 0;
  },
);

subtest main => sub {
  my $out = capture($app, [qw(--help)]);
  is $out->[0], <<'HERE', "usage" or diag "STDERR: $out->[1]";
Usage:
  $ example --name superwoman

Options:
  --help, -h  Output help
  -v          Verbose output
  -x          

HERE
};

subtest subcommand => sub {
  my $out = capture($app, [qw(--help Foo)]);
  is $out->[0], <<'HERE', "usage" or diag "STDERR: $out->[1]";
Some help text.

  $ example foo --name superwoman

Options:
  --help, -h  Output help
  -v          Verbose output
  -x          

HERE

};

done_testing;

__END__

=head1 SYNOPSIS

  $ example --name superwoman

=head1 Foo

Some help text.

  $ example foo --name superwoman

=cut
