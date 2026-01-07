use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT is is_deeply ok plan require_ok subtest use_ok ) ], tests => 19;
use Test::Warn qw( warning_like );

my $module;

BEGIN {
  if ( defined $ENV{ UUT } and ( $module = $ENV{ UUT } ) eq 'Getopt::Std' ) {
    require_ok $module or BAIL_OUT "Cannot loade module '$module'!";
    # Wrap Getopt::Std::getopts() to patch its PROTO section
    *getopts = sub ( $\%;\@ ) {
      my ( $spec, $opts, $argv ) = @_;
      local @ARGV = @$argv if defined $argv;
      Getopt::Std::getopts( $spec, $opts )
    }
  } else {
    $module = 'Getopt::Guided';
    use_ok $module, qw( getopts ) or BAIL_OUT "Cannot loade module '$module'!"
  }
}

subtest 'Flag' => sub {
  plan tests => 3;

  local @ARGV = qw( -b );
  ok getopts( 'b', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { b => 1 }, 'Flag has value 1';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Common option: Option and option-argument are separate arguments' => sub {
  plan tests => 3;

  local @ARGV = qw( -a foo );
  ok getopts( 'a:', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo' }, 'Option has option-argument';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Common option: Option and option-argument are part of same argument string' => sub {
  plan tests => 3;

  local @ARGV = qw( -afoo );
  ok getopts( 'a:', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo' }, 'Option has option-argument';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Empty @ARGV' => sub {
  plan tests => 3;

  local @ARGV = ();
  ok getopts( 'a:b', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, {}, '%got_opts is empty';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Common option: Use unshift to set default' => sub {
  plan tests => 3;

  local @ARGV = qw( -b );
  # Simulate default for option with option-argument
  unshift @ARGV, ( -a => 'foo' );
  ok getopts( 'a:b', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Grouping: Flag followed by common option (separate arguments)' => sub {
  plan tests => 3;

  local @ARGV = qw( -ba foo );
  ok getopts( 'a:b', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Grouping: Flag followed by common option (part of same argument string)' => sub {
  plan tests => 3;

  local @ARGV = qw( -bafoo );
  ok getopts( 'a:b', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Grouping: Flag followed by common option that slurps flag' => sub {
  plan tests => 3;

  local @ARGV = qw( -cab foo );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'b', c => 1 }, 'Options properly set';
  is_deeply \@ARGV, [ qw( foo ) ], '@ARGV restored'
};

subtest 'End of options delimiter' => sub {
  plan tests => 3;

  local @ARGV = qw( -ba foo -c -- -d bar );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1, c => 1 }, 'Options properly set';
  is_deeply \@ARGV, [ qw( -d bar ) ], 'Options removed from @ARGV'
};

subtest 'End of options delimiter is treated as an option-argument' => sub {
  plan tests => 3;

  local @ARGV = qw( -ba foo -d -- -c );
  ok getopts( 'a:bcd:', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1, c => 1, d => '--' }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Unknown option' => sub {
  plan tests => 4;

  local @ARGV = qw( -b -d bar -a foo );
  my %got_opts;
  if ( $module eq 'Getopt::Std' ) {
    warning_like { ok !getopts( 'a:b', %got_opts ), 'Failed' } qr/\AUnknown option: d/, 'Check warning';
    is_deeply \%got_opts, { b => 1 }, 'Options set partially';
    is_deeply \@ARGV, [ qw( bar -a foo ) ], '@ARGV processed partially'
  } else {
    warning_like { ok !getopts( 'a:b', %got_opts ), 'Failed' } qr/illegal option -- d/, 'Check warning';
    is_deeply \%got_opts, {}, '%got_opts is empty';
    is_deeply \@ARGV, [ qw( -b -d bar -a foo ) ], '@ARGV restored'
  }
};

subtest 'Unknown option: Use unshift to set default' => sub {
  plan tests => 4;

  local @ARGV = qw( -b -d bar );
  # Simulate default for option with option-argument
  unshift @ARGV, ( -a => 'foo' );
  my %got_opts;
  if ( $module eq 'Getopt::Std' ) {
    warning_like { ok !getopts( 'a:b', %got_opts ), 'Failed' } qr/Unknown option: d/, 'Check warning';
    is_deeply \%got_opts, { a => 'foo', b => 1 }, 'Options set partially';
    is_deeply \@ARGV, [ qw( bar ) ], '@ARGV partially processed'
  } else {
    warning_like { ok !getopts( 'a:b', %got_opts ), 'Failed' } qr/illegal option -- d/, 'Check warning';
    is_deeply \%got_opts, {}, '%got_opts is empty';
    is_deeply \@ARGV, [ qw( -a foo -b -d bar ) ], '@ARGV restored'
  }
};

subtest 'Trailing common option with missing option-argument' => sub {
  local @ARGV = qw( -b -a foo -c );
  my %got_opts;
  if ( $module eq 'Getopt::Std' ) {
    plan tests => 3;

    # https://github.com/Perl/perl5/issues/23906
    # Getopt::Std questionable undefined value bahaviour
    ok !getopts( 'a:bc:', %got_opts ), 'Failed';
    is_deeply \%got_opts, { a => 'foo', b => 1, c => undef }, 'Options set';
    is @ARGV, 0, '@ARGV is empty'
  } else {
    plan tests => 4;

    warning_like { ok !getopts( 'a:bc:', %got_opts ), 'Failed' } qr/option requires an argument -- c/, 'Check warning';
    is_deeply \%got_opts, {}, '%got_opts is empty';
    is_deeply \@ARGV, [ qw( -b -a foo -c ) ], '@ARGV restored'
  }
};

subtest 'Common option with undefined option-argument' => sub {
  local @ARGV = ( '-b', '-a', undef, '-c' );
  my %got_opts;
  if ( $module eq 'Getopt::Std' ) {
    plan tests => 3;

    ok getopts( 'a:bc', %got_opts ), 'Succeeded';
    is_deeply \%got_opts, { a => undef, b => 1, c => 1 }, 'Options set';
    is @ARGV, 0, '@ARGV is empty'
  } else {
    plan tests => 4;

    warning_like { ok !getopts( 'a:bc', %got_opts ), 'Failed' } qr/option requires an argument -- a/, 'Check warning';
    is_deeply \%got_opts, {}, '%got_opts is empty';
    is_deeply \@ARGV, [ ( '-b', '-a', undef, '-c' ) ], '@ARGV restored'
  }
};

subtest 'Non-option-argument stops option parsing' => sub {
  plan tests => 3;

  local @ARGV = qw( -b -a foo bar -c );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'foo', b => 1 }, 'Options properly set';
  is_deeply \@ARGV, [ qw( bar -c ) ], 'Options removed from @ARGV'
};

subtest 'The option delimiter is a non-option-argument that stops option parsing' => sub {
  plan tests => 3;

  local @ARGV = qw( -b - a foo bar -c );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { b => 1 }, 'Options properly set';
  is_deeply \@ARGV, [ qw( - a foo bar -c ) ], 'Options removed from @ARGV'
};

subtest 'Overwrite option-argument' => sub {
  plan tests => 3;

  local @ARGV = qw( -a foo -b -a bar -c );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => 'bar', b => 1, c => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
};

subtest 'Slurp option' => sub {
  plan tests => 3;

  local @ARGV = qw( -a -b -c );
  ok getopts( 'a:bc', my %got_opts ), 'Succeeded';
  is_deeply \%got_opts, { a => '-b', c => 1 }, 'Options properly set';
  is @ARGV, 0, '@ARGV is empty'
}
