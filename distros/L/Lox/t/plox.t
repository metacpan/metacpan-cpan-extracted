#!perl
use strict;
use warnings;
use File::Find 'find';
use Test::More;

my $LOX_PATH = 'bin/plox';
my $TEST_PATH = 'test';

my @UNSUPPORTED = (
  'operator/equals_method.lox', # I'm not sure why this behavior is desirable
  'benchmark/', # take forever to run
);

find({
  no_chdir => 1,
  wanted   => sub {
    return unless $File::Find::name =~ /\.lox$/;
    return if grep { $File::Find::name =~ m($_) } @UNSUPPORTED;
    test_file($File::Find::name);
  }
}, $TEST_PATH);


done_testing;

sub test_file {
  my $filepath = shift;;
  open my $fh, '<', $filepath or die "Couldn't open $filepath $!";
  my $expected = '';
  my $test_content = '';
  while (my $line = <$fh>) {
    $test_content .= $line;
    $expected .= $1 if $line =~ qr{// expect: (.+)$}s;
  }
  my $output = join '', `$^X -Ilib $LOX_PATH $filepath`;
  my $result = is($output, $expected, "Got expected output for $filepath");
  unless ($result) {
    print "TEST BEGIN\n${test_content}TEST END\n";
    exit 1;
  }
}
