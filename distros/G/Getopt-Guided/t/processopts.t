use Test2::V1
  -target => { MODULE => 'Getopt::Guided' },
  -pragmas,
  qw( dies fail is imported_ok like ok plan subtest warning );
BEGIN { MODULE->import( qw( EOOD print_version_info processopts ) ) }

plan 15;

imported_ok qw( EOOD print_version_info processopts );

use Test::Output qw( stdout_like  );

use File::Basename qw( basename );

my $fail_cb = sub { fail "'$_[ 1 ]' callback shouldn't be called" };

subtest 'Provoke exceptions' => sub {
  plan 4;

  my @argv = qw( -I blib/lib -a foo -I blib/arch );
  like dies {
    processopts @argv, ':a:' => $fail_cb
  }, qr/isn't a non-empty string of alphanumeric/, "Leading ':' character is not allowed";
  is \@argv, [ qw( -I blib/lib -a foo -I blib/arch ) ], '@argv not changed';

  like dies { processopts @argv, 'a:b' => $fail_cb }, qr/specifies 2 options \(expected: 1\)/,
    'Single option specification expected';

  like dies {
    processopts @argv, 'a:' => \my @value, 'I,' => sub { }
  }, qr/\A'ARRAY' is an unsupported destination reference type for the ':' indicator/, ## no critic ( ProhibitComplexRegexes )
    'Unknown destination reference type'
};

subtest 'Callback destination: usual flag' => sub {
  plan 5;

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
  plan 5;

  my @argv = qw( -a foo );
  my ( $value, $name, $indicator );
  ok processopts( @argv, 'a:' => sub { ( $value, $name, $indicator ) = @_ } ), 'Succeeded';
  is $value,     'foo', 'Check 0th callback argument assigned to closure variable (value)';
  is $name,      'a',   'Check 1st callback argument assigned to closure variable (name)';
  is $indicator, ':',   'Check 2nd callback argument assigned to closure variable (indicator)';
  is @argv,      0,     '@argv is empty'
};

subtest 'Scalar reference destination: common option' => sub {
  plan 3;

  my @argv = qw( -a baz );
  ok processopts( @argv, 'a:' => \my $value ), 'Succeeded';
  is $value, 'baz', 'Check common option value';
  is @argv,  0,     '@argv is empty'
};

subtest 'Callback destinations: common option and usual flag' => sub {
  plan 6;

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

subtest 'Callback destinations: list option and incrementable flag' => sub {
  plan 4;

  my @argv = qw( -v -I lib -vv -I local/lib/perl5 );
  ok processopts(
    @argv,
    'v+' => sub { is $_[ 0 ], 3,                             'Check 0th callback argument' },
    'I,' => sub { is $_[ 0 ], [ qw( lib local/lib/perl5 ) ], 'Check 0th callback argument' }
    ),
    'Succeeded';
  is @argv, 0, '@argv is empty'
};

subtest 'Scalar reference destinations: list option and incrementable flag' => sub {
  plan 4;

  my @argv = qw( -v -I lib -vv -I local/lib/perl5 );
  ok processopts( @argv, 'v+' => \my $verbosity, 'I,' => \my $inc ), 'Succeeded';
  is $verbosity, 3,                             'Check incrementable flag value';
  is $inc,       [ qw( lib local/lib/perl5 ) ], 'Check list option value';
  is @argv,      0,                             '@argv is empty'
};

subtest 'Array and scalar reference destination: list option and incrementable flag' => sub {
  plan 4;

  my @argv = qw( -v -I lib -vv -I local/lib/perl5 );
  ok processopts( @argv, 'v+' => \my $verbosity, 'I,' => \my @inc ), 'Succeeded';
  is $verbosity, 3,                             'Check incrementable flag value';
  is \@inc,      [ qw( lib local/lib/perl5 ) ], 'Check list option value';
  is @argv,      0,                             '@argv is empty'
};

subtest 'Hash and scalar reference destination: map option and incrementable flag' => sub {
  plan 4;

  my @argv = qw( -S os=linux -v -Svendor=redhat -v );
  ok processopts( @argv, 'v+' => \my $verbosity, 'S=' => \my %system ), 'Succeeded';
  is $verbosity,                                      2, 'Check incrementable flag value';
  is \%system, { os => 'linux', vendor => 'redhat' }, 'Check map option value';
  is @argv,                                           0, '@argv is empty'
};

subtest 'Scalar reference destinations: list option and map option' => sub {
  plan 4;

  my @argv = qw( -I lib -S vendor=redhat -Sos=windows -I local/lib/perl5 );
  ok processopts( @argv, 'S=' => \my $system, 'I,' => \my $inc ), 'Succeeded';
  is $system, { os => 'windows', vendor => 'redhat' }, 'Check map option value';
  is $inc,  [ qw( lib local/lib/perl5 ) ], 'Check list option value';
  is @argv, 0,                             '@argv is empty'
};

subtest 'Callback destinations: list option, incrementable flag, and map option' => sub {
  plan 5;

  my @argv = qw( -v -d vendor=apple -I local/lib/perl5 -vv -I lib -v -d os=mac );
  ok processopts(
    @argv,
    'v+' => sub { is $_[ 0 ], 4,                                  'Check 0th callback argument' },
    'I,' => sub { is $_[ 0 ], [ qw( local/lib/perl5 lib ) ],      'Check 0th callback argument' },
    'd=' => sub { is $_[ 0 ], { os => 'mac', vendor => 'apple' }, 'Check 0th callback argument' }
    ),
    'Succeeded';
  is @argv, 0, '@argv is empty'
};

subtest 'Unknown option' => sub {
  plan 3;

  my @argv = qw( -b -d bar );
  like warning { ok !processopts( @argv, 'a:' => $fail_cb, 'b' => $fail_cb ), 'Failed' }, qr/illegal option -- d/,
    'Check warning';
  is \@argv, [ qw( -b -d bar ) ], '@argv not changed'
};

subtest 'Semantic priority' => sub {
  plan 4;

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
  plan 6;

  for ( ( 0, 1 ) ) {
    my @argv = ( "-$_" );
    # The early return triggered by EOOD leads to a "-" prefixed return value
    # that is a boolean true value that can be distinguished from TRUE (1)
    ok my $rv = processopts( @argv, $_ => sub { EOOD }, 'h' => $fail_cb ), 'Succeeded';
    is $rv,   "-$_", 'Check return value';
    is @argv, 0,     '@argv is empty'
  }
}
