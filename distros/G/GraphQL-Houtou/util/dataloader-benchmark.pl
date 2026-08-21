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
my $case = '';

GetOptions(
  'count=s' => \$count,
  'width=i' => \$width,
  'scenario=s' => \$scenario,
  'access=s' => \$access,
  'case=s' => \$case,
) or die "Usage: $0 [--count Benchmark-count] [--width key-count] [--scenario loader|execution] [--access unique|cold|repeated|primed] [--case name]\n";

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
  my ($mode) = @_;
  my $fast = $mode eq 'fast';
  my $declarative = $mode eq 'declarative' || $mode eq 'batch_plan';
  my $batch_plan = $mode eq 'batch_plan';
  my $Loaded = GraphQL::Houtou::Type::Object->new(
    name => ucfirst($mode) . 'LoadedValue',
    fields => {
      value => { type => $String },
    },
  );
  my $Row = GraphQL::Houtou::Type::Object->new(
    name => ucfirst($mode) . 'LoaderRow',
    fields => {
      loaded => {
        type => $Loaded,
        ($declarative
          ? (loader => {
              context_key => 'loader',
              key => { source_key => 'id' },
            })
          : (
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
            )),
      },
    },
  );
  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => ucfirst($mode) . 'LoaderQuery',
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
      batch_plan => $batch_plan,
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

sub build_argument_execution_runner {
  my $schema = GraphQL::Houtou::Schema->new(
    query => GraphQL::Houtou::Type::Object->new(
      name => 'ArgumentLoaderBenchmarkQuery',
      fields => {
        loaded => {
          type => $String,
          args => { key => { type => $String } },
          loader => {
            context_key => 'loader',
            key => { argument => 'key' },
          },
        },
      },
    ),
  );
  my $runtime = build_native_runtime($schema, async => 1);
  my $query = '{ ' . join(' ', map {
    "loaded$_: loaded(key: \"$_\")"
  } @request_keys) . ' }';
  my $program = $runtime->compile_program($query);

  return sub {
    my $loader = GraphQL::Houtou::DataLoader->new(
      cache => $access eq 'unique' ? 0 : 1,
      batch => sub {
        my ($batch_keys) = @_;
        return [ map { "value:$_" } @$batch_keys ];
      },
    );
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
    generic_resolver => build_execution_runner('generic'),
    fast_resolver => build_execution_runner('fast'),
    declarative_loader => build_execution_runner('declarative'),
    declarative_batch_plan => build_execution_runner('batch_plan'),
    declarative_argument_loader => build_argument_execution_runner(),
  };
  $label = "$width $access accesses through GraphQL execution";
} else {
  $cases = { load_and_dispatch => \&run_request };
  $label = "$width $access accesses in one batch";
}

if ($case ne '') {
  die "unknown benchmark case '$case'\n" if !exists $cases->{$case};
  $cases = { $case => $cases->{$case} };
}

for my $runner (values %$cases) {
  $runner->() for 1 .. 1_000;
}

print "DataLoader benchmark: $label\n";
cmpthese($count, $cases);
