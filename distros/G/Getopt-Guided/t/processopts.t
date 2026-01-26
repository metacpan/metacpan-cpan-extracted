use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT fail is is_deeply like ok plan subtest use_ok ) ], tests => 12;
use Test::Fatal  qw( exception );
use Test::Output qw( stdout_like  );
use Test::Warn   qw( warning_like );

use File::Basename qw( basename );

my $module;

BEGIN {
  $module = 'Getopt::Guided';
  use_ok $module, qw( EOOD print_version_info processopts ) or BAIL_OUT "Cannot loade module '$module'!"
}

my $fail_cb = sub { fail "'$_[ 1 ]' callback shouldn't be called" };

subtest 'Provoke exceptions' => sub {
  plan tests => 4;

  my @argv = qw( -I blib/lib -a foo -I blib/arch );
  like exception {
    processopts @argv, ':a:' => $fail_cb
  }, qr/isn't a non-empty string of alphanumeric/, "Leading ':' character is not allowed";
  is_deeply \@argv, [ qw( -I blib/lib -a foo -I blib/arch ) ], '@argv not changed';

  like exception { processopts @argv, 'a:b' => $fail_cb }, qr/specifies 2 options \(expected: 1\)/,
    'Single option specification expected';

  like exception {
    processopts @argv, 'a:' => \my @value, 'I,' => sub { }
  }, qr/\A'ARRAY' is an unsupported destination reference type for the ':' indicator/, ## no critic ( ProhibitComplexRegexes )
    'Unknown destination reference type'
};

subtest 'Callback destination: usual flag' => sub {
  plan tests => 5;

  my @argv = qw( -b );
  ok processopts(
    @argv,
    'b' => sub {
      my ( $value, $name, $indicator ) = @_;

      is $value,     1,   'Check 0th callback argument (value)';
      is $name,      'b', 'Check 1st callback argument (name)';
      is $indicator, '',  'Check 2nd callback argument (indicator)'
    }
    ),
    'Succeeded';
  is @argv, 0, '@argv is empty'
};

subtest 'Callback destination: common option' => sub {
  plan tests => 5;

  my @argv = qw( -a foo );
  my ( $value, $name, $indicator );
  ok processopts( @argv, 'a:' => sub { ( $value, $name, $indicator ) = @_ } ), 'Succeeded';
  is $value,     'foo', 'Check 0th callback argument assigned to closure variable (value)';
  is $name,      'a',   'Check 1st callback argument assigned to closure variable (name)';
  is $indicator, ':',   'Check 2nd callback argument assigned to closure variable (indicator)';
  is @argv,      0,     '@argv is empty'
};

subtest 'Scalar reference destination: common option' => sub {
  plan tests => 3;

  my @argv = qw( -a baz );
  ok processopts( @argv, 'a:' => \my $value ), 'Succeeded';
  is $value, 'baz', 'Check common option value';
  is @argv,  0,     '@argv is empty'
};

subtest 'Callback destination: common option and usual flag' => sub {
  plan tests => 6;

  # On purpose @argv doesn't contain flag
  my @argv = qw( -a bar );
  ok processopts(
    @argv,
    'a:' => sub {
      my $value     = shift;
      my $name      = shift;
      my $indicator = shift;

      is $value,     'bar', 'Check 0th shifted callback argument (value)';
      is $name,      'a',   'Check 1st shifted callback argument (name)';
      is $indicator, ':',   'Check 2nd shifted callback argument (indicator)';
      is @_,         0,     '@_ is empty'
    },
    'b' => $fail_cb
    ),
    'Succeeded';
  is @argv, 0, '@argv is empty'
};

subtest 'Callback destination: list option and incrementable flag' => sub {
  plan tests => 4;

  my @argv = qw( -v -I lib -vv -I local/lib/perl5 );
  ok processopts(
    @argv,
    'v+' => sub { is $_[ 0 ],        3,                             'Check 0th callback argument' },
    'I,' => sub { is_deeply $_[ 0 ], [ qw( lib local/lib/perl5 ) ], 'Check 0th callback argument' }
    ),
    'Succeeded';
  is @argv, 0, '@argv is empty'
};

subtest 'Scalar reference destination: list option and incrementable flag' => sub {
  plan tests => 4;

  my @argv = qw( -v -I lib -vv -I local/lib/perl5 );
  ok processopts( @argv, 'v+' => \my $verbosity, 'I,' => \my $inc ), 'Succeeded';
  is $verbosity, 3, 'Check incrementable flag value';
  is_deeply $inc, [ qw( lib local/lib/perl5 ) ], 'Check list option value';
  is @argv, 0, '@argv is empty'
};

subtest 'Array and scalar reference destination: list option and incrementable flag' => sub {
  plan tests => 4;

  my @argv = qw( -v -I lib -vv -I local/lib/perl5 );
  ok processopts( @argv, 'v+' => \my $verbosity, 'I,' => \my @inc ), 'Succeeded';
  is $verbosity, 3, 'Check incrementable flag value';
  is_deeply \@inc, [ qw( lib local/lib/perl5 ) ], 'Check list option value';
  is @argv, 0, '@argv is empty'
};

subtest 'Unknown option' => sub {
  plan tests => 3;

  my @argv = qw( -b -d bar );
  warning_like { ok !processopts( @argv, 'a:' => $fail_cb, 'b' => $fail_cb ), 'Failed' } qr/illegal option -- d/,
    'Check warning';
  is_deeply \@argv, [ qw( -b -d bar ) ], '@argv not changed'
};

subtest 'Semantic priority' => sub {
  plan tests => 4;

  local $main::VERSION = 'v6.6.6';
  # -h comes first on purpose
  my @argv = qw( -h -V );
  # Best pratice: -V should have higher precedence (semantic priority) than -h
  stdout_like {
    ok my $rv = processopts( @argv, 'V' => \&print_version_info, 'h' => $fail_cb ), 'Succeeded';
    is $rv, '-V', 'Check return value'
  }
  qr/\A ${ \( basename( __FILE__ ) ) } \  v6\.6\.6 \n perl \  v\d+\.\d+\.\d+ \n \z/x, 'Check version info';
  is @argv, 0, '@argv is empty'
};

subtest 'Edge case options 0 and 1' => sub {
  plan tests => 6;

  for ( ( 0, 1 ) ) {
    my @argv = ( "-$_" );
    # The early return triggered by EOOD leads to a "-" prefixed return value
    # that is a boolean true value that can be distinguished from TRUE (1)
    ok my $rv = processopts( @argv, $_ => sub { EOOD }, 'h' => $fail_cb ), 'Succeeded';
    is $rv,   "-$_", 'Check return value';
    is @argv, 0,     '@argv is empty'
  }
}
