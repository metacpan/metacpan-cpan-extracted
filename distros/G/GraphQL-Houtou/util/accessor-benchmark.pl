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

GetOptions(
  'count=s' => \$count,
  'width=i' => \$width,
) or die "Usage: $0 [--count Benchmark-count] [--width field-count]\n";

die "--width must be positive\n" unless $width > 0;

{
  package Local::AccessorBenchmarkRow;
  sub new { return bless {}, $_[0] }
}

for my $index (1 .. $width) {
  no strict 'refs';
  my $value = "value$index";
  *{"Local::AccessorBenchmarkRow::field$index"} = sub { return $value };
}

sub build_runner {
  my ($use_accessor) = @_;
  my %fields = map {
    my $name = "field$_";
    ($name => {
      type => $String,
      ($use_accessor ? (accessor => $name) : ()),
    })
  } 1 .. $width;
  my $Row = GraphQL::Houtou::Type::Object->new(
    name => $use_accessor ? 'AccessorRow' : 'DefaultRow',
    fields => \%fields,
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => $use_accessor ? 'AccessorQuery' : 'DefaultQuery',
      fields => {
        viewer => {
          type => $Row,
          resolver_mode => 'fast_resolve_no_args',
          resolve => sub { return Local::AccessorBenchmarkRow->new },
        },
      },
    ),
    types => [ $Row ],
  );
  my $runtime = $schema->build_runtime;
  my $document = '{ viewer { '
    . join(q( ), map { "field$_" } 1 .. $width)
    . ' } }';
  my $program = $runtime->compile_program($document);

  return sub { $runtime->execute_program($program) };
}

my $cases = {
  default_method => build_runner(0),
  accessor => build_runner(1),
};

for my $runner (values %$cases) {
  $runner->() for 1 .. 1_000;
}

print "accessor benchmark: $width object fields\n";
cmpthese($count, $cases);
