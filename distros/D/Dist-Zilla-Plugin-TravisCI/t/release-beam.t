
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print qq{1..0 # SKIP these tests are for release candidate testing\n};
    exit
  }
}

use strict;
use warnings;

use Test::More;
use Test::Requires (
  {
    'Dist::Zilla::Plugin::Beam::Connector' => 0,
    'Beam::Wire'                           => 0,
  }
);

use Test::DZil qw( Builder simple_ini );

# ABSTRACT: Ensure BEAM API does what it says it does.

my @seen_events;

# This definition could live on CPAN, or in @INC (like in inc/ ), it doesn't matter really.
{

  package    # hide me?
    My::Event::Munger;

  sub new { bless { @_[ 1 .. $#_ ] }, $_[0] }

  sub handle_event {
    my ( $self, $event ) = @_;
    push @seen_events, [ $event, $self ];
    push @{ $event->travis_yml->{env} }, @{ $self->{env} || [] };
  }
  BEGIN { $INC{'My/Event/Munger.pm'} = 1 }
}

# This is a bit of a contrived example, just to emulate the fact multiple plugin instances
# can hook into the same event bus, and to demonstrate individual instance configuration
my $container = <<'EOCONTAINER';
---
my_munger:
  $class: My::Event::Munger
  env:
    - AUTHOR_TESTING=1
    - RELEASE_TESTING=1

my_other_munger:
  $class: My::Event::Munger
  env:
    - SMOKE_TESTING=1

EOCONTAINER

my $ini = simple_ini(
  ['TravisCI'],
  [
    'Beam::Connector' => {
      container => 'beam.yml',
      on        => [

        # Order of these on statements affect output order
        'plugin:TravisCI#modify_travis_yml => container:my_munger#handle_event',
        'plugin:TravisCI#modify_travis_yml => container:my_other_munger#handle_event',
      ],
    }
  ]
);
use Path::Tiny qw(path);
my $tzil = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => {
      path(qw( source dist.ini ))   => $ini,
      path(qw( source beam.yml ))   => $container,
      path(qw( source lib Foo.pm )) => 'package Foo',
    },
  }
);

$tzil->chrome->logger->set_debug(1);
$tzil->build;

pass("built ok");

my $need_diag = 0;

$need_diag = 1 unless is( scalar @seen_events, 2, "Saw 2 discrete events" );
my $final_yml = $seen_events[-1]->[0]->travis_yml;
$need_diag = 1 unless is( scalar @{ $final_yml->{env} }, 3, "All 3 lines added" );
$need_diag = 1
  unless is_deeply( $final_yml->{env}, [ 'AUTHOR_TESTING=1', 'RELEASE_TESTING=1', 'SMOKE_TESTING=1' ], "Structure is expected" );

note explain $final_yml if $need_diag;

done_testing;
