
use strict;
use warnings;

use Test::More;
use Test::Fatal qw( exception );
use Log::Dispatchouli;
use Log::Contextual::LogDispatchouli -logger => Log::Dispatchouli->new( { ident => 'test' } );

# FILENAME: utilrole.t
# CREATED: 12/21/13 01:08:35 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test the UtilRole

{

  package Test;
  use Moose;
  with 'Dist::Zilla::UtilRole::MaybeGit';
  __PACKAGE__->meta->make_immutable;
}
{

  package FakeZilla;
  use Moose;
  sub build_root { '' }
  __PACKAGE__->meta->make_immutable;
}
{

  package TestObject;
  use Moose;

  sub zilla {
    return FakeZilla->new();
  }
  __PACKAGE__->meta->make_immutable;
}

pass('Compile passes');

my $e;

subtest empty_params => sub {
  my @args   = ();
  my $newstr = '->new()';

  isnt(
    $e = exception {
      Test->new(@args)->git;
    },
    undef,
    $newstr . '->git() fails'
  ) and note $e;

  isnt(
    $e = exception {
      Test->new(@args)->zilla;
    },
    undef,
    $newstr . '->zilla() fails'
  ) and note $e;

  isnt(
    $e = exception {
      Test->new(@args)->plugin;
    },
    undef,
    $newstr . '->plugin() fails'
  ) and note $e;
};

subtest plugin_params => sub {
  my @args = ( plugin => TestObject->new() );
  my $newstr = '->new( plugin => )';

  is(
    $e = exception {
      Test->new(@args)->git;
    },
    undef,
    $newstr . '->git() ok'
  ) or diag $e;

  is(
    $e = exception {
      Test->new(@args)->zilla;
    },
    undef,
    $newstr . '->zilla() ok'
  ) or diag $e;

  is(
    $e = exception {
      Test->new(@args)->plugin;
    },
    undef,
    $newstr . '->plugin() ok'
  ) or diag $e;
};

subtest zilla_params => sub {
  my @args = ( zilla => TestObject->new() );
  my $newstr = '->new( plugin => )';

  is(
    $e = exception {
      Test->new(@args)->git;
    },
    undef,
    $newstr . '->git() ok'
  ) or diag $e;

  is(
    $e = exception {
      Test->new(@args)->zilla;
    },
    undef,
    $newstr . '->zilla() ok'
  ) or diag $e;

  isnt(
    $e = exception {
      Test->new(@args)->plugin;
    },
    undef,
    $newstr . '->plugin() fails'
  ) and note $e;
};

subtest git_params => sub {
  my @args = ( git => TestObject->new() );
  my $newstr = '->new( plugin => )';

  is(
    $e = exception {
      Test->new(@args)->git;
    },
    undef,
    $newstr . '->git() ok'
  ) or diag $e;

  isnt(
    $e = exception {
      Test->new(@args)->zilla;
    },
    undef,
    $newstr . '->zilla() fails'
  ) and note $e;

  isnt(
    $e = exception {
      Test->new(@args)->plugin;
    },
    undef,
    $newstr . '->plugin() fails'
  ) and note $e;
};

done_testing;

