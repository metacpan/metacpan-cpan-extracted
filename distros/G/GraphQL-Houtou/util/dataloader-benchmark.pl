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

use GraphQL::Houtou::DataLoader;
use GraphQL::Houtou qw(build_native_runtime);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($String);

my $count = -3;
my $width = 10;
my $scenario = 'loader';
my $access = 'unique';

GetOptions(
  'count=s' => \$count,
  'width=i' => \$width,
  'scenario=s' => \$scenario,
  'access=s' => \$access,
) or die "Usage: $0 [--count Benchmark-count] [--width key-count] [--scenario loader|execution] [--access unique|cold|repeated|primed]\n";

die "--width must be positive\n" unless $width > 0;
die "--scenario must be loader or execution\n"
  unless $scenario eq 'loader' || $scenario eq 'execution';
die "--access must be unique, cold, repeated, or primed\n"
  unless $access eq 'unique' || $access eq 'cold'
    || $access eq 'repeated' || $access eq 'primed';

my @keys = map { "key$_" } 1 .. $width;
my @request_keys = $access eq 'repeated' ? (($keys[0]) x $width) : @keys;

sub run_request {
  my $loader = GraphQL::Houtou::DataLoader->new(
    cache => $access eq 'unique' ? 0 : 1,
    batch => sub {
      my ($batch_keys) = @_;
      return [ map { "value:$_" } @$batch_keys ];
    },
  );
  if ($access eq 'primed') {
    $loader->prime($_, "value:$_") for @keys;
  }
  $loader->load($_) for @request_keys;
  return $loader->dispatch;
}

sub build_execution_runner {
  my ($fast) = @_;
  my $Loaded = GraphQL::Houtou::Type::Object->new(
    name => $fast ? 'FastLoadedValue' : 'GenericLoadedValue',
    fields => {
      value => { type => $String },
    },
  );
  my $Row = GraphQL::Houtou::Type::Object->new(
    name => $fast ? 'FastLoaderRow' : 'GenericLoaderRow',
    fields => {
      loaded => {
        type => $Loaded,
        ($fast ? (resolver_mode => 'fast_resolve_no_args') : ()),
        resolve => $fast
          ? sub {
              my ($source, $context) = @_;
              return $context->{loader}->load($source->{id});
            }
          : sub {
              my ($source, undef, $context) = @_;
              return $context->{loader}->load($source->{id});
            },
      },
    },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => $fast ? 'FastLoaderQuery' : 'GenericLoaderQuery',
      fields => {
        rows => {
          type => $Row->list,
          resolver_mode => 'fast_resolve_no_args',
          resolve => sub {
            return [ map { +{ id => $_ } } @request_keys ];
          },
        },
      },
    ),
    types => [ $Row, $Loaded ],
  );
  my $runtime = build_native_runtime($schema, async => 1);
  my $program = $runtime->compile_program('{ rows { loaded { value } } }');

  return sub {
    my $loader = GraphQL::Houtou::DataLoader->new(
      cache => $access eq 'unique' ? 0 : 1,
      batch => sub {
        my ($batch_keys) = @_;
        return [ map { +{ value => "value:$_" } } @$batch_keys ];
      },
    );
    if ($access eq 'primed') {
      $loader->prime($_, +{ value => "value:$_" }) for @keys;
    }
    return $runtime->execute_program(
      $program,
      context => { loader => $loader },
      on_stall => GraphQL::Houtou::DataLoader->on_stall_for($loader),
    );
  };
}

my $cases;
my $label;
if ($scenario eq 'execution') {
  $cases = {
    generic_resolver => build_execution_runner(0),
    fast_resolver => build_execution_runner(1),
  };
  $label = "$width $access accesses through GraphQL execution";
} else {
  $cases = { load_and_dispatch => \&run_request };
  $label = "$width $access accesses in one batch";
}

for my $runner (values %$cases) {
  $runner->() for 1 .. 1_000;
}

print "DataLoader benchmark: $label\n";
cmpthese($count, $cases);
