use 5.014;
use strict;
use warnings;

use Benchmark qw(cmpthese);
use FindBin qw($Bin);
use File::Spec;
use Getopt::Long qw(GetOptions);

BEGIN {
  my $root = File::Spec->catdir($Bin, '..');
  unshift @INC,
    File::Spec->catdir($root, 'blib', 'lib'),
    File::Spec->catdir($root, 'blib', 'arch'),
    File::Spec->catdir($root, 'lib');
}

use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);

my $count = -3;
my $width = 10;
my $scenario = 'no_args';

GetOptions(
  'count=s' => \$count,
  'width=i' => \$width,
  'scenario=s' => \$scenario,
) or die "Usage: $0 [--count Benchmark-count] [--width field-count] [--scenario no_args|static_one_arg|dynamic_one_arg]\n";

die "--width must be positive\n" unless $width > 0;
die "--scenario must be no_args, static_one_arg, or dynamic_one_arg\n"
  unless $scenario eq 'no_args'
    || $scenario eq 'static_one_arg'
    || $scenario eq 'dynamic_one_arg';

sub build_runner {
  my ($resolver_mode) = @_;
  my %fields = map {
    my $value = "value$_";
    ("field$_" => {
      type => $String,
      resolver_mode => $resolver_mode,
      resolve => sub { return $value },
    })
  } 1 .. $width;

  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => \%fields,
    ),
  );
  my $runtime = $schema->build_runtime;
  my $document = '{ ' . join(q( ), map { "field$_" } 1 .. $width) . ' }';
  my $program = $runtime->compile_program($document);

  return sub { $runtime->execute_program($program) };
}

sub build_one_arg_runner {
  my ($resolver_mode, $dynamic) = @_;
  my %fields = map {
    ("field$_" => {
      type => $String,
      resolver_mode => $resolver_mode,
      args => { value => { type => $String } },
      resolve => $resolver_mode eq 'native_one_arg'
        ? sub { return $_[1] }
        : sub { return $_[1]{value} },
    })
  } 1 .. $width;

  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'Query',
      fields => \%fields,
    ),
  );
  my $runtime = $schema->build_runtime;
  my $document = $dynamic
    ? 'query Q($value: String) { '
      . join(q( ), map { "field$_(value: \$value)" } 1 .. $width)
      . ' }'
    : '{ '
      . join(q( ), map { qq{field$_(value: "value")} } 1 .. $width)
      . ' }';
  my $program = $runtime->compile_program($document);

  return $dynamic
    ? sub { $runtime->execute_program($program, variables => { value => 'value' }) }
    : sub { $runtime->execute_program($program) };
}

my ($label, $cases);
if ($scenario eq 'no_args') {
  $label = "$width no-argument fields";
  $cases = {
    native => build_runner('native'),
    native_no_args => build_runner('native_no_args'),
  };
} else {
  my $dynamic = $scenario eq 'dynamic_one_arg';
  $label = "$width fields with one " . ($dynamic ? 'dynamic' : 'static') . ' argument';
  $cases = {
    native => build_one_arg_runner('native', $dynamic),
    native_one_arg => build_one_arg_runner('native_one_arg', $dynamic),
  };
}

for my $runner (values %$cases) {
  $runner->() for 1 .. 1_000;
}

print "resolver ABI benchmark: $label\n";
cmpthese($count, $cases);
